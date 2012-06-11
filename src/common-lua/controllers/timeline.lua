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

controllers.timeline = {}
controllers.timeline.span = {min=0, max=15}
controllers.timeline.playing = false



-- setSlider(slider): Associates the timeline controller with the specified slider widget
function controllers.timeline.setButtons(playButton)
	controllers.timeline.playButton = playButton
	widgets.slider:setValueSpan(controllers.timeline.span.min, 
											controllers.timeline.span.max)
end


--sliderMoved(slider, time): Respond to the slider having been moved manually
function controllers.timeline.sliderMoved(slider, new_time)
	assert(new_time >= controllers.timeline.span.min and
			new_time <= controllers.timeline.span.max,
			"slider should stay within timeline's bounds")
			
	if controllers.timeline.playing then controllers.timeline.pause() end

	controllers.playback.jumpToTime(new_time)
end

function controllers.timeline.sliderMoveFinished(slider, new_time)

	--TODO: only snap here?

	assert(new_time >= controllers.timeline.span.min and
			new_time <= controllers.timeline.span.max,
			"slider should stay within timeline's bounds")
			
	if controllers.timeline.playing then controllers.timeline.pause() end
	controllers.playback.jumpToTime(new_time)
end

-- currentTime():	Global way of exposing the current timeline time! Use this!
function controllers.timeline.currentTime()
	return widgets.slider:currentValue()
end


-- playPause():	Toggle the play/pause button
function controllers.timeline.playPause(_) 

	if not controllers.timeline.playing then 
		controllers.timeline.play()
	else
		controllers.timeline.pause() 
	end
end


-- play():	Start playing the animation from the current time
function controllers.timeline.play()
	assert(not controllers.timeline.playing, 
			"Timeline should be paused before calling controllers.timeline.play()")
	controllers.timeline.playing = true
	controllers.timeline.playButton:setIndex(2)

	controllers.playback.startPlaying(controllers.timeline.currentTime())

	widgets.slider:setValue(controllers.timeline.span.max,
											controllers.timeline.span.max - 
											widgets.slider:currentValue())
end


-- pause(): Pause the timeline when it is playing
function controllers.timeline.pause()

	assert(controllers.timeline.playing, 
			"Timeline should be playing before calling controllers.timeline.pause()")
	controllers.timeline.playing = false
	controllers.timeline.playButton:setIndex(1)	
	
	widgets.slider:stop()

	controllers.playback.stopPlaying()
	controllers.playback.jumpToTime(widgets.slider:currentValue()) -- to snap off

end

return controllers.timeline