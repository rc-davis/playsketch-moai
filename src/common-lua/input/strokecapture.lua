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
	Depending on the interfacestate current state, either uses touches to build a 
	new object or a selection lasso.
	
	To pass them along to a consumer, it needs to support:
		- newStroke()
		- addPoint(x,y)
		- doneStroke()
--]]

input.strokecapture = {}
local activeStrokes = {}
local selectionStroke = nil

local function downCallback(id,x,y)
	if activeStrokes[id] == nil then

		local state = controllers.interfacestate.state()
		
		if	state == STATES.NEUTRAL or state == STATES.DRAWING then
		
			--start drawing
			activeStrokes[id] = controllers.stroke.new()
			controllers.interfacestate.setState(STATES.DRAWING)
			
		elseif state ==  STATES.SELECT_BUTTON_DOWN then
		
			--start SELECTING
			assert(selectionStroke == nil, "Should not be selecting if we begin a selection")
			activeStrokes[id] = controllers.selection.startStroke()	
			selectionStroke = id
			controllers.interfacestate.setState(STATES.SELECTING)
			
		elseif	state == STATES.SELECTING or
				state == STATES.RECORDING then
		
			--ignore since we are busy doing something else!
			
		elseif	state == STATES.DRAWABLES_SELECTED or 
				state == STATES.PATH_SELECTED or 
				state == STATES.RECORDING_BUTTON_DOWN or 
				state == STATES.MANIPULATOR_IN_USE then
				
			--clear out and go back to NEUTRAL
			controllers.interfacestate.setState(STATES.NEUTRAL)
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
		
		
		if id == selectionStroke then 
			selectionStroke = nil 
			if controllers.selection.selectionIsEmpty() then
				controllers.interfacestate.setState(STATES.SELECT_BUTTON_DOWN)
			else
				controllers.interfacestate.setState(STATES.DRAWABLES_SELECTED)
			end
		else
			if not util.tableIsEmpty(stroke.points) then 
				interactormodel.newDrawableCreated(	stroke )
			end
			controllers.interfacestate.setState(STATES.NEUTRAL)
		end
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