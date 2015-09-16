

require 'rubygems'
require 'swapdmi'
require 'swapdmi/ext/sessionhandle'

#
# check module inclusion
#
puts 'checking extension has loaded'
throw :assertExtension unless SwapDmi.hasExtensions?(:sessionhandle)

#
# asserts & stuff
#

def assertEquals(exp, act)
	throw :bad unless exp == act
end

def assertNotNil(obj)
	throw :nil if obj.nil?
end

def implsym(icall, uid, sid)
	"#{icall} -> #{uid} -> #{sid}".to_sym
end

#
# set up
#
puts 'setup context & impl'

$context = SwapDmi::ContextOfUse.new(:test)
$impl = SwapDmi::ModelImpl.new(:test)
[1,2,3].each do |icall| $impl.define(icall) do |id| 
	session = sessionHandling.fetchForUser(id)
	implsym(icall, id, session.id)
end end
$context.setImpl(:default, :test)

puts 'define schema'
class TestModel < SwapDmi::Model
	attr_reader :sessionId
	
	def initializeModel(sundry = {})
		@sessionId = sundry[:sessionId]
		@sessionSundry = sundry.select {|k,v| k != :sessionId}
	end
	
	def [](icall)
		impl[icall].call(id)
	end
	
	def login!()
		sessionHandling.parseTrack(:uid => id, :sid => sessionId) unless sessionHandling.hasForUser?(id)
	end

end

class TestDataSource < SwapDmi::DataSource
	defineDefaultModelType TestModel
	fetchResolvesNil
	
	defineModelInit do |id|
		sundry = {:sessionId => id*2}
		(1..3).each {|i| sundry["s#{i}".to_sym] = id + i}
		sundry 
	end
	
	def [](id)
		super(id)
	end
end

$context.defineDataSource(TestDataSource)

#
# set up session handling
#

$sessionHandling = SwapDmi::SessionHandling.new(:test)
$context.defineSessionHandling(:test)
$impl.defineSessionHandling(:test)

#
# run the damned tests
#

puts 'running tests'

(1..3).each do |i1| (1..3).each do |i2|
	puts "\t #{i1} #{i2}"
	
	model = TestDataSource[:test][i1]
	model.login!
	
	assertNotNil($sessionHandling.fetch(model.sessionId))
	assertNotNil($sessionHandling.fetchForUser(model.id))
	
	res = model[i2]
	
	assertEquals(implsym(i2, model.id, model.sessionId), res)
end end

puts "\n\n"
puts 'test done'

