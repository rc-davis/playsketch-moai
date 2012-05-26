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
	
	Encapsulates a path for transforming Drawables
	TODO: document 2-d linked list for keyframe-to-data-frame lookup

--]]


basemodel.path = {}

local Path = {}

-- Clone the Path prototype
function basemodel.path.newPath()
	p = {}
	for i, v in pairs(Path) do
		p[i]=v
	end
	p:init()
	return p
end


--Path methods

function Path:init(prop)
	self.class = "Path"

	self.timelists = {	scale=basemodel.timelist.new(1),
						rotate=basemodel.timelist.new(0),
						translate=basemodel.timelist.new({x=0,y=0}),
						visibility=basemodel.timelist.new(false) }
						
	self.keyframes = basemodel.timelist.new(nil)

	--self.span = {start=1e99,stop=-1e99}
	--self.dependentTransforms = {}	
	--self.activeThreads = {}
	--self.activeAnimations = {}

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


end

function Path:setVisibility(time, visible)

	--create/retrieve keyframe
	local keyframe = self.keyframes:makeFrameForTime(time, {})

	--TODO: implement smarter logic & keyframes
	local frame = self.timelists.visibility:setValueForTime(time, visible)
	keyframe.value.visibility = frame


	--get current visibility at time
	
	--bail if it is already right

	--figure out if we are right on keyframe
	
		--and remove it
	
	--otherwise set it
	
		--and add a keyframe
	
		--and clean up next entry in stream
		--including its keyframe
		
	return keyframe
end



--[[
- path:addRecordedMotion(path, [scaleStream], [translateStream], [rotateStream]) -> keyframe (start)

- path:positionAtTime(time) -> position
- path:shiftKeyframe(keyframe, timeDelta) -> success
- path:shiftKeyframes(startKeyframe, endKeyframe timeDelta) -> success
--]]

return basemodel.path
