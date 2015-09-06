

#
# adds specialized session tracking support
#
# This extension integrates with the base logging extension, if that extension is present.
#	SessionHandling instances will have access to logging
#
# similar in execution to the basic logging extension, with the exception
#	that all session handling activities must go to the linked SessionHandling object,
#	there is no convient parseSession() methods on Model, ContextOfUse, etc.
#
# the default configuration stores sessions by session-id & user-id
#	in a shared 2-level hash (shared thru-out SwapDmi module)
# a user may only have 1 open session at a time, closed sessions are immediatly deleted from the session-store 
#
# the extension supports API calls for complex search over sessions, but does not implement anything by default
#	if you want/need this capability, you will need to write it yourself
#
module SwapDmi
	SwapDmi.declareExtension(:sessionhandle) 
	
	class SessionInfo
		attr_reader :id, :uid, :expire, :sundry
		
		def initialize(id, uid, expire)
			@id = id
			@uid = uid
			@expire = expire
			@sundry = {}
		end
		
		def withSundry(args = {})
			@sundry.merge!(args)
			self
		end
		
	end
	
	DefaultSessionStore = {
		:sid => {},
		:uid => {}
	}
	
	DefaultSessionFetchForUser = Proc.new do |uid, sundry|
		SwapDmi::DefaultSessionStore[:uid][uid]
	end
	
	DefaultSessionFetchById = Proc.new do |sid|
		SwapDmi::DefaultSessionStore[:sid][sid]
	end
	
	DefaultSessionParsing = Proc.new do |raw|
		SwapDmi::SessionInfo.new(
			raw[:sid], raw[:uid], raw[:expire]
		).withSundry(raw)
	end
	
	DefaultSessionTracking = Proc.new do |session|
		old = SwapDmi::DefaultSessionStore[:uid][session.uid]
		SwapDmi::DefaultSessionStore[:sid].delete(old.id) unless old.nil?
		SwapDmi::DefaultSessionStore[:uid][session.uid] = session
		SwapDmi::DefaultSessionStore[:sid][session.id] = session
		session
	end
	
	class SessionHandling
		extend TrackClassHierarchy
		extend HasConfig
		extend HasLog if SwapDmi.hasExtensions?(:logging)
		
		def initialize(id)
			assignId(id)
		end
		
		def defineFetchForUser(&fetch)
			@userFetch = fetch.nil? ? SwapDmi::DefaultSessionFetchForUser : fetch
			@userFetch = fetch
			self
		end
		def fetchForUser(uid, sundry = {})
			@userFetch = SwapDmi::DefaultSessionFetchForUser if @userFetch.nil?
			@userFetch.call(uid, sundry)
		end
		def hasForUser?(uid, sundry = {})
			fetchForUser(uid,sundry).nil? ? false : true
		end
		
		def defineFetch(&fetch)
			@idFetch = fetch.nil? ? SwapDmi::DefaultSessionFetchById : fetch
			self
		end
		def fetch(sid)
			@idFetch = SwapDmi::DefaultSessionFetchById if @idFetch.nil?
			@idFetch.call(sid)
		end
		def has?(sid)
			fetch(sid).nil? ? false : true
		end
		
		def canSearch?()
			!@search.nil?
		end
		def defineSearch(&search)
			@search = search
			self
		end
		def search(criteria = {})
			@search.call(criteria)
		end
		
		def defineParsing(&parse)
			@parse = parse.nil? ? SwapDmi::DefaultSessionParsing : parse
			self
		end
		def parse(raw)
			@parse = SwapDmi::DefaultSessionParsing if @parse.nil?
			@parse.call(raw)
		end
		
		def defineTracking(&track)
			@track = track.nil? ? SwapDmi::DefaultSessionTracking : track
			self
		end
		def track(session)
			@track = DefaultSessionTracking if @track.nil?
			@track.call(session)
			session
		end
		
		def parseTrack(raw)
			self.track(self.parse(raw))
		end
	end
		
	SwapDmi::SessionHandling.new(:default)
	
	module HasSessionHandling
		
		def self.extended(base)
			handlerTable = Hash.new do |instances,id|
				instances[id] = :default
				
			end
			base.class_variable_set(:@@sessionHandler, handlerTable)
			base.instance_eval { include SwapDmi::HasSessionHandling::Instance }
		end
		
		def allSessionHandling()
			self.class_variable_get(:@@sessionHandler)
		end
		
		def defineSessionHandling(id, shid)
			self.logging[id] = shid
			self
		end
		
		def sessionHandling(id)
			shid = self.allSessionHandling[id]
			SwapDmi::SessionHandling[shid]
		end
		
		module Instance
			
			def defineSessionHandling(shid)
				self.class.allSessionHandling[self.id] = shid
				self
			end
			
			def sessionHandling()
				shid = self.class.allSessionHandling[self.id]
				SwapDmi::SessionHandling[shid]
			end
		end
		
	end
	
	class ModelImpl
		extend HasSessionHandling
	end
	
	class ContextOfUse
		extend HasSessionHandling
	end
	
	class Model
		
		def sessionHandling()
			self.context.sessionHandling
		end
		
		protected :sessionHandling
		
	end
		
end






