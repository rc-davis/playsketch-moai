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
	
	-- Remove the superclass's default prop:
	self.prop = nil

	-- Create our textbox prop in its place
	self.prop = MOAITextBox.new ()

	--Set its properties
	self.prop:setFont ( font )
	self.prop:setAlignment(MOAITextBox.CENTER_JUSTIFY, MOAITextBox.CENTER_JUSTIFY)
	self.prop:setRect(0, 0, frame.size.width, frame.size.height)
	self.prop:setLoc (0, 0)
	self.prop:setYFlip ( true )
	self:setText(text)
	self:setSize(size)
	self:setColor(color)
	
end


function Label:setText(text)

	self.prop:setString(text)

end


function Label:setSize(size)

	self.prop:setTextSize (size)
	
end


function Label:setColor(color)

	self.prop:setColor (unpack(color))

end


return ui.label
