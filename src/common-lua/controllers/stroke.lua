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

	controllers/stroke.lua
	
	Builds an ink stroke drawing with startStroke()
	This stroke can be updated with additional points as they come in from the user.
	When all the points are added, doneStroke() cleans up the results and passes it along
	to the objects controller to add it to the scene.
	
--]]


controllers.stroke = {}
local Stroke = {}

function controllers.stroke.new()
	return util.clone(Stroke):init()
end

function Stroke:init()

	self.deck = MOAIScriptDeck.new ()
	self.prop =  MOAIProp2D.new ()

	self.prop:setDeck ( self.deck )
	self.deck:setRect ( -10, -10, 10, 10 ) --temporarily

	self.points = {}
	self.color = {0.0, 0.0, 0.0}
	self.penWidth = 4.0

	self.deck:setDrawCallback(function () self:onDraw() end)
	drawingLayer:insertProp ( self.prop )
	return self

end


function Stroke:onDraw()
	if controllers.selection.isSelected(self) then
		MOAIGfxDevice.setPenColor (1.0, 1.00, 0)
		MOAIGfxDevice.setPenWidth(10.0)
		MOAIDraw.drawLine ( self.points )
	end
	MOAIGfxDevice.setPenColor ( unpack(self.color) )
	MOAIGfxDevice.setPenWidth( self.penWidth )
	MOAIDraw.drawLine ( self.points)
end

--	addPoint(x,y): Adds the next point to the stroke that is being drawn
function Stroke:addPoint(x,y)
	table.insert(self.points, x)
	table.insert(self.points, y)		
end

-- doneStroke(): Finishes off the stroke and passes it to the objects controller
function Stroke:doneStroke()
	
	-- Find the bounding rectangle of the points
	local minx,miny = 1E100,1E100
	local maxx,maxy = -1E100,-1E100
	for j=1,#self.points,2 do
		minx = math.min(minx,self.points[j])
		maxx = math.max(maxx,self.points[j])
		miny = math.min(miny,self.points[j+1])
		maxy = math.max(maxy,self.points[j+1])
	end
	
	self.deck:setRect (minx, miny, maxx, maxy)
	
	-- If anyone wants to keep this stroke around, they'll need to be responsible for adding it
	drawingLayer:removeProp(self.prop)
end


--cancel():	Cancel the drawing of the stroke	
function Stroke:cancel()
	drawingLayer:removeProp (self.prop)
end


--[[	TODO: saving/loading
function Stroke:propToSave()
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
--]]

function Stroke:correctedPointsAtCurrentTime()
	local corrected = {}
	for i=1,#self.points,2 do
		corrected[i],corrected[i+1] = self.prop:modelToWorld(self.points[i],self.points[i+1])
	end
	return corrected
end

function Stroke:correctedLocAtCurrentTime()
	return self.prop:modelToWorld(0,0)
end


return controllers.stroke