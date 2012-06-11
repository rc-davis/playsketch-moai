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

function controllers.playback.jumpToTime(time)

	--todo: make FAR prettier
	for _,path in pairs(basemodel.allPaths()) do
		path:cacheAtTime(time)
	end
end

local activeThreads = {}
local activePathAnimations = {}

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
	for p,set in pairs(activePathAnimations) do
		for _,a in pairs(set) do
			a:stop()
		end
	end
	
	activeThreads = {}
	activePathAnimations = {}

end


function controllers.playback.startPlayingPath(path, time)

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
	
	-- Define a function that tracks {S,R, or T} on its own thread
	-- Do this by maintaining our position in a timelist and animating to the next frame
	local function backgroundPlayback(path, timelist, animationFunction, thisThread)

		activeThreads[thisThread] = thisThread

		local it = timelist:begin()

		--advance iterator to start time, ignoring past keyframes
		while not it:done() and it:time() <= controllers.timeline.currentTime() do
				it:next()
		end
	
		-- move through remaining ones animating
		while not it:done() do
			local timeDelta = it:time() - controllers.timeline.currentTime() 
	
			activePathAnimations[path] = {}
			for _,drawable in pairs(path.drawables) do
				local prop = drawable:propForPath(path)
				local a = animationFunction(prop, timeDelta, it:value())
				activePathAnimations[path][a] = a
			end
			
			--wait for the animations to be done
			if not util.tableIsEmpty(activePathAnimations[path]) then
				MOAIThread.blockOnAction(util.tableAny(activePathAnimations[path]))
			end
			activePathAnimations[path] = nil

			it:next()
		end
		
		activeThreads[thisThread] = nil
	end


	-- kick off the actual playback!
	path:cacheAtTime(time) --initialize location
	local t1,t2,t3 = MOAIThread.new(), MOAIThread.new(), MOAIThread.new()
	t1:run(backgroundPlayback, path, path.timelists.translate, animateDrawablePropForPathTranslation, t1)
	t2:run(backgroundPlayback, path, path.timelists.rotate, animateDrawablePropForPathRotation, t2)
	t3:run(backgroundPlayback, path, path.timelists.scale, animateDrawablePropForPathScale, t3)	
end





return controllers.playback

