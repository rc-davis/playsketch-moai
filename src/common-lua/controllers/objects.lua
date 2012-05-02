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

	controllers/objects.lua
	
	Maintains the collection of drawn objects. 
	Any prop can be added here and it should get all of the right properties added to
	allow it to be manipulated here.
	
--]]

require "model/model"

controllers.objects = {}


-- storePropAsNewObject(o): Add a new object to the collection
function controllers.objects.storePropAsNewObject(o)
	controllers.objects.storeProp(o, {})
	local x,y = o:getLoc()	
	o:setValueForTime(model.keys.TRANSLATION, controllers.timeline:currentTime(), {x=x,y=y})
	o:setValueForTime(model.keys.ROTATION, controllers.timeline:currentTime(), 0)
	o:setValueForTime(model.keys.SCALE, controllers.timeline:currentTime(), 1)	
	
end

function controllers.objects.storeProp(o, modeltable)

	o.thread = {}
	o.currentAnimation = {}
	drawingLayer:insertProp (o)
	model.addObject(o, modeltable)

	-- playBack(time):	this object will immediately start to perform its animations
	--					beginning at 'time'
	function o:playBack(start_time)
	
	
		-- playThread():start a coroutine that tracks changes in the 'KEY' list of the model
		--				immediateCallback is the code for setting the value immediately (setLoc)
		--				timedCallback is the code for moving to the new state (seekLoc)
		function playThread(KEY, immediateCallback, timedCallback)
			local current_time = start_time
			local loc = o:getInterpolatedValueForTime(KEY, current_time)
			local s = o:getFrameForTime(KEY, start_time)
			immediateCallback(o, loc)

			
			while s ~= nil and s.nextFrame ~= nil and s.nextFrame.value ~= nil do
			
				local timeDelta = s.nextFrame.time - current_time
				local loc_new = s.nextFrame.value
				o.currentAnimation[KEY] = timedCallback(o, loc_new, timeDelta)
				MOAIThread.blockOnAction(self.currentAnimation[KEY])
				current_time = s.nextFrame.time
				s = s.nextFrame
			end
		end
		
		-- start our animation threads for each kind of transition (SRT)
		self.thread[model.keys.TRANSLATION] = MOAIThread.new ()
		self.thread[model.keys.TRANSLATION]:run ( playThread, model.keys.TRANSLATION, 
							function (o,loc) o:setLoc(loc.x, loc.y) end,
							function (o,loc, timeDelta) return o:seekLoc(loc.x, loc.y, timeDelta, MOAIEaseType.LINEAR) end)
		self.thread[model.keys.ROTATION] = MOAIThread.new ()
		self.thread[model.keys.ROTATION]:run ( playThread, model.keys.ROTATION,
							function (o,rot) o:setRot(rot) end,
							function (o,rot, timeDelta) return o:seekRot(rot, timeDelta, MOAIEaseType.LINEAR) end)
		self.thread[model.keys.SCALE] = MOAIThread.new ()
		self.thread[model.keys.SCALE]:run ( playThread, model.keys.SCALE,
							function (o,scale) o:setScl(scale) end,
							function (o,scale, timeDelta) return o:seekScl(scale, scale, timeDelta, MOAIEaseType.LINEAR) end)

	end
	
	
	-- stopPlayback():	if the object is being animated, it will stop immediately
	function o:stopPlayback()
		for _,t in pairs(self.thread) do if t then t:stop() end end
		for _,a in pairs(self.currentAnimation) do if a then a:stop() end end		
	end
	
	-- getCorrectedPointsAtTime(t): Helper for selection lasso. 
	--								Returns the points corrected to the supplied time
	-- TODO: VERY TEMPORARY. This will need to get much much fancier!	
	function o:getCorrectedPointsAtTime(t)	

		local loc = o:getInterpolatedValueForTime(model.keys.TRANSLATION, t)
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
	function o:getSpan()
		local span = {width={max=-1e100, min=1e100}, height={max=-1e100, min=1e100}}
		for j=1,#self.points,2 do
			span.width.min  = math.min(span.width.min, self.points[j])
			span.width.max  = math.max(span.width.max, self.points[j])
			span.height.min = math.min(span.height.min, self.points[j+1])
			span.height.max = math.max(span.height.max, self.points[j+1])
		end
		return span
	end
	
end


-- deleteAll(): Removes all objects from the model
function controllers.objects.deleteAll()
	for _,o in pairs(model.all_objects) do
		controllers.objects.delete(o)
	end
end


-- delete(o): Cleans up any associated properties and deletes an object from the model
function controllers.objects.delete(o)
	o:stopPlayback()
	drawingLayer:removeProp(o)
	model.deleteObject(o)
end


function controllers.objects.loadFromTable(objecttable)
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

return controllers.objects