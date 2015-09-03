
require 'rubygems'
require 'swapdmi'
require 'swapdmi/ext/logging'

#
# asserts & stuff
#
def assertContains(label, level, sym, list)
	throw "miss #{label}: lv.#{level} -> #{sym}" unless list[level].include?(sym)
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

$context = SwapDmi::ContextOfUse.new(:test)
$impl = SwapDmi::ModelImpl.new(:test)
[1,2,3].each do |icall| $impl.define(icall) do |id| 
	[1,2,3].each {|x| log(x,"impl: #{icall} #{id}") }
end end
$context.setImpl(:default, $impl)

puts 'define schema'
class TestModel < SwapDmi::Model
	def [](icall)
		puts "calling: #{id}.#{icall}"
		[1,2,3].each {|x| log(x,"model: #{icall} #{id}") }
		impl[icall].call(id)
		icall
	end
end

class TestDataSource < SwapDmi::DataSource
	defineDefaultModelType TestModel
	fetchResolvesNil
	
	def [](id)
		[1,2,3].each {|x| log(x,"datasource: #{id}") }
		super(id)
	end
end

$context.defineDataSource(TestDataSource)

#
# setup loggers
#

puts 'setup loggers'
$modelOut = Hash.new {|h,k| h[k] = [] }
$sourceOut = Hash.new {|h,k| h[k] = []}
$contextLogger = SwapDmi::Logger.new(:context) do |level,m|
	case m
		when /model[:] (\d+) (\d+)/
			$modelOut[level] << tosym($1,$2)
		when /datasource[:] (\d+)/
			$sourceOut[level] << tosym($1)
	end
end
$context.defineLogger(:context)

$implOut = Hash.new {|h,k| h[k] = []}
$implLogger = SwapDmi::Logger.new(:impl) do |level,m|
	if m =~ /impl[:] (\d+) (\d+)/
		$implOut[level] << tosym($1,$2)
	end
end
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
	
	[1,2,3].each do |level|
		assertContains(:datasource, level, tosym(id), $sourceOut)
		assertContains(:model, level, tosym(icall,id), $modelOut)
		assertContains(:impl, level, tosym(icall,id), $implOut)
	end
	puts "\n"
	
end end

3.times { puts "\n" }
puts 'test complete'
