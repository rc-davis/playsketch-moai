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

	main.lua

	The main entry point for the app.
	Creates the UI, wires up to controllers, and starts the run loop.

--]]


require "widgets/widgets"
require "controllers/controllers"
require "input/input"
require "test/test"

-- set up window
WIDTH = MOAIEnvironment.screenWidth or 800
HEIGHT = MOAIEnvironment.screenHeight or 650
MOAISim.openWindow ( "playsketch2", WIDTH, HEIGHT )

-- set up viewport
viewport = MOAIViewport.new ()
viewport:setScale ( WIDTH, HEIGHT )
viewport:setSize ( WIDTH, HEIGHT )

-- set up a layer to draw to
drawingLayer = MOAILayer2D.new ()
drawingLayer:setViewport ( viewport )
MOAISim.pushRenderPass ( drawingLayer )

widgets.init(viewport) -- this needs to go after our drawing layer is made

--TEMP: test function for adding an image
local function addImage(path)
	print ("requested to add image at ", path)
	local userGfx = MOAIGfxQuad2D.new ()
	userGfx:setTexture (path)
	userGfx:setRect ( -400, -400, 400, 400 )
	local userprop = MOAIProp2D.new ()
	userprop:setDeck ( userGfx )
	userprop:setLoc(0,0)
	userprop.isSelected = false
	userprop.points = {-400, -400, 400, -400, 400, 400, -400, 400 }
	objects.storePropAsNewObject(userprop)
	
end


--TEMP: Build the UI buttons (this is temporary to test the functionality as we code it)


--Button for generating random lines
widgets.newSimpleButton(-WIDTH/2+250,-HEIGHT/2+150,100,100, 
						"resources/button_generate_lines.png", "resources/button_down.png",
						function() test.helpers.generateLines(100,100) end )

--Timeline slider
local slider = widgets.newSlider(50, -HEIGHT/2+50, WIDTH-100, 100,
							"resources/slider_background.png",
							"resources/slider_button.png", 
							"resources/slider_button_down.png", 
							 controllers.timeline.sliderMoved )
controllers.timeline.setSlider(slider)

-- Timeline Play/Pause button					 
widgets.newSimpleButton(-WIDTH/2+50,-HEIGHT/2+50, 100, 100, 
							"resources/button_play.png", "resources/button_down.png", 
							controllers.timeline.playPause)

--picking draw mode vs selection mode
widgets.newToggleButton(-WIDTH/2+350,-HEIGHT/2+150, 100, 100, 
						{"resources/button_draw.png", "resources/button_select.png"}, 
						"resources/button_down.png",
						input.strokecapture.setMode)

--Photo library buttons
if MOAIPhotoPickerIOS then
	local b1x,b1y = -WIDTH/2+50,  -HEIGHT/2+150
	local b2x,b2y = -WIDTH/2+150, -HEIGHT/2+150
	widgets.newSimpleButton(b1x,b1y,100,100, 
							"resources/button_photolibrary.png", "resources/button_down.png",
							function() 
								local wx,wy=drawingLayer:worldToWnd(b1x,b1y) 
								MOAIPhotoPickerIOS:showPhotoPicker(MOAIPhotoPickerIOS.PhotoPicker_LIBRARY, wx,wy, addImage)
							end)
	
	widgets.newSimpleButton(b2x,b2y,100,100, 
							"resources/button_photocamera.png", "resources/button_down.png",
							function() 
								local wx,wy=drawingLayer:worldToWnd(b2x,b2y) 
								MOAIPhotoPickerIOS:showPhotoPicker(MOAIPhotoPickerIOS.PhotoPicker_CAMERA, wx,wy, addImage)
							end)
end


-------- MAIN LOOP
function main ()
	while true do		
		coroutine.yield ()
	end
end

thread = MOAIThread.new ()
thread:run ( main )

