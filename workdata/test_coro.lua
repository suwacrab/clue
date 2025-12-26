local coro_fn = function()
	print('in coro!')
	coroutine.yield()
	print('after yield!')
end

function main(from_lua)
	local coro = coroutine.create(coro_fn)
	print(from_lua
		and '\tcoroutine test start... from lua.'
		or  '\tcoroutine test start...'
	)
	coroutine.resume(coro)
	coroutine.resume(coro)
	print('\tcoroutine test end...')
end

main(true)
