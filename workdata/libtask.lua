local task_mt = {}
task_mt.__index = task_mt

local function printf(str,...)
	print(str:format(...))
end
local function printf_framed(str,...)
	printf('frm.%6d: %s',api.timer_getFrame(),str:format(...))
end

local function task_new(name,fn)
	name = name or "none"
	assert(type(name) == "string", 'invalid task name')
	assert(type(fn) == 'function', 'invalid task function')

	local task = {
		name = name;
		_coro = nil;
		_is_done = false;
	}
	task = setmetatable(task,task_mt)

	task._coro = coroutine.create(function()
		fn(task)
		task._is_done = true;
	end)

	return task;
end

function task_mt:done()
	return self._is_done
end
function task_mt:step()
	if not self:done() then
		local results = { coroutine.resume(self._coro) }
		if not results[1] then
			local errmsg = results[2]
			error(errmsg)
		end
	end
end
function task_mt:step_untilDone()
	while not self:done() do
		self:step()
	end
end

function task_mt:waitOnce()
	coroutine.yield()
end
function task_mt:wait(f)
	assert(math.tointeger(f) and f>=0,"wait argument should be an integer >= 0")
	for i = 1,f do
		self:waitOnce()
	end
end
function task_mt:waitInf()
	while true do
		self:waitOnce()
	end
end

function task_mt:__tostring()
	return ("@task{ name: '%s'; coro: %s; }"):format(self.name,self._coro)
end

local tasklist_mt = {}
tasklist_mt.__index = tasklist_mt
function tasklist_mt:add(prio,name,fn)
	local task = task_new(name,fn)
	local entry = { task = task, priority = prio }
	self.data[entry] = true
end
function tasklist_mt:get_all()
	local list = {}
	for entry,_ in next,self.data do
		table.insert(list,entry)
	end
	return list
end
function tasklist_mt:step_all()
	local tasks_toExec = self:get_all()
	table.sort(tasks_toExec,function(a,b) return a.priority<b.priority end)

	for _,entry in next,tasks_toExec do
		entry.task:step()
		if entry.task:done() then
			self.data[entry] = nil
		end
	end
end
function tasklist_mt:is_allDone()
	return next(self.data) == nil
end

local function tasklist_new()
	local tasklist 
	return setmetatable({
		data = {};
	},tasklist_mt)
end

return {
	task_new = task_new;
	tasklist_new = tasklist_new;
}

