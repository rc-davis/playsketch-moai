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

	basemodel/path.lua
	
	A path represents the changes to the Scale, Rotation, Translation, and visibility of
	a set of drawables over time.

	TODO: Using linked-list timelists for: srtv AND keyframes.
	should be able to use keyframes to speed up lookup along the timelists (like a skiplist) 

--]]


basemodel.path = {}

local Path = {}

-- Clone the Path prototype
function basemodel.path.newPath(index, defaultVisibility, centerPoint)
	return util.clone(Path):init(index, defaultVisibility, centerPoint)
end


--Path methods
function Path:init(index, defaultVisibility, centerPoint)

	self.class = "Path"

	self.timelists = {	scale=basemodel.timelist.new(1),
						rotate=basemodel.timelist.new(0),
						translate=basemodel.timelist.new({x=0,y=0}),
						visibility=basemodel.timelist.new(defaultVisibility) }

	self.keyframes = {	scale=basemodel.timelist.new(nil),
						rotate=basemodel.timelist.new(nil),
						translate=basemodel.timelist.new(nil),
						visibility=basemodel.timelist.new(nil) }

	self.index = index
	self.drawables = {}
	self.cache = {}
	self:displayAtTime(0)
	
	self.centerPoint = centerPoint

	return self

end

function Path:delete()
	assert(util.tableIsEmpty(self:allDrawables()), "Shouldn't be deleting a path that drawables are still using!")
end


function Path:stateAtTime(time)
	local scale = self.timelists.scale:getInterpolatedValueForTime(time)
	local rotate = self.timelists.rotate:getInterpolatedValueForTime(time)
	local translate = util.clone(self.timelists.translate:getInterpolatedValueForTime(time))
	local visibility = self.timelists.visibility:getValueForTime(time)	
	return scale, rotate, translate, visibility
end

function Path:keyframeTimelist(motionType)
	return self.keyframes[motionType]
end

function Path:keyframeBeforeTime(time, motionType)
	local keyframe = self.keyframes[motionType]:getNodeForTime(time)
	if not keyframe or keyframe:time() == basemodel.timelist.NEGINFINITY then
		return nil
	else
		return keyframe
	end
end

function Path:addKeyframedMotion(time, scaleValue, rotateValue, translateValue, keyframeBlendFrom, keyframeBlendTo)

	controllers.undo.startGroup("Path: Add Keyframed Motion")

	assert(scaleValue or rotateValue or translateValue, "a keyframe needs at least one value")

	-- add data to stream
	if scaleValue then
		local frame = self.timelists.scale:setValueForTime(time, scaleValue)
		local keyframe = self.keyframes.scale:setValueForTime(time, frame)
		frame:setMetadata('keyframeScale', keyframe)
	end

	if rotateValue then
		local frame = self.timelists.rotate:setValueForTime(time, rotateValue)
		local keyframe = self.keyframes.rotate:setValueForTime(time, frame)
		frame:setMetadata('keyframeRotate', keyframe)
	end

	if translateValue then
		local frame = self.timelists.translate:setValueForTime(time, util.clone(translateValue))
		local keyframe = self.keyframes.translate:setValueForTime(time, frame)
		frame:setMetadata('keyframeTranslate', keyframe)
	end
	
	--TODO: BLENDING
	assert(keyframeBlendFrom == nil and keyframeBlendTo == nil, "keyframe blending not yet implemented")
	
	--Kick our related Drawables to update their position to reflect this
	self:displayAtTime(time)
	
	controllers.undo.endGroup("Path: Add Keyframed Motion")	
end

