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

	basemodel/timelist.lua

	The most basic data structure for holding the animation steps for an object in time.
	It creates a list of nodes with values associated with a time.
	When looking up the value at a point in time, it returns the node immediately <= to the requested time

	-- TODO: REPLACE OUR streams LISTS with some btrees with iterator, for faster lookup

--]]


basemodel.timelist = {}

basemodel.timelist.NEGINFINITY = -1e99

local TimeList = {}

function basemodel.timelist.new(defaultValue)
	return util.clone(TimeList):init(defaultValue)
end

function basemodel.timelist.newFromTable(t)
	local l = basemodel.timelist.new()
	l:loadFromTable(t)
	return l
end


----- TimeList methods -----

function TimeList:init(defaultValue)
	self.class = "TimeList"
	self.firstFrame = basemodel.keyframe.new(basemodel.timelist.NEGINFINITY, defaultValue)
	self.listSize = 0
	self.defaultValue = defaultValue
	return self
end

function TimeList:size()
	return self.listSize
end


-- getFrameForTime(time):	Returns the node with the time <= 'time'
function TimeList:getFrameForTime(time)
	local toReturn = nil
	local it = self:begin()
	while not it:done() and it:current():time() <= time do
		toReturn = it:current()
		it:next()
	end
	return toReturn
end


-- makeFrameForTime(time):	Creates and returns a new frame at the right place in the linked list
--							its value is set to self.defaultValue
--							precedingFrame is optional and used as a hint
function TimeList:makeFrameForTime(time, precedingFrame)

	if not precedingFrame then 
		precedingFrame = self:getFrameForTime(time)
	end
	
	assert(precedingFrame ~= nil, "shouldn't be making a frame without a preceding frame")

	if precedingFrame:time() == time then
		return precedingFrame
	else
		assert(precedingFrame:time() < time and 
				(not precedingFrame:next() or precedingFrame:next():time() > time), 
				"inserted frames must maintain a strict ordering!")
		local newFrame = basemodel.keyframe.new(time, self.defaultValue, precedingFrame, precedingFrame:next())
		if precedingFrame:next() then precedingFrame:next():setPrevious(newFrame) end
		precedingFrame:setNext(newFrame)
		self.listSize = self.listSize + 1
		controllers.undo.addAction(	"Increment List Size",
								function() self.listSize = self.listSize - 1 end,
								function() self.listSize = self.listSize + 1 end )

		return newFrame
	end
end

function TimeList:deleteFrame(frame)

	assert(frame ~= self.firstFrame, "Shouldn't delete root frame")

	frame:previous():setNext(frame:next())
	if frame:next() then 
		frame:next():setPrevious(frame:previous())
	end
	--TODO: We are assuming that frame actually belongs to self!
	self.listSize = self.listSize - 1
	controllers.undo.addAction(	"Decrement List Size",
							function() self.listSize = self.listSize + 1 end,
							function() self.listSize = self.listSize - 1 end )

	
end

-- setValueForTime(time, value): Sets 'value' at 'time', replacing a pre-existing value at the EXACT same time
-- precedingFrame is an optional hint
function TimeList:setValueForTime(time, value, precedingFrame)
	local frame = self:makeFrameForTime(time, precedingFrame)
	assert(frame ~= nil, "must retrieve a non-nil frame when making a new frame")
	frame:setValue(value)
	return frame
end

-- getValueForTime(time): returns the value from the frame immediately <= 'time'
function TimeList:getValueForTime(time)
	local frame = self:getFrameForTime(time)
	assert(frame ~= nil, "must retrieve a non-nil frame for any given time")
	return frame:value()
end


-- getInterpolatedValueForTime(time): interpolates the value between the frames around 'time' 
function TimeList:getInterpolatedValueForTime(time)
	local frame_before = self:getFrameForTime(time)
	assert(frame_before ~= nil, "must retrieve a non-nil frame for any given time")
	local frame_after = frame_before:next()
	
	local valueBefore = frame_before:value()
	local timeBefore = frame_before:time()
	local valueAfter = frame_after and frame_after:value() or nil
	local timeAfter = frame_after and frame_after:time() or nil
	
	return util.interpolate(time, 
							valueBefore, timeBefore,
							valueAfter, timeAfter)
end

-- Get an iterator for the TimeList
-- use:	local it = list:begin()
--		while not it:done() do
--			local keyframe = it:current()
--			it:next()
--		end
function TimeList:begin()
	
	local it = {}
	it._current = self.firstFrame

	function it:current()
		return it._current
	end

	function it:next()
		if it._current ~= nil then
			it._current = it._current:next()
		end
	end
	
	function it:done()
		return it._current == nil
	end

	return it
end		

-- dump(): For debugging, dump the lists for o.
function TimeList:dump()
	print("====DUMP: ", o)
	local it = self:begin()
	while not it:done() do
		print("time:",it:current():time())
		print("\tvalue:")
		print_deep(it:current():value(), 2)
		print("\tmetadata:")
		print_deep(it:current():metadata(), 2)
		it:next()
	end
	print("====/DUMP")	
end


function TimeList:tableToSave()
	--TODO
end


function TimeList:loadFromTable(table)
	--TODO
end


return basemodel.timelist
