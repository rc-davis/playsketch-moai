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

	controllers/timeline.lua
	
	Controls the playback of the animation, through use of the timeline widget.
	We need a timeline widget! (set using :setSlider())
	
--]]

require "model/model"

controllers.timeline = {}
controllers.timeline.span = {min=0, max=15}
controllers.timeline.slider = nil
controllers.timeline.playing = false



-- setSlider(slider): Associates the timeline controller with the specified slider widget
function controllers.timeline.setSlider(slider)
	controllers.timeline.slider = slider
	controllers.timeline.slider:setValueSpan(controllers.timeline.span.min, 
											controllers.timeline.span.max)
end


--LOCAL bringModelToTime(new_time):	Sets all objects to their state for a given time
local function bringModelToTime(new_time)
	for i, o in ipairs(model.all_objects) do
		local p = o:getInterpolatedValueForTime(model.keys.LOCATION, new_time)
		o:setLoc(p.x, p.y)
	end
end


--sliderMoved(time): Respond to the slider having been moved manually
function controllers.timeline.sliderMoved(new_time)
	assert(new_time >= controllers.timeline.span.min and
			new_time <= controllers.timeline.span.max,
			"slider should stay within timeline's bounds")
			
	if controllers.timeline.playing then controllers.timeline.pause() end

	bringModelToTime(new_time)

end


-- currentTime():	Global way of exposing the current timeline time! Use this!
function controllers.timeline.currentTime()
	return controllers.timeline.slider:currentValue()
end


-- playPause():	Toggle the play/pause button
function controllers.timeline.playPause() 

	--TODO: should also flip the state of the button's graphic!

	if not controllers.timeline.playing then controllers.timeline.play()
	else controllers.timeline.pause() end

end


-- play():	Start playing the animation from the current time
function controllers.timeline.play()
	--TODO: INVESTIGATE A BETTER WAY TO DO THIS?
	-- ideas:	use a particle script?
	-- 			keep pointers to each object and advance through their steps, using native transitions on keyframes?
	--			moaitimer? or register for step() callback

	assert(not controllers.timeline.playing, 
			"Timeline should be paused before calling controllers.timeline.play()")
	controllers.timeline.playing = true

	for i,o in ipairs(model.all_objects) do
		o:playBack(controllers.timeline.slider:currentValue())
	end

	controllers.timeline.slider:setAtValue(controllers.timeline.span.max,
											controllers.timeline.span.max - 
											controllers.timeline.slider:currentValue())
end


-- pause(): Pause the timeline when it is playing
function controllers.timeline.pause()

	assert(controllers.timeline.playing, 
			"Timeline should be playing before calling controllers.timeline.pause()")
	controllers.timeline.playing = false
	
	--todo: figure out current time better?
	controllers.timeline.slider:stop()

	for i,o in ipairs(model.all_objects) do
		o:stopPlayback()
	end
	
	local currenttime = controllers.timeline.slider:currentValue()
	
	bringModelToTime(currenttime)

end

return controllers.timeline