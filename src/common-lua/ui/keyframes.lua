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

	ui/keyframes.lua
	
	- A (crude for now) display of the keyframes associated with a selection.
	- On each draw loop, it reads from interfacestate.currentPath() and displays the keyframes

--]]

ui.keyframes = {}

local Keyframes = util.objects.defineType("Keyframes", ui.view.class())


function ui.keyframes.class()

	return Keyframes

end


function ui.keyframes.new( frame, imgpath )

	local o = Keyframes:create()
	o:init( frame, imgpath )
	return o
	
end


function Keyframes:init( frame )

	self:superClass().init(self, frame)

	-- Create a new scriptdeck to do our custom drawing	
	self.scriptDeck = MOAIScriptDeck.new ()
	self.scriptDeck:setRect ( 0, 0, self.frame.size.width, self.frame.size.height )
	self.scriptDeck:setDrawCallback(	function ( index, xOff, yOff, xFlip, yFlip )
									self:onDraw(index, xOff, yOff, xFlip, yFlip) 
								end)
	self.prop:setDeck ( self.scriptDeck )

	self:setReceivesTouches ( false )

end


function Keyframes:onDraw ( )

	local visibilityColor	=	{	0.7,	0.3,	0.3	}
	local scaleColor 		=	{	0.3,	0.7,	0.3	}
	local rotateColor		=	{	0.3,	0.3,	0.7	}
	local translateColor	=	{	0.65,	0.65,	0.3	}
	local keyframeWidth = 15

	local function timeToPx(time)
		return (time - controllers.timeline.span.min)/
				(controllers.timeline.span.max - controllers.timeline.span.min) *
				self.frame.size.width
	end

	local function drawKeyframes(it, heightOffsetStart, heightOffsetEnd, r,g,b)

		local spanStartPx = nil
		while not it:done() do		
			local timePx =	timeToPx(it:current():time())
			MOAIGfxDevice.setPenColor (r, g, b, 1)
			MOAIDraw.fillRect(	timePx-keyframeWidth/2, heightOffsetStart, 
								timePx+keyframeWidth/2, heightOffsetEnd)
								
			-- Draw a line if we are finishing a recording span!
			if it:current():metadata('recordingFinishes') and spanStartPx ~= nil then
				local spanHeightOffsetDiff = (heightOffsetEnd - heightOffsetStart)/4
				MOAIDraw.fillRect(	spanStartPx, heightOffsetStart + spanHeightOffsetDiff,
									timePx, heightOffsetEnd - spanHeightOffsetDiff)
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

		MOAIGfxDevice.setPenColor (r, g, b, 1)
		
		while not it:done() do
			local timePx =	timeToPx(it:current():time())

			MOAIDraw.fillRect(	timePx-keyframeWidth/2, heightOffsetStart, 
								timePx+keyframeWidth/2, heightOffsetEnd)

			-- Draw a line if we are finishing a time span!
			if spanStartPx ~= nil then
				local spanHeightOffsetDiff = (heightOffsetEnd - heightOffsetStart)/4
				MOAIDraw.fillRect(	spanStartPx,
									heightOffsetStart + spanHeightOffsetDiff,
									timePx,
									heightOffsetEnd - spanHeightOffsetDiff)
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
								heightOffsetStart + spanHeightOffsetDiff,
								self.frame.size.width,
								heightOffsetEnd - spanHeightOffsetDiff)		
		end
	end
	
	local path = controllers.interfacestate.currentPath()
	
	if path then
		drawKeyframes(	path:keyframeTimelist('scale'):begin(),
						0,
						self.frame.size.height*1/4,
						unpack(scaleColor))
		drawKeyframes(	path:keyframeTimelist('rotate'):begin(),
						self.frame.size.height*1/4,
						self.frame.size.height*2/4,
						unpack(rotateColor))
		drawKeyframes(	path:keyframeTimelist('translate'):begin(),
						self.frame.size.height*2/4,
						self.frame.size.height*3/4,
						unpack(translateColor))
		drawVisibility(	path:keyframeTimelist('visibility'):begin(),
						self.frame.size.height*3/4,
						self.frame.size.height*4/4,
						unpack(visibilityColor))
	end

end


return ui.keyframes

