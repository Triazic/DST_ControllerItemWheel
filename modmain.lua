local function GetInventory()
	return GLOBAL.ThePlayer.replica.inventory
end

local function PrintTable(table)
	for key,value in pairs(table) do print(key,value) end 
end

local function GetIfItemEquipped(item)
	local handItem = GetInventory():GetEquippedItem(GLOBAL.EQUIPSLOTS.HANDS)
	if (handItem ~= nil and handItem == item) then return true end
	local headItem = GetInventory():GetEquippedItem(GLOBAL.EQUIPSLOTS.HEAD)
	if (headItem ~= nil and headItem == item) then return true end
	local bodyItem = GetInventory():GetEquippedItem(GLOBAL.EQUIPSLOTS.BODY)
	if (bodyItem ~= nil and bodyItem == item) then return true end
	return false
end

local function ActuallyGetItems()
	local items = {}
	local inventory = GetInventory()
	local numItems = inventory:GetNumSlots()
	for i = 1, numItems do 
		local item = inventory:GetItemInSlot(i)
		if (item ~= nil) then
			table.insert(items, item)
		end 
	end
	local overFlowContainer = inventory:GetOverflowContainer()
	if overFlowContainer == nil then return items end
	local backpack = overFlowContainer
	if backpack == nil then return items end
	local numBackPackSlots = backpack:GetNumSlots()
	for i = 1, numBackPackSlots do 
		local item = backpack:GetItemInSlot(i)
		if (item ~= nil) then
			--print(item.prefab)
			table.insert(items, item)
		end 
	end
	return items
end

KEYBOARDTOGGLEKEY = GetModConfigData("KEYBOARDTOGGLEKEY") or "G"
if type(KEYBOARDTOGGLEKEY) == "string" then
	KEYBOARDTOGGLEKEY = KEYBOARDTOGGLEKEY:lower():byte()
end
local SCALEFACTOR = GetModConfigData("SCALEFACTOR") or 1
local CENTERWHEEL = GetModConfigData("CENTERWHEEL")
--Gross way of handling the default behavior, but I don't see a better option
if CENTERWHEEL == nil then CENTERWHEEL = true end
local RESTORECURSOROPTIONS = GetModConfigData("RESTORECURSOR") or 3
if not CENTERWHEEL and RESTORECURSOROPTIONS == 3 then
	--if the wheel isn't centered, then restoring basically just puts it where it was already
	-- so turn that off to prevent jitter
	RESTORECURSOROPTIONS = 0
end
--0 means don't center or restore, even if the wheel is centered
local CENTERCURSOR  = CENTERWHEEL and (RESTORECURSOROPTIONS >= 1)
local RESTORECURSOR = RESTORECURSOROPTIONS >= 2
local ADJUSTCURSOR  = RESTORECURSOROPTIONS >= 3
local IMAGETEXT = GetModConfigData("IMAGETEXT") or 2
local SHOWIMAGE = IMAGETEXT > 1
local SHOWTEXT = IMAGETEXT%2 == 1
local RIGHTSTICK = GetModConfigData("RIGHTSTICK")
--Backward-compatibility if they had changed the option
if GetModConfigData("LEFTSTICK") == false then RIGHTSTICK = true end
-- ONLYEIGHT isn't compatible with multiple rings; it will disable Party and Old emotes
local ONLYEIGHT = GetModConfigData("ONLYEIGHT")
local EIGHTS = {}
for i=1,8 do
	EIGHTS[i] = GetModConfigData("EIGHT"..i)
end

