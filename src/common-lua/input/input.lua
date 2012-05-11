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

	input/input.lua

	All of the input-specific code:
	
	- manager: Register for mouse events here to abstract away touch vs mouse issues
	- strokecapture: grabs user strokes and hands them to drawing or selection code
	
--]]

input = {}

require "input/manager"
require "input/strokecapture"

input.hasTouch = MOAIInputMgr.device.touch

return input