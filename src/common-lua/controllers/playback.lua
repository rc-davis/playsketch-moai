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

	controllers/playback.lua
	
	Uses the basemodel to play/pause/jump the animation
--]]


controllers.playback = {}

function controllers.playback.refresh()
	controllers.playback.jumpToTime(controllers.timeline.currentTime())
end

function controllers.playback.jumpToTime(time)
	--todo: make FAR prettier
	for _,path in pairs(basemodel.allPaths()) do
		path:displayAtTime(time)
		
	end
end

local activeThreads = {}
local activeAnimations = {}
local pathToNotAnimate = nil

function controllers.playback.startPlaying(time)
	
	if not time then time = 0 end

	-- tell all paths to start animating!
	for _,path in pairs(basemodel.allPaths()) do
		controllers.playback.startPlayingPath(path, time)	
	end
end

function controllers.playback.stopPlaying()

	--kill threads
	for _,t in pairs(activeThreads) do t:stop() end
	
	--kill animations
	for thread,animations in pairs(activeAnimations) do
		for _,a in pairs(animations) do
			a:stop()
		end
	end
	
	activeThreads = {}
	activeAnimations = {}

end

function controllers.playback.setPathToNotAnimate(path)
	pathToNotAnimate = path
end

function controllers.playback.startPlayingPath(path, time)
	
	-- Define a function that tracks {S,R, or T} on its own thread
	-- Do this by maintaining our position in a timelist and animating to the next frame
	local function backgroundPlayback(path, timelist, thisThread, updateFunctionName)

		activeThreads[thisThread] = thisThread
		activeAnimations[thisThread] = nil

		local it = timelist:begin()

		--advance iterator to start time, ignoring past keyframes
		while not it:done() and it:current():time() <= controllers.timeline.currentTime() do
				it:next()
		end
	
		-- move through remaining ones animating
		while not it:done() do
		
			if it:current():metadata('recorded') then
				while not it:done() and it:current():time() > controllers.timeline.currentTime() do
					coroutine.yield()
				end

				path[updateFunctionName](path, it:current():value(), 0)

				activeAnimations[thisThread] = nil
			else
				--wait for the animations to be done
				if not util.tableIsEmpty(activeAnimations[thisThread]) then
					MOAIThread.blockOnAction(util.anyItem(activeAnimations[thisThread]))
				end
		
				local timeDelta = it:current():time() - controllers.timeline.currentTime() 
				
				activeAnimations[thisThread] = path[updateFunctionName](path, it:current():value(), timeDelta)
			
			end

			it:next()
	
		end
		
		activeThreads[thisThread] = nil
	end


	-- kick off the actual playback!
	path:displayAtTime(time) --initialize location
	local t1,t2,t3,t4 = MOAIThread.new(), MOAIThread.new(), MOAIThread.new(), MOAIThread.new()
	t1:run(	backgroundPlayback, path, path.timelists.translate, t1, 'setDisplayTranslation')
	t2:run(	backgroundPlayback, path, path.timelists.rotate, t2, 'setDisplayRotation')
	t3:run(	backgroundPlayback, path, path.timelists.scale, t3, 'setDisplayScale')
	t4:run(	backgroundPlayback, path, path.timelists.visibility, t4, 'setDisplayVisibility')
end





return controllers.playback

