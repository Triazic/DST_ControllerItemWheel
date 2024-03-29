local Image = require "widgets/image"
local Widget = require "widgets/widget"
local Text = require "widgets/text"
local ItemTile = require "widgets/itemtile"

local ATLAS = "images/avatars.xml"

local SMALLSCALE = 1.0
local LARGESCALE = 1.5
local BROWN = {80/255, 60/255, 30/255, 1}

local default_position = {
	offsetx = 0,
	offsety = -37,
	xyscale = 0.7,
	percent = 0.5,
}

local positions = {
	-- -- default item exceptions
	-- emoteXL_loop_dance0 = {
	-- 	offsety = -32,
	-- 	percent = 1,
	-- },
	-- emoteXL_bonesaw = {
	-- 	offsety = -32,
	-- 	xyscale = 0.58,
	-- },
	-- research = { --/joy
	-- 	offsety = -64,
	-- 	offsetx = 5,
	-- },
	-- emoteXL_kiss = {
	-- 	offsety = -27,
	-- 	offsetx = -15,
	-- 	xyxyscale = 0.78,
	-- },
	-- emote_strikepose = {
	-- 	offsety = -32,
	-- 	percent = 0.4,
	-- },
	-- emoteXL_angry = {
	-- 	offsety = -42,
	-- },
	-- emote_sleepy = {
	-- 	xyscale = 0.78,
	-- 	percent = 0.7,
	-- },
	-- emote_yawn = {
	-- 	offsetx = 5,
	-- },
	-- emote_loop_sit3 = {
	-- 	xyscale = 0.8,
	-- 	offsety = -32,
	-- },
	-- emote_loop_sit4 = {
	-- 	xyscale = 0.8,
	-- 	offsety = -32,
	-- },
	-- emote_swoon = {
	-- 	offsetx = -5,
	-- 	offsety = -32,
	-- },
	-- emote_loop_toast = {
	-- 	offsetx = -12,
	-- 	percent = 0.9,
	-- },
	
	-- -- party dance mod exceptions
	-- powerup = { --buffed
	-- 	offsety = -52,
	-- },
	-- bedroll_sleep_loop = { --fakebed
	-- 	offsety = -7,
	-- 	offsetx = 10,
	-- },
	-- sleep_loop = { --wasted
	-- 	offsety = -7,
	-- 	offsetx = 10,
	-- },
	-- powerdown = { --pushup
	-- 	offsety = -17,
	-- 	offsetx = -5,
	-- },
	-- death = { --dead
	-- 	offsety = -22,
	-- },
	-- shock = { --shocked
	-- 	offsety = -40,
	-- 	offsetx = 5,
	-- },
	-- mime = { --various different ones
	-- 	offsety = -27,
	-- },
	
	-- -- old emotes mod exceptions
}
--All old emotes really needed the same thing, so it's neater to do this
-- local old_emotes = {"angry", "annoyed_palmdown", "annoyed_facepalm", "feet",
-- 					"hands", "hat", "pants", "happycheer", "sad", "waving"}
-- for _,emote in ipairs(old_emotes) do
-- 	positions["emote_"..emote] = { offsety = -30 }
-- end

--Copy over mime positioning for each of the mime anims
-- for i=1,8 do
-- 	positions["mime"..i] = positions.mime
-- end

--Set the default value for the table to be the default positioning
metapositions = {
	__index = function() return default_position end,
}
setmetatable(positions, metapositions)

--Set the default values for each of the adjustments listed above to the values of the default table
metaposition = {
	__index = default_position,
}
for anim,position in pairs(positions) do
	setmetatable(position, metaposition)
end

