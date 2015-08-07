

require 'rubygems'
require 'swapdmi-core'

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

def vcalc(k, arg, multiplier)
	"#{k}#{arg * multiplier}".to_sym
end

Delegates = {}
Setup.each do |key, multiplier|
	mlogic = SwapDmi::ModelLogic.new(key)
	
	mlogic.define(:array) do |f, args|
		args.map {|a| vcalc(key,a,multiplier) }
	end
	
	mlogic.define(:scalar, :one) do |f, a1,a2,a3|
		vcalc(key,a,multiplier)
	end
	
	mlogic.define(:scalar, :two) do |f, a1,a2,a3|
		vcalc(key,a,multiplier)
	end
	
	Delegates[key] = mlogic
	
end

#create a merge b/w them
Merge = SwapDmi::ModelLogicMerge.new(:merge) 
Merge.delegateTo(Setup.keys)

Setup.keys.each do |k| 
	filter
	Merge.defineFilterFor(k, :array) {|dk, filter, args| filter =~ /#{dk}/} 
	Merge.defineFilter For(k, :scalar, :one) {|dk, filter, args| filter =~ /#{dk}/}
end

Merge.define(:array) do |subres|
	res = []
	subres.values.each {|sres| res += sres }
	res
end

Merge.define(:scalar, :one) do |subres|
	subres.values
end

merge.define(:scalar, :two) do |subres|
	subres.values
end

#execute the model logic and ensure proper results

def verifyInResults(expected, *results)
	results.include?(expected)
end

#test array output
def executeTest1(filter)	
	args = [1,2,3]
	results = SwapDmi::ModelLogic[:merge][:array].call(filter, args)
	
	Setup.each do |k,multiplier|
		isFiltered = filter =~ /#{k}/
		expecteds = args.map {|a| vcalc(k,a,multiplier) }
		verifys = expectes.map {|e| verifyInResults(e, *results)}
			
		if isFiltered
			assertTrue(verifys.reduce {|acc,v| acc && v}) 
		else
			assertFalse(verifys.reduce {|acc,v| acc || v})
		end
	end
	
end

#test scalar one output
def executeTest2(filter)
	args = [1,2,3]
	sumArg = args.reduce(:+)
	results = SwapDmi::ModelLogic[:merge][:scalar,:one].call(filter, *args)
		
	Setup.each do |k,multiplier|
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
	args = [1,2,3]
	results = SwapDmi::ModelLogic[:merge][:scalar,:two].call(filter, *args)
	
	Setup.each do |k,multiplier|
		expected = vcalc(k,args.reduce(:+),multiplier)
		verify = verifyInResults(expected, *results)
		assertTrue(verify) 
	end
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

