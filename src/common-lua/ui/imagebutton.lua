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

	ui/imagebutton.lua
	
	A simple imagebutton that calls back on down and up

--]]

ui.imagebutton = {}
ui.imagebutton.DISABLED = "DISABLED"

local ImageButton = util.objects.defineType("ImageButton", ui.view.class())


function ui.imagebutton.class()

	return ImageButton

end


function ui.imagebutton.new( frame )

	local o = ImageButton:create()
	o:init( frame )
	return o
	
end


function ImageButton:init( frame )

	self:superClass().init(self, frame)
	self.callbacks = {}

	self.storedGraphics = {} -- path -> ImgGfx
	self.currentGraphics = {} -- state -> ImgGfx


	self.state = MOAITouchSensor.TOUCH_UP
	self:refreshState()

end


function ImageButton:setCallback( state, func )

	self.callbacks[state] = func

end


function ImageButton:setImageForState( state, path )

	-- MOAITouchSensor values or ui.imagebutton.DISABLED
	if self.storedGraphics[path] == nil then
		local gfx = MOAIGfxQuad2D.new()
		gfx:setTexture(path)
		gfx:setRect ( 0, 0,  self.frame.size.width,  self.frame.size.height )
		self.storedGraphics[path] = gfx
	end
	
	self.currentGraphics[state] = self.storedGraphics[path]
	self:refreshState()

end


function ImageButton:refreshState()

	if self.currentGraphics[self.state] then
		self.prop:setDeck(self.currentGraphics[self.state])
	else
		print ("!!!!!! NO GRAPHIC FOR CURRENT STATE!!!!")
	end

end


function ImageButton:touchEvent(id, eventType, x, y)

	if self.state == ui.imagebutton.DISABLED then return end

	self.state = eventType
	self:refreshState()

	if self.callbacks[eventType] then 
		self.callbacks[eventType](id, x, y)
	end
	
end


function ImageButton:setEnabled(enabled)

	if enabled == true then 
		self.state = MOAITouchSensor.TOUCH_UP
	else
		self.state = ui.imagebutton.DISABLED
	end
	
	self:refreshState()
	
end

return ui.imagebutton
