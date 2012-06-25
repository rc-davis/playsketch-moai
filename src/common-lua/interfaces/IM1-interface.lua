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

	IM1-interface.lua

	The script for building the UI for IM1's interface, intended for debugging
	Access global variables set in main.lua

--]]

--MOAIDebugLines.showStyle(MOAIDebugLines.PROP_MODEL_BOUNDS, true)


-- background colour
MOAIGfxDevice.setClearColor( 0.796875 , 0.84765625, 0.890625 )



--timeline sliders
playButton = widgets.newToggleButton(-SCALED_WIDTH/2+64,-SCALED_HEIGHT/2+64, 128, 128, 
							{"resources/IM1/play.png", "resources/IM1/pause.png"},
							"resources/IM1/play_pause_down.png", 
							"resources/button_play_disabled.png",
							controllers.timeline.playPause)

widgets.slider:init(64, -SCALED_HEIGHT/2+64, SCALED_WIDTH-128, 128, 64,
							"resources/IM1/slider.png",
							"resources/IM1/slider_button.png", 
							"resources/IM1/slider_button_down.png", 
							 controllers.timeline.sliderMoved,
							 controllers.timeline.sliderMoveFinished)

controllers.timeline.setButtons(playButton)
--TODO:remove this




-- Create a list of the paths along the right side of the screen
g_pathList = widgets.textButtonList.new(320, -128, 128, 512, 64, controllers.interfacestate.setCurrentPath)
g_addPathButton = widgets.textButton.new(320, 224, 128, 64, "new path", 
	function ()
		local p = interactormodel.makeNewUserPath()
		local index = g_pathList:addItem("Path " .. p.id, p)
		g_pathList:setSelected(index)
	end)
g_deletePathButton = widgets.textButton.new(320, 160, 128, 64, "delete path", interactormodel.deleteSelectedPath)


-- undo redo buttons
g_undoButton = widgets.textButton.new(320, 480, 128, 64, "Undo", controllers.undo.performUndo)
g_redoButton = widgets.textButton.new(320, 416, 128, 64, "Redo", controllers.undo.performRedo)


-- clear button
g_clearButton = widgets.textButton.new(320, 352, 128, 64, "Clear All", 
	function () 
		interactormodel.clearAll()
		g_pathList:clearAll()
		controllers.interfacestate.setState(STATES.NEUTRAL)
	end)


-- visibility toggle button
g_visibilityButton = widgets.textButton.new(320, 288, 128, 64, "toggle visibility", interactormodel.toggleSelectedPathVisibility)


--keyframes visualization
widgets.keyframes:init(64, -SCALED_HEIGHT/2+64, SCALED_WIDTH-128-64, 64)


--initialize modifier button to do both recording and selection
g_modifier = widgets.modifierButton.new(-SCALED_WIDTH/2+192/2, 400, 192, 192, 
	function () 
		if not controllers.interfacestate.isAManipulatorState() then
			controllers.interfacestate.setState(STATES.SELECT_BUTTON_DOWN)
		else
			controllers.interfacestate.setState(STATES.RECORDING_BUTTON_DOWN)
		end
	end,
	function () 
		if not controllers.interfacestate.isAManipulatorState() then
			controllers.interfacestate.setState(STATES.NEUTRAL)
		else
			controllers.interfacestate.setState(STATES.PATH_SELECTED)
		end
	end )


---------- Implement the functions for refreshing the interface required by the other controllers

function refreshToNewState(newstate)

	g_addPathButton:setEnabled(not controllers.selection.selectionIsEmpty())
	g_deletePathButton:setEnabled(controllers.interfacestate.currentPath() ~= nil)
	g_visibilityButton:setEnabled(controllers.interfacestate.currentPath() ~= nil)
	g_undoButton:setEnabled(controllers.undo.canPerformUndo())
	g_redoButton:setEnabled(controllers.undo.canPerformRedo())
	g_clearButton:setEnabled( not util.tableIsEmpty(basemodel.allPaths()) or not util.tableIsEmpty(basemodel.allDrawables()))

	if newstate == STATES.PATH_SELECTED then	
		g_modifier:setImages("resources/IM1/modifier_button_record.png",
						"resources/IM1/modifier_button_record_down.png")
	elseif newstate == STATES.NEUTRAL then
		g_modifier:setImages("resources/IM1/modifier_button_select.png",
						"resources/IM1/modifier_button_select_down.png")
	elseif newstate == STATES.DRAWABLES_SELECTED then
		g_modifier:forceUp()
	end

	controllers.playback.refresh()
end


function refreshCurrentPath(newPath)
	g_pathList:setSelectedObject(newPath)
end


function refreshAfterUndo()
	--brute-force redo the path list
	g_pathList:clearAll()
	for _,path in pairs(interactormodel.getUserPaths()) do
		g_pathList:addItem("Path " .. path.id, path)
	end
	
	controllers.interfacestate.setState(STATES.NEUTRAL)
end


-----------------
-- start in a neutral state
controllers.interfacestate.setState(STATES.NEUTRAL)


