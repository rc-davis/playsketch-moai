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

	self.timelists = {	scale=basemodel.timelist.new(),
						rotate=basemodel.timelist.new(),
						translate=basemodel.timelist.new()	}

	--self.span = {start=1e99,stop=-1e99}
	--self.dependentTransforms = {}	
	--self.activeThreads = {}
	--self.activeAnimations = {}
	--self.keyframes = {}

end

function Path:addKeyframedMotion(time, scaleValue, rotateValue, translateValue, keyframeBlendFrom, keyframeBlendTo)

	-- add data to stream
	
	if scaleValue then
		self.timelists['scale']:setValueForTime(time, scaleValue)
	end

	if rotateValue then
		self.timelists['rotate']:setValueForTime(time, rotateValue)
	end

	if translateValue then
		self.timelists['translate']:setValueForTime(time, translateValue)
	end
	
	-- add new keyframe
	--TODO
	
	--TODO: BLENDING
	
end


- path:shiftKeyframe(keyframe, timeDelta) -> success
- path:shiftKeyframes(startKeyframe, endKeyframe timeDelta) -> success
- path:keyframeBeforeTime(time) -> keyframe
- path:positionAtTime(time) -> position
--]]

return basemodel.path
