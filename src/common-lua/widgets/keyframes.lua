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

	widgets/keyframes.lua

	- A (crude for now) display of the keyframes associated with a selection.
	- On each draw loop, it reads from interfacestate.currentPath() and displays the keyframes
--]]


widgets.keyframes = {}


function widgets.keyframes:init(centerX,centerY,width,height)

	local scriptDeck = MOAIScriptDeck.new ()
	scriptDeck:setRect(centerX - width/2, centerY - height/2, width, height)
	scriptDeck:setDrawCallback(	function ( index, xOff, yOff, xFlip, yFlip )
									self:onDraw(index, xOff, yOff, xFlip, yFlip) 
								end)

	self.prop = MOAIProp2D.new ()
	self.prop:setDeck ( scriptDeck )
	widgets.layer:insertProp(self.prop)
	self.frame = {size={width=width,height=height}, origin={x=centerX-width/2, y=centerY-height/2} }

end

local keyframeWidth = 15

function widgets.keyframes:onDraw( index, xOff, yOff, xFlip, yFlip )

	local function timeToPx(time)
		return (time - controllers.timeline.span.min)/
				(controllers.timeline.span.max - controllers.timeline.span.min) *
				self.frame.size.width + self.frame.origin.x
	end

	local function drawKeyframes(it, heightOffsetStart, heightOffsetEnd, r,g,b)

		local spanStartPx = nil
		while not it:done() do		
			local timePx =	timeToPx(it:current():time())
			MOAIGfxDevice.setPenColor (r, g, b, 0.5)
			MOAIDraw.fillRect(	timePx-keyframeWidth/2, self.frame.origin.y + heightOffsetStart, 
								timePx+keyframeWidth/2, self.frame.origin.y + heightOffsetEnd)
								
			-- Draw a line if we are finishing a recording span!
			if it:current():metadata('recordingFinishes') and spanStartPx ~= nil then
				local spanHeightOffsetDiff = (heightOffsetEnd - heightOffsetStart)/4
				MOAIDraw.fillRect(	spanStartPx, self.frame.origin.y + heightOffsetStart + spanHeightOffsetDiff,
									timePx, self.frame.origin.y + heightOffsetEnd - spanHeightOffsetDiff)
				spanStartPx = nil
			end
			
			if it:current():metadata('recordingStarts') then
				spanStartPx = timePx
			end
								
			it:next()
		end
	end
	
	local function drawVisibility(it, heightOffsetStart, heightOffsetEnd, r,g,b)
		local spanStartPx = timeToPx(0)
		it:next()

		MOAIGfxDevice.setPenColor (r, g, b, 0.5)
		
		while not it:done() do
			local timePx =	timeToPx(it:current():time())

			MOAIDraw.fillRect(	timePx-keyframeWidth/2, self.frame.origin.y + heightOffsetStart, 
								timePx+keyframeWidth/2, self.frame.origin.y + heightOffsetEnd)

			-- Draw a line if we are finishing a time span!
			if spanStartPx ~= nil then
				local spanHeightOffsetDiff = (heightOffsetEnd - heightOffsetStart)/4
				MOAIDraw.fillRect(	spanStartPx,
									self.frame.origin.y + heightOffsetStart + spanHeightOffsetDiff,
									timePx,
									self.frame.origin.y + heightOffsetEnd - spanHeightOffsetDiff)
				spanStartPx = nil
			end
			
			if it:current():value():value() == true then
				spanStartPx = timePx
			end			
			it:next()
		end
		
		if spanStartPx ~= nil then
			local spanHeightOffsetDiff = (heightOffsetEnd - heightOffsetStart)/4
			MOAIDraw.fillRect(	spanStartPx,
								self.frame.origin.y + heightOffsetStart + spanHeightOffsetDiff,
								self.frame.origin.x + self.frame.size.width,
								self.frame.origin.y + heightOffsetEnd - spanHeightOffsetDiff)		
		end
	end
	
	local path = controllers.interfacestate.currentPath()
	
	if path then
		drawKeyframes(	path:keyframeTimelist('scale'):begin(),
						0,
						self.frame.size.height*1/4,
						1,0,0)
		drawKeyframes(	path:keyframeTimelist('rotate'):begin(),
						self.frame.size.height*1/4,
						self.frame.size.height*2/4,
						0,1,0)
		drawKeyframes(	path:keyframeTimelist('translate'):begin(),
						self.frame.size.height*2/4,
						self.frame.size.height*3/4,
						0,0,1)
		drawVisibility(	path:keyframeTimelist('visibility'):begin(),
						self.frame.size.height*3/4,
						self.frame.size.height*4/4,
						1, 0.1, 0.5)
	end
end

return widgets.keyframes
