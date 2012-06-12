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

	widgets/slider.lua

	The timeline slider.
	Counts time in discrete frames!
	
	
--]]

widgets.slider = {}

function widgets.slider:init(centerX, centerY, width, height, scrubberWidth, 
			imgBackground, imgSlider, imgSliderDown, callbackMoved, callbackMoveFinished)

	assert(widgets.layer, "widgets.layer must be initialized before creating buttons")

	self.center = {x=centerX, y=centerY}
	self.size = {width=width, height=height}
	self.pixelSpan = { start=(self.center.x - self.size.width/2 + scrubberWidth/2),
						stop=(self.center.x + self.size.width/2 - scrubberWidth/2)}


	self.minvalue = 0
	self.maxvalue = 1
	self.value = 0

	self.callbackMoved = callbackMoved
	self.callbackMoveFinished = callbackMoveFinished

	self.currentAnimation = nil

	self.background = widgets.newSimpleButton( centerX, centerY, width, height, 
					imgBackground, imgBackground, nil, nil, nil)
	
	self.scrubber = widgets.newSimpleDragableButton( centerX, centerY, scrubberWidth, height, 
						imgSlider, imgSliderDown, nil, nil)
	
	--Hook up our button's callbacks
	self.background.callbackUp = self.backgroundCallbackUp
	self.scrubber.callbackDrag = self.scrubberCallbackDrag
	self.scrubber.callbackUp = self.scrubberCallbackUp

end

function widgets.slider:currentValue()

	if self.currentAnimation then
		local x,_ = self.scrubber:getLoc()
		return self:valueForScrubberX(x, false)
	else
		return self.value
	end
end

function widgets.slider:setValueSpan(min,max)
	local currentValue = math.max(min, math.min(self:currentValue(), max))
	self.minvalue = min
	self.maxvalue = max
	self:setValue(currentValue, 0)
end

function widgets.slider:setValue(value, duration, skipScrubberUpdate)
	assert(value >= self.minvalue and value <= self.maxvalue, "slider:setValue() should be within the slider's bounds")
	--assert(value == math.floor(value), "Slider should only be set to integer values")

	self.value = value	
	local scrubberX = self:scrubberXForValue(value)
	
	-- Fix up the scrubber's location
	if duration == 0 then
		if skipScrubberUpdate == nil or skipScrubberUpdate == false then
			-- snap the scrubber's location
			self.scrubber:setLoc(scrubberX, self.center.y)	
		else
			-- just constrain it along the scrubber line
			local px,_ = self.scrubber:getLoc()
			px = math.max(self.pixelSpan.start, math.min(self.pixelSpan.stop, px))
			self.scrubber:setLoc(px, self.center.y)			
		end
	else
		assert(self.currentAnimation == nil, "should have no existing play animation")
		self.currentAnimation = self.scrubber:seekLoc(scrubberX, self.center.y, duration, MOAIEaseType.LINEAR)
	end
end

function widgets.slider:stop()
	if self.currentAnimation ~= nil then
		local val = self:currentValue()
		self.currentAnimation:stop()
		self.currentAnimation = nil
		self:setValue(val, 0)
	end
end

-- Button movement callbacks 

function widgets.slider.backgroundCallbackUp(button, px, py)
	widgets.slider:setValue(widgets.slider:valueForScrubberX(px, true), 0)
	if widgets.slider.callbackMoveFinished then
		widgets.slider.callbackMoveFinished(widgets.slider, widgets.slider.value)
	end
end

function widgets.slider.scrubberCallbackDrag(button, dx, dy)
	local px,_ = widgets.slider.scrubber:getLoc()
	widgets.slider:setValue(widgets.slider:valueForScrubberX(px, false), 0, true)	
	if widgets.slider.callbackMoved then 
		widgets.slider.callbackMoved(widgets.slider, widgets.slider.value)
	end
end

function widgets.slider.scrubberCallbackUp(_,_,_)
	-- Snap!
	widgets.slider:setValue(math.floor(0.5 + widgets.slider:currentValue()), 0)
	if widgets.slider.callbackMoveFinished then
		widgets.slider.callbackMoveFinished(widgets.slider, widgets.slider.value)
	end
end


-- Math helpers

function widgets.slider:scrubberXForValue(value)
	local valPcnt = (value - self.minvalue) / (self.maxvalue - self.minvalue)
	valPcnt = math.max(0, math.min(1, valPcnt)) -- round up/down to truncate
	return self.pixelSpan.start + valPcnt * (self.pixelSpan.stop - self.pixelSpan.start)
end

function widgets.slider:valueForScrubberX(x, snap)
	local xPcnt = (x - self.pixelSpan.start) / (self.pixelSpan.stop - self.pixelSpan.start)
	xPcnt = math.max(0, math.min(1, xPcnt)) -- round up/down to truncate
	local unRounded = self.minvalue + xPcnt * ( self.maxvalue - self.minvalue)
	if snap then return math.floor(0.5 + unRounded)
	else return unRounded end
end

return widgets.slider
