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

	model/model.lua

	The most basic data structure for holding the animation steps for an object in time.
	For any supplied key, it creates a list of nodes with values for that key, associated with a time.
	When looking up the value at a point in time, it returns the node immediately <= to the requested time

	-- TODO: REPLACE OUR streams LISTS with some btrees with iterator, for faster lookup

--]]


model = {}
model.all_objects = {}
model.keys = {LOCATION=1}


-- addObject(o): Adds all of the state and functions to o to track lists of time-information
function model.addObject(o)

	model.all_objects[o] = o

	-- add state
	o.streams = {}

	
	-- createStream(key):	initialize a new list with the specified key
	function o:createStream(key)
		self.streams[key] = { time=-1e100, value=nil, nextFrame={ time = 1e100, value=nil }}
	end


	-- getFrameForTime(key, time):	Returns the node with the time <= 'time'
	function o:getFrameForTime(key, time)

		assert(self.streams[key], "KEY "..key.." should be present in our time-streams")

		local frame = self.streams[key]
		
		while 	frame ~= nil and
				frame.nextFrame ~= nil 
				and frame.nextFrame.time <= time do
			frame = frame.nextFrame	
		end
	
		return frame
	end
	
	
	-- makeFrameForTime(key, time):	Creates and returns a new frame at the right place in the linked list
	function o:makeFrameForTime(key, time)
				
		if self.streams[key] == nil then
			self:createStream(key)
		end

		local previousFrame = self:getFrameForTime(key, time)
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
	
	
	-- setValueForTime(key, time, value): Sets 'value' for 'key' at 'time', replacing a pre-existing value at the EXACT same time
	function o:setValueForTime(key, time, value)	
		local frame = self:makeFrameForTime(key, time)
		assert(frame ~= nil, "must retrieve a non-nil frame for any given time")		
		frame.value = value
	end


	-- getValueForTime(key,time): returns the value from the frame immediately <= 'time'
	function o:getValueForTime(key, time)
		local frame = self:getFrameForTime(key, time)
		assert(frame ~= nil, "must retrieve a non-nil frame for any given time")
		return frame.value
	end
	
	
	-- getInterpolatedValueForTime(key,time): interpolates the value for 'key' between the frames around 'time' 
	function o:getInterpolatedValueForTime(key, time)
		local frame_before = self:getFrameForTime(key, time)
		assert(frame_before ~= nil, "must retrieve a non-nil frame for any given time")
		local frame_after = frame_before.nextFrame
		
		--TODO: test for type to interpolate (check if it is a table, then interpolate each value, otherwise, interpolate the values themselves
		if frame_after == nil or frame_after.value == nil then 
			return frame_before.value 
		elseif frame_before.value == nil then 
			return frame_after.value 
		else
			local pcnt = (time-frame_before.time)/(frame_after.time - frame_before.time)
			local interp = {}
			for k,v in pairs(frame_before.value) do
				if frame_after.value then
					interp[k] = v*(1-pcnt) + frame_after.value[k]*(pcnt)
				end
			end
			return interp
		end
	end
	
	
	-- dump(): For debugging, dump the lists for o.
	function o:dump()

		print("====DUMP: ", o)

		for k,v in pairs(self.streams) do 
			print("stream:{"..k.."}")
			local f = v
			local c = 1
			while f ~= nil do
				print("\t"..c..":\t")
				for j,w in pairs(f) do
					print ("\t", j, w)
				end
				f = f.nextFrame
				c = c+1
			end
		
		end
		print("====/DUMP")	
	end

	function o:modelToSave()
		return {streams=self.streams}
	end
	
	return o
end

return model
