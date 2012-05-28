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
	for _,drawable in pairs(basemodel.allDrawables()) do
		drawable:refreshPathProps()
	end
end

function controllers.playback.startPlaying(time)

	if not time then time = 0 end
	
	
end

function controllers.playback.stopPlaying()


end

return controllers.playback

