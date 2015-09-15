
require 'rubygems'
require 'swapdmi'
require 'swapdmi/ext/logging'

require 'stringio'

#
# create a mock logger class,
#	so we can confirm messages logged programmatically
#
#
class LogMsg
	attr_reader :severity, :progname, :mssg 
	
	def initialize(sev, pnm, m)
		@severity, @progname, @mssg = sev, pnm, m
	end
end

class MockLogger < Logger

	attr_reader :mockCache, :io
	
	def initialize(&trans)
		@io = StringIO.new("")
		super(@io)
		@transform = trans
		@mockCache = Hash.new do |cache,sev|
			cache[sev] = []
		end
	end

	def add(s, m = nil, pn = nil, &block)
		s ||= Logger::Severity::UNKNOWN
		pn ||= self.progname
		
		if m.nil?
			if block_given?
				m = yield
			else
				m = pn
				pn = self.progname
			end
		end
		
		@mockCache[s] << LogMsg.new(s,pn,@transform.call(s,m))
		true
	end
	alias :log :add
	
end

#
# check module inclusion
#
puts 'checking extension has loaded'
throw :assertExtension unless SwapDmi.hasExtensions?(:logging)

#
# asserts & stuff
#
def assertContains(label, level, sym, mockLogger)
	selection = mockLogger.mockCache[level].map {|lm| lm.mssg}
	throw "miss #{label}: lv.#{level} -> #{sym}" unless selection.include?(sym)
end

def tosym(*ids)
	ids.join("_").to_sym
end

def assertNotNil(obj)
	throw :nil if obj.nil?
end

#
# set up
#
puts 'setup context & impl'

$logLevels = [Logger::Severity::INFO, Logger::Severity::DEBUG, Logger::Severity::ERROR]

$context = SwapDmi::ContextOfUse.new(:test)
$impl = SwapDmi::ModelImpl.new(:test)
[1,2,3].each do |icall| $impl.define(icall) do |id| 
	$logLevels.each {|sev| logger.log(sev,"impl: #{icall} #{id}") }
	log("impl: #{icall} #{id} default")
end end
$context.setImpl(:default, :test)

puts 'define schema'
class TestModel < SwapDmi::Model
	def [](icall)
		puts "calling: #{id}.#{icall}"
		$logLevels.each {|sev| logger.log(sev,"model: #{icall} #{id}") }
		log("model: #{icall} #{id} default")
		impl[icall].call(id)
		icall
	end
end

class TestDataSource < SwapDmi::DataSource
	defineDefaultModelType TestModel
	fetchResolvesNil
	
	def [](id)
		$logLevels.each {|sev| logger.log(sev,"datasource: #{id}") }
		log("datasource: #{id} default")
		super(id)
	end
end

$context.defineDataSource(TestDataSource)

#
# setup loggers
#

puts 'setup loggers'
$modelLogger = MockLogger.new do |sev,m|
	case m
		when /^model[:] (\d+) (\d+)$/
			tosym($1,$2)
		when /^model[:] (\d+) (\d+) default$/
			tosym($1,$2,:default) 
		when /^datasource[:] (\d+)$/
			tosym($1)
		when /^datasource[:] (\d+) default$/
			tosym($1,:default)
		else
			"fail: #{m}"
	end
end
$modelLogger.progname = "MODEL/DS"
SwapDmi::LogRegistry.register(:context, $modelLogger)
$context.defineLogger(:context)

$implLogger = MockLogger.new do |sev,m|
	case m
		when /^impl[:] (\d+) (\d+)$/
			tosym($1,$2)
		when /^impl[:] (\d+) (\d+) default$/
			tosym($1,$2,:default) 
		else
			"fail: #{m}"
	end
end
$implLogger.progname = "IMPL"
SwapDmi::LogRegistry.register(:impl, $implLogger)
$impl.defineLogger(:impl)

#
# do tests
#
puts 'start test'

(1..10).each do |id| [1,2,3].each do |icall|
	puts "#{id} -> #{icall}"
	
	dsource = TestDataSource[:test]
	assertNotNil(dsource)
	model = dsource[id]
	assertNotNil(model)
	model[icall]
	
	$logLevels.each do |level|
		assertContains(:datasource, level, tosym(id), $modelLogger)
		assertContains(:model, level, tosym(icall,id), $modelLogger)
		assertContains(:impl, level, tosym(icall,id), $implLogger)
	end
	
	assertContains(:datasource, Logger::Severity::INFO, tosym(id,:default), $modelLogger)
	assertContains(:model, Logger::Severity::INFO, tosym(icall,id,:default), $modelLogger)
	assertContains(:impl, Logger::Severity::INFO, tosym(icall,id,:default), $implLogger)
	puts "\n"
	
end end

3.times { puts "\n" }
puts 'test complete'
