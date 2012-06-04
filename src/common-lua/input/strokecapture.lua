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
input.strokecapture.modes = {MODE_DRAW=1, MODE_SELECT=2, MODE_RECORD=3}
input.strokecapture.mode = input.strokecapture.modes.MODE_DRAW
local activeStrokes = {}
local selectionStroke = nil


function input.strokecapture.setMode(mode)
	input.strokecapture.mode = mode
end

local function downCallback(id,x,y)
	if activeStrokes[id] == nil then
	
		if input.strokecapture.mode == input.strokecapture.modes.MODE_DRAW then
			activeStrokes[id] = controllers.drawing.startStroke()
		elseif input.strokecapture.mode == input.strokecapture.modes.MODE_SELECT 
			and selectionStroke == nil then
			activeStrokes[id] = controllers.selection.startStroke()	
			selectionStroke = id
		elseif input.strokecapture.mode == input.strokecapture.modes.MODE_RECORD then
			-- change modes
			widgets.modifierButton:setState(widgets.modifierButton.states.SELECT_UP)
			controllers.selection.clearSelection()
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
		if id == selectionStroke then selectionStroke = nil end
	end
	return false
end

local function cancelledCallback()
	for i,_ in pairs(activeStrokes) do
		activeStrokes[i]:cancel()
		activeStrokes[i] = nil	
	end
	selectionStroke = nil
	return false
end	

-- INIT!
input.manager.addDownCallback( input.manager.DRAWINGLAYER, downCallback)
input.manager.addMovedCallback( input.manager.DRAWINGLAYER, movedCallback)
input.manager.addUpCallback( input.manager.DRAWINGLAYER, upCallback)
input.manager.addCancelledCallback( input.manager.DRAWINGLAYER, cancelledCallback)

return input.strokecapture