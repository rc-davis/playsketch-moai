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
	local scaledWidth = 768
	local scaledHeight = 1024

	MOAISim.openWindow ( "playsketch2", nativeWidth, nativeHeight )

	-- set up viewport
	ui.viewport = MOAIViewport.new ()
	ui.viewport:setScale ( scaledWidth, scaledHeight )
	ui.viewport:setSize ( nativeWidth, nativeHeight )

	-- Import all of the parts of this package once the layer has been created
	require "ui/view"
	
	-- Initialize our View Hierarchy
	
end

return ui
