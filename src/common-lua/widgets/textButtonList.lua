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

	widgets/textButtonList.lua

	- A dynamic list of text buttons

--]]

widgets.textButtonList = {}
local TextButtonList = {}

function widgets.textButtonList.new( centerX, centerY, width, height, buttonHeight, selectionChangeCallback)
	return util.clone(TextButtonList):init( centerX, centerY, width, height, buttonHeight, selectionChangeCallback)
end

function TextButtonList:init (centerX, centerY, width, height, buttonHeight, selectionChangeCallback)

	self.frame = {size={width=width,height=height}, origin={x=centerX-width/2, y=centerY-height/2} }
	self.selectionChangeCallback = selectionChangeCallback
	self.buttons = {}
	self.buttonHeight = buttonHeight
	self.selectionIndex = nil

	-- create background
	self.scriptDeck = MOAIScriptDeck.new ()
	self.scriptDeck:setRect (	-width/2, -height/2, width/2, height/2)
	self.scriptDeck:setDrawCallback(function () self:onDraw() end)
	self.prop = MOAIProp2D.new ()
	self.prop:setDeck (self.scriptDeck)
	self.prop:setLoc ( centerX, centerY )	
	widgets.layer:insertProp ( self.prop )
	
	-- register for touches
	input.manager.addDownCallback(input.manager.UILAYER, 
								function (id,px,py) return self:onTouchDown(id,px,py) end)


	return self
end


function TextButtonList:onDraw( index, xOff, yOff, xFlip, yFlip )
	MOAIGfxDevice.setPenColor (0.957, 0.973, 0.808)
	MOAIDraw.fillRect (	-self.frame.size.width/2, -self.frame.size.height / 2,
						 self.frame.size.width/2,  self.frame.size.height / 2)
	MOAIGfxDevice.setPenColor (0.686, 0.729, 0.769)
	MOAIDraw.drawRect (	-self.frame.size.width/2, -self.frame.size.height / 2,
						 self.frame.size.width/2,  self.frame.size.height / 2)
end


function TextButtonList:addItem(textLabel, id)
	local newIndex = #self.buttons + 1
	local newbutton = widgets.textButton.new(
						self.frame.origin.x + self.frame.size.width/2,
						self.frame.origin.y + self.buttonHeight * (0.5 + #self.buttons),
						self.frame.size.width, self.buttonHeight, textLabel, 
						function() self:setSelected(newIndex) end )
	newbutton.buttonListId = id
	table.insert(self.buttons, newbutton)
	self:setSelected(newIndex)
end

function TextButtonList:setSelected(index)
	if index == self.selectionIndex then return end
	assert(index > 0 and index <= #self.buttons)
	if self.selectionIndex then
		self.buttons[self.selectionIndex]:setHighlighted(false)
	end
	self.buttons[index]:setHighlighted(true)
	self.selectionIndex = index
	if self.selectionChangeCallback then 
		self.selectionChangeCallback(self.buttons[self.selectionIndex].buttonListId)
	end
end

function TextButtonList:onTouchDown(id,px,py)
	if not self.prop:inside(px,py) then return false
	else return true end
end

return widgets.textButtonList