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

	Random pieces of code for helping to exercise our system
	
--]]

require "controllers/controllers"

test.helpers = {}


-- generateLines(): Add 'nLines' random-walk lines, each with 'nPointsPerLine' points
function test.helpers.generateLines(nLines, nPointsPerLine)

	local variance = 30

	for i=1,nLines do
	
		local o = controllers.drawing.startStroke()

		--make the points!
		local x = math.random(-SCALED_WIDTH/2, SCALED_WIDTH/2)
		local y = math.random(-SCALED_HEIGHT/2, SCALED_HEIGHT/2)
		
		for j=1,nPointsPerLine do	
	
			o:addPoint(x,y)
			x = x + math.random(-variance, variance)
			y = y + math.random(-variance, variance)
		end

		o:doneStroke()

	end


end



-- addDebugGrid()	Adds a background grid image to the supplied prop to help track its
--					coordinate system
function test.helpers.addDebugGrid(prop)
	if test.helpers.gridImg == nil then
		test.helpers.gridImg = MOAIGfxQuad2D.new ()
		test.helpers.gridImg:setTexture ( "resources/grid.png" )
		test.helpers.gridImg:setRect ( -100, -100, 100, 100 )
	end
	
	--create a new prop, which inherits from the provided prop
	newprop = MOAIProp2D.new ()
	newprop:setDeck ( test.helpers.gridImg )
	newprop:setLoc (0,0)
	drawingLayer:insertProp (newprop)
	newprop:setAttrLink(MOAIProp2D.INHERIT_TRANSFORM, prop, MOAIProp2D.TRANSFORM_TRAIT)	
end

return test.helpers