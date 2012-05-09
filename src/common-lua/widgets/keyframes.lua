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
	- On each draw loop, it reads from self.usertransform and displays its span, as well
	  as every "keyframe time".
--]]


widgets.keyframes = {}

local KeyFrameWidget = {}

function widgets.keyframes.new(centerX,centerY,width,height)
	local l = {}
	for i,v in pairs(KeyFrameWidget) do
		l[i] = v
	end
	l:init(centerX,centerY,width,height)
	return l
end


function KeyFrameWidget:init(centerX,centerY,width,height)

	self.usertransform = nil

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


function KeyFrameWidget:onDraw( index, xOff, yOff, xFlip, yFlip )

	MOAIGfxDevice.setPenColor (0.3, 0.3, 0.3, 1.0)
	MOAIDraw.fillRect(	self.frame.origin.x, self.frame.origin.y, 
						self.frame.origin.x + self.frame.size.width,
						self.frame.origin.y + self.frame.size.height)

	if self.usertransform then						

		--draw span
		local spanStartPx = (self.usertransform.span.start - controllers.timeline.span.min)/
							(controllers.timeline.span.max - controllers.timeline.span.min) *
							self.frame.size.width + self.frame.origin.x
		local spanEndPx = 	(self.usertransform.span.stop - controllers.timeline.span.min)/
							(controllers.timeline.span.max - controllers.timeline.span.min) *
							self.frame.size.width + self.frame.origin.x

		MOAIGfxDevice.setPenColor (0, 1.0, 0.0, 1.0)
		MOAIGfxDevice.setPenWidth(self.frame.size.height/2)
		MOAIDraw.drawLine( spanStartPx, self.frame.origin.y + self.frame.size.height/2,
							spanEndPx, self.frame.origin.y + self.frame.size.height/2)
		
		for _,t in pairs(self.usertransform.keyframeTimes) do
			local timePx =	(t - controllers.timeline.span.min)/
							(controllers.timeline.span.max - controllers.timeline.span.min) *
							self.frame.size.width + self.frame.origin.x
			MOAIDraw.drawLine(timePx, self.frame.origin.y, timePx, self.frame.origin.y+self.frame.size.height)		
		end
	end
end

function KeyFrameWidget:setUserTransform(usertransform)
	self.usertransform = usertransform
end


return widgets.keyframes
