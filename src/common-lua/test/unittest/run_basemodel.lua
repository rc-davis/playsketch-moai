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
		local path1 = basemodel.allPaths()[1]
		verify(drawable1, "Drawable1 successfully created")
		verify(#basemodel.allPaths() == 1, "Path for drawable1 added to set")
		verify(#basemodel.allDrawables() == 1, "Drawable1 added to set")
		local _,_,_,visBefore = path1:stateAtTime(9)
		local _,_,_,visAfter  = path1:stateAtTime(10)
		verify(not visBefore, "Path isn't visible at the time before it was added at")
		verify(visAfter, "Path IS visible at the time which it was added at")		
		local s,r,t,_  = path1:stateAtTime(5000)
		verify(s == 1, "default scale should be 1, to the end of time")
		verify(r == 0, "default should have no rotation, to the end of time")
		verify(t.x == 100 and t.y == -23, "default should be in default position, to the end of time")
		verify(path1:keyframeTimelist():size() == 1, "Should only be one keyframe at this point")
		
	endSection()

endSection()