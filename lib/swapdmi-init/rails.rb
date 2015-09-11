
#
# a Ruby on Rails specific initializer.
#	generally, you want to add a new script under Rails config/initializers which and configures the initializer, 
#	and then calls the invoke method
#
# the initilizer follows these conventions:
#	* definition of domain objects & implementations will be under Rails app/models root
#	* initializer will be configured via config/models.yml
#		- 'swapdmi.loadDomainDefinitions': array of domain model definitions library files
#		- 'swapdmi.loadDomainImplementations': array of domain model implemenation files (functors)
#		- 'swapdmi.defaultModelLogicId': default model logic id. this should ALWAYS be provided.
#		- 'swapdmi.setMergeDelegates': key->array hash defining ModelLogicMerge delegates
#

require 'swapdmi'
require 'swapdmi/ext/sessionhandle'
require 'swapdmi/ext/logging'

#ruby on rails specific required libraries.
#	we put this in a guard for purposes of testing the extension,
#	since Rails does not play nice with randomly requiring in components, and we don't want a full rails stack
#	in a unit test anyway.
#	
#	see applicable unit/integ tests for whatever we are currently doing to mock up rails functionality	
#
unless $test
	require 'action_controller'
end
	
#do this to resolve rails' stupid autoloading stuff
RailsBaseController = ActionController::Base

