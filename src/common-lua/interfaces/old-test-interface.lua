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

	old-test-interface.lua

	Temporary home for the pre-base-model interface
	This should be deleted soon.

--]]


--TEMP: Build the UI buttons (this is temporary to test the functionality as we code it)


--Button for generating random lines
widgets.newSimpleButton(-SCALED_WIDTH/2+125,-SCALED_HEIGHT/2+125,50,50, 
						"resources/button_generate_lines.png", "resources/button_down.png", nil, 
						function(_) test.helpers.generateLines(50,50) end, nil )

--Timeline buttons
local slider = widgets.slider.newSlider(25, -SCALED_HEIGHT/2+25, SCALED_WIDTH-50, 50,
							"resources/slider_background.png",
							"resources/slider_button.png", 
							"resources/slider_button_down.png", 
							 controllers.timeline.sliderMoved,
							 controllers.timeline.sliderMoveFinished)


local playButton = widgets.newToggleButton(-SCALED_WIDTH/2+25,-SCALED_HEIGHT/2+25, 50, 50, 
							{"resources/button_play.png", "resources/button_pause.png"},
							"resources/button_down.png", 
							"resources/button_play_disabled.png",
							controllers.timeline.playPause)
controllers.timeline.setButtons(slider, playButton)



g_keyframeWidget= widgets.keyframes.new(25, -SCALED_HEIGHT/2+75, SCALED_WIDTH-50-50, 50)
g_recButton = widgets.newSimpleButton(-SCALED_WIDTH/2+25, -SCALED_HEIGHT/2+75, 50, 50,
					 "resources/button_record.png",
					"resources/button_stop.png",
					"resources/button_record_disabled.png", 
					controllers.recording.recordingButtonUp, 
					controllers.recording.recordingButtonDown)
g_recButton:setEnabled(false)

--picking draw mode vs selection mode
widgets.newToggleButton(-SCALED_WIDTH/2+175,-SCALED_HEIGHT/2+125, 50, 50, 
						{"resources/button_draw.png", "resources/button_select.png"}, 
						"resources/button_down.png",
						nil,
						input.strokecapture.changeMode)

widgets.newSimpleButton(-SCALED_WIDTH/2+225,-SCALED_HEIGHT/2+125,50,50, 
						"resources/button_save.png", "resources/button_down.png", nil, 
						controllers.disk.saveToDisk, nil)

widgets.newSimpleButton(-SCALED_WIDTH/2+275,-SCALED_HEIGHT/2+125,50,50, 
						"resources/button_load.png", "resources/button_down.png", nil, 
						controllers.disk.loadFromDisk, nil)



widgets.newSimpleButton(-SCALED_WIDTH/2+325,-SCALED_HEIGHT/2+125,50,50, 
						"resources/button_clear.png", "resources/button_down.png", nil, 
						nil, nil)

--Photo library buttons
if MOAIPhotoPickerIOS then
	local b1x,b1y = -SCALED_WIDTH/2+25,  -SCALED_HEIGHT/2+125
	local b2x,b2y = -SCALED_WIDTH/2+75, -SCALED_HEIGHT/2+125
	widgets.newSimpleButton(b1x,b1y,50,50, 
							"resources/button_photolibrary.png", "resources/button_down.png", nil, 
							function(_) 
								local wx,wy=drawingLayer:worldToWnd(b1x,b1y) 
								MOAIPhotoPickerIOS:showPhotoPicker(MOAIPhotoPickerIOS.PhotoPicker_LIBRARY, wx,wy, addImage)
							end,
							nil)
	
	widgets.newSimpleButton(b2x,b2y,50,50, 
							"resources/button_photocamera.png", "resources/button_down.png", nil, 
							function(_) 
								local wx,wy=drawingLayer:worldToWnd(b2x,b2y) 
								MOAIPhotoPickerIOS:showPhotoPicker(MOAIPhotoPickerIOS.PhotoPicker_CAMERA, wx,wy, addImage)
							end, nil)
end
