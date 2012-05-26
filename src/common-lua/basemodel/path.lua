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

	--self.span = {start=1e99,stop=-1e99}
	--self.dependentTransforms = {}	
	--self.activeThreads = {}
	--self.activeAnimations = {}
	--self.keyframes = {}

end

function Path:stateAtTime(time)
	local scale = self.timelists.scale:getInterpolatedValueForTime(time)
	local rotate = self.timelists.rotate:getInterpolatedValueForTime(time)
	local translate = self.timelists.translate:getInterpolatedValueForTime(time)	
	local visibility = self.timelists.visibility:getValueForTime(time)	
	print(time, visibility)
	return scale, rotate, translate, visibility
end


function Path:addKeyframedMotion(time, scaleValue, rotateValue, translateValue, keyframeBlendFrom, keyframeBlendTo)

	-- add data to stream
	
	if scaleValue then
		self.timelists.scale:setValueForTime(time, scaleValue)
	end

	if rotateValue then
		self.timelists.rotate:setValueForTime(time, rotateValue)
	end

	if translateValue then
		self.timelists.translate:setValueForTime(time, translateValue)
	end
	
	-- add new keyframe
	--TODO
	
	--TODO: BLENDING
	
end

function Path:setVisibility(time, visible)

	--TODO: implement smarter logic & keyframes
	self.timelists.visibility:setValueForTime(time, visible)
	self.timelists.visibility:dump()


	--get current visibility at time
	
	--bail if it is already right

	--figure out if we are right on keyframe
	
		--and remove it
	
	--otherwise set it
	
		--and add a keyframe
	
		--and clean up next entry in stream
		--including its keyframe
		
	--todo: return keyframe
end

--[[
- path:addRecordedMotion(path, [scaleStream], [translateStream], [rotateStream]) -> keyframe (start)


- path:shiftKeyframe(keyframe, timeDelta) -> success
- path:shiftKeyframes(startKeyframe, endKeyframe timeDelta) -> success
- path:keyframeBeforeTime(time) -> keyframe
- path:positionAtTime(time) -> position
--]]

return basemodel.path
