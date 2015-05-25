
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

require 'swapdmi-core'
require 'action_controller'

#do this to resolve rails' stupid autoloading stuff
RailsBaseController = ActionController::Base

module SwapDmi
	
	RailsSessionTracking = Proc.new do |session|
		railsSession = Thread.current[:railsSession]
		railsSession[:sid] = session.id
		railsSession[:uid] = session.uid
		railsSession[:expire] = Time.now + session[:expire]
		session.sundry.each {|k,v| railsSession[k.to_sym] = v}
		session
	end
	
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
		
		def invoke(args = {})
			Rails.logger.debug('initializing SwapDmi')
			
			SwapDmi.enableRailsSessionAccess if args[:enableRailsSessionAccess]
			
			xcfg = args[:cfg]
			xcfg = YAML.load_file( Rails.root.join('config','swapdmi.yml') ) if xcfg.nil?
			cfg = xcfg[Rails.env]
	
			SwapDmi::ModelLogic.defineLogging {|message| Rails.logger.debug(message)}
	
			Rails.logger.debug('SwapDmi: load Domain Definitions')
			domainDefs = cfg['swapdmi.loadDomainDefinitions']
			domainDefs = [] if domainDefs.nil?
			domainDefs.each {|domainModels| Kernel.require Rails.root.join('app/models', domainModels) }		
	
			Rails.logger().debug('SwapDmi: load Configuration Parameters')
			cfps = cfg['swapdmi.config']
			unless cfps.nil? 
			cfps.each do |instance,params|
				next if params.nil?
				params.each {|k,v| SwapDmi::ModelLogic.config[instance.to_sym][k.to_sym] = v}		
			end end
				
			Rails.logger.debug('SwapDmi: load Logic Implementations')
			impls = cfg['swapdmi.loadDomainImplementations']
			impls = [] if impls.nil?
			impls.each {|modelImpl| Kernel.require Rails.root.join('app/models', modelImpl) }
				
			defaultLogicId = cfg['swapdmi.defaultModelLogicId']
			SwapDmi::ModelLogic.defineDefault(defaultLogicId.to_sym) unless defaultLogicId.nil?
	
			mergeDelgs = cfg['swapdmi.setMergeDelegates']
			mergeDelgs = {} if mergeDelgs.nil?
			mergeDelgs.each do |mk, delegates| 
				SwapDmi::ModelLogic.instance(mk).delegateTo(*delegates)
			end
	
			Rails.logger.debug('done initializing SwapDmi')
		end
	end 

end