-- dataType = {'scale', 'rotate', 'translate'}
function Path:startRecordedMotion(time, dataType)

	assert(dataType == 'scale' or dataType == 'rotate' or dataType == 'translate', 
			"dataType needs to be scale, rotate, or translate")

	controllers.undo.startGroup("Path Recorded Motion")

	-- create a recorded motion session token
	local recordedMotionSession = {}
	recordedMotionSession.path = self
	recordedMotionSession.dataType = dataType
	recordedMotionSession.startTime = time

	-- Get a pointer to the node right before the start time (to advance as we record)
	recordedMotionSession.node = self.timelists[dataType]:getNodeForTime(time)

	-- Create start and end keyframes (slightly offset)
	recordedMotionSession.startKeyframe = self.keyframes[dataType]:setValueForTime(time, true)
	recordedMotionSession.startKeyframe:setMetadata('recordingStarts', true)
	recordedMotionSession.startKeyframe:setMetadata('recordingFinishes', 
										recordedMotionSession.node:previous() ~= nil and
										recordedMotionSession.node:previous():metadata('recorded'))

	recordedMotionSession.endKeyframe = self.keyframes[dataType]:setValueForTime(time + 1e-10, true)
	recordedMotionSession.endKeyframe:setMetadata('recordingFinishes', true)
	recordedMotionSession.endKeyframe:setMetadata('recordingStarts', 
										recordedMotionSession.node:next() ~= nil and
										recordedMotionSession.node:next():metadata('recorded'))
	assert(	recordedMotionSession.startKeyframe ~= recordedMotionSession.endKeyframe, "start and end keyframes should be distinct" )
	
	
	--do the same for visibility, since we have to keep this visible for the duration
	local visibleAtStart = self.timelists.visibility:getValueForTime(time)
	recordedMotionSession.startVisibilityNode = self.timelists['visibility']:setValueForTime(time, true)
	recordedMotionSession.endVisibilityNode = self.timelists['visibility']:setValueForTime(time + 1e-10, visibleAtStart)
	recordedMotionSession.startVisibilityKeyframe = self.keyframes['visibility']:setValueForTime(time, 
				recordedMotionSession.startVisibilityNode)
	recordedMotionSession.endVisibilityKeyframe = self.keyframes['visibility']:setValueForTime(time + 1e-10,
				recordedMotionSession.endVisibilityNode)
	recordedMotionSession.startVisibilityNode:setMetadata('keyframeVisibility', recordedMotionSession.startVisibilityKeyframe)
	recordedMotionSession.endVisibilityNode:setMetadata('keyframeVisibility', recordedMotionSession.endVisibilityKeyframe)
	
	--define the functions for working with the recordedMotionSession

	function recordedMotionSession:addMotion(time, value)
	
		-- erase data between our last pointer entry and the new time
		while self.node:next() and self.node:next():time() <= time do
			self.path.timelists[self.dataType]:deleteNode(self.node:next())
		end
	
		--erase keyframes as move along and update our endKeyframe
		while self.endKeyframe:next() and self.endKeyframe:next():time() <= time do
			self.path.keyframes[self.dataType]:deleteNode(self.endKeyframe:next())
		end
		self.endKeyframe:setTime(time)
		self.endKeyframe:setMetadata('recordingStarts', self.node:next() ~= nil and
														self.node:next():metadata('recorded'))
	
		-- Add in our new data
		if value then
			local newNode = self.path.timelists[self.dataType]:setValueForTime(time, util.clone(value), self.node)

			-- Label it as 'recorded' for all but the first node (TODO: fix hacky workaround)
			if self.firstNewNodeWritten then 
				newNode:setMetadata('recorded', true)
			else self.firstNewNodeWritten = true end
				
			self.node = newNode
		end

		--advance the visibility node
		local nextVisibility = self.endVisibilityNode:value()
		while self.endVisibilityNode:next() and self.endVisibilityNode:next():time() <= time do
			nextVisibility = self.endVisibilityNode:next():value()
			self.path.timelists['visibility']:deleteNode(self.endVisibilityNode:next())
		end
		self.endVisibilityNode:setTime(time)
		self.endVisibilityNode:setValue(nextVisibility)

		--advance the visibility keyframe
		while self.endVisibilityKeyframe:next() and self.endVisibilityKeyframe:next():time() <= time do
			self.path.keyframes['visibility']:deleteNode(self.endVisibilityKeyframe:next())
		end
		self.endVisibilityKeyframe:setTime(time)
				
		--Kick our related Drawables to update their position to reflect this
		self.path:displayAtTime(time)

	end

	function recordedMotionSession:endSession(endTime)
	
		-- Clean up any areas we didn't record over
		self:addMotion(endTime, nil)
	
		-- Get rid of our visisbility nodes if they weren't necessary
		if self.startVisibilityNode:previous() and self.startVisibilityNode:previous():value() == true then
			self.path.keyframes['visibility']:deleteNode(self.startVisibilityKeyframe)
			self.path.timelists['visibility']:deleteNode(self.startVisibilityNode)
		end
		
		if self.endVisibilityNode:value() == true then
			self.path.keyframes['visibility']:deleteNode(self.endVisibilityKeyframe)
			self.path.timelists['visibility']:deleteNode(self.endVisibilityNode)
		end

		controllers.undo.endGroup("Path Recorded Motion")

	end

	return recordedMotionSession

