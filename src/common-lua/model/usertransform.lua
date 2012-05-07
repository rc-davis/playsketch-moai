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

	model/usertransform.lua

	This models a transform at a level that should correspond to a user's input or 
	intentions. It captures a span of time and a set of SRT actions (three timelists).
	
	It is applied to Drawable objects by creating Transforms in the draw hierarchy.
	Each object a user transform applies to gets its own dependent transform for simplicity.

--]]


model.usertransform = {}

local UserTransform = {}

function model.usertransform.new(drawables)
	local l = {}
	for i,v in pairs(UserTransform) do
		l[i] = v
	end
	l:init(drawables)
	return l
end

----- UserTransform methods -----
function UserTransform:init(drawables)

	self.span = {start=1e100,stop=-1e100}
	self.drawables = drawables
	
	self.scaleTimelist = model.timelist.new()
	self.rotateTimelist = model.timelist.new()
	self.translateTimelist = model.timelist.new()	

	--create a transform for each object
	self.dependentTransforms = {}
	for _,d in pairs(drawables) do
		self.dependentTransforms[d] = model.dependenttransform.new(d, self)		
	end
end


function UserTransform:setSpan(start, stop)
	self.span.start = start
	self.span.stop = stop
	
	--TODO: set to identity at "start" time and zero out everything before that!
	self.scaleTimelist:setValueForTime(start, 1)
	self.rotateTimelist:setValueForTime(start, 0)
	self.translateTimelist:setValueForTime(start, {x=0,y=0})		
	
end

function UserTransform:updateSelectionTranslate(time, dx, dy)
	local old_loc = self.translateTimelist:getInterpolatedValueForTime(time)
	local new_x, new_y = old_loc.x+dx, old_loc.y+dy
	self.translateTimelist:setValueForTime(time, {x=new_x, y=new_y})
	for _,dt in pairs(self.dependentTransforms) do
		dt:refresh(nil, nil, new_x, new_y)
	end
end

function UserTransform:updateSelectionRotate(time, dRot)
	local old_rot = self.rotateTimelist:getInterpolatedValueForTime(time)
	local new_rot = old_rot + dRot
	self.rotateTimelist:setValueForTime(time, new_rot)
	for _,dt in pairs(self.dependentTransforms) do
		dt:refresh(nil, new_rot, nil, nil)
	end
	self.rotateTimelist:dump()
end

function UserTransform:updateSelectionScale(time, dScale)
	local old_scl = self.scaleTimelist:getInterpolatedValueForTime(time)
	local new_scl = old_scl + dScale
	self.scaleTimelist:setValueForTime(time, new_scl)
	for _,dt in pairs(self.dependentTransforms) do
		dt:refresh(new_scl, nil, nil, nil)
	end
end

function UserTransform:displayAtFixedTime(time)
	local s = self.scaleTimelist:getInterpolatedValueForTime(time)
	local r = self.rotateTimelist:getInterpolatedValueForTime(time)
	local p = self.translateTimelist:getInterpolatedValueForTime(time)
	for _,dt in pairs(self.dependentTransforms) do
		dt:refresh(s, r, p.x, p.y)
	end
end


return model.usertransform
