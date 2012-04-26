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

	controllers.lua
	
	The controllers are responsible for receiving input and turning it into action.
	
	- timeline:		controls the state of what is shown temporally
	- objects:		adding objects and updating their state
	- selection:	turning user input into a selection lasso and manipulating the result
	- drawing: 		turning user input into an ink stroke and storing it as an object

--]]



controllers = {}

require "controllers/timeline"
require "controllers/objects"
require "controllers/selection"
require "controllers/drawing"

return controllers