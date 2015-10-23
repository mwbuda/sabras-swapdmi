
require 'rubygems'
require 'swapdmi'
require 'swapdmi/ext/init'
require 'logger'
require 'stringio'

#set up asserts & stuiff

def assertNotNil(x)
	throw :nil if x.nil?
end

def assertEquals(exp, act)
	throw :bad unless exp == act
end

#set global flag picked up by the initializer to not bring in real rails libraries
$test = true

#mock rails logger
class MockLogger < Logger
	attr_reader :io
	
	def initialize()
		@io = StringIO.new("")
		super(@io)
	end
	
	def add(s, m = nil, pn = nil, &block)
		true
	end
	alias :log :add

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
		@logger = MockLogger.new if @logger.nil?
		@logger
	end
end

module ActionController
class Base
	def self.before_action(sym)
		#do nothing
	end
	
end	end

yaml = { 'env' => {
	'swapdmi.cfg.schema' => {
		'cxt1' => { 'a' => 1, 'b' => 2 },
		'cxt2' => { 'a' => 3, 'b' => 4 },
	},
	'swapdmi.cfg.impl' => {
		'imp1' => { 'a' => 1, 'b' => 2 },
		'imp2' => { 'a' => 3, 'b' => 4 },
	},
	'swapdmi.bind' => {
		'cxt1' => { 'a' => 'imp1', 'b' => 'imp2' },
		'cxt2' => { 'a' => 'imp2', 'b' => 'imp1' },
	},
	'swapdmi.files' => ['schema', 'context', 'impl'],
}}

SwapDmi::SwapDmiInit.invoke(:rails, :cfg => yaml)

puts 'init done. running tests to ensure everything loaded correctly'

{
	:cxt1 => [2,8],
	:cxt2 => [9,6]
	
}.each do |cxtk,pair|
	puts "test context #{cxtk}"
	dsource = Test::TestDataSource[cxtk]
	assertNotNil(dsource)
	model = dsource[1]
	assertNotNil(model)
	assertEquals(pair[0], model.a)
	assertEquals(pair[1], model.b)
end

puts 'test complete. no problems encountered'