local function ActuallyBuildItemSets()
	-- get all items
	local allitems = ActuallyGetItems()

	-- filter to equippable items
	local equippableItems = {}
	-- local handItem = GetInventory():GetEquippedItem(GLOBAL.EQUIPSLOTS.HANDS)
	-- local headItem = GetInventory():GetEquippedItem(GLOBAL.EQUIPSLOTS.HEAD)
	-- local bodyItem = GetInventory():GetEquippedItem(GLOBAL.EQUIPSLOTS.BODY)
	for i, item in ipairs(allitems) do
		local equippable = item.replica.equippable ~= nil
		-- local isEquipped = (handItem ~= nil and item == handItem)
		-- 				or (headItem ~= nil and item == headItem)
		-- 				or (bodyItem ~= nil and item == bodyItem)
		if (
				equippable 
				--and (not isEquipped)
			) then 
			item.myIndex = i
			table.insert(equippableItems, item)
		end
	end
	-- add to item set
	local defaultitemset = {}
	for i, item in ipairs(equippableItems) do
		table.insert(defaultitemset, item)
	end

	-- for i, item in ipairs(defaultitemset) do 
	-- 	print(item.prefab)
	-- 	print(item.myIndex)
	-- end
	
	local actual_item_sets = {}
	table.insert(
		actual_item_sets, 
		{
			name = "default",
			emotes = defaultitemset,
			radius = ONLYEIGHT and 250 or 325,
			color = GLOBAL.BROWN,
		}
	)

	return actual_item_sets
end

--All code below is for handling the wheel

local ItemWheel = GLOBAL.require("widgets/itemwheel")

--Variables to control the display of the wheel
local cursorx = 0
local cursory = 0
local centerx = 0
local centery = 0
local controls = nil
local itemwheel = nil
local keydown = false
local using_gesture_wheel = false
local NORMSCALE = nil
local STARTSCALE = nil

local function CanUseItemWheel()
	local screen = GLOBAL.TheFrontEnd:GetActiveScreen()
	screen = (screen and type(screen.name) == "string") and screen.name or ""
	if screen:find("HUD") == nil or not GLOBAL.ThePlayer then
		return false
	end
	local full_enabled, soft_enabled = GLOBAL.ThePlayer.components.playercontroller:IsEnabled()
	return full_enabled or soft_enabled or using_gesture_wheel
end

local function ResetTransform()
	local screenwidth, screenheight = GLOBAL.TheSim:GetScreenSize()
	centerx = math.floor(screenwidth/2 + 0.5)
	centery = math.floor(screenheight/2 + 0.5)
	local screenscalefactor = math.min(screenwidth/1920, screenheight/1080) --normalize by my testing setup, 1080p
	itemwheel.screenscalefactor = SCALEFACTOR*screenscalefactor
	NORMSCALE = SCALEFACTOR*screenscalefactor
	STARTSCALE = 0
	itemwheel:SetPosition(centerx, centery, 0)
	itemwheel.inst.UITransform:SetScale(STARTSCALE, STARTSCALE, 1)
end

local function ShowItemWheel(controller_mode)
	if keydown then 
		return 
	end
	if type(GLOBAL.ThePlayer) ~= "table" or type(GLOBAL.ThePlayer.HUD) ~= "table" then 
		return 
	end
	if not CanUseItemWheel() then 
		return 
	end
	
	keydown = true
	--SetModHUDFocus("ItemWheel", true)
	GLOBAL.ThePlayer.HUD.controls:HideCraftingAndInventory()
	using_gesture_wheel = true
	
	ResetTransform()
	
	if RESTORECURSOR then
		cursorx, cursory = GLOBAL.TheInputProxy:GetOSCursorPos()
	end
	
	if CENTERCURSOR then
		GLOBAL.TheInputProxy:SetOSCursorPos(centerx, centery)
	end
	if CENTERWHEEL then
		itemwheel:SetPosition(centerx, centery, 0)
	else
		itemwheel:SetPosition(GLOBAL.TheInput:GetScreenPosition():Get())
	end
	itemwheel:SetControllerMode(controller_mode)
	local actualItemSets = ActuallyBuildItemSets()
	
	itemwheel:UpdateItems(actualItemSets, SHOWIMAGE, SHOWTEXT)
	itemwheel:Show()
	itemwheel:ScaleTo(STARTSCALE, NORMSCALE, .25)
end

