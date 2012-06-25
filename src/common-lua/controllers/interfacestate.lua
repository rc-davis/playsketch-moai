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



controllers.state = {}


controllers.state.all = {
	
	NONE					=	1,
	DRAW_BUTTON_DOWN		=	2,
	DRAWING					=	3,
	SELECT_BUTTON_DOWN		=	4,
	SELECTING				=	5,
	DRAWABLES_SELECTED		=	6,
	PATH_SELECTED			=	7,
	RECORDING_BUTTON_DOWN	=	8,
	MANIPULATOR_IN_USE		=	9,
	RECORDING				=	10
	
	}
	
controllers.state.current = controllers.state.all.NONE

function controllers.state.refreshInterface()

	--go through widgets and set them!

end



function controllers.state.changeToState(newstate)

	--giant switch statement of changing states!


end


-- TODO: this is temp and should be covered in our new shared state controller
local function refreshInterface()
	g_undoButton:setEnabled(not util.tableIsEmpty(pastActionStack))
	g_redoButton:setEnabled(not util.tableIsEmpty(futureActionStack))
	controllers.playback.refresh()
end


return controllers.state