local function GetImageAsset(prefab)
	local item_tex = prefab..'.tex'
	local atlas = GetInventoryItemAtlas(item_tex)
	local localized_name = STRINGS.NAMES[string.upper(prefab)] or prefab
	local prefabData = Prefabs[prefab]
  
	if prefabData then
	  -- first run we find assets with exact match of prefab name
	  if not atlas or not TheSim:AtlasContains(atlas, item_tex) then
		for _, asset in ipairs(prefabData.assets) do
		  if asset.type == "INV_IMAGE" then
			item_tex = asset.file..'.tex'
			atlas = GetInventoryItemAtlas(item_tex)
		  elseif asset.type == "ATLAS" then
			atlas = asset.file
		  end
		end
	  end
  
	  -- second run, a special case for migrated items, they are prefixed via `quagmire_`
	  if not atlas or not TheSim:AtlasContains(atlas, item_tex) then
		for _, asset in ipairs(Prefabs[prefab].assets) do
		  if asset.type == "INV_IMAGE" then
			item_tex = 'quagmire_'..asset.file..'.tex'
			atlas = GetInventoryItemAtlas(item_tex)
		  end
		end
	  end
	end
  
	return item_tex, resolvefilepath(atlas), localized_name
end

local ItemBadge = Class(Widget, function(self, item, image, text, color, item1prefab, item2prefab, item3prefab)
	local prefab = item.prefab
	local index = item.myIndex 

	Widget._ctor(self, "ItemBadge-"..tostring(index))
	self.isFE = false
	self:SetClickable(false)

	self.root = self:AddChild(Widget("root"))

	-- self.icon = self.root:AddChild(Widget("target"))
	-- self.icon:SetScale(SMALLSCALE)
	self.expanded = false
	self.color = PLAYERCOLOURS.EGGSHELL

	self.background = self.root:AddChild(Image(ATLAS, "avatar_bg.tex"))
	self.background:SetTint(unpack(self.color))
	self.tile = self.root:AddChild(ItemTile(item))

	local amItem1 = item1prefab ~= nil and item.prefab == item1prefab
	local amItem2 = item2prefab ~= nil and item.prefab == item2prefab
	local amItem3 = item3prefab ~= nil and item.prefab == item3prefab

	local function AddText(message)
		local text = self.root:AddChild(Text(NUMBERFONT, 28))
		text:SetHAlign(ANCHOR_MIDDLE)
		text:SetPosition(-18, 18, 0)
		text:SetScale(1,0.78,1)
		text:SetString(message)
	end

	if (amItem1) then 
		AddText("1")
	elseif (amItem2) then 
		AddText("2")
	elseif (amItem3) then 
		AddText("3")
	end

	-- if image then
	-- 	self.background = self.icon:AddChild(Image(ATLAS, "avatar_bg.tex"))
	-- 	local item_tex, _atlasfilepath, localized_name = GetImageAsset(prefab)
	-- 	local _image = self.icon:AddChild(Image(_atlasfilepath, item_tex))
	-- end
	
	-- if text then
	-- 	self.bg = self.icon:AddChild(Image("images/gesture_bg.xml", "gesture_bg.tex"))
	-- 	self.bg:SetScale(.11*(prefab:len()+1),.5,0)
	-- 	if image then self.bg:SetPosition(-.5,-34,0) end
	-- 	self.bg:SetTint(unpack(color))

	-- 	self.text = self.icon:AddChild(Text(NUMBERFONT, 28))
	-- 	self.text:SetHAlign(ANCHOR_MIDDLE)
	-- 	if image then
	-- 		self.text:SetPosition(3.5, -50, 0)
	-- 	else
	-- 		self.text:SetPosition(3.5, -18, 0)
	-- 	end
	-- 	self.text:SetScale(1,.78,1)
	-- 	self.text:SetString("/"..prefab)
	-- end
end)

function ItemBadge:Expand()
	-- focusses a badge. 
	if self.expanded then return end
	self.expanded = true
	self.root:ScaleTo(SMALLSCALE, LARGESCALE, .25)
	self.background:SetTint(unpack(PLAYERCOLOURS.GREEN))
	self:MoveToFront()
end

function ItemBadge:Contract()
	-- unfocusses a badge (default state)
	if not self.expanded then return end
	self.expanded = false
	self.root:ScaleTo(LARGESCALE, SMALLSCALE, .25)
	self.background:SetTint(unpack(self.color))
	self:MoveToBack()
end

return ItemBadge