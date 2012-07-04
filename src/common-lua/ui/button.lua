--[[
	--------------
	Copyright 2012 Singapore Management University
	 
	This Source Code Form is subject to the terms of the
	Mozilla Public License, v. 2.0. If a copy of the MPL was
	not distributed with this file, You can obtain one at
	http://mozilla.org/MPL/2.0/.
	--------------
--]]

--[[

	ui/button.lua
	
	A simple button that calls back on down and up

--]]

ui.button = {}
ui.button.DISABLED = "DISABLED"

local Button = util.objects.defineType("Button", ui.view.class())


function ui.button.class()

	return Button

end


function ui.button.new( frame )

	local o = Button:create()
	o:init( frame )
	return o
	
end


function Button:init( frame )

	self:superClass().init(self, frame)
	self.callbacks = {}

	self.backgroundColors = {}
	self:setBackgroundColorForState(MOAITouchSensor.TOUCH_UP, { 0.5, 0.5, 0.5 })
	self:setBackgroundColorForState(MOAITouchSensor.TOUCH_DOWN, { 1.0, 0.5, 0.5 })
	self:setBackgroundColorForState(ui.button.DISABLED, { 0.3, 0.3, 0.3 })

	self.borderColor = { 0.2, 0.2, 0.2 }

	self.state = MOAITouchSensor.TOUCH_UP
	self:refreshState()

end


function Button:setCallback( state, func )

	self.callbacks[state] = func

end


function Button:setBackgroundColorForState( state, color )

	-- MOAITouchSensor values or ui.button.DISABLED
	self.backgroundColors[state] = color

end


function Button:refreshState()

	if self.backgroundColors[self.state] then
		self:setBackgroundColor(self.backgroundColors[self.state])
	else
		self:setBackgroundColor( { 1, 1, 1 } )
	end
end


function Button:touchEvent(id, eventType, x, y)

	if self.state == ui.button.DISABLED then return end

	self.state = eventType
	self:refreshState()

	if self.callbacks[eventType] then 
		self.callbacks[eventType](id, x, y)
	end
	
end


function Button:getTextLabel()

	return self.textLabel
	
end


function Button:setText(text)

	if self.textLabel == nil then

		self.textLabel = ui.label.new ( ui.rect.new(0, 0, self.frame.size.width, self.frame.size.height), text, 20, { 0, 0, 0 } )
		self.textLabel:setReceivesTouches(false)
		self:addSubview(self.textLabel)

	else
	
		self.textLabel:setText(text)
	
	end

end


function Button:setEnabled(enabled)

	if enabled == true then 
		self.state = MOAITouchSensor.TOUCH_UP
	else
		self.state = ui.button.DISABLED
	end
	
	self:refreshState()
	
end

return ui.button
