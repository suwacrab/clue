-- main.lua -----------------------------------------------------------------@/
local function printf_framed(str,...)
	liblog.printf('frm.%6d: %s',api.timer_getFrame(),str:format(...))
end

local tsk_stage;
local stagetasks = libtask.taskgarden_new()

tsk_stage = libtask.task_new('a',function(task)
	-- task is a variable that's the current task being
	-- executed. in this case, it'd be tsk_stage.
	
	local function barrage_make()
		stagetasks:add(3,'sample barrage',function(ts)
			printf_framed('now: %s',ts)
			for i = 1,5 do
				printf_framed('barrage enemy.')
				ts:wait(9)
			end
		end)
	end
	stagetasks:add(1,'main stage',function(task)
		stagetasks:add(2,nil,function(task)
			task:wait(15)
			printf_framed('spawned an enemy')
			task:wait(15)
			printf_framed('spawned an enemy [2]')
		end)

		task:wait(60)
		stagetasks:add(2,'barrage maker',function(task)
			for i = 1,5 do
				barrage_make()
				task:wait(29)
			end
		end)
	end)

	while not stagetasks:is_allDone() do
		stagetasks:step_all()
		task:wait(1)
	end

	-- the main stage task shouldn't end, so it should instead
	-- infinitely wait and do nothing after it's finished.
	print('stage done.')
	task:waitInf()
end)

-- fn_update is called by the game automatically every frame.
-- it executes the stage task, which should deal with adding enemies
-- at certain points, along with dealing with camera angles and stage
-- backgrounds.
local function fn_update()
	tsk_stage:step()
end

-- assign it so the function actually gets used by the game
api.assign_fnUpdate(fn_update)


