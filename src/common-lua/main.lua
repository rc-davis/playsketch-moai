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
SCALED_WIDTH = WIDTH
SCALED_HEIGHT = HEIGHT
if MOAIEnvironment.iosRetinaDisplay then
	SCALED_WIDTH = WIDTH/2
	SCALED_HEIGHT = HEIGHT/2
end

MOAISim.openWindow ( "playsketch2", WIDTH, HEIGHT )

-- set up viewport
viewport = MOAIViewport.new ()
viewport:setScale ( SCALED_WIDTH, SCALED_HEIGHT )
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
	userGfx:setRect ( -130, -100, 130, 130 )
	local userprop = MOAIProp2D.new ()
	userprop:setDeck ( userGfx )
	userprop:setLoc(0,0)
	userprop.isSelected = false
	userprop.points = {-130, -130, 130, -130, 130, 130, -130, 130 }
	model.addProp(userprop)
	
end


--TEMP: Build the UI buttons (this is temporary to test the functionality as we code it)


--Button for generating random lines
widgets.newSimpleButton(-SCALED_WIDTH/2+125,-SCALED_HEIGHT/2+75,50,50, 
						"resources/button_generate_lines.png", "resources/button_down.png",
						function(_) test.helpers.generateLines(50,50) end )

--Timeline buttons
local slider = widgets.newSlider(25, -SCALED_HEIGHT/2+25, SCALED_WIDTH-50, 50,
							"resources/slider_background.png",
							"resources/slider_button.png", 
							"resources/slider_button_down.png", 
							 controllers.timeline.sliderMoved )

local playButton = widgets.newToggleButton(-SCALED_WIDTH/2+25,-SCALED_HEIGHT/2+25, 50, 50, 
							{"resources/button_play.png", "resources/button_pause.png"},
							"resources/button_down.png", 
							controllers.timeline.playPause)
controllers.timeline.setButtons(slider, playButton)


--picking draw mode vs selection mode
widgets.newToggleButton(-SCALED_WIDTH/2+175,-SCALED_HEIGHT/2+75, 50, 50, 
						{"resources/button_draw.png", "resources/button_select.png"}, 
						"resources/button_down.png",
						input.strokecapture.changeMode)

widgets.newSimpleButton(-SCALED_WIDTH/2+225,-SCALED_HEIGHT/2+75,50,50, 
						"resources/button_save.png", "resources/button_down.png",
						controllers.disk.saveToDisk)

widgets.newSimpleButton(-SCALED_WIDTH/2+275,-SCALED_HEIGHT/2+75,50,50, 
						"resources/button_load.png", "resources/button_down.png",
						controllers.disk.loadFromDisk)



widgets.newSimpleButton(-SCALED_WIDTH/2+325,-SCALED_HEIGHT/2+75,50,50, 
						"resources/button_clear.png", "resources/button_down.png",
						model.deleteAll)

--Photo library buttons
if MOAIPhotoPickerIOS then
	local b1x,b1y = -SCALED_WIDTH/2+25,  -SCALED_HEIGHT/2+75
	local b2x,b2y = -SCALED_WIDTH/2+75, -SCALED_HEIGHT/2+75
	widgets.newSimpleButton(b1x,b1y,50,50, 
							"resources/button_photolibrary.png", "resources/button_down.png",
							function(_) 
								local wx,wy=drawingLayer:worldToWnd(b1x,b1y) 
								MOAIPhotoPickerIOS:showPhotoPicker(MOAIPhotoPickerIOS.PhotoPicker_LIBRARY, wx,wy, addImage)
							end)
	
	widgets.newSimpleButton(b2x,b2y,50,50, 
							"resources/button_photocamera.png", "resources/button_down.png",
							function(_) 
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

