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
-- stroke should be centred on 0,0
function basemodel.drawable.newFromStroke(stroke)
	return util.clone(Drawable):init(stroke)
end


--Drawable methods
function Drawable:init(stroke)
	self.class = "Drawable"
	self.stroke = stroke
	self.prop = stroke.prop
	self.prop.visible = true
	self.paths = {}
	drawingLayer:insertProp (self.prop)
	
	controllers.undo.addAction(	"Init Drawable",
								function() drawingLayer:removeProp (self.prop) end,
								function() drawingLayer:insertProp (self.prop) end )
	
	return self
end

function Drawable:addPath(path)

	--create a new proxy Prop for it
	self.paths[path] = MOAIProp2D.new ()
	drawingLayer:insertProp(self.paths[path])
	path.drawables[self] = self

	controllers.undo.addAction(	"Add Path to Drawable",
							function() self:removePath(path) end,
							function() self:addPath(path) end )
	
	-- brute-force redo our inheritance
	-- TODO: this might be a good place to optimize if adding new transforms is slow
	self:redoPathHierarchy()
	
end

function Drawable:removePath(path)

	--create a new proxy Prop for it
	path.drawables[self] = nil
	drawingLayer:removeProp(self.paths[path])
	self.paths[path] = nil	
	
	controllers.undo.addAction(	"Remove Path from Drawable",
							function() self:addPath(path) end,
							function() self:removePath(path) end )
	
	self:redoPathHierarchy()
end

function Drawable:affectedByPath(path)
	return self.paths[path] ~= nil
end

function Drawable:delete()

	drawingLayer:removeProp(self.prop)
	
	--remove paths
	for path,_ in pairs(self.paths) do
		self:removePath(path)
	end
	
	controllers.undo.addAction(	"Delete Drawable",
							function() self:init(self.stroke) end,
							function() self:delete() end )
	
end

----------------- PRIVATE

function Drawable:pathOrdersUpdated(pathlist)
	
	--TODO: this might be a good place to optimize if we end up calling this often
	if util.any(pathlist, function (_,o) return self.paths[o] ~= nil end) then
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
		prop1:clearAttrLink(MOAIProp2D.ATTR_VISIBLE)
		if i < #sortedPaths then
			local prop2 = sortedPaths[i+1][2]		
			prop1:setAttrLink(MOAIProp2D.INHERIT_TRANSFORM, prop2, MOAIProp2D.TRANSFORM_TRAIT)
			prop1:setAttrLink (MOAIProp2D.ATTR_VISIBLE, prop2, MOAIProp2D.ATTR_VISIBLE )
		end
	end
	
	--finally, set our drawable prop to inherit from the first on the list
	self.prop:clearAttrLink(MOAIProp2D.INHERIT_TRANSFORM)
	self.prop:clearAttrLink(MOAIProp2D.ATTR_VISIBLE)
	if #sortedPaths > 0 then
		self.prop:setAttrLink(MOAIProp2D.INHERIT_TRANSFORM, sortedPaths[1][2], MOAIProp2D.TRANSFORM_TRAIT)
		self.prop:setAttrLink(MOAIProp2D.ATTR_VISIBLE, sortedPaths[1][2], MOAIProp2D.ATTR_VISIBLE ) 
	end
end

function Drawable:correctedPointsAtCurrentTime()
	return self.stroke:correctedPointsAtCurrentTime()
end

function Drawable:correctedLocAtCurrentTime()
	return self.stroke:correctedLocAtCurrentTime()
end

function Drawable:visibleAtCurrentTime()
	--TODO: should be able to retrieve this from self.prop?
	local visible = true
	for path,_ in pairs(self.paths) do
		local _,_,_,v = path:cached()
		visible = v and visible
	end
	return visible
end


function Drawable:refreshPathProps(path)
	local pathProp = self.paths[path]
	local s,r,t,v = path:cached()
	pathProp:setScl(s,s)
	pathProp:setRot(r)
	pathProp:setLoc(t.x, t.y)
	pathProp:setVisible(v)
end


function Drawable:propForPath(path)
	return self.paths[path]
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
