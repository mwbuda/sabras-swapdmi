
require 'net/http'
require 'json'

module SwapDmi
SwapDmi.declareExtension(:restapi) 
module RestApi

	class RestApiError < StandardError
				
	end
	
	DefaultContentType = 'application/json;charset=utf-8'	

	DefaultErrorHandling = Proc.new do |uri, responseCode, errorBody|
		raise SwapDmi::RestApiError.new("#{uri} => #{responseCode}")
	end
	
	DefaultResponseProcessing = Proc.neew do |raw|
		JSON.parse(raw)
	end
	
	class RestApiImpl < SwapDmi::ModelImpl
		
		def initialize(id, host, contentType = SwapDmi::RestApi::DefaultContentType)
			super(id)
			@restResponseProcessing = SwapDmi::RestApi::DefaultResponseProcessing
			@contentType = contentType
			@host = host
			@setParams = {}
		end
		
		def restError(uri, responseCode, errorBody)
			@restErrorHandle.call(uri,responseCode, errorBody) unless @restErrorHandle.nil?
		end
		
		def defineRestErrorHandling(&proc)
			@restErrorHandle = proc 
			self
		end
		
		def defineResponseProcessing(&proc)
			@restResponseProcessing = proc
			self
		end
		
		def withSetParam(name, value)
			@setParams[name] = value
			self
		end
		
		def path(tail, params = {})
			result = "#{@host}/#{tail}?apiKey=#{apiKey}"
			qps = []
			@setParams.each {|k,v| qps << "#{k}=#{v}"}
			params.each {|k,v| qps << "#{k}=#{v}"}
			result += "?#{qps.join('&')}"
			URI.parse(result)
		end
		
		def processResponse(raw)
			@restResponseProcessing.nil? ? raw : @restResponseProcessing.call(raw)
		end
		
		def logRestCall(uri, method, headers = {}, body = nil)
			body = "#{uri} : #{method}"
			body += "\n\tBODY: "
			self.log(:info, "")
		end
		
		#TODO: expand to multiple calls as per ODET
		def callRest(uri)
			self.log(:info, uri) if self.respond_to?(:log)
			result = Net::HTTP.get_response(uri)
			restError(uri, "???", nil) if result.nil?
			restError(uri, "???", result.body) if result.code.nil?
			restError(uri, result.code.to_i, result.body) if (result.code.to_i / 100) != 2
			JSON.parse(result.body)
		end
		
		def restGet(uri, params = {})
			self.log(:info, "#{uri} : GET") if self.respond_to?(:log)
			result = Net::HTTP.get_response(uri)
			restError(uri, "???", nil) if result.nil?
			restError(uri, "???", result.body) if result.code.nil?
			restError(uri, result.code.to_i, result.body) if (result.code.to_i / 100) != 2
			processResponse(result)
		end
		
		def restPost(root, body = nil, params = {})
			self.log(:info, uri) if self.respond_to?(:log)
			
			
		end
		
		def restPut(root, body = nil, params = {})	
			
		end
		
		def restDelete(root, params = {})
			
		end
		
		def restOptions(root, params = {})
			
		end
		
		def restPatch(root, body = nil, params = {})
			
		end
	end
	
	
	
	
	
end end

