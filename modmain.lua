local function GetNumberOfItemsInInventory()
	return GLOBAL.ThePlayer.components.inventory:NumItems()
end

local function PrintEachItemInInventory(numItems)
	GLOBAL.ThePlayer.components.inventory:ForEachItem(function(item)
		local isStackable = item.components.stackable ~= nil
		if isStackable then
			local stackSize = item.components.stackable:StackSize()
			print(tostring(item.prefab))
			print(tostring(stackSize))
		end
	end)
end

Assets = {
	Asset("IMAGE", "images/gesture_bg.tex"),
	Asset("ATLAS", "images/gesture_bg.xml"),
}

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

--Constants for the emote definitions; name is used for display text, anim for puppet animation

local DEFAULT_EMOTES = {
	{name = "rude",		anim = {anim="emoteXL_waving4", randomanim=true}},
	{name = "annoyed",	anim = {anim="emoteXL_annoyed"}},
	{name = "sad",		anim = {anim="emoteXL_sad", fx="tears", fxoffset={0.25,3.25,0}, fxdelay=17*GLOBAL.FRAMES}},
	{name = "joy",		anim = {anim="research", fx=false}},
	{name = "facepalm",	anim = {anim="emoteXL_facepalm"}},
	{name = "wave",		anim = {anim={"emoteXL_waving1", "emoteXL_waving2", "emoteXL_waving3"}, randomanim=true}},
	{name = "dance",	anim = {anim ={ "emoteXL_pre_dance0", "emoteXL_loop_dance0" }, loop = true, fx = false, beaver = true }},
	{name = "pose",		anim = {anim = "emote_strikepose", zoom = true, soundoverride = "/pose"}},
	{name = "kiss",		anim = {anim="emoteXL_kiss"}},
	{name = "bonesaw",	anim = {anim="emoteXL_bonesaw"}},
	{name = "happy",	anim = {anim="emoteXL_happycheer"}},
	{name = "angry",	anim = {anim="emoteXL_angry"}},
	{name = "sit",		anim = {anim={{"emote_pre_sit2", "emote_loop_sit2"}, {"emote_pre_sit4", "emote_loop_sit4"}}, randomanim = true, loop = true, fx = false}},
	{name = "squat",	anim = {anim={{"emote_pre_sit1", "emote_loop_sit1"}, {"emote_pre_sit3", "emote_loop_sit3"}}, randomanim = true, loop = true, fx = false}},
	{name = "toast",	anim = {anim={ "emote_pre_toast", "emote_loop_toast" }, loop = true, fx = false }},
	-- TODO: make sure this list stays up to date
}
--These emotes are unlocked by certain cosmetic Steam/skin items
local EMOTE_ITEMS = {
	{name = "sleepy",	anim = {anim="emote_sleepy"},		item = "emote_sleepy"},
	{name = "yawn",		anim = {anim="emote_yawn"},			item = "emote_yawn"},
	{name = "swoon",	anim = {anim="emote_swoon"},		item = "emote_swoon"},
	{name = "chicken",	anim = {anim="emoteXL_loop_dance6"},item = "emote_dance_chicken"},
	{name = "robot",	anim = {anim="emoteXL_loop_dance8"},item = "emote_dance_robot"},
	{name = "step",		anim = {anim="emoteXL_loop_dance7"},item = "emote_dance_step"},
	{name = "fistshake",anim = {anim="emote_fistshake"},	item = "emote_fistshake"},
	{name = "flex",		anim = {anim="emote_flex"},			item = "emote_flex"},
	{name = "impatient",anim = {anim="emote_impatient"},	item = "emote_impatient"},
	{name = "cheer",	anim = {anim="emote_jumpcheer"},	item = "emote_jumpcheer"},
	{name = "laugh",	anim = {anim="emote_laugh"},		item = "emote_laugh"},
	{name = "shrug",	anim = {anim="emote_shrug"},		item = "emote_shrug"},
	{name = "slowclap",	anim = {anim="emote_slowclap"},		item = "emote_slowclap"},
	{name = "carol",	anim = {anim="emote_loop_carol"},	item = "emote_carol"},
}

--Checking for other emote mods
local PARTY_ADDED = GLOBAL.KnownModIndex:IsModEnabled("workshop-437521942")
local OLD_ADDED = GLOBAL.KnownModIndex:IsModEnabled("workshop-732180082")
for k,v in pairs(GLOBAL.KnownModIndex:GetModsToLoad()) do
	PARTY_ADDED = PARTY_ADDED or v == "workshop-437521942"
	OLD_ADDED = OLD_ADDED or v == "workshop-732180082"
