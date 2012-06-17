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

function Keyframe:init(time, value, previous, next, metadata)

	if metadata == nil then metadata = {} end
	
	self.class = "Keyframe"
	self._time = time
	self._value = util.clone(value)
	self._metadata = metadata
	self._previousKeyframe = previous
	self._nextKeyframe = next

	return self
end

function Keyframe:delete()

	self._nextKeyframe = nil
	self._previousKeyframe = nil	
	self._metadata = nil
	self._value = nil
	self._time = nil
	self.class = nil
	
end


-- Accessors 

function Keyframe:time()
	return self._time
end

function Keyframe:value()
	return self._value
end

function Keyframe:setValue(v)

	local oldValue = self._value
	local newValue = util.clone(v)

	controllers.undo.addAction(	"Keyframe set value",
						function() self._value = oldValue end,
						function() self._value = newValue end )	

	self._value = newValue						
end



-- Set value one level deep (can we do without this?) TODO: remove both of these
function Keyframe:tableValue(key)
	return self._value[key]
end


function Keyframe:setTableValue(key, value)

	local oldValue = self._value[key]
	local newValue = util.clone(value)

	controllers.undo.addAction(	"Keyframe set Table Value",
						function() self._value[key] = oldValue end,
						function() self._value[key] = newValue end )	

	self._value[key] = newValue
end




function Keyframe:metadata(key)
	return self._metadata[key]
end

function Keyframe:setMetadata(key, value)
	assert(key ~= nil, "Need a key")

	local oldValue = self._metadata[key]
	local newValue = value
	self._metadata[key] = newValue
	
	controllers.undo.addAction(	"Keyframe set metadata",
						function() self._metadata[key] = oldValue end,
						function() self._metadata[key] = newValue end )		
end

function Keyframe:previous()
	return self._previousKeyframe
end

function Keyframe:setPrevious(keyframe)
	assert(keyframe == nil or keyframe._time <= self._time, "Times should always be ordered!")

	local oldValue = self._previousKeyframe
	local newValue = keyframe
	self._previousKeyframe = newValue
	
	controllers.undo.addAction(	"Keyframe set previous",
						function() self._previousKeyframe = oldValue end,
						function() self._previousKeyframe = newValue end )		
	
end

function Keyframe:next()
	return self._nextKeyframe
end

function Keyframe:setNext(keyframe)
	assert(keyframe == nil or self._time <= keyframe._time, "Times should always be ordered!")

	local oldValue = self._nextKeyframe
	local newValue = keyframe

	self._nextKeyframe = keyframe
	
	controllers.undo.addAction(	"Keyframe set next",
						function() self._nextKeyframe = oldValue end,
						function() self._nextKeyframe = newValue end )		
	
end


return basemodel.keyframe
