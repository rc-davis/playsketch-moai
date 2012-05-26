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

	basemodel/keyframe.lua
	
	Very simple class for representing keyframes
--]]


basemodel.keyframe = {}

local Keyframe = {}

-- Clone the Keyframe prototype
function basemodel.keyframe.new(previousFrame, nextFrame, motionType)
	k = {}
	for i, v in pairs(Keyframe) do
		k[i]=v
	end
	k:init(previousFrame, nextFrame, motionType)
	return k
end


--Keyframe methods
function Keyframe:init(previousFrame, nextFrame, motionType)
	self.class = "Keyframe"
	
	self.nextF = previousFrame
	self.previousF = nextFrame
	self.motionTypes = {}
	if motionType ~= nil then self.motionTypes[motionType] = true end
end

function Keyframe:nextFrame()
	return self.nextF
end

function Keyframe:previousFrame()
	return self.previousF
end

function Keyframe:isType(motionType)
	return self.motionTypes[motionType] ~= nil
end

function Keyframe:setType(motionType, isType)
	if isType then
		self.motionTypes[motionType] = true 
	else
		self.motionTypes[motionType] = nil
	end
end

return basemodel.keyframe
