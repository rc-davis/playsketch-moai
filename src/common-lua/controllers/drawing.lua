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

	controllers/drawing.lua
	
	Builds an ink stroke drawing with startStroke()
	This stroke can be updated with additional points as they come in from the user.
	When all the points are added, doneStroke() cleans up the results and passes it along
	to the objects controller to add it to the scene.
	
--]]


controllers.drawing = {}


function controllers.drawing.newStroke()

	local strokeDeck = MOAIScriptDeck.new ()
	local new_stroke = MOAIProp2D.new ()
	new_stroke:setDeck ( strokeDeck )
	
	strokeDeck:setRect ( -10, -10, 10, 10 ) --temporarily
	new_stroke.points = {}
	new_stroke.color = {1.0, 0.0, math.random()}
	new_stroke.penWidth = 4.0


	strokeDeck:setDrawCallback(
		function ( index, xOff, yOff, xFlip, yFlip )
			if controllers.selection.isSelected(new_stroke) then
				MOAIGfxDevice.setPenColor (1.0, 1.00, 0)
				MOAIGfxDevice.setPenWidth(10.0)
				MOAIDraw.drawLine ( new_stroke.points)
			end
			MOAIGfxDevice.setPenColor (unpack(new_stroke.color))
			MOAIGfxDevice.setPenWidth(new_stroke.penWidth)
			MOAIDraw.drawLine ( new_stroke.points)
		end)


	drawingLayer:insertProp ( new_stroke )


	--	addPoint(x,y): Adds the next point to the stroke that is being drawn
	function new_stroke:addPoint(x,y)
		table.insert(new_stroke.points, x)
		table.insert(new_stroke.points, y)		
	end


	-- doneStroke(): Finishes off the stroke and passes it to the objects controller
	function new_stroke:doneStroke()
	
		-- clean up the points so that they are centred
		local minx,miny = 1E100,1E100
		local maxx,maxy = -1E100,-1E100
		for j=1,#self.points,2 do
			minx = math.min(minx,self.points[j])
			maxx = math.max(maxx,self.points[j])
			miny = math.min(miny,self.points[j+1])
			maxy = math.max(maxy,self.points[j+1])
		end
		local width = (maxx - minx)
		local height = (maxy-miny)
		local new_x,new_y = minx + width/2, miny + height/2
		
		--fix up the numbers to be relative to the new zero point
		for j=1,#self.points,2 do
			self.points[j] = self.points[j] - new_x
			self.points[j+1] = self.points[j+1] - new_y
		end
		
		strokeDeck:setRect (-width/2, -height/2, width/2, height/2)

--TODO! This should call to the interactor model!!
basemodel.addNewDrawable(self, controllers.timeline.currentTime(), {x=minx + width/2,y=miny + height/2})

	end
	
	--cancel():	Cancel the drawing of the stroke	
	function new_stroke:cancel()
		drawingLayer:removeProp (self)
		print("CANCELLING")
	end


	function new_stroke:propToSave()
		local x,y = self:getLoc()
		return {points=self.points, proptype="DRAWING", location={x=x,y=y}}
	end

	function new_stroke:loadSaved(proptable)
		self.points = {}
		local max_id = 0
		for k,v in pairs(proptable.points) do
			max_id = math.max(max_id, k)
		end
		for i=1,max_id do
			table.insert(self.points, proptable.points[i])
		end
		self:doneStroke()
		self:setLoc(proptable.location.x, proptable.location.y)		
	end

	function new_stroke:correctedPointsAtCurrentTime()
		local corrected = {}
		for i=1,#self.points,2 do
			corrected[i],corrected[i+1] = self:modelToWorld(self.points[i],self.points[i+1])
			print(self.points[i], '->', corrected[i])
		end
		return corrected
	end

	return new_stroke

end


function controllers.drawing.startStroke()
	return controllers.drawing.newStroke()
end


function controllers.drawing.loadSavedProp(proptable)

	local new_stroke = controllers.drawing.newStroke()
	new_stroke:loadSaved(proptable)
	return new_stroke
end


return controllers.drawing