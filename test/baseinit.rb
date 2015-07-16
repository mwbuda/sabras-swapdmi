

require 'rubygems'
require 'swapdmi-core'

def assertTrue(expression)
	throw :assert unless expression
end

def assertFalse(expression)
	throw :assert if expression
end

TestModelData = Hash.new {|h,k| h[k] = Hash.new }

TestModelLogic = SwapDmi::ModelLogic.new(:test)

TestModelLogic.define(:test, :data, :set) {|mid,k,v| TestModelData[mid][k] = v}
TestModelLogic.define(:test, :data, :get) {|mid,k| TestModelData[mid][k] }
TestModelLogic.define(:test, :data, :list) {|mid| TestModelData[mid].keys }
	
class TestModel < SwapDmi::Model
	
	attr_reader :id
	
	def initializeModel(sundry)
		@id = sundry[:id]
	end
	
	def [](k)
		self.logic[:test,:data,:get].call(@id,k)
	end
	
	def []=(k,v)
		self.logic[:test,:data,:set].call(@id,k,v)
		self.logic()[:test,:data,:get].call(@id,k) 
	end
	
	def values()
		self.logic[:test,:data,:list].call(@id)
	end
	
end

class TestDataSource < SwapDmi::DataSource
	
	def initializeModel(sundry)
		cxt = self.logic
		@models = Hash.new {|h,k| h[k] = TestModel.new(cxt, :id => k)}
	end
	
	def [](id)
		@models[id]
	end
	
end

modelLogicInstance = SwapDmi::ModelLogic.instance(:test)

assertTrue(modelLogicInstance == TestModelLogic)

TestDataSource.new(TestModelLogic)
testDataSource = TestDataSource[:test]
assertFalse(testDataSource.nil?)
assertTrue(testDataSource.logic == TestModelLogic)

testModelA = testDataSource[:a]
assertTrue(testModelA.logic == TestModelLogic)
testModelA[:a] = 'aa'
assertTrue(testModelA[:a] == 'aa')
assertTrue(testModelA.values.include?(:a))
testModelA[:b] = 'ab'
assertTrue(testModelA[:b] == 'ab')
assertTrue(testModelA.values.include?(:b))
	
testModelB = testDataSource[:b]
assertTrue(testModelB.logic == TestModelLogic)
testModelB[:a] = 'ba'
assertTrue(testModelB[:a] == 'ba')
assertTrue(testModelB.values.include?(:a))
testModelB[:b] = 'bb'
assertTrue(testModelB[:b] == 'bb')
assertTrue(testModelB.values.include?(:b))		
	
