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

	widgets/textButton.lua

	- A plain button with generated text on it (not designed to be pretty)

--]]

widgets.textButton = {}
local TextButton = {}

function widgets.textButton.new( centerX, centerY, width, height, text, callbackUp )
	return util.clone(TextButton):init( centerX, centerY, width, height, text, callbackUp )
end

-- load shared resources once
local charcodes = 'asdfghjklqwertyuiopzxcvbnm0123456789 -'
local font = MOAIFont.new ()
font:loadFromTTF ( 'resources/arial-rounded.TTF', charcodes, 16, 163 )


function TextButton:init( centerX, centerY, width, height, text, callbackUp )

	self.frame = {size={width=width,height=height}, origin={x=centerX-width/2, y=centerY-height/2} }
	self.text = nil
	self.callbackUp = callbackUp
	self.highlighted = false
	self.enabled = true

	-- create background
	self.scriptDeck = MOAIScriptDeck.new ()
	self.scriptDeck:setRect (	-width/2, -height/2, width/2, height/2)
	self.scriptDeck:setDrawCallback(function () self:onDraw() end)
	self.prop = MOAIProp2D.new ()
	self.prop:setDeck (self.scriptDeck)
	self.prop:setLoc ( centerX, centerY )	
	widgets.layer:insertProp ( self.prop )
	
	-- create text box
	self.textbox = MOAITextBox.new ()
	self.textbox:setFont ( font )
	self.textbox:setTextSize (18)
	self.textbox:setColor (0.3, 0.3, 0.3)
	self.textbox:setAlignment(MOAITextBox.CENTER_JUSTIFY, MOAITextBox.CENTER_JUSTIFY)
	self.textbox:setYFlip ( true )
	self.textbox:setRect(	-width/2, -height/2, width/2, height/2)
	self.textbox:setLoc ( centerX, centerY )
	widgets.layer:insertProp ( self.textbox )
	
	-- register for touches
	input.manager.addDownCallback(input.manager.UILAYER, 
								function (id,px,py) return self:onTouchDown(id,px,py) end)
	input.manager.addUpCallback(input.manager.UILAYER, 
								function (id,px,py) return self:onTouchUp(id,px,py) end)

	self:setText(text)
	return self
end

function TextButton:setText(text)
	self.text = text
	self.textbox:setString(text)
end

function TextButton:setHighlighted(highlighted)
	self.highlighted = highlighted
end

function TextButton:setEnabled(enabled)
	self.enabled = enabled
	if not enabled then
		self.textbox:setColor(0.85, 0.75, 0.75)
	else
		self.textbox:setColor(0.3, 0.3, 0.3)
	end
end

function TextButton:onDraw( index, xOff, yOff, xFlip, yFlip )
	if self.touchID then
		MOAIGfxDevice.setPenColor (0.686, 0.729, 0.769)
	elseif self.highlighted == true then
		MOAIGfxDevice.setPenColor (0.90, 0.90, 0.90)
	elseif self.enabled == false then
		MOAIGfxDevice.setPenColor (0.85, 0.85, 0.85)
	else
		MOAIGfxDevice.setPenColor (0.957, 0.973, 0.808)
	end
	MOAIDraw.fillRect (	-self.frame.size.width/2, -self.frame.size.height / 2,
						 self.frame.size.width/2,  self.frame.size.height / 2)

	if self.touchID then
		MOAIGfxDevice.setPenColor (0.957, 0.973, 0.808)
	else
		MOAIGfxDevice.setPenColor (0.686, 0.729, 0.769)
	end
	MOAIGfxDevice.setPenWidth(1)	
	MOAIDraw.drawRect (	-self.frame.size.width/2, -self.frame.size.height / 2,
						 self.frame.size.width/2,  self.frame.size.height / 2)
end



function TextButton:onTouchDown(id,px,py)
	if not self.prop:inside(px,py) then return false end

	if self.enabled and self.touchID == nil then
		self.touchID = id
	end
	return true
end

function TextButton:onTouchUp(id,px,py)
	if self.touchID == id then
		self.touchID = nil
		if self.prop:inside(px,py) and self.callbackUp then
			self.callbackUp(self.prop, px, py)
		end
		return true
	end
	return false
end

function TextButton:delete()
	widgets.layer:removeProp ( self.prop )
	widgets.layer:removeProp ( self.textbox )
end

return widgets.textButton