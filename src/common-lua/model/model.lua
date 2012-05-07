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

	model/model.lua
	
	The interface point for ALL logic on creating/grouping objects and
	interacting with the model.

--]]


model = {}

require "model/datastructure"
require "model/usertransform"

local DrawableObject = {}


function model.deleteAll()
	for _,o in pairs(model.datastructure.all_objects) do
		model.delete(o)
	end
end

-- delete(o): Cleans up any associated properties and deletes an object from the model
function model.delete(o)
	o:stopPlayback()
	drawingLayer:removeProp(o)
	model.datastructure.deleteObject(o)
end

function model.newDrawableFromTable(objecttable)
	assert(objecttable.prop and objecttable.prop.proptype and objecttable.model,
		"To restore a prop, it needs a proptype, model, and prop tables")

	if objecttable.prop.proptype == "DRAWING" then
		local o = controllers.drawing.loadSavedProp(objecttable.prop)
		o:loadSavedModel(objecttable.model)
	else
		assert(false, "attempting to load unknown object type: "..objecttable.prop.proptype)
		--todo: load other proptypes here
	end
end

function model.newDrawableFromProp(p)
	--clone the DrawableObject methods
	for i, v in pairs(DrawableObject) do
		p[i]=v
	end
	p:init()
	
	model.datastructure.addObject(p, {})
	local x,y = p:getLoc()	
	p:setValueForTime(model.datastructure.keys.TRANSLATION, controllers.timeline:currentTime(), {x=x,y=y})
	p:setValueForTime(model.datastructure.keys.ROTATION, controllers.timeline:currentTime(), 0)
	p:setValueForTime(model.datastructure.keys.SCALE, controllers.timeline:currentTime(), 1)	
end


----- model passthroughs
function model.allDrawables()
	return model.datastructure.all_objects
end

function model.allToSave()
	return model.datastructure.all_objects
end


--selection responders

		
		--TODO: MOVE ALL OF THIS INTO THE OBJECT!!!
function model.updateSelectionTranslate(set, dx, dy)
	for i,o in ipairs(set) do
		local old_loc = o:getInterpolatedValueForTime(model.datastructure.keys.TRANSLATION, controllers.timeline:currentTime())
		o:setValueForTime(model.datastructure.keys.TRANSLATION, controllers.timeline:currentTime(), {x=old_loc.x+dx, y=old_loc.y+dy})
		o:setLoc(old_loc.x+dx, old_loc.y+dy)
	end
end

function model.updateSelectionRotate(set, dRot)
	for i,o in ipairs(set) do
		local old_rot = o:getInterpolatedValueForTime(model.datastructure.keys.ROTATION, controllers.timeline:currentTime())
		o:setValueForTime(model.datastructure.keys.ROTATION, controllers.timeline:currentTime(), old_rot + dRot)
		o:setRot(old_rot + dRot)
	end
end

function model.updateSelectionScale(set, dScale)
	for i,o in ipairs(set) do
		local old_scale = o:getInterpolatedValueForTime(model.datastructure.keys.SCALE, controllers.timeline:currentTime())
		o:setValueForTime(model.datastructure.keys.SCALE, controllers.timeline:currentTime(), old_scale + dScale)
		o:setScl(old_scale + dScale)
	end
end

---------------------------------------------
-- temporary helpers below here


function DrawableObject:init()

	self.thread = {}
	self.currentAnimation = {}
	drawingLayer:insertProp (self)

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
	

-- getCorrectedPointsAtTime(t): Helper for selection lasso. 
--								Returns the points corrected to the supplied time
-- TODO: VERY TEMPORARY. This will need to get much much fancier!	
function DrawableObject:getCorrectedPointsAtTime(t)	

	local loc = self:getInterpolatedValueForTime(model.datastructure.keys.TRANSLATION, t)
	local dx,dy = loc.x, loc.y
	new_points = {}
	for j=1,#self.points,2 do
		new_points[j] = self.points[j] + dx
		new_points[j+1] = self.points[j+1] + dy
	end
	
	--TODO: correct for rotation AND SCALE here too!	
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

return model
