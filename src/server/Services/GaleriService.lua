-- ModuleScript: ServerScriptService/Server/Services/GaleriService
-- Each player gets a folder in Workspace/Galeris/[userId] with pedestal Parts.
-- Pedestals glow by item rarity (PointLight). Players can place collectibles on slots.
-- Other players can visit and browse via OpenGaleri signal.

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit        = require(ReplicatedStorage:WaitForChild("Packages").Knit)
local AssetConfig = require(ReplicatedStorage:WaitForChild("Shared").Config.AssetConfig)

local PEDESTAL_SIZE   = Vector3.new(3, 1, 3)
local PEDESTAL_HEIGHT = 1.5
local COLS_PER_ROW    = 5
local CELL_SPACING    = 4
local MAX_SLOTS       = 50

local GaleriService = Knit.CreateService {
	Name   = "GaleriService",
	Client = {
		-- client → server
		PlaceCollectible = Knit.CreateSignal(), -- (itemId: string, pedestalSlot: number)
		OpenGaleri       = Knit.CreateSignal(), -- (targetUserId: number)
		GaleriLike       = Knit.CreateSignal(), -- (targetUserId: number)
		-- server → client
		GaleriData       = Knit.CreateSignal(), -- (targetUserId, layout, isOwner)
		GaleriVisited    = Knit.CreateSignal(), -- (visitorName: string)
		GaleriLiked      = Knit.CreateSignal(), -- (likerName: string) fired to galeri owner
	},

	_dataService      = nil,
	_inventoryService = nil,
	_galerisFolder    = nil,
}

-- ── Private: folder helpers ───────────────────────────────────────

local function ensureFolder(parent, name)
	local f = parent:FindFirstChild(name)
	if not f then
		f          = Instance.new("Folder")
		f.Name     = name
		f.Parent   = parent
	end
	return f
end

-- ── Private: pedestal construction ───────────────────────────────

local function pedestalPosition(slot)
	local col = (slot - 1) % COLS_PER_ROW
	local row = math.floor((slot - 1) / COLS_PER_ROW)
	return Vector3.new(col * CELL_SPACING, PEDESTAL_HEIGHT, row * CELL_SPACING)
end

local function buildPedestal(parent, slot, itemId)
	local slotName = "Pedestal_" .. slot
	local existing = parent:FindFirstChild(slotName)
	if existing then
		existing:Destroy()
	end

	local part = Instance.new("Part")
	part.Name       = slotName
	part.Size       = PEDESTAL_SIZE
	part.Position   = pedestalPosition(slot)
	part.Anchored   = true
	part.CanCollide = true
	part.CastShadow = false
	part.Material   = Enum.Material.SmoothPlastic

	local itemCfg = AssetConfig.getItem(itemId)
	if itemCfg then
		local rarityInfo = AssetConfig.Rarity and AssetConfig.Rarity[itemCfg.rarity]
		local color      = rarityInfo and rarityInfo.color    or Color3.fromRGB(180, 180, 180)
		local glowRange  = rarityInfo and rarityInfo.glowRange or 8

		part.Color = color

		local light      = Instance.new("PointLight")
		light.Brightness = 2
		light.Range      = glowRange
		light.Color      = color
		light.Parent     = part

		local billboard       = Instance.new("BillboardGui")
		billboard.Size        = UDim2.fromOffset(160, 36)
		billboard.StudsOffset = Vector3.new(0, 2.5, 0)
		billboard.AlwaysOnTop = false
		billboard.Parent      = part

		local label = Instance.new("TextLabel")
		label.Size                   = UDim2.fromScale(1, 1)
		label.BackgroundTransparency = 1
		label.Font                   = Enum.Font.GothamBold
		label.TextScaled             = true
		label.TextColor3             = Color3.fromRGB(255, 255, 255)
		label.Text                   = itemCfg.nameKey
		label.Parent                 = billboard
	else
		part.Color = Color3.fromRGB(60, 60, 80)
	end

	part.Parent = parent
	return part
end

-- ── Private: build entire galeri for a player ────────────────────