module SwapDmi
	
	#swapDmi logger wh/ will integrate with rails logger
	RailsLogger = SwapDmi::Logger.new(:rails) do |level,m|
		clevel = level.to_s.downcase.to_sym
		case level
			when :debug then Rails.logger.debug(m)
			when :info then Rails.logger.info(m)
			when :warn then Rails.logger.warn(m)
			when :error then Rails.logger.error(m)
			when :fatal then Rails.logger.fatal(m)
			when :unknown then Rails.logger.unknown(m)
		end
	end
	
	#extend SessionInfo for de/serializing to/from Rails Session objects
	class SessionInfo
		def self.fromRails(railsSession)
			return nil if railsSession.nil?
					
			start = railsSession[:start]
			expire = railsSession[:expire]
			sid = railsSession[:sid]
			uid = railsSession[:uid]
			
			have = [start,sid,uid].reduce(false) {|acc,x| acc or x.nil?}	
			return nil unless have
			
			cexpire = expire.nil? ? nil : expire - start
				
			sundry = {}
			railsSession.keys.each do |k|
				ksym = k.to_sym
				next if [:start,:expire,:sid,:uid].include?(ksym)
				sundry[ksym] = railsSession[ksym]
			end
			
			SwapDmi::SessionInfo.new(
				railsSession[:sid], railsSession[:uid], cexpire
			).withSundry(sundry).withStartTime(Time.at(start))	
		end
		
		def updateRailsSession(railsSession)
			return false if rails.nil?
			railsSession[:sid] = self.id
			railsSession[:uid] = self.uid
			railsSession[:start] = self.startTime
			railsSession[:expire] = self.expireTime.to_i if self.willExpire?
			self.sundry.each {|k,v| railsSession[k.to_sym] = v}
			true
		end
	end
	
	#define a SessionHandling wh/ will integrate with Rails
	RailsSessionHandling = SwapDmi::SessionHandling.new(:rails)
	
	RailsSessionHandling.defineFetchForUser(&nil)
	RailsSessionHandling.defineFetch(&nil)
	
	RailsSessionHandling.defineFetchCurrent do 
		railsSession = Thread.current[:railsSession]
		session = SwapDmi::SessionInfo.fromRails(railsSession)
		Thread.current[:swapdmiSession] = session unless session.nil?
		session
	end
	
	RailsSessionHandling.defineTracking do |session|
		railsSession = Thread.current[:railsSession]
		session.updateRails(railsSession)
		Thread.current[:swapdmiSession] = session unless railsSession.nil?		
		railsSession.nil? ? nil : session
	end
	
	#need to module-extend BaseController to capture session where we can get at it
	#	(thread local variable)
	module RailsSessionAccessExtension
		def enableSwapDmiSessionAccess()
			define_method(:swapdmiExposeSession) {Thread.current[:railsSession] = session}
			before_action :swapdmiExposeSession
		end
	end
	
	def self.enableRailsSessionAccess(isGlobal = true)
		RailsBaseController.extend(SwapDmi::RailsSessionAccessExtension)
		RailsBaseController.enableSwapDmiSessionAccess() if isGlobal
	end
	
	class RailsInit < SwapDmi::SwapDmiInit
		registerInitAs :rails
		
		def defaultArgs()
			{
				:enableRailsSessionAccess => true
			}
		end
		
		def invoke(args = {})
			Rails.logger.debug('initializing SwapDmi')
			
			if args[:enableRailsSessionAccess]
				SwapDmi.enableRailsSessionAccess
				SwapDmi::SessionHandling.defineDefaultInstance(:rails)
			end

			SwapDmi::Logger.defineDefaultInstance(:rails)			
				
			xcfg = args[:cfg]
			xcfg = YAML.load_file( Rails.root.join('config','swapdmi.yml') ) if xcfg.nil?
			cfg = xcfg[Rails.env]
	
			loadConfig(SwapDmi::ContextOfUse, 'schema', cfg)
			loadConfig(SwapDmi::ModelImpl, 'impl', cfg)
			loadFiles(cfg)
			loadMergeDelegates(cfg)
			loadBindImpls(cfg)
			
			Rails.logger.debug('done initializing SwapDmi')
		end
		
		def loadFiles(cfg)
			Rails.logger.debug('SwapDmi: load Model Files')
			paths = cfg['swapdmi.files'].nil? ? [] : cfg['swapdmi.files']
			paths.each do |path|
				Rails.logger.debug("SwapDmi:\t--> app/models/#{path}") 
				Kernel.require Rails.root.join('app/models', path)
			end
		end
		
		def loadConfig(klass, cfgroot, cfg)
			Rails.logger.debug('SwapDmi: load ContextOfUse config')
			cfgKey = "swapdmi.cfg.#{cfgroot}"
			allCfg = Hash.new {|h,k| h[k] = {}}
			rawCfg = cfg[cfgKey].nil? ? {} : cfg[cfgKey]
			allCfg.merge!(rawCfg)
			allCfg.each do |k,xcfg|
				Rails.logger.debug("SwapDmi:\t--> #{cfgroot} = #{k}") 
				klass.config(k.to_s.to_sym).merge!(xcfg)
			end
		end
		
		def loadMergeDelegates(cfg)
			Rails.logger.debug('SwapDmi: assign merge impl delegates')
			mergCfg = Hash.new {|h,k| h[k] = Array.new } 
			xcfg = cfg['swapdmi.bind.mergeDelegates'].nil? ? {} : cfg['swapdmi.bind.mergeDelegates']
			mergCfg.merge!(xcfg)
			mergCfg.each do |k,delegates|
				merge = ModelImpl[k.to_sym]
				next unless merge.respond_to?(:delegateTo)
				xds = delegates.map {|id| id.to_s.to_sym}
				merge.delegateTo(*xds)
			end
		end
		
		def loadBindImpls(cfg)
			Rails.logger.debug('SwapDmi: bind impl to schema')
			bindCfg = Hash.new {|h,k| h[k] = Hash.new}
			xcfg = cfg['swapdmi.bind'].nil? ? {} : cfg['swapdmi.bind']
			bindCfg.merge!(xcfg)
			bindCfg.each do |cxtk,binds|
				context = SwapDmi::ContextOfUse[cxtk.to_sym]
				if binds.instance_of?(Hash)
					binds.each {|nk,ik| context.setImpl(nk.to_s.to_sym, ik.to_s.to_sym) }
				else
					context.setImpl(SwapDmi::ContextOfUse::DefaultImplId, binds.to_s.to_sym)
				end
			end
		end
	end 

end

