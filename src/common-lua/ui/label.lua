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

	ui/label.lua
	
	A simple text label

--]]

ui.label = {}

-- Load shared font once
local charcodes = 'asdfghjklqwertyuiopzxcvbnm0123456789 -'
local font = MOAIFont.new ()
font:loadFromTTF ( 'resources/arial-rounded.TTF', charcodes, 48, 163 )



local Label = util.objects.defineType("Label", ui.view.class())


function ui.label.class()

	return Label

end


function ui.label.new(frame, text, size, color)

	local o = Label:create()
	o:init(frame, text, size, color)
	return o
	
end


function Label:init(frame, text, size, color)

	self:superClass().init(self, frame)
	
	-- Create our textbox prop
	self.textbox = MOAITextBox.new ()
	self.textbox:setFont ( font )
	self.textbox:setAlignment(MOAITextBox.CENTER_JUSTIFY, MOAITextBox.CENTER_JUSTIFY)

	--Set its properties
	self.textbox:setRect(0, 0, frame.size.width, frame.size.height)
	self.textbox:setLoc (0, 0)
	self.textbox:setYFlip ( true )
	self:setText(text)
	self:setSize(size)
	self:setColor(color)
	
	-- Make text dependent on self's location
	self.textbox:setAttrLink(MOAIProp2D.INHERIT_TRANSFORM, self.prop, MOAIProp2D.TRANSFORM_TRAIT)
	ui.view.layer:insertProp(self.textbox)
end


function Label:setText(text)

	self.textbox:setString(text)

end


function Label:setSize(size)

	self.textbox:setTextSize (size)
	
end


function Label:setColor(color)

	self.textbox:setColor (unpack(color))

end


return ui.label
