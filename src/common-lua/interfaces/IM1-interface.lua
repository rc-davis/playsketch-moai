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
g_pathList = widgets.textButtonList.new(320, -64, 128, 640, 64, interactormodel.setSelectedPath)
g_addPathButton = widgets.textButton.new(320, 288, 128, 64, "new path", interactormodel.makeNewUserPath)
g_addPathButton:setEnabled(false)


-- undo redo buttons
g_undoButton = widgets.textButton.new(320, 480, 128, 64, "Undo", controllers.undo.performUndo)
g_redoButton = widgets.textButton.new(320, 416, 128, 64, "Redo", controllers.undo.performRedo)
g_undoButton:setEnabled(false)
g_redoButton:setEnabled(false)

-- clear button
widgets.newSimpleButton(320, 352, 128, 64,
					'resources/IM1/button_clear.png',
					'resources/IM1/button_clear_down.png', nil,
					interactormodel.clearAll, nil)




widgets.keyframes:init(64, -SCALED_HEIGHT/2+64, SCALED_WIDTH-128-64, 64)



widgets.modifierButton.init(-SCALED_WIDTH/2+192/2, 400, 192, 192,
								"resources/IM1/modifier_button_select.png",
								"resources/IM1/modifier_button_select_down.png",
								"resources/IM1/modifier_button_record.png",
								"resources/IM1/modifier_button_record_down.png",
								function () input.strokecapture.setMode( input.strokecapture.modes.MODE_SELECT ) end,
								function () input.strokecapture.setMode( input.strokecapture.modes.MODE_DRAW ) end,
								nil,
								nil)