local function HideItemWheel(delay_focus_loss)
	if type(GLOBAL.ThePlayer) ~= "table" or type(GLOBAL.ThePlayer.HUD) ~= "table" then return end
	keydown = false
	
	itemwheel:Hide()
	GLOBAL.ThePlayer.HUD.controls:ShowCraftingAndInventory()
	itemwheel.inst.UITransform:SetScale(STARTSCALE, STARTSCALE, 1)
	
	local can_use_wheel = CanUseItemWheel()
	using_gesture_wheel = false
	if not can_use_wheel then return end
	
	if RESTORECURSOR then
		if ADJUSTCURSOR then
			local x,y = GLOBAL.TheInputProxy:GetOSCursorPos()
			local gx, gy = itemwheel:GetPosition():Get()
			local dx, dy = x-gx, y-gy
			cursorx = cursorx + dx
			cursory = cursory + dy
		end
		GLOBAL.TheInputProxy:SetOSCursorPos(cursorx, cursory)
	end
	
	if itemwheel.activeitem then -- actually an active item
		local itemIndex = itemwheel.activeitem -- NOT SAFE, WILL PROBABLY FUCK UP WHEN MULTIPLE WHEELS
		--local item = GetInventory():GetItemInSlot(itemIndex)
		local item = itemwheel.actualItems[itemIndex]
		if item == nil then 
			print("item is nil somehow, index was:")
			print(tostring(itemIndex))
			return
		end
		GetInventory():UseItemFromInvTile(item)
	end

	SetModHUDFocus("ItemWheel", false)
end

