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
function basemodel.path.newPath(index)
	p = {}
	for i, v in pairs(Path) do
		p[i]=v
	end
	p:init(index)
	return p
end


--Path methods
function Path:init(index)
	self.class = "Path"

	self.timelists = {	scale=basemodel.timelist.new(1),
						rotate=basemodel.timelist.new(0),
						translate=basemodel.timelist.new({x=0,y=0}),
						visibility=basemodel.timelist.new(false) }
						
	self.keyframes = basemodel.timelist.new(nil)

	self.index = index
	self.drawablecount = 0 -- To track how many drawables are part of this path

end

function Path:stateAtTime(time)
	local scale = self.timelists.scale:getInterpolatedValueForTime(time)
	local rotate = self.timelists.rotate:getInterpolatedValueForTime(time)
	local translate = self.timelists.translate:getInterpolatedValueForTime(time)	
	local visibility = self.timelists.visibility:getValueForTime(time)	
	return scale, rotate, translate, visibility
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
		self.timelists.translate:setValueForTime(time, translateValue)
		keyframe.value.translate = frame
	end
	
	
	--TODO: BLENDING
	assert(keyframeBlendFrom == nil and keyframeBlendTo == nil, "keyframe blending not yet implemented")

end

--scaleStream = {{time=??, scale=??}, ...}
function Path:addRecordedMotion(scaleStream, rotateStream, translateStream)

	assert(scaleStream or translateStream or rotateStream,
		"need at least one stream of data to be setting")

	local startTime = 1e99
	local endTime = -1e99

	--calculate startTime and end Time
	for _,stream in pairs{scaleStream, translateStream, rotateStream} do
		startTime = math.min(startTime, stream[1].time)
		endTime = math.max(endTime, stream[#stream].time)		
	end

	-- write the data into the streams, erasing what was there before
	if scaleStream then
		self.timelists.scale:erase(startTime, endTime)
		self.timelists.scale:setFromList(scaleStream)		
	end
	if rotateStream then
		self.timelists.rotate:erase(startTime, endTime)
		self.timelists.rotate:setFromList(rotateStream)		
	end
	if translateStream then
		self.timelists.translate:erase(startTime, endTime)
		self.timelists.translate:setFromList(translateStream)		
	end

	--eliminate keyframes that are only used for the properties we are overwriting
	self.keyframes:erase(startTime, endTime,
		function (v) 
			return	(v.scale == nil or scaleStream ~= nil) and
					(v.rotate == nil or rotateStream ~= nil) and
					(v.translate == nil and translateStream ~= nil) 
		end)

	--add new keyframes at startTime and endTime, pointing to the streams
	local keyframeStart = self.keyframes:makeFrameForTime(startTime, {})
	local keyframeEnd = self.keyframes:makeFrameForTime(endTime, {})
	if scaleStream then 
		keyframeStart.scale = self.timelists.scale:getFrameForTime(startTime)
		keyframeEnd.scale = self.timelists.scale:getFrameForTime(endTime)
	end
	if rotateStream then 
		keyframeStart.rotate = self.timelists.rotate:getFrameForTime(startTime)
		keyframeEnd.rotate = self.timelists.rotate:getFrameForTime(endTime)
	end
	if translateStream then 
		keyframeStart.translate = self.timelists.translate:getFrameForTime(startTime)
		keyframeEnd.translate = self.timelists.translate:getFrameForTime(endTime)
	end

	-- set the region as visible, and restore visibility at the end of the region
	local visibleBefore = self.timelists.visibility:getValueForTime(startTime)
	local visibleAfter = self.timelists.visibility:getValueForTime(endTime)	
	self.timelists.visibility:erase(startTime, endTime)
	if not visibleBefore then self.timelists.visibility:setValueForTime(startTime, true) end
	if not visibleAfter then self.timelists.visibility:setValueForTime(endTime, false) end

	return keyframeStart
end


function Path:setVisibility(time, visible)

	-- Add the new value to the list
	local frame = self.timelists.visibility:setValueForTime(time, visible)
	local keyframe = self.keyframes:makeFrameForTime(time, {})
	keyframe.value.visibility = frame
	
	-- Run through the list and remove redundancies
	local v = self.timelists.visibility.firstFrame.value
	local f = self.timelists.visibility.firstFrame.nextFrame
	while f ~= nil do
		if f.value == v then 	
		-- remove f if it isn't necessary
			local toRemove = f
			f = f.nextFrame
			self.timelists.visibility:deleteFrame(toRemove)

			--also remove the corresponding keyframe
			local oldKeyframe = self.keyframes:getFrameForTime(time)
			assert(oldKeyframe.time == time, "Every visibility timelist frame corresponds to a keyframe")
			assert(oldKeyframe.value.visibility == toRemove, "Should be removing the right keyframe")
			if oldKeyframe.scale == nil and oldKeyframe.rotate == nil and oldKeyframe.translate == nil then
				self.keyframes:deleteFrame(oldKeyframe)
			else
				oldKeyframe.visibility = nil
			end
		else
			f = f.nextFrame
		end
	end

	return keyframe
end


function Path:drawableCount()
	return self.drawablecount
end


function Path:incrementDrawableCount()
	self.drawablecount = self.drawablecount + 1
end


function Path:decrementDrawableCount()
	self.drawablecount = self.drawablecount - 1
	assert(self.drawablecount >= 0, "over-decrementing our drawables count!")
end


function Path:delete()
	self.timelists = nil
	self.keyframes = nil
	self.index = nil
	assert(self.drawablecount == 0, "Shouldn't be deleting a path that drawables are still using!")
end

--[[
TODO: 
- path:shiftKeyframe(keyframe, timeDelta) -> success
- path:shiftKeyframes(startKeyframe, endKeyframe timeDelta) -> success
--]]

return basemodel.path
