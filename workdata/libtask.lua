-- task class ---------------------------------------------------------------@/
local task_mt = {}
task_mt.__index = task_mt

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
	return ("@task{ '%s'; coro: [%s]; }"):format(self.name,self._coro)
end

-- taskgarden class -----------------------------------------------------------@/
local taskgarden_mt = {}
taskgarden_mt.__index = taskgarden_mt
function taskgarden_mt:add(prio,name,fn)
	local task = task_new(name,fn)
	local entry = { task = task, priority = prio }
	self.data[entry] = true;
end
function taskgarden_mt:get_all(sortmode)
	local list = {}
	for entry,_ in next,self.data do
		table.insert(list,entry)
	end
	if sortmode == 'prio' then
		table.sort(list,function(a,b) return a.priority<b.priority end)
	end
	return list
end
function taskgarden_mt:get_count()
	local n = 0
	for _,_ in next,self.data do
		n = n+1
	end
	return n
end
function taskgarden_mt:step_all()
	local tasks_toExec = self:get_all('prio')

	for _,entry in next,tasks_toExec do
		entry.task:step()
		if entry.task:done() then
			self.data[entry] = nil
		end
	end
end
function taskgarden_mt:is_allDone()
	return next(self.data) == nil
end

function taskgarden_mt:__tostring()
	local names = {}
	for _,entry in next,self:get_all('prio') do
		table.insert(names,("'%s'"):format(entry.task.name))
	end
	
	return ("@taskgarden{ '%s'; tasks: %d [%s] }"):format(self.name,self:get_count(),table.concat(names,', '))
end

local function taskgarden_new(name)
	name = name or "none";
	assert(type(name) == "string", "invalid taskgarden name")
	local garden = {
		name = name;
		data = {};
	}
	return setmetatable(garden,taskgarden_mt)
end

return {
	task_new = task_new;
	taskgarden_new = taskgarden_new;
}

