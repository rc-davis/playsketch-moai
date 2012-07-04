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

	ui/ui.lua
	
	Our widgets, the classes for maintaining their hierarchy, and managing their input events

--]]

ui = {}

function ui.init()

	-- set up a window
	local nativeWidth = MOAIEnvironment.screenWidth or 512
	local nativeHeight = MOAIEnvironment.screenHeight or 683 
	ui.scaledWidth = 768
	ui.scaledHeight = 1024

	print("Opening window: ", nativeWidth, nativeHeight)
	MOAISim.openWindow ( "playsketch2", nativeWidth, nativeHeight )

	-- set up viewport
	ui.viewport = MOAIViewport.new ()
	ui.viewport:setScale ( ui.scaledWidth, ui.scaledHeight )
	ui.viewport:setSize ( nativeWidth, nativeHeight )

	-- Import all of the parts of this package once the layer has been created
	require "ui/view"
	require "ui/label"
	require "ui/button"
	require "ui/list"
	
	-- Initialize our View Hierarchy
	ui.view.initViewSystem(ui.viewport, ui.scaledWidth, ui.scaledHeight)
	
end

return ui

