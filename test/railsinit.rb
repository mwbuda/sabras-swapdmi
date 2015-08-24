
require 'rubygems'
require 'swapdmi'

#set global flag picked up by the initializer to not bring in real rails libraries
$test = true

#mock rails logger
class Logger

	def debug(m)
		nil
	end

end

#we use this to mock up the rails root directory.
#	for this to work, ensure that you are running the test script from the gem project's test directory
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

module ActionController
class Base
	#nothing else required, we just need it around to be extended by the initializer
	
end	end

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

puts 'test complete. no problems encountered'

