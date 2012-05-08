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

	model/drawableobject.lua

	Modeling an object that is actually drawn to the screen 
	(i.e. the leaf of the scene graph)

--]]


model.drawableobject = {}
local DrawableObject = {}

function model.drawableobject.newFromProp(prop)
	d = {}
	--clone the DrawableObject methods
	for i, v in pairs(DrawableObject) do
		d[i]=v
	end
	d:init(prop)
	return d
end


----- drawableobject methods

function DrawableObject:init(prop)
	self.thread = {}
	self.currentAnimation = {}
	self.prop = prop
	self.isSelected = false
	self.transforms = {self}
	drawingLayer:insertProp (prop)
end

function DrawableObject:delete()
	drawingLayer:removeProp(self.prop)
end


	

-- getCorrectedPointsAtCurrentTime(): Helper for selection lasso. 
function DrawableObject:getCorrectedPointsAtCurrentTime()
	new_points = {}
	for j=1,#self.prop.points,2 do
		new_points[j],new_points[j+1] = 
			self.prop:modelToWorld(self.prop.points[j],self.prop.points[j+1])
	end
	return new_points
end

function DrawableObject:getCorrectedLocAtCurrentTime()
	return self.prop:modelToWorld(0,0)
end

	
-- getSpan():	Return a list of the max & min points in the x & y dimensions
--				Note these are not corrected to a timestep
function DrawableObject:getSpan()
	local span = {width={max=-1e100, min=1e100}, height={max=-1e100, min=1e100}}
	for j=1,#self.points,2 do
		span.width.min  = math.min(span.width.min, self.points[j])
		span.width.max  = math.max(span.width.max, self.points[j])
		span.height.min = math.min(span.height.min, self.points[j+1])
		span.height.max = math.max(span.height.max, self.points[j+1])
	end
	return span
end


function DrawableObject:setSelected(sel)
	self.prop.isSelected = sel
end

function DrawableObject:selected()
	return self.prop.isSelected
end

function DrawableObject:addTopLevelTransform(new_parent_transform)
	self.transforms[#self.transforms].prop:setAttrLink(MOAIProp2D.INHERIT_TRANSFORM, new_parent_transform.prop, MOAIProp2D.TRANSFORM_TRAIT )
	drawingLayer:insertProp (new_parent_transform.prop)
	table.insert(self.transforms, new_parent_transform)
end

function DrawableObject:lastActionTimeBefore(time)
	local most_recent = -1e100
	for i=2,#self.transforms do
		for _,timelist in pairs(self.transforms[i].usertransform.timelists) do
			most_recent = math.max(most_recent, timelist:getFrameForTime(time).time)
		end
	end
	return most_recent
end

return model.drawableobject