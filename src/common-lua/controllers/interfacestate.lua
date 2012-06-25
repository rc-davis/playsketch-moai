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

	controllers/state.lua
	
	This file centralizes the current state of the application's interface.
	Any state decisions that need to be made outside of a specific file should come 
	through this file.
	
--]]



controllers.interfacestate = {}

STATES = {
	
	NEUTRAL					=	"NEUTRAL",
	DRAW_BUTTON_DOWN		=	"DRAW_BUTTON_DOWN",
	DRAWING					=	"DRAWING",
	SELECT_BUTTON_DOWN		=	"SELECT_BUTTON_DOWN",
	SELECTING				=	"SELECTING",
	DRAWABLES_SELECTED		=	"DRAWABLES_SELECTED",
	PATH_SELECTED			=	"PATH_SELECTED",
	RECORDING_BUTTON_DOWN	=	"RECORDING_BUTTON_DOWN",
	MANIPULATOR_IN_USE		=	"MANIPULATOR_IN_USE",
	RECORDING				=	"RECORDING"
}

local _state = STATES.NEUTRAL
local _currentPath = nil


function controllers.interfacestate.state()
	return _state
end

function controllers.interfacestate.setState(newstate)
	local oldstate = _state
	_state = newstate

	print(oldstate, "->", newstate)	
	
	if newstate == STATES.PATH_SELECTED then
		assert(_currentPath, "We should have a non-nil current path if we are in PATH_SELECTED")
		widgets.manipulator:attachToPath(_currentPath)
	elseif not controllers.interfacestate.isAManipulatorState() then
		widgets.manipulator:hide()
	end
	
	if newstate == STATES.NEUTRAL then
		controllers.selection.clearSelection()
		controllers.interfacestate.setCurrentPath(nil)
	end
		
	assert(refreshToNewState, "Your interface file should define refreshToNewState(newstate) to respond to state changes")
	refreshToNewState(newstate)
end

function controllers.interfacestate.currentPath()
	return _currentPath
end

function controllers.interfacestate.setCurrentPath(path)

	_currentPath = path	

	if path ~= nil then

		--Replace the current selection with the drawables in path
		controllers.selection.setSelectedDrawables(path:allDrawables())

		controllers.interfacestate.setState(STATES.PATH_SELECTED)
	end
	
	assert(refreshCurrentPath, "Your interface file should define refreshCurrentPath(newPath) to respond to state changes")
	refreshCurrentPath(path)

end

function controllers.interfacestate.isAManipulatorState()
	return	_state == STATES.PATH_SELECTED or
			_state == STATES.RECORDING_BUTTON_DOWN or
			_state == STATES.MANIPULATOR_IN_USE or
			_state == STATES.RECORDING
end




return controllers.interfacestate
