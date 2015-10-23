

require 'rubygems'
require 'swapdmi'

def assertTrue(expression)
	throw :assert unless expression
end

def assertFalse(expression)
	throw :assert if expression
end

TestContext = SwapDmi::ContextOfUse.new(:test)
TestModelData = Hash.new {|h,k| h[k] = Hash.new }

TestModelImpl = SwapDmi::ModelImpl.new(:test)
TestContext.setImpl(:default, :test)

puts 'check model impl'
modelImpl = SwapDmi::ModelImpl.instance(:test)
assertTrue(modelImpl == TestModelImpl)
assertTrue(modelImpl == TestContext.impl)

puts 'define model impl logic'
TestModelImpl.define(:test, :data, :set) {|mid,k,v| TestModelData[mid][k] = v}
TestModelImpl.define(:test, :data, :get) {|mid,k| TestModelData[mid][k] }
TestModelImpl.define(:test, :data, :get, :deeper) {|mid,k| TestModelData[mid][k] }
TestModelImpl.define(:test, :data, :list) {|mid| TestModelData[mid].keys }

TestModelImpl.define(:test, :checkScope) do |*args|
	check = (self == TestModelImpl)
	"model scope check => #{check} : #{args.join(',')}"
end
puts '1st model scope check'
puts TestModelImpl[:test, :checkScope].call(1,2,3)


	
puts 'define schema: model'
class TestModel < SwapDmi::Model
	attr_reader :dsv
	
	def initializeModel(sundry)
		@dsv = sundry[:dsv]
	end
	
	def [](k)
		self.impl[:test,:data,:get].call(self.id,k)
	end
	
	def deep(k)
		self.impl[:test,:data,:get,:deeper].call(self.id,k)
	end
	
	def []=(k,v)
		self.impl[:test,:data,:set].call(self.id,k,v)
		self.impl[:test,:data,:get].call(self.id,k) 
	end
	
	def values()
		self.impl[:test,:data,:list].call(self.id)
	end
	
end

puts 'define schema: data source'
class TestDataSource < SwapDmi::SmartDataSource
	defineDefaultModelType TestModel
	whiteListModelType TestModel
	fetchResolvesNil
	
	defineModelPreInit do |id| 
		{:id => id, :dsv => self.dsv}
	end
	
	attr_reader :dsv
		
	def initializeModel(sundry)
		@dsv = sundry[:value] 
	end
	
end

puts 'init & check data source'
TestContext.defineDataSource(TestDataSource, :value => 123)
testDataSource = TestDataSource[:test]
assertFalse(testDataSource.nil?)
assertTrue(testDataSource.id == :test)
assertTrue(testDataSource.context == TestContext)
assertTrue(testDataSource.impl == TestModelImpl )
assertTrue( testDataSource.dsv == 123)

puts '2nd model scope check'
puts testDataSource.impl()[:test, :checkScope].call(4,5,6)

puts 'test data A'
testModelA = testDataSource[:a]
assertFalse(testModelA.nil?)
assertTrue(testModelA.id == :a)
assertTrue(testModelA.context == TestContext)
assertTrue(testModelA.impl == TestModelImpl)
assertTrue(testModelA.dsv == 123)
testModelA[:a] = 'aa'
assertTrue(testModelA[:a] == 'aa')
assertTrue(testModelA.deep(:a) == 'aa')
assertTrue(testModelA.values.include?(:a))
testModelA[:b] = 'ab'
assertTrue(testModelA[:b] == 'ab')
assertTrue(testModelA.deep(:b) == 'ab')
assertTrue(testModelA.values.include?(:b))

puts 'test data B'
testModelB = testDataSource[:b]
assertFalse(testModelB.nil?)
assertTrue(testModelB.id == :b)
assertTrue(testModelB.context == TestContext)
assertTrue(testModelB.impl == TestModelImpl)
assertTrue(testModelB.dsv == 123)
testModelB[:a] = 'ba'
assertTrue(testModelB[:a] == 'ba')
assertTrue(testModelB.deep(:a) == 'ba')
assertTrue(testModelB.values.include?(:a))
testModelB[:b] = 'bb'
assertTrue(testModelB[:b] == 'bb')
assertTrue(testModelB.deep(:b) == 'bb')
assertTrue(testModelB.values.include?(:b))		
	
puts 'test complete. no problems'