end


function Path:setVisibility(time, visible)

	-- Add the new value to the list
	local node = self.timelists.visibility:setValueForTime(time, visible)
	local keyframe = self.keyframes.visibility:setValueForTime(time, node)
	node:setMetadata('keyframeVisibility', keyframe)
	assert(node:metadata('keyframeVisibility') == keyframe, "make sure we've set this right: node to keyframe")
	assert(keyframe:value() == node, "make sure we've set this right: keyfreame to frame")
	
	-- Run through the visibility list and remove redundancies
	local it = self.timelists.visibility:begin()	

	while not it:done() and it:current():next() do

		local currentVisible = it:current():value()
	
		local nextVisible = it:current():next():value()
		
		if nextVisible == currentVisible then -- next node isn't needed!
		
			local nodeToDelete = it:current():next()
			local keyframeToDelete = nodeToDelete:metadata('keyframeVisibility')
			assert(keyframeToDelete:value() == nodeToDelete, "Keyframe must refer to this node")
			
			self.timelists.visibility:deleteNode(nodeToDelete)
			self.keyframes.visibility:deleteNode(keyframeToDelete)

		else 
			it:next()
		end
	end
	
	return keyframe
end


function Path:allDrawables()
	return self.drawables
end


-- FUNCTIONS FOR DISPLAYING AND ANIMATING THIS PATH!

function Path:currentState()
	return self.cache.scale,self.cache.rotate,self.cache.translate,self.cache.visibility
end	

function Path:displayAtTime(time)
	self.cache.scale,self.cache.rotate,self.cache.translate,self.cache.visibility = 
	self:stateAtTime(time)
	self:refreshDependentDrawables()
end	

function Path:setDisplayScale(scale, duration)
	if duration == 0 then
		for _,d in pairs(self.drawables) do
			d:propForPath(self):setScl(scale, scale)
		end
	else
		local animations = {}
		for _,d in pairs(self.drawables) do
			local a = d:propForPath(self):seekScl(scale, scale, duration, MOAIEaseType.LINEAR)
			table.insert(animations, a)
		end
		return animations
	end
end

function Path:setDisplayRotation(rot, duration)
	if duration == 0 then
		for _,d in pairs(self.drawables) do
			d:propForPath(self):setRot(rot)
		end
	else
		local animations = {}
		for _,d in pairs(self.drawables) do
			local a = d:propForPath(self):seekRot(rot, duration, MOAIEaseType.LINEAR)
			table.insert(animations, a)
		end
		return animations
	end
end

function Path:setDisplayTranslation(loc,duration)
	if duration == 0 then
		for _,d in pairs(self.drawables) do
			local centerPointOffset = d:centerPointOffsetForPath(self)
			d:propForPath(self):setLoc(loc.x + self.centerPoint.x, loc.y + self.centerPoint.y)
		end
	else
		local animations = {}
		for _,d in pairs(self.drawables) do
			local centerPointOffset = d:centerPointOffsetForPath(self)
			local a = d:propForPath(self):seekLoc(	loc.x + centerPointOffset.x,
									 				loc.y + centerPointOffset.y,
													 duration, MOAIEaseType.LINEAR)
			table.insert(animations, a)
		end
		return animations
	end
end

function Path:setDisplayVisibility(visible, duration)

	local desiredTime = controllers.timeline.currentTime() + duration
	while desiredTime > controllers.timeline.currentTime() do coroutine.yield() end
	self.cache.visibility = visible
	for _,d in pairs(self.drawables) do
		d:updateVisibility()
	end
end


function Path:refreshDependentDrawables()
	for _,d in pairs(self.drawables) do
		d:refreshDisplayOfPath(self, self.cache.scale,self.cache.rotate,self.cache.translate,self.cache.visibility)
	end
end



--[[
TODO: 
- path:shiftKeyframe(keyframe, timeDelta) -> success
- path:shiftKeyframes(startKeyframe, endKeyframe timeDelta) -> success
--]]

return basemodel.path
