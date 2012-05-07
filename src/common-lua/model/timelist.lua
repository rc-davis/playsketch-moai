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

	model/timelist.lua

	The most basic data structure for holding the animation steps for an object in time.
	It creates a list of nodes with values associated with a time.
	When looking up the value at a point in time, it returns the node immediately <= to the requested time

	-- TODO: REPLACE OUR streams LISTS with some btrees with iterator, for faster lookup

--]]


model.timelist = {}

local TimeList = {}

function model.newTimelist()
	local l = {}
	for i,v in pairs(TimeList) do
		l[i] = v
	end
	return l
end

function model.newTimelistFromTable(t)
	local l = model.newTimelist()
	l:loadFromTable(t)
	return l
end


----- TimeList methods -----

function TimeList:init()
	self.firstFrame = { time=-1e100, value=nil, nextFrame={ time = 1e100, value=nil }}
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


-- makeFrameForTime(time):	Creates and returns a new frame at the right place in the linked list
function TimeList:makeFrameForTime(time)

	local previousFrame = self:getFrameForTime(time)
	assert(previousFrame ~= nil, "shouldn't be making a frame without a previous frame")

	if previousFrame.time == time then
		return previousFrame
	else
		assert(previousFrame.time < time and previousFrame.nextFrame.time > time, 
			"we should be inserting a frame to maintain a strict ordering!")

		--make a new frame
		local newFrame = {	time=time,
							nextFrame = previousFrame.nextFrame }
		previousFrame.nextFrame = newFrame
		return newFrame
	end
end


-- setValueForTime(time, value): Sets 'value' at 'time', replacing a pre-existing value at the EXACT same time
function TimeList:setValueForTime(time, value)	
	local frame = self:makeFrameForTime(time)
	assert(frame ~= nil, "must retrieve a non-nil frame for any given time")		
	frame.value = value
end


-- getValueForTime(time): returns the value from the frame immediately <= 'time'
function TimeList:getValueForTime(time)
	local frame = self:getFrameForTime(time)
	assert(frame ~= nil, "must retrieve a non-nil frame for any given time")
	return frame.value
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
				if frame_after.value then
					interp[k] = v*(1-pcnt) + frame_after.value[k]*(pcnt)
				end
			end
		end
		return interp
	end
end


-- dump(): For debugging, dump the lists for o.
function TimeList:dump()
	print("====DUMP: ", o)
	local f = self.firstFrame
	local c = 1
	while f ~= nil do
		print("\t"..c..":\t")
		for j,w in pairs(f) do
			print ("\t", j, w)
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


return model.timelist
