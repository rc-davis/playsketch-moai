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

	widgets/modifierButton.lua
	
	A button to take the place of the shift key.
	
	Defaults to drawing mode, hold to get to select mode, 
	release with a selection, get to recording mode
	
--]]


widgets.modifierButton = {}

local Modifier = {}

function widgets.modifierButton.new(centerX, centerY, width, height, 
										callbackStartModifier, callbackStopModifier)
	return util.clone(Modifier):init(centerX, centerY, width, height, 
										callbackStartModifier, callbackStopModifier)
end

function Modifier:init(centerX, centerY, width, height, callbackStartModifier, callbackStopModifier)

	self.storedGraphics = {} -- maps cached file paths to MOAIGfxQuad2D objects

	--create prop
	self.prop = MOAIProp2D.new ()
	self.prop:setLoc ( centerX, centerY )
	widgets.layer:insertProp (self.prop)	
	
	--store callbacks
	self.callbackStartModifier = callbackStartModifier
	self.callbackStopModifier = callbackStopModifier
	
	--register for touches
	input.manager.addDownCallback(input.manager.UILAYER, 
		function (id,px,py) return self:touchDown(id,px,py) end)

	input.manager.addUpCallback(input.manager.UILAYER, 
		function (id,px,py) return self:touchUp(id,px,py) end)
		
		
	self.size = {width=width, height=height}	
	self.touchID = nil
	self.isModifying = false
	self.upImage = nil
	self.downImage = nil
	
	return self
end

function Modifier:touchDown(id,px,py)
	if self.touchID == nil and self.prop:inside(px,py) then
		self.touchID = id
		
		if MOAIInputMgr.device.touch then
			self.isModifying = true
			if self.callbackStartModifier then self.callbackStartModifier() end
		end
		self:refreshPropGfx()
		return true
	end
	return false
end


function Modifier:touchUp(id,px,py)
	if self.touchID == id then
		self.touchID = nil
		
		if MOAIInputMgr.device.touch or self.isModifying then --touchscreen up: stop modifying
			self.isModifying = false
			if self.callbackStopModifier then self.callbackStopModifier() end
		else -- mouse up while not modifying : start modifying
			self.isModifying = true
			if self.callbackStartModifier then self.callbackStartModifier() end
		end
		
		self:refreshPropGfx()
	
		return true
	end
	return false
end

function Modifier:setImages(upImagePath, downImagePath)

	--cache the up image
	if self.storedGraphics[upImagePath] == nil then
		local gfx = MOAIGfxQuad2D.new()
		gfx:setTexture(upImagePath)
		gfx:setRect( -self.size.width/2, -self.size.height/2, self.size.width/2, self.size.height/2 )
		self.storedGraphics[upImagePath] = gfx
	end

	--cache the down image
	if self.storedGraphics[downImagePath] == nil then
		local gfx = MOAIGfxQuad2D.new()
		gfx:setTexture(downImagePath)
		gfx:setRect( -self.size.width/2, -self.size.height/2, self.size.width/2, self.size.height/2 )
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

	if (self.isModifying == true or self.touchID ~= nil) and self.downImage then
		self.prop:setDeck(self.downImage)
	elseif self.upImage then
		self.prop:setDeck(self.upImage)
	end
end

return widgets.modifierButton
