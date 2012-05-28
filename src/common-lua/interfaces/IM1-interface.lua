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
							"resources/IM1/down.png", 
							"resources/button_play_disabled.png",
							controllers.timeline.playPause)

slider = widgets.newSlider(64, -SCALED_HEIGHT/2+64, SCALED_WIDTH-128, 128, 64,
							"resources/IM1/slider.png",
							"resources/IM1/slider_button.png", 
							"resources/IM1/slider_button_down.png", 
							 controllers.timeline.sliderMoved,
							 controllers.timeline.sliderMoveFinished)

controllers.timeline.setButtons(slider, playButton)


