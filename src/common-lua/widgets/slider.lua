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

	The timeline slider
	
--]]

widgets.slider = {}


-- newSlider(): 	A slider that can be used to select a value (used for timelines)
-- 					the callback has the form: callback(button,value), when the value changes
--					Use :setValueSpan(min,max) to set the allowable range of values
function widgets.slider.newSlider(centerX, centerY, width, height, sliderWidth, imgBackground, imgSlider, imgSliderDown, callbackMoved, callbackMoveFinished)

	assert(widgets.layer, "widgets.layer must be initialized before creating buttons")

	local slider = {}

	slider.minvalue = 0
	slider.maxvalue = 1
	slider.value = 0
	slider.callbackMoved = callbackMoved
	slider.callbackMoveFinished = callbackMoveFinished
	slider.currentAnimation = nil

	slider.background = widgets.newSimpleButton( centerX, centerY, width, height, 
					imgBackground, imgBackground, nil, nil, nil)
	
	slider.scrubber = widgets.newSimpleDragableButton( centerX, centerY, sliderWidth, height, 
						imgSlider, imgSliderDown, nil, nil)
	
	--jump to a time when 
	slider.background.callbackUp = 
		function (button, px, py)
			slider:setAtX(x, 0, true)
			if slider.callbackMoveFinished then slider.callbackMoveFinished(slider, slider.value) end
		end

	slider.scrubber.callbackDrag = 
		function (button, dx, dy)
			local px,_ = slider.scrubber:getLoc()
			slider:setAtX(px, 0, true)
		end
	slider.scrubber.callbackUp = 
		function (_,_,_)
			if slider.callbackMoveFinished then slider.callbackMoveFinished(slider, slider.value) end
		end

	function slider:xToValue(x)
		assert(x >= centerX - width/2 + sliderWidth/2 and x <= centerX + width/2 - sliderWidth/2, 
			"converting x should go to a valid value")
		local new_pcnt_value = (x + width/2 - sliderWidth/2 - centerX)/(width - sliderWidth)
		return new_pcnt_value*(slider.maxvalue - slider.minvalue)+slider.minvalue
	end

	function slider:setAtValue(v, duration)
		local pcnt = self.minvalue + (v - self.minvalue)/(self.maxvalue - self.minvalue)
		pcnt = math.max(0, math.min(1, pcnt))
		local new_x = centerX - width/2 + sliderWidth/2 + pcnt*(width - sliderWidth)
		self:setAtX(new_x, duration, false)
	end

	function slider:setAtX(px, duration, shouldCallback)
		
		--scrubber location
		px = math.min(px, centerX + width/2 - sliderWidth/2)
		px = math.max(px, centerX - width/2 + sliderWidth/2)

		if duration == 0 then
			self.scrubber:setLoc(px, centerY)
			self.value = self:xToValue(px)
		else
			self.currentAnimation = self.scrubber:seekLoc(px, centerY, duration, MOAIEaseType.LINEAR)
		end

		--callback
		if self.callbackMoved and shouldCallback then
			self.callbackMoved(self, self.value)
		end
	end
	
	function slider:currentValue()
		return self.value
	end

	function slider:setValueSpan(min,max)
		local currentValue = self:currentValue()	
		self.minvalue = min
		self.maxvalue = max
		self:setAtValue(currentValue, 0)
		if self.callbackMovied and shouldCallback then
			self.callbackMoved(self, currentValue)
		end
	end
	
	function slider:stop()
		if self.currentAnimation ~= nil then
			self.currentAnimation:stop()
			local x,_ = self.scrubber:getLoc()
			self.value = self:xToValue(x)
		end
	end

	return slider
end


return widgets.slider