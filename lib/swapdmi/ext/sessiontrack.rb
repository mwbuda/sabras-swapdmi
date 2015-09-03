

#
# adds specialized session tracking support
#
#
#
#
#
module SwapDmi
	SwapDmi.declareExtension(:sessiontrack) 
	
	class SessionInfo
		attr_reader :id, :uid, :expire, :sundry
		
		def initialize(id, uid, expire)
			@id = id
			@uid = uid
			@expire = expire
			@sundry = []
		end
		
		def withSundry(args = {})
			@sundry.merge!(args)
			self
		end
		
	end
	
	DefaultSessionTracking = Proc.new {|session| session}
	DefaultSessionParsing = Proc.new do |raw| 
		SwapDmi::SessionInfo.new(raw[:id], raw[:uid], raw[:expire])
	end
	
	class SessionHandling
		extend TrackClassHierarchy
		extend HasConfig
		extend HasLog if SwapDmi.hasExtensions?(:logging)
		
		def initialize(id)
			assignId(id)
		end
		
		def defineParsing(&parse)
			@parse = parse.nil? ? SwapDmi::DefaultSessionParsing : parse
			self
		end
		
		def defineTracking(&track)
			@track = track.nil? ? SwapDmi::DefaultSessionTracking : track
			self
		end
		
		def parse(raw)
			@parse = DefaultSessionParsing if @parse.nil?
			@parse.call(raw)
		end
		
		def trackSession(session)
			@track = DefaultSessionTracking if @track.nil?
			@track.call(session)
			session
		end
		
		def parseTrackSession(raw)
			self.trackSession(self.parseSession(raw))
		end
	end
		
	SwapDmi::SessionHandling.new(:default)
	
	module HasSessionHandling
		
		def self.extended(base)
			handlerTable = Hash.new do |instances[id]|
				instances[id] = :default
				
			end
			base.class_variable_set(:@@sessionHandler, handlerTable)
			base.instance_eval { include SwapDmi::HasSessionHandling::Instance }
		end
		
		def sessionHandling()
			self.class_variable_get(:@@sessionHandler)
		end
		
		def defineSessionHandler(id, shid)
			self.logging[id] = shid
			self
		end
		
		def sessionHandler(id)
			shid = self.sessionHandling[id]
			SwapDmi::SessionHandling[shid]
		end
		
		module Instance
			
			def defineSessionHandler(shid)
				self.class.sessionHandling[self.id] = shid
				self
			end
			
			def sessionHandler()
				shid = self.class.sessionHandling[self.id]
				SwapDmi::SessionHandling[shid]
			end
			
			def parseSession(raw)
				self.sessionHandler.parseSession(raw)
			end
			
			def trackSession(session)
				self.sessionHandler.trackSession(session)
			end
			
			def parseTrackSession(raw)
				self.sessionHandler.parseTrackSession(raw)
			end
			
			protected :sessionHandler, :parseSession, :trackSession, :parseTrackSessio
	
		end
		
	end
	
	class ModelImpl
		extend HasSessionHandling
	end
	
	class ContextOfUse
		extend HasSessionHandling
	end
	
	class Model
		
		def sessionHandler()
			self.context.sessionHandler
		end
		
		def parseSession(raw)
			self.sessionHandler.parseSession(raw)
		end
		
		def trackSession(session)
			self.sessionHandler.trackSession(session)
		end
		
		def parseTrackSession(raw)
			self.sessionHandler.parseTrackSession(raw)
		end
		
		protected :sessionTracker, :parseSession, :trackSession, :parseTrackSession
		
	end
		
end






