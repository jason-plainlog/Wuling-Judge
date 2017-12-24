$redis = Redis.new

if $redis.dbsize == 0
	$redis.set('docker', 0)
	$redis.set('sid', 0)
end