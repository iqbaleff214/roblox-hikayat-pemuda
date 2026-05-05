-- ModuleScript: ReplicatedStorage/Shared/Modules/MobileUtil
-- Centralised mobile / console detection used by all LocalScripts.
-- Import: local MobileUtil = require(ReplicatedStorage.Shared.Modules.MobileUtil)

local UserInputService = game:GetService("UserInputService")
local GuiService       = game:GetService("GuiService")

local MobileUtil = {}

-- True when the client has a touch screen (phone / tablet)
MobileUtil.IS_MOBILE  = UserInputService.TouchEnabled

-- True when running on a 10-foot / console interface
MobileUtil.IS_CONSOLE = GuiService:IsTenFootInterface()

-- Minimum tap-target height in pixels (WCAG / Apple HIG recommendation)
MobileUtil.MIN_TOUCH_PX = 44

-- Minimum hotbar slot size on mobile
MobileUtil.MIN_HOTBAR_PX = 60

-- Minimum dot/marker diameter on maps
MobileUtil.MIN_MAP_DOT_PX = 30

-- Returns true if the platform benefits from larger touch targets.
function MobileUtil.needsLargeTargets()
	return MobileUtil.IS_MOBILE or MobileUtil.IS_CONSOLE
end

-- Clamps a pixel size to at least MIN_TOUCH_PX on mobile.
function MobileUtil.clampTouchSize(px)
	if MobileUtil.needsLargeTargets() then
		return math.max(px, MobileUtil.MIN_TOUCH_PX)
	end
	return px
end

-- Returns the preferred dialog-panel height UDim2 for the current platform.
-- Desktop: 0px scale, ~220px fixed. Mobile: 40% of screen height.
function MobileUtil.dialogPanelSize()
	if MobileUtil.IS_MOBILE then
		return UDim2.new(1, -32, 0.4, 0)
	end
	return UDim2.new(1, -32, 0, 220)
end

-- Returns the preferred dialog-panel Y position.
function MobileUtil.dialogPanelPos()
	if MobileUtil.IS_MOBILE then
		return UDim2.new(0, 16, 0.6, 0)
	end
	return UDim2.new(0, 16, 1, -236)
end

-- Returns the choice-button height (taller on mobile for finger-friendliness).
function MobileUtil.choiceButtonHeight()
	if MobileUtil.needsLargeTargets() then
		return 52
	end
	return 44
end

-- Applies a minimum-size constraint to a GuiObject.
function MobileUtil.ensureMinSize(guiObject, minX, minY)
	local cx = minX or MobileUtil.MIN_TOUCH_PX
	local cy = minY or MobileUtil.MIN_TOUCH_PX
	local usc = guiObject:FindFirstChildOfClass("UISizeConstraint")
	if not usc then
		usc      = Instance.new("UISizeConstraint")
		usc.Parent = guiObject
	end
	usc.MinSize = Vector2.new(cx, cy)
end

return MobileUtil