local handlers_applied = false
local originalOpenControllerInventory = nil
local function AddItemWheel(self)
	controls = self -- this just makes controls available in the rest of the modmain's functions
	if itemwheel then
		itemwheel:Kill()
	end
	itemwheel = controls:AddChild(ItemWheel(SHOWIMAGE, SHOWTEXT, RIGHTSTICK))
	controls.itemwheel = itemwheel
	ResetTransform()
	itemwheel:Hide()
	
	if not handlers_applied then
		-- APPLY HANDLERS TO OPEN / CLOSE WHEEL
		-- Keyboard controls
		GLOBAL.TheInput:AddKeyDownHandler(KEYBOARDTOGGLEKEY, ShowItemWheel)
		GLOBAL.TheInput:AddKeyUpHandler(KEYBOARDTOGGLEKEY, HideItemWheel)

		-- fuck the opening of inventory thingo
		originalOpenControllerInventory = GLOBAL.ThePlayer.HUD.OpenControllerInventory
		GLOBAL.ThePlayer.HUD.OpenControllerInventory = function() 
			ShowItemWheel(true)
		end
		
		-- Controller controls
		-- This is pressing the left stick in
		-- CONTROL_MENU_MISC_3 is the same thing as CONTROL_OPEN_DEBUG_MENU
		-- CONTROL_MENU_MISC_4 is the right stick click
		GLOBAL.TheInput:AddControlHandler(GLOBAL.CONTROL_OPEN_INVENTORY, function(down)
			if down then
				return -- this case doesn't get hit anyway
			else
				HideItemWheel(true)
			end
		end)

		GLOBAL.TheInput:AddControlHandler(GLOBAL.CONTROL_MENU_MISC_3, function(down)
			if (down and using_gesture_wheel) then
				SetModHUDFocus("ItemWheel", true)
			else
				return
			end
		end)

		-- hot switching
		-- CONTROL_INVENTORY_EXAMINE = 51 -- d-pad up
		-- CONTROL_INVENTORY_USEONSELF = 52 -- d-pad right
		-- CONTROL_INVENTORY_USEONSCENE = 53 -- d-pad left
		-- CONTROL_INVENTORY_DROP = 54 -- d-pad down
		GLOBAL.TheInput:AddControlHandler(GLOBAL.CONTROL_INVENTORY_EXAMINE, function(down)
			if not down then return end
			if itemwheel.activeitem == nil then return end
			local item = itemwheel.actualItems[itemwheel.activeitem]
			if item == nil then return end
			itemwheel.item1 = item
			itemwheel:UpdateItems(ActuallyBuildItemSets(), SHOWIMAGE, SHOWTEXT)
		end)
		GLOBAL.TheInput:AddControlHandler(GLOBAL.CONTROL_INVENTORY_USEONSELF, function(down)
			if not down then return end
			if itemwheel.activeitem == nil then return end
			local item = itemwheel.actualItems[itemwheel.activeitem]
			if item == nil then return end
			itemwheel.item2 = item
			itemwheel:UpdateItems(ActuallyBuildItemSets(), SHOWIMAGE, SHOWTEXT)
		end)
		GLOBAL.TheInput:AddControlHandler(GLOBAL.CONTROL_INVENTORY_DROP, function(down)
			if not down then return end
			if itemwheel.activeitem == nil then return end
			local item = itemwheel.actualItems[itemwheel.activeitem]
			if item == nil then return end
			itemwheel.item3 = item
			itemwheel:UpdateItems(ActuallyBuildItemSets(), SHOWIMAGE, SHOWTEXT)
		end)

		GLOBAL.ACTIONS.LOOKAT.fn = function(act) return end -- disables inspection completely
		GLOBAL.ThePlayer.HUD.InspectSelf = function() return end -- disables self inspection popup

		local timeLastTriangleDown = 0
		GLOBAL.TheInput:AddControlHandler(GLOBAL.CONTROL_MENU_MISC_2, function(down)
			if ((down) and using_gesture_wheel) then
				-- show default inventory
				HideItemWheel(true)
				originalOpenControllerInventory(GLOBAL.ThePlayer.HUD)
			elseif (down and (not using_gesture_wheel)) then 
				timeLastTriangleDown = GLOBAL.GetTime()
			elseif ((not down) and (not using_gesture_wheel)) then 
				function GetItemToHotSwitchTo()
					if (itemwheel.item3 ~=nil and (not GetIfItemEquipped(itemwheel.item3) and (GLOBAL.GetTime() - timeLastTriangleDown > 0.2))) then 
						return itemwheel.item3
					end
					if (itemwheel.item1 ~=nil and (not GetIfItemEquipped(itemwheel.item1))) then 
						return itemwheel.item1
					end
					if (itemwheel.item2 ~=nil and (not GetIfItemEquipped(itemwheel.item2))) then 
						return itemwheel.item2
					end
					return nil
				end
				local itemToSwitchTo = GetItemToHotSwitchTo()
				if (itemToSwitchTo ~= nil) then
					GetInventory():UseItemFromInvTile(itemToSwitchTo)
				end
			end
		end)
		
		-- this is just a lock system to make it only register one shift at a time
		local rotate_left_free = true
		GLOBAL.TheInput:AddControlHandler(GLOBAL.CONTROL_ROTATE_LEFT, function(down)
			if down then
				if keydown and rotate_left_free then
					itemwheel:SwitchWheel(-1)
					rotate_left_free = false
				end
			else
				rotate_left_free = true
			end
		end)
		local rotate_right_free = true
		GLOBAL.TheInput:AddControlHandler(GLOBAL.CONTROL_ROTATE_RIGHT, function(down)
			if down then
				if keydown and rotate_right_free then
					itemwheel:SwitchWheel(1)
					rotate_right_free = false
				end
			else
				rotate_right_free = true
			end
		end)
		
		handlers_applied = true
	end
end
AddClassPostConstruct( "widgets/controls", AddItemWheel)

--Patch the class definition directly instead of each new instance
local Controls = GLOBAL.require("widgets/controls")
local OldOnUpdate = Controls.OnUpdate
local function OnUpdate(self, ...)
	OldOnUpdate(self, ...)
	if keydown then
		self.itemwheel:OnUpdate()
	end
end
Controls.OnUpdate = OnUpdate

--In order to update the emote set when a skin is received, hook into the giftitempopup
AddClassPostConstruct("screens/giftitempopup", function(self)
	local function ScheduleRebuild()
		--give it a little time to update the skin inventory
		controls.owner:DoTaskInTime(5, function() AddItemWheel(controls) end)
	end
	local OldOnClose = self.OnClose
	function self:OnClose(...)
		OldOnClose(self, ...)
		ScheduleRebuild()
	end
	local OldApplySkin = self.ApplySkin
	function self:ApplySkin(...)
		OldApplySkin(self, ...)
		ScheduleRebuild()
	end
end)