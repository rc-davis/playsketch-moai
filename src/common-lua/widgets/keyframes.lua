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

	if self.currentPath then						

		local keyframeWidth = 30
		MOAIGfxDevice.setPenColor (0, 0, 0, 0.5)

		local it = self.currentPath:keyframeTimelist():begin()
		while not it:done() do
			local timePx =	(it:time() - controllers.timeline.span.min)/
							(controllers.timeline.span.max - controllers.timeline.span.min) *
							self.frame.size.width + self.frame.origin.x
			MOAIDraw.fillRect(	timePx-keyframeWidth/2, self.frame.origin.y, 
								timePx+keyframeWidth/2, self.frame.origin.y+self.frame.size.height)
			it:next()
		end
	end
end

function widgets.keyframes:setCurrentPath(p)
	self.currentPath = p
end

return widgets.keyframes
