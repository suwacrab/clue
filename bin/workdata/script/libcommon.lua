local libcommon = {}

function libcommon.clamp(x,min,max)
	return (x < min)
		and min
	or (x > max)
		and max
	or x
end
function libcommon.lerp(a,b,x)
	return a + (b-a) * x
end
function libcommon.sec_conv(unittype,units)
	local fn_lut = {
		sec = function() return units end;
		min = function() return 60*units end;
		hrs = function() return 60*60*units end;
		day = function() return 60*60*24*units end;
	}
	local fn = fn_lut[unittype]
	assert(fn,("unknown unit type %s"):format(unittype))
	assert(units,"nil units")
	return math.floor(fn() + .5)
end
function libcommon.millisec_conv(unittype,units)
	return libcommon.sec_conv(unittype,units) * 1000
end
function libcommon.num_fraction(n)
	return n - math.floor(n)
end
function libcommon.tostr_decsplit(f,divider)
	divider = divider or ','
	assert(type(divider) == "string","invalid divider")
	assert(type(f) == "number","invalid number")
	f = math.floor(f)

	local curstr = ""
	local absf = math.abs(f)
	if absf > 1000 then
		local curn = absf
		local iter = 0
		while curn>0 do
			local num = curn % 1000
			local next_curn = math.floor(curn / 1000)
			if next_curn>0 then
				if iter == 0 then
					curstr = ("%03d"):format(num)..curstr
				else
					curstr = ("%03d%s"):format(num,divider)..curstr
				end
			else
				curstr = ("%d%s"):format(num,divider)..curstr
			end
			curn = next_curn
			iter = iter+1
		end
	else
		curstr = tostring(absf)
	end
	return curstr
end
function libcommon.str_wraplines(str,line_len,options)
	local do_wrap = options.wrap or false
	local linestart = options.linestart or ''
	local linestart_cont = options.linestart_cont or ''
	assert(type(str) == 'string','invalid string')
	assert(type(line_len) == 'number','invalid line_len')
	assert(line_len>0,'line_len must be >0')
	assert(type(linestart) == 'string','invalid linestart')
	assert(type(linestart_cont) == 'string','invalid linestart_cont')

	local allcnt = { linestart }
	local cur_x = 0
	local function push_word(word)
		if cur_x+utf8.len(word) >= line_len then
			table.insert(allcnt,'\n')
			table.insert(allcnt,linestart_cont)
			table.insert(allcnt,word)
			cur_x = utf8.len(word)
		else
			table.insert(allcnt,word)
			cur_x = cur_x+utf8.len(word)
		end
	end
	for block in str:gmatch("[^%s]+%s*") do
		local word,wspace = block:match("([^%s]+)(%s*)")
		if utf8.len(word) >= line_len then
			if do_wrap then
				-- keep pushing slices of the full string until a slice
				-- where the string wouldn't go over a line is reached
				while utf8.len(word) >= line_len do
					local endp = line_len-cur_x
					local subA = word:sub(1,endp)
					local subB = word:sub(endp+1)
					if utf8.len(word) <= line_len then
						cur_x = utf8.len(subA)
					else
						table.insert(allcnt,subA..'\n')
						table.insert(allcnt,linestart_cont)
						cur_x = 0
					end
					word = subB
				end
				if utf8.len(word) > 0 then
					push_word(word)
				end
			else
				push_word(word)
			end
		else
			push_word(word)
		end

		for space in wspace:gmatch("%s") do
			if space == '\n' then
				cur_x = 0
				table.insert(allcnt,'\n')
				table.insert(allcnt,linestart_cont)
			elseif space == ' ' then
				cur_x = cur_x+1
				table.insert(allcnt,' ')
			end
		end
	end
	return table.concat(allcnt)
end
function libcommon.table_sanitizeStr(tbl)
	local tblclone = {};
	local function iter(pa,send)
		for _i,_v in next,pa do
			local idx = _i
			local val = _v
			-- sanitize index ------------------------------------@/
			if (type(_i) ~= 'string') or (type(_i) ~= 'number') then
				idx = tostring(_i)
			end

			-- sanitize val --------------------------------------@/
			if type(_v) == 'thread' or type(_v) == 'function' then
				val = ("@[%s]"):format(_v)
			end
			if type(_v) == 'table' then
				send[idx] = {}
				iter(_v,send[idx])
			else
				send[idx] = val
			end
		end
	end
	iter(tbl,tblclone)
	return tblclone
end

return libcommon

