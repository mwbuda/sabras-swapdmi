require 'rubygems'
require 'swapdmi'
require 'swapdmi/ext/caching'

#
# check module inclusion
#
puts 'Checking if extension has loaded - Caching Extension'
throw :assertExtension unless SwapDmi.hasExtensions?(:caching)



# Test is completed - Output stuff
puts 'Caching Test Completed'