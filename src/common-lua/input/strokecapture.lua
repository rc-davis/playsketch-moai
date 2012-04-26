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

	input/strokecapture.lua

	Registers for mouse events with the input.manager.
	Depending on the input.strokecapture.mode state, either uses touches to build a 
	new object or a selection lasso.
	
	To pass them along to a consumer, it needs to support:
		- newStroke()
		- addPoint(x,y)
		- doneStroke()
--]]

input.strokecapture = {}
input.strokecapture.MODE_DRAW = 1
input.strokecapture.MODE_SELECT = 2
input.strokecapture.mode = input.strokecapture.MODE_DRAW
local activeStrokes = {}


--setMode(mode):	Select who the stroke should be passed along to
function input.strokecapture.setMode(mode)
	print(mode)
	if input.strokecapture.mode ~= mode then
		input.strokecapture.mode = mode 
	end
end


local function downCallback(id,x,y)
	if activeStrokes[id] == nil then
	
		if input.strokecapture.mode == input.strokecapture.MODE_DRAW then
			activeStrokes[id] = controllers.drawing.startStroke()
		elseif input.strokecapture.mode == input.strokecapture.MODE_SELECT then
			activeStrokes[id] = controllers.selection.startStroke()	
		end

		return true
	end
	return false
end
	
local function movedCallback(id,x,y)
	if activeStrokes[id] then
		activeStrokes[id]:addPoint(x,y)
		return true
	end
	return false
end
	
local function upCallback(id,x,y)
	if activeStrokes[id] ~= nil then
		local stroke = activeStrokes[id]
		activeStrokes[id] = nil	
		drawingLayer:removeProp (stroke)
		stroke:doneStroke()
	end
	return false
end
	

-- INIT!
input.manager.addDownCallback( input.manager.DRAWINGLAYER, downCallback)
input.manager.addMovedCallback( input.manager.DRAWINGLAYER, movedCallback)
input.manager.addUpCallback( input.manager.DRAWINGLAYER, upCallback)


return input.strokecapture