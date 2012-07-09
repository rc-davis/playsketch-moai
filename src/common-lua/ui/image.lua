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

	ui/image.lua
	
	A view wrapper for a Moai image

--]]

ui.image = {}

local Image = util.objects.defineType("Image", ui.view.class())


function ui.image.class()

	return Image

end


function ui.image.new( frame, imgpath )

	local o = Image:create()
	o:init( frame, imgpath )
	return o
	
end


function Image:init( frame, imgpath )

	self:superClass().init(self, frame)

	-- Load the image
	local gfx = MOAIGfxQuad2D.new()
	gfx:setTexture(imgpath)
	gfx:setRect ( 0, 0,  self.frame.size.width,  self.frame.size.height )

	-- Attach it to our existing prop
	self.prop:setDeck(gfx)
	
	-- Disable touches
	self:setReceivesTouches(false)

end

return ui.image
