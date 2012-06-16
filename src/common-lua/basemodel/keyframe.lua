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
	
	A linked-list node which is used by timelists to contain each element.
	Consists of:
		- forward and backward pointers
		- a time value
		- an arbitrary value (used for x,y or rotation, etc)
		- a metadata dictionary (used for tracking extra useful information)

--]]


basemodel.keyframe = {}

local Keyframe = {}

function basemodel.keyframe.new(time, value, previous, next)
	return util.clone(Keyframe):init(time, value, previous, next)
end



----- Keyframe methods -----

function Keyframe:init(time, value, previous, next)
	self.class = "Keyframe"
	self._time = time
	self._value = util.clone(value)
	self._metadata = {}
	self._previousKeyframe = previous
	self._nextKeyframe = next
	return self
end


-- Accessors 

function Keyframe:time()
	return self._time
end

function Keyframe:value()
	return self._value
end

function Keyframe:setValue(v)
	self._value = util.clone(v)
end

function Keyframe:metadata(key)
	return self._metadata[key]
end

function Keyframe:setMetadata(key, value)
	assert(key ~= nil, "Need a key")
	self._metadata[key] = value
end

function Keyframe:previous()
	return self._previousKeyframe
end

function Keyframe:setPrevious(keyframe)
	assert(keyframe == nil or keyframe._time <= self._time, "Times should always be ordered!")
	self._previousKeyframe = keyframe
end

function Keyframe:next()
	return self._nextKeyframe
end

function Keyframe:setNext(keyframe)
	assert(keyframe == nil or self._time <= keyframe._time, "Times should always be ordered!")
	self._nextKeyframe = keyframe
end


return basemodel.keyframe
