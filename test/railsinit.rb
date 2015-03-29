
require 'rubygems'
require 'swapdmi-core'

#mock rails logger
class Logger

	def debug(m)
		nil
	end

end

class RailsRoot 

	def join(*other)
		result = './rails'
		other.each {|o| result += "/#{o}" }
		result
	end

end

#mock rails object to get constants from & stuff
class Rails

	def self.root
		@root = RailsRoot.new if @root.nil?
		@root
	end


	def self.env
		'env'
	end

	def self.logger()
		@logger = Logger.new if @logger.nil?
		@logger
	end
end


yaml = { 'env' => {
	'swapdmi.loadDomainDefinitions' => [
		'test'
	],
	'swapdmi.loadDomainImplementations' => [
		'testimpl'

	],
	'swapdmi.defaultModelLogicId' => 'test'	
}}


SwapDmi::SwapDmiInit.invoke(:rails, :cfg => yaml)



