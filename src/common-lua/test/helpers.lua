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


return test.helpers