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

	A start time is provided to constrain the span of the transform.
--]]


model.usertransform = {}

local UserTransform = {}

function model.usertransform.new(drawables, startTime)
	print("init: usertransform")
	local l = {}
	for i,v in pairs(UserTransform) do
		l[i] = v
	end
	l:init(drawables, startTime)
	return l
end

----- UserTransform methods -----
function UserTransform:init(drawables, startTime)

	self.class = "UserTransform"
	self.span = {start=startTime,stop=startTime}
	self.drawables = drawables
	
	self.timelists = {	scale=model.timelist.new(),
						rotate=model.timelist.new(),
						translate=model.timelist.new()	}
	self.activeThreads = {}
	self.activeAnimations = {}
	self.pivot = {x=0,y=0}
	self.isIdentity = true

	--create a transform for each object
	self.dependentTransforms = {}
	for _,d in pairs(drawables) do
		self.dependentTransforms[d] = model.dependenttransform.new(d, self)		
	end

	--insert an identity frame at the start to limit the scope of other transforms
	self.timelists['scale']:setValueForTime(startTime, 1)
	self.timelists['rotate']:setValueForTime(startTime, 0)
	self.timelists['translate']:setValueForTime(startTime, {x=0,y=0})		
end


function UserTransform:setPivot(pivX, pivY)

	self.pivot.x = pivX
	self.pivot.y = pivY
	for _,dt in pairs(self.dependentTransforms) do
		dt.prop:setPiv(pivX, pivY)
		dt.prop:setLoc(pivX, pivY)
	end
end

function UserTransform:getCorrectedLocAtCurrentTime()
	for _,dt in pairs(self.dependentTransforms) do
		return dt.prop:modelToWorld(self.pivot.x, self.pivot.y)
	end
end

function UserTransform:updateSelectionTranslate(time, dx, dy)
	local old_loc = self.timelists['translate']:getInterpolatedValueForTime(time)
	local new_x, new_y = old_loc.x+dx, old_loc.y+dy
	self.timelists['translate']:setValueForTime(time, {x=new_x, y=new_y})
	for _,dt in pairs(self.dependentTransforms) do
		dt:refresh(nil, nil, new_x + self.pivot.x, new_y + self.pivot.y)
	end
	self.span.stop = math.max(self.span.stop, time)
	self.isIdentity = false
end

function UserTransform:updateSelectionRotate(time, dRot)
	local old_rot = self.timelists['rotate']:getInterpolatedValueForTime(time)
	local new_rot = old_rot + dRot
	self.timelists['rotate']:setValueForTime(time, new_rot)
	for _,dt in pairs(self.dependentTransforms) do
		dt:refresh(nil, new_rot, nil, nil)
	end
	self.span.stop = math.max(self.span.stop, time)
	self.isIdentity = false
end

function UserTransform:updateSelectionScale(time, dScale)
	local old_scl = self.timelists['scale']:getInterpolatedValueForTime(time)
	local new_scl = old_scl + dScale
	self.timelists['scale']:setValueForTime(time, new_scl)
	for _,dt in pairs(self.dependentTransforms) do
		dt:refresh(new_scl, nil, nil, nil)
	end
	self.span.stop = math.max(self.span.stop, time)
	self.isIdentity = false
end


---- Functions for animating and playing back!

function UserTransform:displayAtFixedTime(time)
	local s = self.timelists['scale']:getInterpolatedValueForTime(time)
	local r = self.timelists['rotate']:getInterpolatedValueForTime(time)
	local p = self.timelists['translate']:getInterpolatedValueForTime(time)
	for _,dt in pairs(self.dependentTransforms) do
		dt:refresh(s, r, p.x + self.pivot.x, p.y + self.pivot.y)
	end
end


function UserTransform:playBack(start_time)

	self:displayAtFixedTime(start_time)

	-- start our animation threads for each kind of transition (SRT)
	for _,k in pairs({'scale', 'rotate', 'translate'}) do	
		self.activeThreads[k] = MOAIThread.new ()
		self.activeThreads[k]:run (self.playThread, self, start_time, k)
	end
end


-- playThread():start a coroutine that moves through the events in timelists[key] and
--				tells all the dependent transforms to animate toward that state
--				animations are all stored in activeAnimations so they can be cancelled
function UserTransform:playThread(start_time, key)
	local current_time = start_time
	local frame = self.timelists[key]:getFrameForTime(start_time)

	while frame ~= nil and frame.nextFrame ~= nil and frame.nextFrame.value ~= nil do
		local timeDelta = frame.nextFrame.time - current_time
		local newValue = frame.nextFrame.value

		--Tell all dependent transforms to seek their next state
		local nextAnimation = nil
		for _,dt in pairs(self.dependentTransforms) do
			if key == 'scale' then
				nextAnimation = dt.prop:seekScl(newValue, newValue, timeDelta, MOAIEaseType.LINEAR)
			elseif key == 'rotate' then
				nextAnimation = dt.prop:seekRot(newValue, timeDelta, MOAIEaseType.LINEAR)
			elseif key == 'translate' then
				nextAnimation = dt.prop:seekLoc(newValue.x + self.pivot.x,
												newValue.y + self.pivot.y,
												timeDelta, MOAIEaseType.LINEAR)
			end
			table.insert(self.activeAnimations, nextAnimation)
		end

		MOAIThread.blockOnAction(nextAnimation)
		current_time = frame.nextFrame.time
		frame = frame.nextFrame
	end

end
	

-- stopPlayback():	if the object is being animated, it will stop immediately
function UserTransform:stopPlayback()
	for _,t in pairs(self.activeThreads) do if t then t:stop() end end
	for _,a in pairs(self.activeAnimations) do if a then a:stop() end end		
	self.activeThreads = {}
	self.activeAnimations = {}
end


function UserTransform:delete()
	self:stopPlayback()
	for _,dt in pairs(self.dependentTransforms) do
		dt.drawable:removeTransform(dt)
	end
	self.dependentTransforms = {}
end


-- implementation-dependent short-cut for O(1) lookup of membership
function UserTransform:appliesTo(drawable)
	return (self.dependentTransforms[drawable] ~= nil)
end

return model.usertransform
