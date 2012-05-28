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
	Loads the interface from a file in the interfaces/ directory.

--]]

require "widgets/widgets"
require "controllers/controllers"
require "input/input"
require "test/test"

-- set up a window
WIDTH = MOAIEnvironment.screenWidth or 512
HEIGHT = MOAIEnvironment.screenHeight or 683 
SCALED_WIDTH = 768
SCALED_HEIGHT = 1024

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
controllers.recording.initManipulator()


--LOAD AN INTERFACE HERE!
require "interfaces/old-test-interface" 


-------- MAIN LOOP
function main ()
	while true do		
		coroutine.yield ()
	end
end

thread = MOAIThread.new ()
thread:run ( main )

