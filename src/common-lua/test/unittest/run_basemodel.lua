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

	startSection("Adding a drawable")

		verify(#basemodel.allPaths() == 0, "Start with empty path set")
		verify(#basemodel.allDrawables() == 0, "Start with empty drawables set")
		local drawable1 = basemodel.addNewDrawable({ prop=MOAIProp2D.new () }, 10)
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
		verify(t.x == 0 and t.y == 0, "default should be in default position far in the future")
		verify(path1:keyframeTimelist('visibility'):size() == 1, "Should only be one keyframe at this point")
		basemodel.deleteDrawable(drawable1)
		drawable1 = nil
		path1 = nil
	endSection()
	
	startSection("Add a keyframed motion")
		verify(#basemodel.allPaths() == 0, "Start with empty path set")
		verify(#basemodel.allDrawables() == 0, "Start with empty drawables set")
		local drawable1 = basemodel.addNewDrawable({ prop=MOAIProp2D.new () }, 10)
		local path1 = basemodel.allPaths()[1] -- manually grab the first path
		verify(#basemodel.allPaths() == 1, "Has two paths now")
		path1:addKeyframedMotion(20, 2.0, 90, {x=50,y=20}, nil, nil) --keyframe at 20
		local s,r,t,v  = path1:stateAtTime(15)
		verify(s == 1.5 and r == 45 and t.x == 25 and t.y == 10 and v == true,
				"new values should be interpolated from 10")
		local s,r,t,v  = path1:stateAtTime(20)
		verify(s == 2.0 and r == 90 and t.x == 50 and t.y == 20 and v == true,
				"new values apply at 20")
		local s,r,t,v  = path1:stateAtTime(5000)
		verify(s == 2.0 and r == 90 and t.x == 50 and t.y == 20 and v == true,
			"new values apply far in the future")
		verify(path1:keyframeTimelist('visibility'):size() == 1, "Should still be one visibility keyframe now")
		verify(path1:keyframeTimelist('scale'):size() == 2, "Should be two scale keyframe now")
		verify(path1:keyframeTimelist('rotate'):size() == 2, "Should be two rotate keyframe now")
		verify(path1:keyframeTimelist('translate'):size() == 2, "Should be two translate keyframe now")
		--clean up
		basemodel.deleteDrawable(drawable1)
		drawable1 = nil
		path1 = nil
	endSection()
		
	startSection("Test Keyframe operations")
		verify(#basemodel.allPaths() == 0, "Start with empty path set")
		verify(#basemodel.allDrawables() == 0, "Start with empty drawables set")
		local drawable1 = basemodel.addNewDrawable({ prop=MOAIProp2D.new () }, 10)
		local path1 = basemodel:allPaths()[1]
		--add a second keyframe:
		path1:addKeyframedMotion(20, 2.0, 90, {x=50,y=20}, nil, nil)
		 --keyframes at 10 and 20
		local k1 = path1:keyframeBeforeTime(-100, 'translate')
		local k2 = path1:keyframeBeforeTime(9, 'translate')
		local k3 = path1:keyframeBeforeTime(10, 'translate')
		local k4 = path1:keyframeBeforeTime(19, 'translate')
		local k5 = path1:keyframeBeforeTime(20, 'translate')
		local k6 = path1:keyframeBeforeTime(5000, 'translate')
		verify(k1 == nil and k2 == nil, "keyframeBeforeTime(): no keyframes before the new one")
		verify(k3:time() == 10 and k3 == k4, "keyframeBeforeTime(): between keyframes returns 10")
		verify(k5:time() == 20 and k5 == k6, "keyframeBeforeTime(): future keyframes returns 20")
		basemodel.deleteDrawable(drawable1)
		drawable1 = nil
		path1 = nil
	endSection()
		
	startSection("Test Setting Visibility")
		verify(#basemodel.allPaths() == 0, "Start with empty path set")
		verify(#basemodel.allDrawables() == 0, "Start with empty drawables set")
		local drawable1 = basemodel.addNewDrawable({ prop=MOAIProp2D.new () }, 10)
		local path1 = basemodel.createNewPath({drawable1}, nil, 10, true, {x=0,y=0}) --create new empty path
		verify(path1:keyframeTimelist('visibility'):size() == 0, "No keyframes on an empty path")
		
		-- set 10 to visible
		local _,_,_,v = path1:stateAtTime(10)
		verify(v == false, "Not visible at time=10")
		path1:setVisibility(10, true)
		local _,_,_,v = path1:stateAtTime(10)
		verify(v == true, "Now should be visible at time=10")
		local _,_,_,v = path1:stateAtTime(1000)
		verify(v == true, "Should also be visible at time=1000")
		verify(path1:keyframeTimelist('visibility'):size() == 1, "1 keyframe now")
		
		--set 15 to invisible
		path1:setVisibility(15, false)		
		local _,_,_,v = path1:stateAtTime(14)
		verify(v == true, "Should still be visible at time=14")
		local _,_,_,v = path1:stateAtTime(15)
		verify(v == false, "Should NOT be visible at time=15")
		local _,_,_,v = path1:stateAtTime(1000)
		verify(v == false, "Should NOT be visible at time=1000")
		verify(path1:keyframeTimelist('visibility'):size() == 2, "2 keyframes now")

		--set 14 to invisible, removing the keyframe at 15 implicitly
		path1:setVisibility(14, false) -- this should remove the keyframe at 15
		local _,_,_,v = path1:stateAtTime(13)
		verify(v == true, "Should still be visible at time=13")
		local _,_,_,v = path1:stateAtTime(14)
		verify(v == false, "Should NOT be visible at time=14")
		local _,_,_,v = path1:stateAtTime(15)
		verify(v == false, "Should NOT be visible at time=15")
		verify(path1:keyframeTimelist('visibility'):size() == 2, "Should still have 2 keyframes")

		--set 10 to invisible, removing its keyframe implicitly
		path1:setVisibility(10, false) -- this should remove the keyframe at 10 AND 14
		local _,_,_,v = path1:stateAtTime(10)
		verify(v == false, "Should NOT be visible at time=10")
		local _,_,_,v = path1:stateAtTime(15)
		verify(v == false, "Should NOT be visible at time=15")
		local _,_,_,v = path1:stateAtTime(1000)
		verify(v == false, "Should NOT be visible at time=1000")
		verify(path1:keyframeTimelist('visibility'):size() == 0, "Should have removed ALL keyframes")

		basemodel.deleteDrawable(drawable1)
		drawable1 = nil
		path1 = nil
	endSection()
	
	startSection("Test Recording a Path")	
		verify(#basemodel.allPaths() == 0, "Start with empty path set")
		verify(#basemodel.allDrawables() == 0, "Start with empty drawables set")
		local drawable1 = basemodel.addNewDrawable({ prop=MOAIProp2D.new () }, 10)
		local path1 = basemodel:allPaths()[1]
	
		--insert a keyframe that will be totally deleted (since it is only translate)
		path1:addKeyframedMotion(19, nil, nil, {x=-300,y=-300}, nil, nil)		
		--insert a keyframed motion that is partially overwritted (but have scale preserved)
		path1:addKeyframedMotion(20, 2.0, 90, {x=50,y=20}, nil, nil)
		--set the visibility to be off in the middle of the recorded path
		path1:setVisibility(21, false)
		verify(path1:keyframeTimelist('translate'):size() == 3, "Should be 3 translate keyframes now (10,19,20)")
		verify(path1:keyframeTimelist('visibility'):size() == 2, "Should be 2 visibility keyframes now (10,21)")

		-- add a recorded motion, overwrites 19 and 21
		local recordSession = path1:startRecordedMotion(18, 'translate')
		recordSession:addMotion(19, {x=100, y = 100})
		recordSession:addMotion(20, {x=-100, y = 100})
		recordSession:addMotion(21, {x=-100, y = -100} )
		recordSession:addMotion(22, {x=0, y = 0})
		recordSession:endSession(22)

		local s,r,t,v  = path1:stateAtTime(19)
		verify(t.x == 100 and t.y == 100, "19:take the recorded translation")
		verify(s == 1.9 and r == 81, "19:preserve the existing scale and rotation")
		verify(v == true, "19:recording should wipe out the invisible markers")

		local s,r,t,v  = path1:stateAtTime(20)
		verify(t.x == -100 and t.y == 100, "20:take the recorded translation")
		verify(s == 2.0 and r == 90, "20:preserve the existing scale and rotation")
		verify(v == true, "20:recording should wipe out the invisible markers")
		verify(path1:keyframeTimelist('visibility'):size() == 2, "Should be 2 visibility keyframes now (10,22)")
		verify(path1:keyframeTimelist('translate'):size() == 3, "Should be 3 translate keyframes now (10,18,22)")

		local _,_,_,v  = path1:stateAtTime(23)
		verify(v == false, "we should remember that we are invisible after the recording is complete")
		basemodel.deleteDrawable(drawable1)
		drawable1 = nil
		path1 = nil
	endSection()


	startSection("Creating more Paths")
		verify(#basemodel.allPaths() == 0, "Start with empty path set")
		verify(#basemodel.allDrawables() == 0, "Start with empty drawables set")
		local drawable1 = basemodel.addNewDrawable({ prop=MOAIProp2D.new () }, 10)
		local path1 = basemodel:allPaths()[1]
		local path2 = basemodel.createNewPath({drawable1}, nil, 0, true, {x=0,y=0})	-- path1, path2
		local path3 = basemodel.createNewPath({drawable1}, 1, 0, true, {x=0,y=0}) -- path3, path1, path2
		local path4 = basemodel.createNewPath({drawable1}, 4, 0, true, {x=0,y=0}) -- path3, path1, path2, path4
		local path5 = basemodel.createNewPath({drawable1}, 3, 0, true, {x=0,y=0}) -- path3, path1, path5, path2, path4

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

		basemodel.deleteDrawable(drawable1)
		drawable1 = nil
		path1 = nil	
	endSection()


	startSection("Deleting Drawables")
		verify(#basemodel.allPaths() == 0, "Start with empty path set")
		verify(#basemodel.allDrawables() == 0, "Start with empty drawables set")
		local drawable1 = basemodel.addNewDrawable({ prop=MOAIProp2D.new () }, 10)
		local path1 = basemodel:allPaths()[1]

		basemodel.deleteDrawable(drawable1)
		verify(#basemodel.allPaths() == 0, "All paths should have been deleted")
		verify(#basemodel.allDrawables() == 0, "All Drawables should be gone")

		local drawable2 = basemodel.addNewDrawable({ prop=MOAIProp2D.new () }, 10)
		local drawable3 = basemodel.addNewDrawable({ prop=MOAIProp2D.new () }, 11)
		local drawable4 = basemodel.addNewDrawable({ prop=MOAIProp2D.new () }, 12)
		local path2 = basemodel.createNewPath({drawable3, drawable2}, nil, 0, true, {x=0,y=0})
		local path3 = basemodel.createNewPath({drawable3, drawable2}, nil, 0, true, {x=0,y=0})
		local path4 = basemodel.createNewPath({drawable4}, nil, 0, true, {x=0,y=0})

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

		basemodel.deleteDrawable(drawable1)
		drawable1 = nil
		path1 = nil	
	endSection()

endSection()


