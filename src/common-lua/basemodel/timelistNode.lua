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

	basemodel/timelistNode.lua
	
	A linked-list node which is used by timelists to contain each element.
	Consists of:
		- forward and backward pointers
		- a time value
		- an arbitrary value (used for x,y or rotation, etc)
		- a metadata dictionary (used for tracking extra useful information)

--]]


basemodel.timelistNode = {}

local TimelistNode = {}

function basemodel.timelistNode.new(time, value, previous, next)
	return util.clone(TimelistNode):init(time, value, previous, next)
end



----- TimelistNode methods -----

function TimelistNode:init(time, value, previous, next, metadata)

	if metadata == nil then metadata = {} end
	
	self.class = "TimelistNode"
	self._time = time
	self._value = util.clone(value)
	self._metadata = metadata
	self._previousTimelistNode = previous
	self._nextTimelistNode = next

	return self
end

function TimelistNode:delete()

	self._nextTimelistNode = nil
	self._previousTimelistNode = nil	
	self._metadata = nil
	self._value = nil
	self._time = nil
	self.class = nil
	
end


-- Accessors 

function TimelistNode:time()
	return self._time
end

function TimelistNode:value()
	return self._value
end

function TimelistNode:setValue(v)

	local oldValue = self._value
	local newValue = util.clone(v)

	controllers.undo.addAction(	"TimelistNode set value",
						function() self._value = oldValue end,
						function() self._value = newValue end )	

	self._value = newValue						
end



-- Set value one level deep (can we do without this?) TODO: remove both of these
function TimelistNode:tableValue(key)
	return self._value[key]
end


function TimelistNode:setTableValue(key, value)

	local oldValue = self._value[key]
	local newValue = util.clone(value)

	controllers.undo.addAction(	"TimelistNode set Table Value",
						function() self._value[key] = oldValue end,
						function() self._value[key] = newValue end )	

	self._value[key] = newValue
end




function TimelistNode:metadata(key)
	return self._metadata[key]
end

function TimelistNode:setMetadata(key, value)
	assert(key ~= nil, "Need a key")

	local oldValue = self._metadata[key]
	local newValue = value
	self._metadata[key] = newValue
	
	controllers.undo.addAction(	"TimelistNode set metadata",
						function() self._metadata[key] = oldValue end,
						function() self._metadata[key] = newValue end )		
end

function TimelistNode:previous()
	return self._previousTimelistNode
end

function TimelistNode:setPrevious(timelistNode)
	assert(timelistNode == nil or timelistNode._time <= self._time, "Times should always be ordered!")

	local oldValue = self._previousTimelistNode
	local newValue = timelistNode
	self._previousTimelistNode = newValue
	
	controllers.undo.addAction(	"TimelistNode set previous",
						function() self._previousTimelistNode = oldValue end,
						function() self._previousTimelistNode = newValue end )		
	
end

function TimelistNode:next()
	return self._nextTimelistNode
end

function TimelistNode:setNext(timelistNode)
	assert(timelistNode == nil or self._time <= timelistNode._time, "Times should always be ordered!")

	local oldValue = self._nextTimelistNode
	local newValue = timelistNode

	self._nextTimelistNode = timelistNode
	
	controllers.undo.addAction(	"TimelistNode set next",
						function() self._nextTimelistNode = oldValue end,
						function() self._nextTimelistNode = newValue end )		
	
end


return basemodel.timelistNode
