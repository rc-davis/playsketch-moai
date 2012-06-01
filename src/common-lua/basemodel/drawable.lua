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
	
	Represents an animation item that is drawn to the screen (ink stroke, image, etc). 
	To support this, it creates and maintains the MOAIProp2D object that is part of the
	MOAI scene graph.
	Also tracks the various Path objects that apply to the drawable, and represents each
	one with its own MOAIProp2D object.

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
	self.prop.visible = true
	self.paths = {}
	drawingLayer:insertProp (prop)
end

function Drawable:addPath(path)

	--create a new proxy Prop for it
	self.paths[path] = MOAIProp2D.new ()
	drawingLayer:insertProp(self.paths[path])
	path:incrementDrawableCount()
	
	-- brute-force redo our inheritance
	-- TODO: this might be a good place to optimize if adding new transforms is slow
	self:redoPathHierarchy()
	
end

function Drawable:affectedByPath(path)
	return self.paths[path] ~= nil
end

function Drawable:delete()

	drawingLayer:removeProp(self.prop)
	
	--remove paths
	for path,pathprop in pairs(self.paths) do
		drawingLayer:removeProp(pathprop)
		path:decrementDrawableCount()
		self.paths[path] = nil
	end
end

----------------- PRIVATE

function Drawable:swapPathOrders(path1, path2)
	
	--TODO: this might be a good place to optimize if we end up swapping often

	if self.paths[path1] or self.paths[path2] then
		self:redoPathHierarchy()
	end
end


--brute-force the props representing the paths into the correct hierarchy based on the 
function Drawable:redoPathHierarchy()

	-- build a sorted list of paths
	local sortedPaths = {}
	for path,prop in pairs(self.paths) do
		table.insert(sortedPaths, {path, prop})
	end
	table.sort(sortedPaths, function (a,b) return a[1].index < b[1].index end )

	-- go through them and fix up their props by setting them to inherit from the next one
	for i=1,#sortedPaths do
		local prop1 = sortedPaths[i][2]
		prop1:clearAttrLink(MOAIProp2D.INHERIT_TRANSFORM)
		if i < #sortedPaths then
			local prop2 = sortedPaths[i+1][2]		
			prop1:setAttrLink(MOAIProp2D.INHERIT_TRANSFORM, prop2, MOAIProp2D.TRANSFORM_TRAIT)
		end
	end
	
	--finally, set our drawable prop to inherit from the first on the list
	self.prop:clearAttrLink(MOAIProp2D.INHERIT_TRANSFORM)
	if #sortedPaths > 0 then
		self.prop:setAttrLink(MOAIProp2D.INHERIT_TRANSFORM, sortedPaths[1][2], MOAIProp2D.TRANSFORM_TRAIT)
	end
end

function Drawable:correctedPointsAtCurrentTime()
	return self.prop:correctedPointsAtCurrentTime()
end

function Drawable:visibleAtCurrentTime()
	return self.prop.visible
end


function Drawable:refreshPathProps()
	local visible = true
	for path,prop in pairs(self.paths) do
		local s,r,t,v = path:cached()
		visible = visible and v
		prop:setScl(s,s)
		prop:setRot(r)
		prop:setLoc(t.x, t.y)
	end
	self.prop.visible = visible
	self.prop:setVisible(visible)
end


------------ TEST HELPERS ---------------
--  return success,message

function Drawable:verifyPathHierarchyConsistency()

	-- we want to make sure that the order of indexes of the paths corresponds to 
	-- the order of our MOAI hierarchy by checking the attrLinks manually
	-- This is to make sure that basemodel's path reordering operations are correct
	-- If this *ever* returns false, it is the result of a bug 
	
	-- make an ordered list of paths by sorting
	local sortedPaths = {}
	for path,prop in pairs(self.paths) do
		table.insert(sortedPaths, {path, prop})
	end
	table.sort(sortedPaths, function (a,b) return a[1].index < b[1].index end )
	
	-- verify the hierarchy
	for i=1,#sortedPaths do
		local parent = sortedPaths[i][2]:getAttrLink(MOAIProp2D.INHERIT_TRANSFORM)
		if i < #sortedPaths then

			if parent ~= sortedPaths[i+1][2] then
				return false, "Hierarchy is inconsistent! Path with index "..sortedPaths[i][1].index.." should have parent: "..sortedPaths[i+1][1].index
			end
		else
			if parent ~= nil then
				return false, "Hierarchy management is inconsistent! Top-level parent should be nil"
			end
		end
	end

	return true, "Drawable Path Hierarchy appears to be consistent"
end

return basemodel.drawable
