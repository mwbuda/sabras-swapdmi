
require 'rubygems'
require 'swapdmi'
require 'swapdmi/ext/caching'

#
# check module inclusion
#
puts 'Checking if extension has loaded - Caching Extension'
throw :assertExtension unless SwapDmi.hasExtensions?(:caching)


#check cache readying

#	can't use cache w/ out def save & get
	#TODO

#	ready cache, ensure can't reconfigure
	#TODO

#check the default cache logic

#	cache key matching
	#TODO

#	data in, data out 
	#TODO

#	eviction (evict time = 0)
	#TODO

# Test is completed - Output stuff
puts 'Caching Test Completed'