local function buildPlayerGaleri(self, player)
	local data = self._dataService:get(player)
	if not data then
		return
	end

	local galeriFolder = ensureFolder(self._galerisFolder, tostring(player.UserId))

	-- Clear any existing pedestals
	for _, child in galeriFolder:GetChildren() do
		if child:IsA("Part") then
			child:Destroy()
		end
	end

	-- One pedestal per distinct collectible in inventory
	local slot = 1
	local seenItems = {}
	for _, entry in (data.inventory or {}) do
		local cfg = AssetConfig.getItem(entry.id)
		if cfg and cfg.type == "Koleksi" and not seenItems[entry.id] then
			seenItems[entry.id] = true
			buildPedestal(galeriFolder, slot, entry.id)
			slot = slot + 1
		end
	end

	-- Restore saved layout on top of auto-assigned pedestals
	for slotKey, itemId in (data.galeriLayout or {}) do
		local s = tonumber(slotKey)
		if s and s >= 1 and s <= MAX_SLOTS then
			buildPedestal(galeriFolder, s, itemId)
		end
	end
end

-- ── KnitInit / KnitStart ──────────────────────────────────────────

function GaleriService:KnitInit()
end

function GaleriService:KnitStart()
	self._dataService = Knit.GetService("DataService")

	pcall(function()
		self._inventoryService = Knit.GetService("InventoryService")
	end)

	self._galerisFolder = ensureFolder(workspace, "Galeris")

	Players.PlayerAdded:Connect(function(player)
		local loaded = self._dataService:waitForLoad(player, 15)
		if loaded then
			buildPlayerGaleri(self, player)
		end
	end)

	Players.PlayerRemoving:Connect(function(player)
		local folder = self._galerisFolder:FindFirstChild(tostring(player.UserId))
		if folder then
			folder:Destroy()
		end
	end)

	self.Client.PlaceCollectible:Connect(function(player, itemId, pedestalSlot)
		self:_handlePlaceCollectible(player, itemId, pedestalSlot)
	end)

	self.Client.OpenGaleri:Connect(function(player, targetUserId)
		self:_handleOpenGaleri(player, targetUserId)
	end)

	self.Client.GaleriLike:Connect(function(player, targetUserId)
		self:_handleGaleriLike(player, targetUserId)
	end)

	-- Seed for players already in game (Studio play solo)
	for _, player in Players:GetPlayers() do
		task.spawn(function()
			local loaded = self._dataService:waitForLoad(player, 15)
			if loaded then
				buildPlayerGaleri(self, player)
			end
		end)
	end
end

-- ── Handlers ─────────────────────────────────────────────────────

function GaleriService:_handlePlaceCollectible(player, itemId, pedestalSlot)
	if type(itemId) ~= "string" then
		return
	end
	if type(pedestalSlot) ~= "number" or pedestalSlot < 1 or pedestalSlot > MAX_SLOTS then
		return
	end

	local cfg = AssetConfig.getItem(itemId)
	if not cfg or cfg.type ~= "Koleksi" then
		return
	end

	if self._inventoryService then
		if not self._inventoryService:hasItem(player, itemId, 1) then
			return
		end
	end

	local data = self._dataService:get(player)
	if not data then
		return
	end

	data.galeriLayout[tostring(pedestalSlot)] = itemId

	local galeriFolder = self._galerisFolder:FindFirstChild(tostring(player.UserId))
	if galeriFolder then
		buildPedestal(galeriFolder, pedestalSlot, itemId)
	end
end

function GaleriService:_handleOpenGaleri(player, targetUserId)
	if type(targetUserId) ~= "number" then
		return
	end

	local layout = {}
	local targetPlayer = Players:GetPlayerByUserId(targetUserId)

	if targetPlayer then
		local dataTarget = self._dataService:get(targetPlayer)
		if dataTarget then
			layout = dataTarget.galeriLayout or {}
		end

		-- Notify the target that someone is visiting (skip self-visit)
		if targetPlayer ~= player then
			self.Client.GaleriVisited:Fire(targetPlayer, player.Name)
		end
	end

	local isOwner = (player.UserId == targetUserId)
	self.Client.GaleriData:Fire(player, targetUserId, layout, isOwner)
end

function GaleriService:_handleGaleriLike(player, targetUserId)
	if type(targetUserId) ~= "number" then
		return
	end
	if player.UserId == targetUserId then
		return
	end
	local targetPlayer = Players:GetPlayerByUserId(targetUserId)
	if not targetPlayer then
		return
	end
	self.Client.GaleriLiked:Fire(targetPlayer, player.Name)
end

-- ── Public API ────────────────────────────────────────────────────

function GaleriService:getGaleriLayout(userId)
	local targetPlayer = Players:GetPlayerByUserId(userId)
	if not targetPlayer then
		return {}
	end
	local data = self._dataService:get(targetPlayer)
	if not data then
		return {}
	end
	return data.galeriLayout or {}
end

return GaleriService
