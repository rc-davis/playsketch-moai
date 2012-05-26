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

	basemodel/drawable.lua
	
	Encapsulates a drawable
	Maintains a reference to the prop object that is part of the MOAI hierarchy
	Tracks the path objects that apply to it

--]]


basemodel.drawable = {}

local Drawable = {}

-- Clone the Drawable prototype
-- prop should be centred on 0,0
function basemodel.drawable.newFromProp(prop)
	d = {}
	for i, v in pairs(Drawable) do
		d[i]=v
	end
	d:init(prop)
	return d
end


--Drawable methods
function Drawable:init(prop)
	self.class = "Drawable"
	self.prop = prop
	self.isSelected = false
	self.transforms = {}
	drawingLayer:insertProp (prop)
end

return basemodel.drawable
