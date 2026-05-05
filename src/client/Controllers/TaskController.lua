-- LocalScript (Knit Controller): StarterPlayerScripts/Client/Controllers/TaskController
-- Caches daily/weekly task state from TaskService.
-- Exposes claimTask / rerollTask for the task panel UI (Phase 7).

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage:WaitForChild("Packages").Knit)

local TaskController = Knit.CreateController { Name = "TaskController" }

-- ── Local state ───────────────────────────────────────────────────

local _taskService = nil
local _taskState   = { dailyTasks = {}, weeklyTasks = {} }

-- ── KnitInit / KnitStart ──────────────────────────────────────────

function TaskController:KnitInit()
end

function TaskController:KnitStart()
	_taskService = Knit.GetService("TaskService")

	_taskService.TaskUpdate:Connect(function(taskData)
		_taskState = taskData
	end)
end

-- ── Public API ────────────────────────────────────────────────────

-- Returns a snapshot of the current daily tasks array.
function TaskController:getDailyTasks()
	return _taskState.dailyTasks or {}
end

-- Returns a snapshot of the current weekly tasks array.
function TaskController:getWeeklyTasks()
	return _taskState.weeklyTasks or {}
end

-- Fire-and-forget: claim a completed task's reward.
-- taskIndex: 1-based index in the daily or weekly list.
-- isWeekly: true for weekly tasks, false/nil for daily.
function TaskController:claimTask(taskIndex, isWeekly)
	_taskService.ClaimTask:Fire(taskIndex, isWeekly == true)
end

-- Fire-and-forget: reroll a daily task (costs Rupiah, limited to 1/day).
function TaskController:rerollTask(taskIndex)
	_taskService.RerollTask:Fire(taskIndex)
end

return TaskController
