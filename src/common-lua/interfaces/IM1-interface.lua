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
MOAIGfxDevice.setClearColor( 0.95, 0.95, 0.95 )


ui.drawing.init ( ui.rect.new(0, 128, 640, 896 ) )



--timeline sliders

playButton = ui.imagebutton.new(ui.rect.new(0, 0, 128, 128))
playButton:setImageForState(MOAITouchSensor.TOUCH_UP, "resources/IM1/play.png")
playButton:setImageForState(MOAITouchSensor.TOUCH_DOWN, "resources/IM1/play_down.png")
playButton:setCallback(MOAITouchSensor.TOUCH_UP, controllers.timeline.playPause )
ui.view.window:addSubview ( playButton )


slider = ui.slider.new(		ui.rect.new ( 128, 0, 640, 128 ), 
							0, 15, 
							"resources/IM1/slider.png",
							"resources/IM1/slider_button.png", 
							"resources/IM1/slider_button_down.png",
							64)
slider:setValueChangedCallback ( controllers.timeline.sliderMoved )
slider:setValueChangeFinishedCallback ( controllers.timeline.sliderMoveFinished )
ui.view.window:addSubview ( slider ) 
controllers.timeline.setSlider ( slider )

keyframes = ui.keyframes.new( ui.rect.new( 32, 16, 640 - (32*2), 128 - 16*2 ) )
slider:addSubview ( keyframes )






-- Create a list of the paths along the right side of the screen
local pathToButtonMap = {}
local pathList = ui.list.new ( ui.rect.new( 640, 128, 128, 512 ) )
ui.view.window:addSubview ( pathList )
pathList:setBackgroundColor( {0.7, 0.7, 0.7 } )
pathList:setBorderColor( {0, 0, 0 } )



-- add path button
local addPathButton = ui.button.new ( ui.rect.new( 640, 640, 128, 64 ) )
addPathButton:setText ( "new path" )
addPathButton:setCallback ( MOAITouchSensor.TOUCH_UP, 
	function ()
		local p = interactormodel.makeNewUserPath()
		if p then
			local newbutton = ui.button.new ( ui.rect.new(0, 0, 128, 64 ) )
			newbutton:setCallback ( MOAITouchSensor.TOUCH_UP, 
				function()
					controllers.interfacestate.setCurrentPath(p)
				end )
			newbutton:setText("Path " .. p.id)
			pathList:addItem(newbutton)
			pathToButtonMap[p] = newbutton
			controllers.interfacestate.setCurrentPath(p)
		end
	end )
ui.view.window:addSubview ( addPathButton )



-- delete path button
local deletePathButton = ui.button.new ( ui.rect.new( 640, 704, 128, 64 ) )
deletePathButton:setText ( "delete path" )
deletePathButton:setCallback ( MOAITouchSensor.TOUCH_UP, 
	function ()
		local button = pathToButtonMap[controllers.interfacestate.currentPath()]
		pathList:removeItem(button)
		interactormodel.deleteSelectedPath()
	end)
ui.view.window:addSubview ( deletePathButton )


-- undo button
local undoButton = ui.button.new ( ui.rect.new( 640, 960, 128, 64 ) )
undoButton:setText ( "Undo" )
undoButton:setCallback ( MOAITouchSensor.TOUCH_UP, controllers.undo.performUndo )
ui.view.window:addSubview ( undoButton )


-- redo button
local redoButton = ui.button.new ( ui.rect.new( 640, 896, 128, 64 ) )
redoButton:setText ( "Redo" )
redoButton:setCallback ( MOAITouchSensor.TOUCH_UP, controllers.undo.performRedo )
ui.view.window:addSubview ( redoButton )


-- clear button
local clearButton = ui.button.new ( ui.rect.new( 640, 832, 128, 64 ) )
clearButton:setText ( "Clear All" )
clearButton:setCallback ( MOAITouchSensor.TOUCH_UP, 
	function () 
		interactormodel.clearAll()
		pathList:clearAll()
		pathToButtonMap = {}
		controllers.interfacestate.setState(STATES.NEUTRAL)
	end )
ui.view.window:addSubview ( clearButton )


-- toggle visibility button
local visibilityButton = ui.button.new ( ui.rect.new( 640, 768, 128, 64 ) )
visibilityButton:setText ( "toggle visibility" )
visibilityButton:setCallback ( MOAITouchSensor.TOUCH_UP, interactormodel.toggleSelectedPathVisibility )
ui.view.window:addSubview ( visibilityButton )


--initialize modifier button to do both recording and selection
local modifier = ui.modifier.new(ui.rect.new(0, 832, 192, 192),
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
ui.view.window:addSubview( modifier )







---------- Implement the functions for refreshing the interface required by the other controllers

function refreshToNewState(newstate)
	print("REFRESHING")
	addPathButton:setEnabled(not controllers.selection.selectionIsEmpty())
	deletePathButton:setEnabled(controllers.interfacestate.currentPath() ~= nil)
	visibilityButton:setEnabled(controllers.interfacestate.currentPath() ~= nil)
	undoButton:setEnabled(controllers.undo.canPerformUndo())
	redoButton:setEnabled(controllers.undo.canPerformRedo())
	clearButton:setEnabled( not util.tableIsEmpty(basemodel.allPaths()) or not util.tableIsEmpty(basemodel.allDrawables()))

	if newstate == STATES.PATH_SELECTED then	
		modifier:setImages("resources/IM1/modifier_button_record.png",
						"resources/IM1/modifier_button_record_down.png")
	elseif newstate == STATES.NEUTRAL then
		modifier:setImages("resources/IM1/modifier_button_select.png",
						"resources/IM1/modifier_button_select_down.png")
	elseif newstate == STATES.DRAWABLES_SELECTED then
		modifier:forceUp()
	end

	controllers.playback.refresh()
end


function refreshCurrentPath(newPath)
	pathList:setSelected(pathToButtonMap[newPath])

end


function refreshAfterUndo()
	--brute-force redo the path list
	pathList:clearAll()
	pathToButtonMap = {}
	for _,path in pairs(interactormodel.getUserPaths()) do
		local newbutton = ui.button.new ( ui.rect.new(0, 0, 128, 64 ) )
		newbutton:setCallback ( MOAITouchSensor.TOUCH_UP, 
			function()
				controllers.interfacestate.setCurrentPath(path)
			end )
		newbutton:setText("Path " .. path.id)
		pathList:addItem(newbutton)
		pathToButtonMap[path] = newButton
	end
	
	controllers.interfacestate.setState(STATES.NEUTRAL)
end


function startedPlaying()

	playButton:setImageForState(MOAITouchSensor.TOUCH_UP, "resources/IM1/pause.png")
	playButton:setImageForState(MOAITouchSensor.TOUCH_DOWN, "resources/IM1/pause_down.png")

end


function stoppedPlaying()

	playButton:setImageForState(MOAITouchSensor.TOUCH_UP, "resources/IM1/play.png")
	playButton:setImageForState(MOAITouchSensor.TOUCH_DOWN, "resources/IM1/play_down.png")

end


-----------------
-- start in a neutral state
controllers.interfacestate.setState(STATES.NEUTRAL)

