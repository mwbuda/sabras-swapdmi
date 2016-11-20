
require 'rubygems'
require 'swapdmi'
require 'swapdmi/ext/caching'

###############################

def assertTrue(expression)
	throw :assert unless expression
end

def assertFalse(expression)
	throw :assert if expression
end

##############################

$backing = Hash.new do |perCache, cacheid|
	perCache[cacheid] = {}
end
$timestamps = Hash.new do |perCache, cacheid|
	perCache[cacheid] = {}
end

$stash = SwapDmi::StashCacheLogic::Stash.new(:testme)
$stash.definePrepare do |cid, ck, data|
	data + 1
end
$stash.definePut do |cid, ck, data|
	$backing[cid][ck] = data
	$timestamps[cid][ck] = Time.now
end
$stash.defineParse do |cid, ck, raw|
	raw - 1
end
$stash.defineGet do |cid, ck|
	$backing[cid][ck]
end
$stash.defineRemove do |cid,ck|
	$backing[cid].delete(ck)
	$timestamps[cid].delete(ck)
end
$stash.defineSummary do |cid|
	$timestamps[cid].dup
end

puts 'test get stash by id'
assertTrue($stash == SwapDmi::StashCacheLogic::Stash[:testme])
assertTrue($stash == SwapDmi::StashCacheLogic::Stash[:testme])

$cache = SwapDmi::Cache.new(:tcache)
SwapDmi::StashCacheLogic.configureCache($cache, :testme)
$cache.config[:evictTime] = 0

puts 'test insert/look/evict'
(1..10).each do |i|
	$cache[i] = i
	assertTrue($backing[:tcache][i] == i+1)
	assertTrue($cache.has?(i))
	assertTrue($stash.summary(:tcache).keys.include?(i))
	assertTrue($cache[i] == i)
	$cache.evict(i)
	assertTrue(!$backing[:tcache].key?(i))
end

puts 'test multiget'
(1..10).each {|i| $cache[i] = i }
getall = $cache.getMany(SwapDmi::CacheKey.wildcard)
(1..10).each {|i| puts i ; assertTrue(getall.include?(i))}

puts 'test done'
