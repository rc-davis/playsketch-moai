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
function basemodel.path.newPath(index, defaultVisibility)
	return util.clone(Path):init(index, defaultVisibility)
end


--Path methods
function Path:init(index, defaultVisibility)

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

function Path:startRecordedMotion(time)

	controllers.undo.startGroup("Path Recorded Motion")

	-- create a recorded motion session token
	local recordedMotionSession = {}
	recordedMotionSession.path = self
	recordedMotionSession.start = {}
	recordedMotionSession.start.time = time
	recordedMotionSession.finish = {}
	
	
	recordedMotionSession.dataTypes = {}
	
	-- Get pointers to the nodes right before the start time (to advance as we record)
	recordedMotionSession.nodes = {}
	recordedMotionSession.nodes.scale = self.timelists.scale:getNodeForTime(time)
	recordedMotionSession.nodes.rotate = self.timelists.rotate:getNodeForTime(time)
	recordedMotionSession.nodes.translate = self.timelists.translate:getNodeForTime(time)
	recordedMotionSession.nodes.visibility = self.timelists.visibility:getNodeForTime(time)	

	--Get pointers to the keyframes to do the same with them
	recordedMotionSession.keyframenode = {}
	recordedMotionSession.keyframenode.scale = self.keyframes.scale:getNodeForTime(time)
	recordedMotionSession.keyframenode.rotate = self.keyframes.rotate:getNodeForTime(time)
	recordedMotionSession.keyframenode.translate = self.keyframes.translate:getNodeForTime(time)
	recordedMotionSession.keyframenode.visibility = self.keyframes.visibility:getNodeForTime(time)	

	
	--Make the path visible if necessary (and remember if this was necessary)
	if not self.timelists.visibility:getValueForTime(time) then
		recordedMotionSession.start.visibility = self:setVisibility(time, true)
	end
	
	
	--define the functions for working with the recordedMotionSession

	function recordedMotionSession:addMotion(time, scaleValue, rotateValue, translateValue)
	
		assert(scaleValue or rotateValue or translateValue, "need at least one kind of data to record")

		local function addMotionInternal(dataType, dataValue)
			self.dataTypes[dataType] = true

			-- erase data between our last pointer entry and the new time
			while self.nodes[dataType]:next() and self.nodes[dataType]:next():time() <= time do
				self.path.timelists[dataType]:deleteNode(self.nodes[dataType]:next())
			end
		
			--erase keyframes as move along
			while self.keyframenode[dataType]:next() and self.keyframenode[dataType]:next():time() <= time do
				self.path.keyframes[dataType]:deleteNode(self.keyframenode[dataType]:next())
			end
		
			-- Set our new data properly
			local newNode = self.path.timelists[dataType]:setValueForTime(time, util.clone(dataValue), self.nodes[dataType])
			newNode:setMetadata('recorded', true)
			self.nodes[dataType] = newNode
		
			if not self.start[dataType] then self.start[dataType] = newNode end
			self.finish[dataType] = newNode
		end
		
		if scaleValue then addMotionInternal('scale', scaleValue) end
		if rotateValue then addMotionInternal('rotate', rotateValue) end
		if translateValue then addMotionInternal('translate', translateValue) end

		--Kick our related Drawables to update their position to reflect this
		self.path:displayAtTime(time)
	end

	function recordedMotionSession:endSession(endTime)
		
		-- Add keyframes for anything we've touched
		for _,dataType in pairs({'scale', 'rotate', 'translate'}) do
			if self.dataTypes[dataType] then
				local keyframeStart = self.path.keyframes[dataType]:setValueForTime(self.start.time, self.start[dataType])
				keyframeStart:setMetadata('recordingStarts', true)
				self.start[dataType]:setMetadata('keyframeScale', keyframeStart)

				local keyframeFinish = self.path.keyframes[dataType]:setValueForTime(endTime, self.finish[dataType])
				self.finish[dataType]:setMetadata('keyframeScale', keyframeFinish)
				keyframeFinish:setMetadata('recordingFinishes', true)

				-- put a nice start/end on any pre-existing recorded spans we are overwriting
				if self.start[dataType]:previous() and self.start[dataType]:previous():metadata('recorded') then
					keyframeStart:setMetadata('recordingFinishes', true)
				end
				if self.finish[dataType]:next() and self.finish[dataType]:next():metadata('recorded') then
					keyframeFinish:setMetadata('recordingStarts', true)
				end
				
				--hacky way to keep the aniamtion working right
				self.start[dataType]:setMetadata('recorded', nil)
				self.finish[dataType]:setMetadata('recorded', nil)
			end
		end

		-- Make it invisible again if we had to force this visible
		if self.start.visibility then 
			self.path:setVisibility(endTime, false)
		end

		controllers.undo.endGroup("Path Recorded Motion")

	end

	return recordedMotionSession

end


function Path:setVisibility(time, visible)

	-- Add the new value to the list
	local frame = self.timelists.visibility:setValueForTime(time, visible)
	local keyframe = self.keyframes.visibility:setValueForTime(time, frame)
	frame:setMetadata('keyframeVisibility', keyframe)
	assert(frame:metadata('keyframeVisibility') == keyframe, "make sure we've set this right: frame to keyframe")
	assert(keyframe:value() == frame, "make sure we've set this right: keyfreame to frame")
	
	-- Run through the visibility list and remove redundancies
	local it = self.timelists.visibility:begin()	

	while not it:done() and it:current():next() do

		local currentVisible = it:current():value()
	
		local nextVisible = it:current():next():value()
		
		if nextVisible == currentVisible then -- next frame isn't needed!
		
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
			d:propForPath(self):setLoc(loc.x, loc.y)
		end
	else
		local animations = {}
		for _,d in pairs(self.drawables) do
			local a = d:propForPath(self):seekLoc(loc.x, loc.y, duration, MOAIEaseType.LINEAR)	
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
