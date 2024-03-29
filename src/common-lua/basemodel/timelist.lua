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
	self.firstFrame = { time=basemodel.timelist.NEGINFINITY, value=defaultValue, nextFrame=nil, previousFrame=nil, metadata={} }
	self.listSize = 0
	return self
end

function TimeList:size()
	return self.listSize
end


-- getFrameForTime(time):	Returns the node with the time <= 'time'
function TimeList:getFrameForTime(time)
	local frame = self.firstFrame
	while 	frame ~= nil and
			frame.nextFrame ~= nil 
			and frame.nextFrame.time <= time do
		frame = frame.nextFrame	
	end
	return frame
end


-- makeFrameForTime(time, defaultValue):	Creates and returns a new frame at the right place in the linked list
--											DefaultValue is set as the value if the frame is newly created
function TimeList:makeFrameForTime(time, defaultValue, precedingFrame)

	if not precedingFrame then 
		precedingFrame = self:getFrameForTime(time)
	end
	
	assert(precedingFrame ~= nil, "shouldn't be making a frame without a preceding frame")

	if precedingFrame.time == time then
		return precedingFrame
	else
		assert(precedingFrame.time < time and 
				(not precedingFrame.nextFrame or precedingFrame.nextFrame.time > time), 
				"inserted frames must maintain a strict ordering!")
		local newFrame = {	time=time, nextFrame = precedingFrame.nextFrame, previousFrame=precedingFrame, metadata={} }
		if precedingFrame.nextFrame then precedingFrame.nextFrame.previousFrame = newFrame end
		precedingFrame.nextFrame = newFrame
		self.listSize = self.listSize + 1
		newFrame.value = defaultValue
		return newFrame
	end
end

function TimeList:deleteFrame(frame)

	assert(frame.time ~= basemodel.timelist.NEGINFINITY, "Shouldn't delete root frame")
	--todo: verify membership in this list?
	frame.previousFrame.nextFrame = frame.nextFrame
	if frame.nextFrame then 
		frame.nextFrame.previousFrame = frame.previousFrame
	end
	self.listSize = self.listSize - 1
end



-- setValueForTime(time, value): Sets 'value' at 'time', replacing a pre-existing value at the EXACT same time
-- precedingFrame is an optional hint
function TimeList:setValueForTime(time, value, precedingFrame)
	local frame = self:makeFrameForTime(time, nil, precedingFrame)
	assert(frame ~= nil, "must retrieve a non-nil frame when making a new frame")
	frame.value = util.clone(value)
	return frame
end

-- setFromList(list): 	Sets 'value' from an ORDERED list of the format: {time=t, value=v}
--						Does not overwrite the current contents
function TimeList:setFromList(list)

	--TODO: This could definitely be optimized to make recording faster if necessary
	
	for i,o in ipairs(list) do
		local frame = self:makeFrameForTime(o.time, nil)
		frame.value = o.value
	end
end

-- getValueForTime(time): returns the value from the frame immediately <= 'time'
function TimeList:getValueForTime(time)
	local frame = self:getFrameForTime(time)
	assert(frame ~= nil, "must retrieve a non-nil frame for any given time")
	if frame.value == nil then return frame.nextFrame.value
	else return frame.value end
end


-- getInterpolatedValueForTime(time): interpolates the value between the frames around 'time' 
function TimeList:getInterpolatedValueForTime(time)
	local frame_before = self:getFrameForTime(time)
	assert(frame_before ~= nil, "must retrieve a non-nil frame for any given time")
	local frame_after = frame_before.nextFrame
	
	if frame_after == nil or frame_after.value == nil then 
		return frame_before.value 
	elseif frame_before.value == nil then 
		return frame_after.value 
	else
		local pcnt = (time-frame_before.time)/(frame_after.time - frame_before.time)
		local interp = nil
		
		--interpolate tables and single numbers
		if type(frame_before.value) == "number" then
			interp = frame_before.value*(1-pcnt) + frame_after.value*(pcnt)
		elseif type(frame_before.value) == "table" then
			interp = {}
			for k,v in pairs(frame_before.value) do
				if frame_after.value and type(v) == "number" then
					interp[k] = v*(1-pcnt) + frame_after.value[k]*(pcnt)
				else
					interp[k] = v
				end
			end
		end
		return interp
	end
end

--conditional: is a function that takes a value and returns if it should be deleted
function TimeList:erase(startTime, endTime, conditional)
	if conditional == nil then
		conditional = function (val) return true end
	end

	local first = self:getFrameForTime(startTime)
	while first.nextFrame and first.nextFrame.time < endTime do
		if conditional(first.nextFrame.value) then
			first.nextFrame = first.nextFrame.nextFrame
			if first.nextFrame then first.nextFrame.previousFrame = first end
			self.listSize = self.listSize - 1
		else
			first = first.nextFrame
		end
	end
end

-- Get an iterator for the TimeList
-- use:	local it = list:begin()
--		while not it:done() do
--			print(it:time(), it:value())
--			it:next()
--		end
function TimeList:begin()
	
	local it = {}
	it.current = self.firstFrame.nextFrame
	
	function it:time()
		return it.current.time
	end

	function it:value()
		return it.current.value
	end

	function it:metadata()
		return it.current.metadata
	end


	function it:next()
		if it.current ~= nil then
			it.current = it.current.nextFrame
		end
	end
	
	function it:done()
		return it.current == nil
	end

	return it
end		

-- dump(): For debugging, dump the lists for o.
function TimeList:dump()
	print("====DUMP: ", o)
	local f = self.firstFrame
	local c = 1
	while f ~= nil do
		print("\t"..c..":\t")
		for j,w in pairs(f) do
			if j == 'nextFrame' or j == 'previousFrame' then
				--pass
			elseif type(w) ~= 'table' then
				print ("\t", j.."=", w)
			else
				print ("\t", j.." = ", "{")
				for k1,v1 in pairs(w) do
					print ( "\t\t\t",k1.." = "..tostring(v1))
				end
				print ("\t\t", "}")
			end
		end
		f = f.nextFrame
		c = c+1
	end
	print("====/DUMP")	
end


function TimeList:tableToSave()
	return {firstFrame=self.firstFrame}
end


function TimeList:loadFromTable(table)
	self.firstFrame=table.firstFrame
end


return basemodel.timelist
