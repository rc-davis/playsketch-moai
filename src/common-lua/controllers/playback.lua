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
		path:cacheAtTime(time)
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

	-- Bail out if we've been told not to animate this path (used for recording)
	--if path == pathToNotAnimate then return nil end

	--Define the animation functions that actually operate on the drawable's props
	local function animateDrawablePropForPathScale(prop, timeDelta, value)
		return prop:seekScl(value, value, timeDelta, MOAIEaseType.LINEAR)
	end

	local function animateDrawablePropForPathRotation(prop, timeDelta, value)
		return prop:seekRot(value, timeDelta, MOAIEaseType.LINEAR)
	end

	local function animateDrawablePropForPathTranslation(prop, timeDelta, value)
		return prop:seekLoc(value.x, value.y, timeDelta, MOAIEaseType.LINEAR)
	end

	--Define the static functions for when we just want to jump to the state
	local function staticDrawablePropForPathScale(prop, value)
		return prop:setScl(value, value)
	end

	local function staticDrawablePropForPathRotation(prop, value)
		return prop:setRot(value)
	end

	local function staticDrawablePropForPathTranslation(prop, value)
		return prop:setLoc(value.x, value.y)
	end

	
	-- Define a function that tracks {S,R, or T} on its own thread
	-- Do this by maintaining our position in a timelist and animating to the next frame
	local function backgroundPlayback(path, timelist, animationFunction, staticFunction, thisThread)

		activeThreads[thisThread] = thisThread
		activeAnimations[thisThread] = {}

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

				for _,drawable in pairs(path.drawables) do
					local prop = drawable:propForPath(path)
					staticFunction(prop, it:current():value())
				end

				activeAnimations[thisThread] = {}
			else
				--wait for the animations to be done
				if not util.tableIsEmpty(activeAnimations[thisThread]) then
					MOAIThread.blockOnAction(util.tableAny(activeAnimations[thisThread]))
				end
		
				local timeDelta = it:current():time() - controllers.timeline.currentTime() 
				activeAnimations[thisThread] = {}
				for _,drawable in pairs(path.drawables) do
					local prop = drawable:propForPath(path)
					local a = animationFunction(prop, timeDelta, it:current():value())
					activeAnimations[thisThread][a] = a
				end
			
			end
			
	
			it:next()
			
	
		end
		
		activeThreads[thisThread] = nil
	end


	-- kick off the actual playback!
	path:cacheAtTime(time) --initialize location
	local t1,t2,t3 = MOAIThread.new(), MOAIThread.new(), MOAIThread.new()
	t1:run(	backgroundPlayback, path, path.timelists.translate, 
			animateDrawablePropForPathTranslation,
			staticDrawablePropForPathTranslation, t1)
	t2:run(	backgroundPlayback, path, path.timelists.rotate, 
			animateDrawablePropForPathRotation,
			staticDrawablePropForPathRotation, t2)
	t3:run(	backgroundPlayback, path, path.timelists.scale, 
			animateDrawablePropForPathScale,
			staticDrawablePropForPathScale, t3)	
end





return controllers.playback

