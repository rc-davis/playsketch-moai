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
	
	startSection("Add a drawable")
		local prop1 = MOAIProp2D.new ()
		local time1 = 10
		local location1 = {x=100, y=-20}
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
		verify(s == 1, "default scale should be 1 far in the future")
		verify(r == 0, "default should have no rotation far in the future")
		verify(t.x == 100 and t.y == -20, "default should be in default position far in the future")
		verify(path1:keyframeTimelist():size() == 1, "Should only be one keyframe at this point")
	endSection()
	
	startSection("Add a keyframe")
		path1:addKeyframedMotion(20, 2.0, 90, {x=50,y=20}, nil, nil)

		local s,r,t,v  = path1:stateAtTime(15)
		verify(s == 1.5 and r == 45 and t.x == 75 and t.y == 0 and v == true,
				"new values should be interpolated from 10")

		local s,r,t,v  = path1:stateAtTime(20)
		verify(s == 2.0 and r == 90 and t.x == 50 and t.y == 20 and v == true,
				"new values apply at 20")

		local s,r,t,v  = path1:stateAtTime(5000)
		verify(s == 2.0 and r == 90 and t.x == 50 and t.y == 20 and v == true,
			"new values apply far in the future")
		verify(path1:keyframeTimelist():size() == 2, "Should be two keyframes now")
	endSection()
		
	startSection("Test Keyframe operations")
		local k1 = path1:keyframeBeforeTime(-100)
		local k2 = path1:keyframeBeforeTime(9)
		local k3 = path1:keyframeBeforeTime(10)
		local k4 = path1:keyframeBeforeTime(19)
		local k5 = path1:keyframeBeforeTime(20)
		local k6 = path1:keyframeBeforeTime(5000)
		verify(k1 == nil and k2 ~= nil, "keyframeBeforeTime(): no keyframes before the new one")
		verify(k3 ~= nil and k3 == k4, "keyframeBeforeTime(): between keyframes returns 10")
		verify(k5 ~= k3 and k5 == k6, "keyframeBeforeTime(): future keyframes returns 20")		
	endSection()
		
	endSection()
