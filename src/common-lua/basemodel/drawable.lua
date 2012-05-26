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
	--self.isSelected = false
	self.paths = {}
	drawingLayer:insertProp (prop)
end

function Drawable:addPath(path)

	-- figure out the path above and below this one
	local beforePath = nil
	local afterPath = nil
	for p,_ in pairs(self.paths) do
		assert(p.index ~= path.index, "Can't add a path that already belongs")
		if path.index > p.index and (beforePath == nil or p.index > beforePath.index) then
			beforePath = p
		elseif path.index < p.index and (afterPath == nil or p.index < afterPath.index) then
			afterPath = p
		end
	end

	--create a new proxy Prop for it
	self.paths[path] = MOAIProp2D.new ()
	drawingLayer:insertProp(self.paths[path])

	--set inheritance on objects
	if beforePath then
		self.paths[beforePath]:clearAttrLink(MOAIProp2D.INHERIT_TRANSFORM)
		self.paths[beforePath]:setAttrLink(MOAIProp2D.INHERIT_TRANSFORM, self.paths[path], MOAIProp2D.TRANSFORM_TRAIT)
	end
	
	if afterPath then
		self.paths[path]:setAttrLink(MOAIProp2D.INHERIT_TRANSFORM, self.paths[afterPath], MOAIProp2D.TRANSFORM_TRAIT)
	end
end


return basemodel.drawable
