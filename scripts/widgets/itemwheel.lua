local Widget = require "widgets/widget"
local Text = require "widgets/text"
local ItemBadge = require("widgets/itembadge")

local function build_wheel(self, name, emotes, radius, color, scale, image, text)
	local wheel = self.root:AddChild(Widget("ItemWheelRoot-"..name))
	wheel:SetScale(1)
	table.insert(self.wheels, wheel)
	if name == "default" then
		self.activewheel = #self.wheels
	end 
	local count = #emotes
	radius = radius * scale
	wheel.radius = radius
	local delta = -2*math.pi/count
	local theta = math.pi/2
	wheel.items = {}
	for i, item in ipairs(emotes) do
		local itemBadge = wheel:AddChild(ItemBadge(item, image, text, color))
		itemBadge:SetPosition(radius*math.cos(theta),radius*math.sin(theta), 0)
		itemBadge:SetScale(scale)
		self.actualItems[item.myIndex] = item
		self.items[item.myIndex] = itemBadge
		wheel.items[item.myIndex] = itemBadge
		theta = theta + delta
	end
end

local function construct(self, item_sets, image, text)
	self.root:KillAllChildren()
	self.actualItems = {}
	self.items = {}
	self.wheels = {}
	self.activewheel = nil

	-- Sort the emote sets in order of decreasing radius
	table.sort(item_sets, function(a,b) return a.radius > b.radius end)
	local scale = 1
	for _, item_set in ipairs(item_sets) do
		build_wheel(self, item_set.name, item_set.emotes, item_set.radius, item_set.color, scale, image, text)
		scale = scale * 0.85
	end
end

local ItemWheel = Class(Widget, function(self, image, text, rightstick)
	Widget._ctor(self, "ItemWheel")
	self.isFE = false
	self:SetClickable(false)
	self.userightstick = rightstick
	self.screenscalefactor = 1
	self.controllermode = false
	self.root = self:AddChild(Widget("root"))
	self.item1 = nil
	self.item2 = nil
	self.item3 = nil
end)

local function GetMouseDistance(self, gesture, mouse)
	local pos = self:GetPosition()
	if gesture ~= nil then
		local offset = gesture:GetPosition()*self.screenscalefactor
		pos.x = pos.x + offset.x
		pos.y = pos.y + offset.y
	end
	local dx = pos.x - mouse.x
	local dy = pos.y - mouse.y
	return dx*dx + dy*dy
end

local function GetControllerDistance(self, gesture, direction)
	local pos = self:GetPosition()
	if gesture ~= nil then
		pos = gesture:GetPosition()
	else
		pos.x = 0
		pos.y = 0
	end
	local dx = pos.x - direction.x
	local dy = pos.y - direction.y
	return dx*dx + dy*dy
end

local function GetControllerTilt(right)
	local xdir = 0
	local ydir = 0
	if right then
		xdir = TheInput:GetAnalogControlValue(CONTROL_INVENTORY_RIGHT) - TheInput:GetAnalogControlValue(CONTROL_INVENTORY_LEFT)
		ydir = TheInput:GetAnalogControlValue(CONTROL_INVENTORY_UP) - TheInput:GetAnalogControlValue(CONTROL_INVENTORY_DOWN)
	else
		xdir = TheInput:GetAnalogControlValue(CONTROL_MOVE_RIGHT) - TheInput:GetAnalogControlValue(CONTROL_MOVE_LEFT)
		ydir = TheInput:GetAnalogControlValue(CONTROL_MOVE_UP) - TheInput:GetAnalogControlValue(CONTROL_MOVE_DOWN)
	end
	return xdir, ydir
end

function ItemWheel:UpdateItems(item_sets, image, text)
	construct(self, item_sets, image, text)
	return
end

function ItemWheel:OnUpdate()
	local mindist = math.huge
	local mingesture = nil
	
	if TheInput:ControllerAttached() then
		local xdir, ydir = GetControllerTilt(self.userightstick)
		local deadzone = .15 -- low deadzone
		if math.abs(xdir) >= deadzone or math.abs(ydir) >= deadzone then
			local wheel = self.wheels[self.activewheel]
			local dir = Vector3(xdir, ydir, 0):GetNormalized() * wheel.radius
			
			for k,v in pairs(wheel.items) do
				local dist = GetControllerDistance(self, v, dir)
				if dist < mindist then
					mindist = dist
					mingesture = k
				end
			end
		else
			mingesture = nil
			self.activeitem = nil		
		end
	else
		--find the gesture closest to the mouse
		local mouse = TheInput:GetScreenPosition()
		for k,v in pairs(self.items) do
			local dist = GetMouseDistance(self, v, mouse)
			if dist < mindist then
				mindist = dist
				mingesture = k
			end
		end
		-- make sure the mouse isn't still close to the center of the gesture wheel
		if GetMouseDistance(self, nil, mouse) < mindist then
			mingesture = nil
			self.activeitem = nil
		end
	end
	
	for k,v in pairs(self.items) do
		if k == mingesture then
			v:Expand()
			self.activeitem = k
		else
			v:Contract()
		end
	end
end

local function SetWheelAlpha(wheel, alpha)
	for _,badge in pairs(wheel.items) do
		badge:SetFadeAlpha(alpha)
		if badge.puppet ~= nil then
			badge.puppet.animstate:SetMultColour(1,1,1,alpha)
		end
	end
end

function ItemWheel:SetControllerMode(enabled)
	if self.controllermode ~= enabled then
		self.controllermode = enabled
		local alpha = enabled and 0.25 or 1
		-- for i,wheel in pairs(self.wheels) do
		-- 	SetWheelAlpha(wheel, i == self.activewheel and 1 or alpha)
		-- end
	end
end

function ItemWheel:SwitchWheel(delta)
	if self.activewheel == nil then return end
	local oldwheel = self.activewheel
	self.activewheel = math.max(1, math.min(self.activewheel + delta, #self.wheels))
	if oldwheel ~= self.activewheel then
		if self.activeitem ~= nil then
			self.items[self.activeitem]:Contract()
			self.activeitem = nil
		end
		SetWheelAlpha(self.wheels[oldwheel], 0.25)
		SetWheelAlpha(self.wheels[self.activewheel], 1)
	end
end

return ItemWheel