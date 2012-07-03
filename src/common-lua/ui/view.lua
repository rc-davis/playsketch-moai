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

	ui/view.lua

	The ui.view class is responsible for managing screen display and input handling.
	All ui widgets should inherit from this class.

	Before using it must be initialized with ui.view.init(), which will create the root window
	
	A new empty view can be created with:
	ui.view.new(frameRect)

	TODO:
		bounds/frame	
		input passing
	
--]]

ui.view = {}

local drawingLayer

function ui.view.init(viewport, width, height)

	-- set up a layer to draw to
	print("Creating drawing layer")
	drawingLayer = MOAILayer2D.new ()
	drawingLayer:setViewport ( viewport )
	MOAISim.pushRenderPass ( drawingLayer )
	
end
