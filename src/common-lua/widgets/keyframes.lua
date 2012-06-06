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
	- On each draw loop, it reads from self.currentPath and displays its span, as well
	  as every "keyframe time".
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

	MOAIGfxDevice.setPenColor (0.3, 0.3, 0.3, 1.0)

	if self.currentPath then						

		--draw span
		--local spanStartPx = (self.currentPath.span.start - controllers.timeline.span.min)/
		--					(controllers.timeline.span.max - controllers.timeline.span.min) *
		--					self.frame.size.width + self.frame.origin.x
		--local spanEndPx = 	(self.currentPath.span.stop - controllers.timeline.span.min)/
		--					(controllers.timeline.span.max - controllers.timeline.span.min) *
		--					self.frame.size.width + self.frame.origin.x

		MOAIGfxDevice.setPenColor (0, 1.0, 0.0, 1.0)
		MOAIGfxDevice.setPenWidth(self.frame.size.height/2)
		--MOAIDraw.drawLine( spanStartPx, self.frame.origin.y + self.frame.size.height/2,
		--					spanEndPx, self.frame.origin.y + self.frame.size.height/2)
		
		local it = self.currentPath:keyframeTimelist():begin()
		while not it:done() do
			local timePx =	(it:time() - controllers.timeline.span.min)/
							(controllers.timeline.span.max - controllers.timeline.span.min) *
							self.frame.size.width + self.frame.origin.x
			MOAIDraw.drawLine(timePx, self.frame.origin.y, timePx, self.frame.origin.y+self.frame.size.height)		
			it:next()
		end
	end
end

function widgets.keyframes:setCurrentPath(p)
	self.currentPath = p
end

return widgets.keyframes
