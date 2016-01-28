

require 'rubygems'
require 'swapdmi'

def assertTrue(expression)
	throw :assert unless expression
end

def assertFalse(expression)
	throw :assert if expression
end

#create basic model logic implentations

Setup = {
	:a => 2,
	:b => 3,
	:c => 5,
}

Priority = {
	:a => 200,
	:b => nil,
	:c => 300
}

GPriority = {
	:a => nil,
	:b => nil,
	:c => -1
}

def vcalc(k, arg, multiplier)
	"#{k}#{arg * multiplier}".to_sym
end

puts 'create delegate model logic impls'
Delegates = {}
Setup.each do |key, multiplier|
	puts "\t creating delegate #{key}"
	mlogic = SwapDmi::ModelImpl.new(key)
	
	mlogic.define(:array) do |f, args|
		args.map {|a| vcalc(key,a,multiplier) }
	end
	
	mlogic.define(:scalar, :one) do |f, a1,a2,a3|
		vcalc(key,a1+a2+a3,multiplier)
	end
	
	mlogic.define(:scalar, :two) do |f, a1,a2,a3|
		vcalc(key,a1+a2+a3,multiplier)
	end
	
	mlogic.define(:priority) do
		key
	end
	
	mlogic.define(:gpriority) do
		key
	end
	
	mlogic.define(:checkId) do
		self.id
	end
	
	Delegates[key] = mlogic
end

puts 'create merge model logic'
#create a merge b/w them
Merge = SwapDmi::MergedModelImpl.new(:merge) 
Merge.delegateTo(*Setup.keys)

puts 'create filters'
Setup.keys.each do |k|
	puts "\t filters for #{k}" 
	Merge.defineFilterFor(k, :array)        {|dk, d, filter, args| filter =~ /#{dk}/} 
	Merge.defineFilterFor(k, :scalar, :one) {|dk, d, filter, args| filter =~ /#{dk}/}
	puts "\tset priority for #{k}"
	Merge.defineCallPriorityFor(k, Priority[k], :priority)
	Merge.defineGlobalCallPriorityFor(k, GPriority[k])
end

puts 'define array logic'
Merge.define(:array) do |aggregate|
	res = []
	aggregate.results.each {|sres| res += sres}
	res
end

puts 'define scalar one logic'
Merge.define(:scalar, :one) do |aggregate|
	aggregate.results
end

puts 'define scalar two logic'
Merge.define(:scalar, :two) do |aggregate|
	aggregate.results
end

puts 'define priority logic'
Merge.define(:priority) do |aggregate|
	aggregate.results
end

puts 'define gpriority logic'
Merge.define(:gpriority) do |aggregate|
	aggregate.results
end

puts 'define check id logic'
Merge.define(:checkId) do |aggregate|
	"#{self.id}(#{aggregate.delegates.sort.join(',')})"
end

#execute the model logic and ensure proper results

def verifyInResults(expected, *results)
	results.include?(expected)
end

#test array output
def executeTest1(filter)
	puts "execute test 1 #{filter}"	
	args = [1,2,3]
	results = SwapDmi::ModelImpl[:merge][:array].call(filter, args)
	puts "\tinvoke done"
		
	Setup.each do |k,multiplier|
		puts "\tverify #{k}"
		isFiltered = filter =~ /#{k}/
		expecteds = args.map {|a| vcalc(k,a,multiplier) }
		verifys = expecteds.map {|e| verifyInResults(e, *results)}
			
		if isFiltered
			assertTrue(verifys.reduce {|acc,v| acc && v}) 
		else
			assertFalse(verifys.reduce {|acc,v| acc || v})
		end
	end
	
end

#test scalar one output
def executeTest2(filter)
	puts "execute test 2 #{filter}"
	args = [1,2,3]
	sumArg = args.reduce(:+)
	results = SwapDmi::ModelImpl[:merge][:scalar,:one].call(filter, *args)
	puts "\tinvoke done"
		
	Setup.each do |k,multiplier|
		puts "\tverify #{k}"
		isFiltered = filter =~ /#{k}/
		expected = vcalc(k,args.reduce(:+),multiplier)
		verify = verifyInResults(expected, *results)
			
		if isFiltered
			assertTrue(verify) 
		else
			assertFalse(verify)
		end
	end
end

# test scalar two output
def executeTest3(filter) 
	puts "execute test 3 #{filter}"
	args = [1,2,3]
	results = SwapDmi::ModelImpl[:merge][:scalar,:two].call(filter, *args)
	puts "\tinvoke done"
		
	Setup.each do |k,multiplier|
		puts "\tverify #{k}"
		expected = vcalc(k,args.reduce(:+),multiplier)
		verify = verifyInResults(expected, *results)
		assertTrue(verify) 
	end
end

def executePriorityTest()
	puts 'execute priority test: global'
	results = SwapDmi::ModelImpl[:merge][:gpriority].call.join
	puts "\t'#{results}'"
	assertTrue(results == 'abc')
	
	puts 'execute priority test: per action'
	results = SwapDmi::ModelImpl[:merge][:priority].call.join
	puts "\t'#{results}'"
	assertTrue(results == 'cab')
	
end

def executeCheckIdTest()
	puts 'execute check id/scope test'
	res = SwapDmi::ModelImpl[:merge][:checkId].call()
	assertTrue(res == 'merge(a,b,c)')
end

executeTest1("abc")
executeTest1("ab")
executeTest1("a")

executeTest2("abc")
executeTest2("ab")
executeTest2("a")

executeTest3("abc")
executeTest3("ab")
executeTest3("a")

executePriorityTest()
executeCheckIdTest()
puts 'all tests pass, complete'


