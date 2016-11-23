
require 'rubygems'
require 'swapdmi'
require 'swapdmi/ext/modelMarshal'

###############################

def assertTrue(expression)
	throw :assert unless expression
end

def assertFalse(expression)
	throw :assert if expression
end

##############################

class TestA < SwapDmi::Model

	attr_accessor :a, :b, :c

end

ta = TestA.new(:ta)
ta.a = 1
ta.b = 2
ta.c = 3

bta = 

bta = SwapDmi.marshal(ta)
xta1 = SwapDmi.unmarshal(bta)
xta2 = Marshal::load(bta)

File.binwrite('./tmp', bta)
xta3 = SwapDmi.unmarshal( File.binread('./tmp') )
File.delete('./tmp')

assertTrue(xta2.id == ta.id)
assertTrue(xta2.modelClass == TestA)
assertTrue(xta2.contextOfUse == :default)
assertTrue(xta2.fields[:a] == ta.a)
assertTrue(xta2.fields[:b] == ta.b)
assertTrue(xta2.fields[:c] == ta.c)

assertTrue(xta1.id == ta.id)
assertTrue(xta1.a == ta.a)
assertTrue(xta1.b == ta.b)
assertTrue(xta1.c == ta.c)

puts 'test complete'
