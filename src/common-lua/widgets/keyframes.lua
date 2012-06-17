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
	- On each draw loop, it reads from self.currentPath and displays the keyframes
--]]


widgets.keyframes = {}


function widgets.keyframes:init(centerX,centerY,width,height)

	self.currentPath = nil

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


function widgets.keyframes:onDraw( index, xOff, yOff, xFlip, yFlip )

	local function drawKeyframes(it, heightOffsetStart, heightOffsetEnd, r,g,b)
		local keyframeWidth = 30
		while not it:done() do		
			local timePx =	(it:current():time() - controllers.timeline.span.min)/
							(controllers.timeline.span.max - controllers.timeline.span.min) *
							self.frame.size.width + self.frame.origin.x
			MOAIGfxDevice.setPenColor (r, g, b, 0.5)
			MOAIDraw.fillRect(	timePx-keyframeWidth/2, self.frame.origin.y + heightOffsetStart, 
								timePx+keyframeWidth/2, self.frame.origin.y + heightOffsetEnd)
			it:next()
		end
	end
	
	if self.currentPath then
		drawKeyframes(	self.currentPath:keyframeTimelist('scale'):begin(),
						0,
						self.frame.size.height*1/4,
						1,0,0)
		drawKeyframes(	self.currentPath:keyframeTimelist('rotate'):begin(),
						self.frame.size.height*1/4,
						self.frame.size.height*2/4,
						0,1,0)
		drawKeyframes(	self.currentPath:keyframeTimelist('translate'):begin(),
						self.frame.size.height*2/4,
						self.frame.size.height*3/4,
						0,0,1)
		drawKeyframes(	self.currentPath:keyframeTimelist('visibility'):begin(),
						self.frame.size.height*3/4,
						self.frame.size.height*4/4,
						0.5,0.5,0)
	end
end

function widgets.keyframes:setCurrentPath(p)
	self.currentPath = p
end

return widgets.keyframes
