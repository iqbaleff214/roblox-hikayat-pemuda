-- ModuleScript: ServerScriptService/Server/Services/LeaderboardService
-- Maintains a global OrderedDataStore leaderboard ranked by collectible count.
-- Updates the in-world BillboardGui in Workspace/Map/Zones/KotaJogja/Leaderboard.
-- Exposes getTop10() for other systems (e.g. GaleriGui).

local Players           = game:GetService("Players")
local DataStoreService  = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage:WaitForChild("Packages").Knit)

local UPDATE_INTERVAL = 300 -- 5 minutes in seconds

local LeaderboardService = Knit.CreateService {
	Name   = "LeaderboardService",
	Client = {
		Top10Updated = Knit.CreateSignal(), -- server → client: (top10 array)
	},

	_dataService  = nil,
	_top10        = {},
	_orderedStore = nil,
}

-- ── Private: billboard helpers ────────────────────────────────────

local function getLeaderboardPart()
	local map = workspace:FindFirstChild("Map")
	if not map then
		return nil
	end
	local zones = map:FindFirstChild("Zones")
	if not zones then
		return nil
	end
	local kj = zones:FindFirstChild("KotaJogja")
	if not kj then
		return nil
	end
	return kj:FindFirstChild("Leaderboard")
end

local function buildSurfaceGui(part)
	local existing = part:FindFirstChildOfClass("SurfaceGui")
	if existing then
		existing:Destroy()
	end

	local sg = Instance.new("SurfaceGui")
	sg.Name   = "LeaderboardGui"
	sg.Face   = Enum.NormalId.Front
	sg.Parent = part

	local bg = Instance.new("Frame")
	bg.Name                   = "BG"
	bg.Size                   = UDim2.fromScale(1, 1)
	bg.BackgroundColor3       = Color3.fromRGB(10, 10, 20)
	bg.BackgroundTransparency = 0.2
	bg.BorderSizePixel        = 0
	bg.Parent                 = sg

	local title = Instance.new("TextLabel")
	title.Name               = "Title"
	title.Size               = UDim2.new(1, 0, 0, 40)
	title.Position           = UDim2.fromScale(0, 0)
	title.BackgroundTransparency = 1
	title.Font               = Enum.Font.GothamBold
	title.TextScaled         = true
	title.TextColor3         = Color3.fromRGB(255, 215, 0)
	title.Text               = "Top Kolektor"
	title.Parent             = bg

	local listFrame = Instance.new("Frame")
	listFrame.Name                   = "List"
	listFrame.Size                   = UDim2.new(1, 0, 1, -40)
	listFrame.Position               = UDim2.new(0, 0, 0, 40)
	listFrame.BackgroundTransparency = 1
	listFrame.Parent                 = bg

	local layout = Instance.new("UIListLayout")
	layout.SortOrder    = Enum.SortOrder.LayoutOrder
	layout.FillDirection = Enum.FillDirection.Vertical
	layout.Parent       = listFrame

	for i = 1, 10 do
		local row = Instance.new("TextLabel")
		row.Name               = "Row" .. i
		row.Size               = UDim2.new(1, 0, 0.1, 0)
		row.BackgroundTransparency = 1
		row.Font               = Enum.Font.Gotham
		row.TextScaled         = true
		row.TextColor3         = Color3.fromRGB(220, 220, 220)
		row.Text               = i .. ". —"
		row.LayoutOrder        = i
		row.Parent             = listFrame
	end

	return sg
end

local function updateBillboard(self)
	local part = getLeaderboardPart()
	if not part then
		return
	end

	local sg = part:FindFirstChild("LeaderboardGui")
	if not sg then
		sg = buildSurfaceGui(part)
	end

	local bg   = sg:FindFirstChild("BG")
	if not bg then
		return
	end
	local list = bg:FindFirstChild("List")
	if not list then
		return
	end

	for i = 1, 10 do
		local row = list:FindFirstChild("Row" .. i)
		if not row then
			break
		end

		local entry = self._top10[i]
		if entry then
			row.Text = i .. ". " .. tostring(entry.name) .. "  (" .. tostring(entry.count) .. ")"
		else
			row.Text = i .. ". —"
		end
	end
end

-- ── Private: DataStore helpers ────────────────────────────────────

local function savePlayerScore(self, player)
	if not self._orderedStore then
		return
	end
	local data = self._dataService:get(player)
	if not data then
		return
	end
	local count = data.collectibleCount or 0
	pcall(function()
		self._orderedStore:SetAsync(tostring(player.UserId), count)
	end)
end

local function fetchGlobalTop10(self)
	if not self._orderedStore then
		return
	end

	local ok, pages = pcall(function()
		return self._orderedStore:GetSortedAsync(false, 10)
	end)
	if not ok or not pages then
		return
	end

	local top10 = {}
	pcall(function()
		local page = pages:GetCurrentPage()
		for rank, entry in page do
			local userId = tonumber(entry.key)
			local name   = "[unknown]"
			if userId then
				local okName, displayName = pcall(function()
					return Players:GetNameFromUserIdAsync(userId)
				end)
				if okName and displayName then
					name = displayName
				end
			end
			top10[rank] = {
				rank  = rank,
				name  = name,
				count = entry.value,
			}
		end
	end)

	self._top10 = top10
end

local function runUpdate(self)
	-- Persist current scores
	for _, player in Players:GetPlayers() do
		savePlayerScore(self, player)
	end

	-- Fetch global rankings and refresh billboard
	fetchGlobalTop10(self)
	updateBillboard(self)

	-- Broadcast to all clients
	for _, player in Players:GetPlayers() do
		self.Client.Top10Updated:Fire(player, self._top10)
	end
end

-- ── KnitInit / KnitStart ──────────────────────────────────────────

function LeaderboardService:KnitInit()
end

function LeaderboardService:KnitStart()
	self._dataService = Knit.GetService("DataService")

	pcall(function()
		self._orderedStore = DataStoreService:GetOrderedDataStore("CollectibleLeaderboard")
	end)

	-- Save score when player leaves
	Players.PlayerRemoving:Connect(function(player)
		savePlayerScore(self, player)
	end)

	-- Periodic update loop
	task.spawn(function()
		-- Initial fetch after data stores are warm
		task.wait(15)
		fetchGlobalTop10(self)
		updateBillboard(self)

		while true do
			task.wait(UPDATE_INTERVAL)
			runUpdate(self)
		end
	end)
end

-- ── Public API ────────────────────────────────────────────────────

function LeaderboardService:getTop10()
	return self._top10
end

return LeaderboardService
