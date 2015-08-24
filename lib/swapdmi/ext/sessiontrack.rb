

#
# adds specialized session tracking support
#
#
#
#
#

module SwapDmi
	
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
	DefaultSessionParsing = Proc.new {|raw| SessionInfo.new(raw[:id], raw[:uid], raw[:expire])}
	
	class ModelLogic
		
		def defineSessionParsing(&parsing)
			@sessionParsing = parsing.nil? ? DefaultSessionParsing : parsing
			self
		end
		
		def defineSessionTracking(&tracking)
			@sessionTracking = tracking.nil? ? DefaultSessionTracking : tracking
			self
		end
		
		def parseSession(raw)
			@sessionParsing = DefaultSessionParsing if @sessionParsing.nil?
			@sessionParsing.call(raw)
		end

		def trackSession(session)
			@sessionTracking = DefaultSessionTracking if @sessionTracking.nil?
			@sessionTracking.call(session)
			session
		end
		
		def parseTrackSession(raw)
			self.trackSession(self.parseSession(raw))
		end
		
	end
	
	class Model
		
		def extractAndTrackSession(rawSession)
			self.logic.parseTrackSession(rawSession)
		end
		protected :extractAndTrackSession
		
	end
		
end







