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
	Keyframes should be abstracted more nicely, and we should be able to use keyframes to 
	speed up lookup along the timelists (like a skiplist) 

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
						
	self.keyframes = basemodel.timelist.new(nil)

	self.index = index
	self.drawables = {}
	self.cache = {}
	self:cacheAtTime(0)
	
	return self

end

function Path:stateAtTime(time)
	local scale = self.timelists.scale:getInterpolatedValueForTime(time)
	local rotate = self.timelists.rotate:getInterpolatedValueForTime(time)
	local translate = util.clone(self.timelists.translate:getInterpolatedValueForTime(time))
	local visibility = self.timelists.visibility:getValueForTime(time)	
	return scale, rotate, translate, visibility
end

function Path:cacheAtTime(time)
	self.cache.scale,self.cache.rotate,self.cache.translate,self.cache.visibility = 
	self:stateAtTime(time)
	for _,d in pairs(self.drawables) do
		d:refreshPathProps(self)
	end
end	

function Path:cached()
	return self.cache.scale,self.cache.rotate,self.cache.translate,self.cache.visibility
end	



function Path:keyframeTimelist()
	return self.keyframes
end

function Path:keyframeBeforeTime(time)
	local keyframe = self.keyframes:getFrameForTime(time)
	if not keyframe or keyframe.time == basemodel.timelist.NEGINFINITY then
		return nil
	else
		return keyframe
	end
end

function Path:addKeyframedMotion(time, scaleValue, rotateValue, translateValue, keyframeBlendFrom, keyframeBlendTo)

	assert(scaleValue or rotateValue or translateValue, "a keyframe needs at least one value")

	--create/retrieve keyframe
	local keyframe = self.keyframes:makeFrameForTime(time, {})

	-- add data to stream
	if scaleValue then
		local frame = self.timelists.scale:setValueForTime(time, scaleValue)
		keyframe.value.scale = frame
	end

	if rotateValue then
		local frame = self.timelists.rotate:setValueForTime(time, rotateValue)
		keyframe.value.rotate = frame
	end

	if translateValue then
		local frame = self.timelists.translate:setValueForTime(time, translateValue)
		keyframe.value.translate = frame
	end
	
	
	--TODO: BLENDING
	assert(keyframeBlendFrom == nil and keyframeBlendTo == nil, "keyframe blending not yet implemented")
	
	--Kick our related Drawables to update their position to reflect this
	self:cacheAtTime(time)
end

function Path:startRecordedMotion(time)

	-- create a recorded motion session token
	local recordedMotionSession = {}
	recordedMotionSession.path = self
	recordedMotionSession.start = {}
	recordedMotionSession.start.time = time
	recordedMotionSession.finish = {}
	
	
	recordedMotionSession.dataTypes = {}
	
	-- Get pointers to the frames right before the start time (to advance as we record)
	recordedMotionSession.frames = {}
	recordedMotionSession.frames.scale = self.timelists.scale:getFrameForTime(time)
	recordedMotionSession.frames.rotate = self.timelists.rotate:getFrameForTime(time)
	recordedMotionSession.frames.translate = self.timelists.translate:getFrameForTime(time)
	recordedMotionSession.frames.visibility = self.timelists.visibility:getFrameForTime(time)	
	
	--Make the path visible if necessary (and remember a keyframe if this was necessary)
	if not self.timelists.visibility:getValueForTime(time) then
		recordedMotionSession.start.visibility = self:setVisibility(time, true)
	end
	
	
	--define the functions for working with the recordedMotionSession

	function recordedMotionSession:addMotion(time, scaleValue, rotateValue, translateValue)
	
		assert(scaleValue or rotateValue or translateValue, "need at least one kind of data to record")

		local function addMotionInternal(dataType, dataValue)
			self.dataTypes[dataType] = true

			-- erase data between our last pointer entry and the new time
			while self.frames[dataType].nextFrame and self.frames[dataType].nextFrame.time <= time do
				self.path.timelists[dataType]:deleteFrame(self.frames[dataType].nextFrame)
			end
		
			-- Set our new data properly
			local newFrame = self.path.timelists[dataType]:setValueForTime(time, dataValue, self.frames[dataType])
			newFrame.metadata.recorded = true
			self.frames[dataType] = newFrame
		
			if not self.start[dataType] then self.start[dataType] = newFrame end
			self.finish[dataType] = newFrame
		end
		
		if scaleValue then addMotionInternal('scale', scaleValue) end
		if rotateValue then addMotionInternal('rotate', rotateValue) end
		if translateValue then addMotionInternal('translate', translateValue) end

		--Kick our related Drawables to update their position to reflect this
		self.path:cacheAtTime(time)
	end

	function recordedMotionSession:endSession(endTime)
	
		--erase old keyframes that are no longer necessary
		local keyframe = self.path.keyframes:getFrameForTime(self.start.time)
		while keyframe.nextFrame and keyframe.nextFrame.time <= endTime do

			--zero out elements of the keyframe we are writing to
			if self.dataTypes.scale then keyframe.nextFrame.value.scale = nil end
			if self.dataTypes.rotate then keyframe.nextFrame.value.rotate = nil end
			if self.dataTypes.translate then keyframe.nextFrame.value.translate = nil end

			if util.tableCount(keyframe.nextFrame.value) == 0 then
				self.path.keyframes:deleteFrame(keyframe.nextFrame)
			else
				keyframe = keyframe.nextFrame
			end
		end
	
	
		-- Add new keyframes at startTime and endTime
		local keyframeStart = self.path.keyframes:makeFrameForTime(self.start.time, {})
		local keyframeEnd = self.path.keyframes:makeFrameForTime(endTime, {})
		
		-- Set the correct types for the keyframes by pointing at their corresponding frames
		for _,dataType in pairs({'scale', 'rotate', 'translate'}) do
			if self.dataTypes[dataType] then
				keyframeStart.value[dataType] = self.start[dataType]
				keyframeEnd.value[dataType] = self.finish[dataType]
				self.start[dataType].metadata.recorded = nil
				self.finish[dataType].metadata.recorded = nil
			end
		end

		-- Set a visibility keyframe if we had to toggle visibility explicitly
		if self.start.visibility then
			keyframeStart.value.visibility = self.start.visibility
			keyframeEnd.value.visibility = self.path:setVisibility(endTime, true)
		end

	end

	return recordedMotionSession

