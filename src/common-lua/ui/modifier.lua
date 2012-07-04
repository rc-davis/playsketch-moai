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

	ui/modifier.lua
	
	A button to take the place of the shift key.
	
	Defaults to drawing mode, hold to get to select mode, 
	release with a selection, get to recording mode

--]]

ui.modifier = {}


local Modifier = util.objects.defineType("Modifier", ui.view.class())


function ui.modifier.class()

	return Modifier

end


function ui.modifier.new( frame, callbackStartModifier, callbackStopModifier )

	local o = Modifier:create()
	o:init(frame, callbackStartModifier, callbackStopModifier)
	return o
	
end


function Modifier:init ( frame, callbackStartModifier, callbackStopModifier )

	self:superClass().init ( self, frame )
	
	self.callbackStartModifier = callbackStartModifier
	self.callbackStopModifier = callbackStopModifier
	
	
	self.storedGraphics = {} -- maps cached file paths to MOAIGfxQuad2D objects

	self.touchID = nil
	self.isModifying = false
	self.upImage = nil
	self.downImage = nil
	
	return self
	
end


function Modifier:touchEvent(id, eventType, x, y)

	if eventType == MOAITouchSensor.TOUCH_DOWN and self.touchID == nil then

		--Behave differently for touchscreens vs mouse + keyboard
		if MOAIInputMgr.device.touch then
			self.isModifying = true
			if self.callbackStartModifier then self.callbackStartModifier() end
		end
		
		self.touchID = id

	elseif eventType == MOAITouchSensor.TOUCH_UP and id == self.touchID then

		if MOAIInputMgr.device.touch or self.isModifying then --touchscreen up: stop modifying

			self.isModifying = false
			if self.callbackStopModifier then self.callbackStopModifier() end

		else -- mouse up while not modifying : start modifying

			self.isModifying = true
			if self.callbackStartModifier then self.callbackStartModifier() end

		end
		
		self.touchID = nil
		
	end
	--TODO: handle cancel too?
	
	self:refreshPropGfx()

end


function Modifier:setImages(upImagePath, downImagePath)

	--cache the up image
	if self.storedGraphics[upImagePath] == nil then
		local gfx = MOAIGfxQuad2D.new()
		gfx:setTexture(upImagePath)
		gfx:setRect ( 0, 0,  self.frame.size.width,  self.frame.size.height )
		self.storedGraphics[upImagePath] = gfx
	end

	--cache the down image
	if self.storedGraphics[downImagePath] == nil then
		local gfx = MOAIGfxQuad2D.new()
		gfx:setTexture(downImagePath)
		gfx:setRect ( 0, 0,  self.frame.size.width,  self.frame.size.height )
		self.storedGraphics[downImagePath] = gfx
	end

	--set the current image
	self.upImage = self.storedGraphics[upImagePath]
	self.downImage = self.storedGraphics[downImagePath]

	self:forceUp()

end


function Modifier:forceUp()	

	self.touchID = nil
	self.isModifying = false
	self:refreshPropGfx()

end


function Modifier:refreshPropGfx()

	print("REFRESHING", self.prop, self.upImage)
	if (self.isModifying == true or self.touchID ~= nil) and self.downImage then

		self.prop:setDeck(self.downImage)

	elseif self.upImage then

		self.prop:setDeck(self.upImage)

	end

end


return ui.modifier
