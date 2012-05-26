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

	testbasemodel.lua
	
	tests the "basemodel" directory against:
	https://github.com/richardcd73/playsketch2/wiki/Base-Model-Spec
	
--]]

require "basemodel/basemodel"

startSection("Testing basemodel")

	verify(#basemodel.allPaths() == 0, "Start with empty path set")
	verify(#basemodel.allDrawables() == 0, "Start with empty drawables set")
	
	startSection("Add first drawable")
		local prop1 = MOAIProp2D.new ()
		local time1 = 10
		local location1 = {x=100, y=-23}
		local drawable1 = basemodel.addNewDrawable(prop1, time1, location1)
		verify(drawable1, "Drawable1 successfully created")
		verify(#basemodel.allPaths() == 1, "Path for drawable1 added to set")
		verify(#basemodel.allDrawables() == 1, "Drawable1 added to set")
		local _,_,_,visBefore = basemodel.allPaths()[1]:stateAtTime(9)
		local _,_,_,visAfter  = basemodel.allPaths()[1]:stateAtTime(10)
		verify(not visBefore, "Path isn't visible at the time before it was added at")
		verify(visAfter, "Path IS visible at the time which it was added at")		
	endSection()

endSection()