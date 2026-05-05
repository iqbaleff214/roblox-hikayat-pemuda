-- LocalScript: StarterPlayerScripts/Client/Controllers/LeaderboardController
-- Caches the top-10 leaderboard received from LeaderboardService.
-- Exposes getTop10() for GaleriGui and any other UI that needs rankings.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Knit = require(ReplicatedStorage:WaitForChild("Packages").Knit)

local LeaderboardController = Knit.CreateController { Name = "LeaderboardController" }

-- ── State ─────────────────────────────────────────────────────────

local _top10 = {}

-- ── KnitInit / KnitStart ─────────────────────────────────────────

function LeaderboardController:KnitInit()
end

function LeaderboardController:KnitStart()
	local lbService = Knit.GetService("LeaderboardService")

	lbService.Top10Updated:Connect(function(top10)
		_top10 = top10
	end)
end

-- ── Public API ────────────────────────────────────────────────────

function LeaderboardController:getTop10()
	return _top10
end

return LeaderboardController