end

--[[

	if scaleStream then 
		keyframeStart.value.scale = self.timelists.scale:getFrameForTime(startTime)
		keyframeEnd.value.scale = self.timelists.scale:getFrameForTime(endTime)
	end
	if rotateStream then 
		keyframeStart.value.rotate = self.timelists.rotate:getFrameForTime(startTime)
		keyframeEnd.value.rotate = self.timelists.rotate:getFrameForTime(endTime)
	end
	if translateStream then 
		keyframeStart.value.translate = self.timelists.translate:getFrameForTime(startTime)
		keyframeEnd.value.translate = self.timelists.translate:getFrameForTime(endTime)
	end

--]]

function Path:setVisibility(time, visible)
	-- Add the new value to the list
	local frame = self.timelists.visibility:setValueForTime(time, visible)
	local keyframe = self.keyframes:makeFrameForTime(time, {})
	keyframe.value.visibility = frame
	
	-- Run through the list and remove redundancies
	local framePrevious = self.timelists.visibility.firstFrame
	local frameCurrent = self.timelists.visibility.firstFrame.nextFrame
	while frameCurrent ~= nil do
		if frameCurrent.value == framePrevious.value then 	

			--first remove the corresponding keyframe
			local oldKeyframe = self.keyframes:getFrameForTime(frameCurrent.time)
			assert(oldKeyframe.time == frameCurrent.time, "Every visibility timelist frame corresponds to a keyframe")
			assert(oldKeyframe.value.visibility == frameCurrent, "Should be removing the right keyframe")
			if oldKeyframe.value.visibility ~= nil and util.tableCount(oldKeyframe) == 1 then
				self.keyframes:deleteFrame(oldKeyframe)
			else
				oldKeyframe.value.visibility = nil
			end
			
			-- then remove the actual visibility list:
			self.timelists.visibility:deleteFrame(frameCurrent)

			frameCurrent = framePrevious.nextFrame
		else
			framePrevious = frameCurrent
			frameCurrent = frameCurrent.nextFrame
		end
	end

	return keyframe
end


function Path:allDrawables()
	return self.drawables
end


function Path:delete()
	self.timelists = nil
	self.keyframes = nil
	self.index = nil
	assert(util.tableIsEmpty(self:allDrawables()), "Shouldn't be deleting a path that drawables are still using!")
end

--[[
TODO: 
- path:shiftKeyframe(keyframe, timeDelta) -> success
- path:shiftKeyframes(startKeyframe, endKeyframe timeDelta) -> success
--]]

return basemodel.path