end

local PARTY_EMOTES = nil
if PARTY_ADDED and not ONLYEIGHT then
	PARTY_EMOTES = 
		{
			name = "party",
			emotes = 
			{
				{name = "dance2",	anim = {anim = "idle_onemanband1_loop"}},
				{name = "dance3",	anim = {anim = "idle_onemanband2_loop"}},
				{name = "run",		anim = {anim = {"run_pre", "run_loop", "run_loop", "run_loop", "run_pst"}}},
				{name = "thriller",	anim = {anim = "mime2"}},
				{name = "choochoo",	anim = {anim = "mime3"}},
				{name = "plsgo",	anim = {anim = "mime4"}},
				{name = "ez",		anim = {anim = "mime5"}},
				{name = "box",		anim = {anim = "mime6"}},
				{name = "bicycle",	anim = {anim = "mime8"}},
				{name = "comehere",	anim = {anim = "mime7"}},
				{name = "wasted",	anim = {anim = "sleep_loop"}},
				{name = "buffed",	anim = {anim = "powerup"}},
				{name = "pushup",	anim = {anim = "powerdown"}},
				{name = "fakebed",	anim = {anim = "bedroll_sleep_loop"}},
				{name = "shocked",	anim = {anim = "shock"}},
				{name = "dead",		anim = {anim = {"death", "wakeup"}}},
				{name = "spooked",	anim = {anim = "distress_loop"}},
			},
			radius = 375,
			color = GLOBAL.PLAYERCOLOURS.FUSCHIA,
		}
end

local OLD_EMOTES = nil
if OLD_ADDED and not ONLYEIGHT then
	OLD_EMOTES = 
		{
			name = "old",
			emotes = 
			{
				{name = "angry2",	anim = {anim = "emote_angry"}},
				{name = "annoyed2",	anim = {anim = "emote_annoyed_palmdown"}},
				{name = "gdi",		anim = {anim = "emote_annoyed_facepalm"}},
				{name = "pose2",	anim = {anim = "emote_feet"}},
				{name = "pose3",	anim = {anim = "emote_hands"}},
				{name = "pose4",	anim = {anim = "emote_hat"}},
				{name = "pose5",	anim = {anim = "emote_pants"}},
				{name = "grats",	anim = {anim = "emote_happycheer"}},
				{name = "sigh",		anim = {anim = "emote_sad"}},
				{name = "heya",		anim = {anim = "emote_waving"}},
			},
			radius = 175,
			color = GLOBAL.DARKGREY,
		}
end

local function ActuallyBuildItemSets()
	local actual_item_sets = {}
	
	local defaultitemset = {}
	local allitems = GLOBAL.ThePlayer.components.inventory:FindItems(function() return true end)
	for i, item in ipairs(allitems) do 
		item.myIndex = i
		defaultitemset[i] = item
	end
	
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
	-- for i, itemSet in ipairs(actualItemSets) do 
	-- 	print(itemSet.name)
	-- end
	
	itemwheel:UpdateItems(actualItemSets, SHOWIMAGE, SHOWTEXT)
	itemwheel:Show()
	itemwheel:ScaleTo(STARTSCALE, NORMSCALE, .25)
end

local function HideItemWheel(delay_focus_loss)
	if type(GLOBAL.ThePlayer) ~= "table" or type(GLOBAL.ThePlayer.HUD) ~= "table" then return end
	keydown = false
	if delay_focus_loss and itemwheel.activeitem then
		--delay a little on controllers to prevent canceling the emote by moving
		--GLOBAL.ThePlayer:DoTaskInTime(0.5, function() SetModHUDFocus("ItemWheel", false) end)
	else
		--SetModHUDFocus("ItemWheel", false)
	end
	
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
		-- GLOBAL.TheNet:SendSlashCmdToServer(itemwheel.activeitem, true)
		print("action fired")
		local itemIndex = itemwheel.activeitem -- NOT SAFE, WILL PROBABLY FUCK UP WHEN MULTIPLE WHEELS
		print(itemIndex)
		--local item = GLOBAL.ThePlayer.components.inventory:GetItemInSlot(itemIndex)
		local item = itemwheel.actualItems[itemIndex]
		if item == nil then 
			print("item is nil somehow, index was:")
			print(tostring(itemIndex))
			return
		end
		print(item.prefab)
		print("attempt to equip")
		GLOBAL.ThePlayer.components.inventory:Equip(item)
	end
end

local handlers_applied = false
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