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
	drawingLayer:insertProp (prop)
end

function DrawableObject:delete()
	self:stopPlayback()
	drawingLayer:removeProp(self.prop)
end


function DrawableObject:playBack(start_time)
	-- start our animation threads for each kind of transition (SRT)
	self.thread[model.datastructure.keys.TRANSLATION] = MOAIThread.new ()
	self.thread[model.datastructure.keys.TRANSLATION]:run ( self.playThread, self, start_time, model.datastructure.keys.TRANSLATION, 
						function (o,loc) o:setLoc(loc.x, loc.y) end,
						function (o,loc, timeDelta) return o:seekLoc(loc.x, loc.y, timeDelta, MOAIEaseType.LINEAR) end)
	self.thread[model.datastructure.keys.ROTATION] = MOAIThread.new ()
	self.thread[model.datastructure.keys.ROTATION]:run ( self.playThread, self, start_time, model.datastructure.keys.ROTATION,
						function (o,rot) o:setRot(rot) end,
						function (o,rot, timeDelta) return o:seekRot(rot, timeDelta, MOAIEaseType.LINEAR) end)
	self.thread[model.datastructure.keys.SCALE] = MOAIThread.new ()
	self.thread[model.datastructure.keys.SCALE]:run ( self.playThread, self, start_time, model.datastructure.keys.SCALE,
						function (o,scale) o:setScl(scale) end,
						function (o,scale, timeDelta) return o:seekScl(scale, scale, timeDelta, MOAIEaseType.LINEAR) end)
end


-- playThread():start a coroutine that tracks changes in the 'KEY' list of the model
--				immediateCallback is the code for setting the value immediately (setLoc)
--				timedCallback is the code for moving to the new state (seekLoc)
function DrawableObject:playThread(start_time, KEY, immediateCallback, timedCallback)
	local current_time = start_time
	local loc = self:getInterpolatedValueForTime(KEY, current_time)
	local s = self:getFrameForTime(KEY, start_time)
	immediateCallback(self, loc)

	while s ~= nil and s.nextFrame ~= nil and s.nextFrame.value ~= nil do
	
		local timeDelta = s.nextFrame.time - current_time
		local loc_new = s.nextFrame.value
		self.currentAnimation[KEY] = timedCallback(self, loc_new, timeDelta)
		MOAIThread.blockOnAction(self.currentAnimation[KEY])
		current_time = s.nextFrame.time
		s = s.nextFrame
	end
end
	

-- stopPlayback():	if the object is being animated, it will stop immediately
function DrawableObject:stopPlayback()
	for _,t in pairs(self.thread) do if t then t:stop() end end
	for _,a in pairs(self.currentAnimation) do if a then a:stop() end end		
end
	

-- getCorrectedPointsAtCurrentTime(): Helper for selection lasso. 
function DrawableObject:getCorrectedPointsAtCurrentTime()
	new_points = {}
	for j=1,#self.prop.points,2 do
		new_points[j],new_points[j+1] = 
			self.prop:modelToWorld(self.prop.points[j],self.prop.points[j+1])
	end
	print_deep(new_points)
	return new_points
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


function DrawableObject:bringToTime(time)
	local p = self:getInterpolatedValueForTime(model.datastructure.keys.TRANSLATION, time)
	self:setLoc(p.x, p.y)
	local r = self:getInterpolatedValueForTime(model.datastructure.keys.ROTATION, time)
	self:setRot(r)
	local s = self:getInterpolatedValueForTime(model.datastructure.keys.SCALE, time)
	self:setScl(s)
end	


function DrawableObject:setSelected(sel)
	self.prop.isSelected = sel
end

function DrawableObject:selected()
	return self.prop.isSelected
end

return model.drawableobject