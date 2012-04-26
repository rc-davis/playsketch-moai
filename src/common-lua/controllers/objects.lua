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

	drawingLayer:insertProp (o)
	model.addObject(o)
	local x,y = o:getLoc()

	o:setValueForTime(model.keys.LOCATION, controllers.timeline:currentTime(), {x=x,y=y})


	-- playBack(time):	this object will immediately start to perform its animations
	--					beginning at 'time'
	function o:playBack(start_time)
	
		function playThread()
			local current_time = start_time
			local loc = o:getInterpolatedValueForTime(model.keys.LOCATION, current_time)			
			local s = o:getFrameForTime(model.keys.LOCATION, start_time)
			o:setLoc(loc.x, loc.y)
			
			while s ~= nil and s.nextFrame ~= nil and s.nextFrame.value ~= nil do
			
				local timeDelta = s.nextFrame.time - current_time
				local loc_new = s.nextFrame.value
				self.currentAnimation = self:seekLoc(loc_new.x, loc_new.y, timeDelta, MOAIEaseType.LINEAR)
				MOAIThread.blockOnAction(self.currentAnimation)
				current_time = s.nextFrame.time
				s = s.nextFrame
			end
		end
		
		self.thread = MOAIThread.new ()
		self.thread:run ( playThread, self )
	
	end
	
	
	-- stopPlayback():	if the object is being animated, it will stop immediately
	function o:stopPlayback()

		if self.thread then
			self.thread:stop()
		end
		
		if self.currentAnimation then
			self.currentAnimation:stop()
		end
		
	end
	
	
	-- getCorrectedPointsAtTime(t): Helper for selection lasso. 
	--								Returns the points corrected to the supplied time
	-- TODO: VERY TEMPORARY. This will need to get much much fancier!	
	function o:getCorrectedPointsAtTime(t)	

		local loc = o:getInterpolatedValueForTime(model.keys.LOCATION, t)
		local dx,dy = loc.x, loc.y
		new_points = {}
		for j=1,#self.points,2 do
			new_points[j] = self.points[j] + dx
			new_points[j+1] = self.points[j+1] + dy
		end
		
		return new_points
	end
	
end



return controllers.objects