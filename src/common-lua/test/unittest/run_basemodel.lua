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
		verify(k1 == nil and k2 == nil, "keyframeBeforeTime(): no keyframes before the new one")
		verify(k3 ~= nil and k3 == k4, "keyframeBeforeTime(): between keyframes returns 10")
		verify(k5 ~= k3 and k5 == k6, "keyframeBeforeTime(): future keyframes returns 20")		
	endSection()
		
	startSection("Test Setting Visibility")
		
		-- set 10 to visible
		local _,_,_,v = path1:stateAtTime(10)
		verify(v == false, "Not visible at time=10")
		path1:setVisibility(10, true)
		local _,_,_,v = path1:stateAtTime(10)
		verify(v == true, "Now should be visible at time=10")
		local _,_,_,v = path1:stateAtTime(1000)
		verify(v == true, "Should also be visible at time=1000")
		verify(path1:keyframeTimelist():size() == 1, "1 keyframe now")
		
		--set 15 to invisible
		path1:setVisibility(15, false)
		local _,_,_,v = path1:stateAtTime(14)
		verify(v == true, "Should still be visible at time=14")
		local _,_,_,v = path1:stateAtTime(15)
		verify(v == false, "Should NOT be visible at time=15")
		local _,_,_,v = path1:stateAtTime(1000)
		verify(v == false, "Should NOT be visible at time=1000")
		verify(path1:keyframeTimelist():size() == 2, "2 keyframes now")

		--set 14 to invisible, removing the keyframe at 15 implicitly
		path1:setVisibility(14, false) -- this should remove the keyframe at 15
		local _,_,_,v = path1:stateAtTime(13)
		verify(v == true, "Should still be visible at time=13")
		local _,_,_,v = path1:stateAtTime(14)
		verify(v == false, "Should NOT be visible at time=14")
		local _,_,_,v = path1:stateAtTime(15)
		verify(v == false, "Should NOT be visible at time=15")
		verify(path1:keyframeTimelist():size() == 2, "Should still have 2 keyframes")

		--set 10 to invisible, removing its keyframe implicitly
		path1:setVisibility(10, false) -- this should remove the keyframe at 10 AND 14
		local _,_,_,v = path1:stateAtTime(10)
		verify(v == false, "Should NOT be visible at time=10")
		local _,_,_,v = path1:stateAtTime(15)
		verify(v == false, "Should NOT be visible at time=15")
		local _,_,_,v = path1:stateAtTime(1000)
		verify(v == false, "Should NOT be visible at time=1000")
		verify(path1:keyframeTimelist():size() == 0, "Should have removed ALL keyframes")

	endSection()
	
	startSection("Test Recording a Path")	
	
		--insert a keyframe that should be deleted
		path1:addKeyframedMotion(19, nil, nil, {x=-300,y=-300}, nil, nil)

		local fakeRecordingDataT = {	{time=18, value={x=100, y = -100}},
										{time=19, value={x=100, y = 100}},
										{time=20, value={x=-100, y = 100}},
										{time=21, value={x=-100, y = -100}},
										{time=22, value={x=0, y = 0}}}
		path1:addRecordedMotion(nil, nil, fakeRecordingDataT)

		local s,r,t,v  = path1:stateAtTime(19)
		verify(t.x == 100 and t.y == 100, "19:take the recorded translation")
		verify(s == 1.9 and r == 81, "19:preserve the existing scale and rotation")
		verify(v == true, "19:recording should wipe out the invisible markers")

		local s,r,t,v  = path1:stateAtTime(20)
		verify(t.x == -100 and t.y == 100, "20:take the recorded translation")
		verify(s == 2.0 and r == 90, "20:preserve the existing scale and rotation")
		verify(v == true, "20:recording should wipe out the invisible markers")
		verify(path1:keyframeTimelist():size() == 5, "Should be five keyframes now (10, 15, 18, 20, 22)")


		local _,_,_,v  = path1:stateAtTime(23)
		verify(v == false, "we should remember that we are invisible after the recording is complete")
	
	endSection()


	startSection("Creating more Paths")

		local path2 = basemodel.createNewPath({drawable1})	-- path1, path2
		local path3 = basemodel.createNewPath({drawable1}, 1) -- path3, path1, path2
		local path4 = basemodel.createNewPath({drawable1}, 4) -- path3, path1, path2, path4
		local path5 = basemodel.createNewPath({drawable1}, 3) -- path3, path1, path5, path2, path4

		verify(path3.index == 1, "Path 3 should have index 1")
		verify(path1.index == 2, "Path 1 should have index 2")
		verify(path5.index == 3, "Path 5 should have index 3")
		verify(path2.index == 4, "Path 2 should have index 4")
		verify(path4.index == 5, "Path 4 should have index 5")
		verify(drawable1:verifyPathHierarchyConsistency())
				
		basemodel.swapPathOrder(2, 5) -- path3, path4, path5, path2, path1
		verify(path4.index == 2, "Path 4 should have index 2")
		verify(path1.index == 5, "Path 1 should have index 5")
		verify(drawable1:verifyPathHierarchyConsistency())
	
	endSection()


	startSection("Delete Drawables")

		basemodel.deleteDrawable(drawable1)
		verify(#basemodel.allPaths() == 0, "All paths should have been deleted")
		verify(#basemodel.allDrawables() == 0, "All Drawables should be gone")

		local drawable2 = basemodel.addNewDrawable(MOAIProp2D.new (), 10, {x=0,y=0})
		local drawable3 = basemodel.addNewDrawable(MOAIProp2D.new (), 11, {x=0,y=0})
		local drawable4 = basemodel.addNewDrawable(MOAIProp2D.new (), 12, {x=0,y=0})
		local path2 = basemodel.createNewPath({drawable3, drawable2})
		local path3 = basemodel.createNewPath({drawable3, drawable2})
		local path4 = basemodel.createNewPath({drawable4})

		verify(#basemodel.allDrawables() == 3, "Should have added 3 new drawables")
		verify(#basemodel.allPaths() == 6, "Should have six new paths")

		basemodel.deleteDrawable(drawable2)
		verify(#basemodel.allDrawables() == 2, "One drawable should go away")
		verify(#basemodel.allPaths() == 5, "Only drawable2's path should go away")

		basemodel.deleteDrawable(drawable3)
		verify(#basemodel.allDrawables() == 1, "One drawable should go away")
		verify(#basemodel.allPaths() == 2, "path2 and path3 should go away, along with drawable3's implicit paths")
		
		basemodel.deleteDrawable(drawable4)
		verify(#basemodel.allDrawables() == 0, "All drawables should be gone")
		verify(#basemodel.allPaths() == 0, "All Paths should be gone")		
		
		
	endSection()

endSection()


