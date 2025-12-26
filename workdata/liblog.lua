local liblog = {}

function liblog.printf(str,...)
	print(str:format(...))
end

return liblog

