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

	controllers/selection.lua

	The selection lasso and associated functionality.
	Uses a ray-casting algorithm for each point in the set of objects to see if it 
	crosses the lasso's lines.
	For efficiency, the points are tested only incrementally against each new segment of 
	the lasso.
	After a selection is made, the manipulator widget is displayed.
	
	--TODO: The logic for displaying the manipulator and responding	to it will 
	probably move out into an independent controller
	
--]]

require "model/model"
require "widgets/widgets"

controllers.selection = {}
controllers.selection.selectedSet = {}

-- create a single manipulator widget for controlling the selection
local manipulatorWidget = nil
local manipulatorWidgetThread = nil

-- startStroke(): begin a new selection lasso stroke
function controllers.selection.startStroke()

	local selection_stroke = controllers.drawing.startStroke()
	selection_stroke.color = {1, 1, 0}
	selection_stroke.penWidth = 10.0
	
	local last_x, last_y, first_x, first_y = nil,nil,nil,nil
	local crossing_counts = {}

	--cache the current pixel points for ALL objects 
	-- this might get expensive?
	local cached_points = {}
	local current_time = controllers.timeline.currentTime()
	for i,o in ipairs(model.all_objects) do
		cached_points[o] = o:getCorrectedPointsAtTime(current_time)
		o.isSelected = false
	end

	controllers.selection.clearSelection()


	--addPoint(x,y):	Add a point to the selection lasso.
	--					The line between the new point and the last point is tested for
	--					crossings with all points.
	--					We also test the line between the new point and the first point to
	--					close the loop.
	function selection_stroke:addPoint(x,y)

		table.insert(selection_stroke.points, x)
		table.insert(selection_stroke.points, y)
		
		if first_x == nil then
			first_x = x
			first_y = y
		end
		
		if last_x ~= nil then
		
			-- calculate m,b for y = mx+b between this and previous point to define a line
			local m,b,min_x,miny = nil,nil,nil,nil
			if last_x ~= x then --avoid inifinities
				m = (y - last_y) / (x - last_x)
				b = last_y - m*last_x
				min_x = math.min(x, last_x)
				max_x = math.max(x, last_x)
			end

			-- do the same for the inferred line back to the origin
			local im,ib,imin_x,iminy = nil,nil,nil,nil
			if first_x ~= x then --avoid inifinities
				im = (y - first_y) / (x - first_x)
				ib = first_y - im*first_x
				imin_x = math.min(x, first_x)
				imax_x = math.max(x, first_x)
			end
			
			-- update the crossing counts for all points
			local i = 0
			for o,points in pairs(cached_points) do -- go through all objects
				i = i + 1

				if crossing_counts[i] == nil then crossing_counts[i] = {} end

				local o_matches = false
				for j=1,#points,2 do --go through all points in the line
					
					if crossing_counts[i][j] == nil then crossing_counts[i][j] = 0 end
					
					local px = points[j]
					local py = points[j+1]
					
					if m ~= nil then					
						local hits = px >= min_x and px < max_x and (m*px+b) > py						
						if hits then 
							crossing_counts[i][j] = crossing_counts[i][j] + 1
						end
					end

					--test the inferred line back
					local inferred_count = 0
					if im ~= nil then
						local hits = px >= imin_x and px < imax_x and (im*px+ib) > py
						if hits then 
							inferred_count = 1
						end
					end

					o_matches = o_matches or ( (crossing_counts[i][j] + inferred_count)%2 == 1)
				
				end
				o.isSelected = o_matches
			end
		end
		
		last_x = x
		last_y = y
		
	end


	-- doneStroke(): 	For when the lasso is finished. 
	--					If the selected set contains objects, show the manipulator
	function selection_stroke:doneStroke()

		controllers.selection.selectedSet = {}
		for i,o in ipairs(model.all_objects) do
			if o.isSelected then 
				table.insert(controllers.selection.selectedSet, o)
			end
		end
		
		controllers.selection.showManipulator()
	end

	return selection_stroke
end


-- showManipulator(): Start a coroutine to keep the manipulator centered on the selected objects
function controllers.selection.showManipulator()
	
	assert(manipulatorWidgetThread == nil, "Don't call showManipulator() while it is already running")
	
	--create the manipulator widget if it doesn't exist
	if not manipulatorWidget then
		manipulatorWidget = widgets.newManipulator(
			function(dx,dy)
				for i,o in ipairs(controllers.selection.selectedSet) do
					local old_loc = o:getInterpolatedValueForTime(model.keys.LOCATION, controllers.timeline:currentTime())
					o:setValueForTime(model.keys.LOCATION, controllers.timeline:currentTime(), {x=old_loc.x+dx, y=old_loc.y+dy})
					o:setLoc(old_loc.x+dx, old_loc.y+dy)
				end
			end,

			nil -- TODO rotate callback

			)
	end

	-- selectionMain(): Loops as long as there are items in the selected set
	-- 					On each step, we center the manipulatorWidget	
	local function selectionMain()

		manipulatorWidget:show()

		while #controllers.selection.selectedSet > 0 do
		
			-- average the centers of all the objects
			local avgX,avgY = 0,0
			for i,o in ipairs(controllers.selection.selectedSet) do
				local x,y = o:getLoc()
				avgX = avgX + x
				avgY = avgY + y
			end
			avgX = avgX/#controllers.selection.selectedSet
			avgY = avgY/#controllers.selection.selectedSet			
		
			--ensure we are still on the screen
			avgX = math.min(WIDTH/2, math.max(-WIDTH/2, avgX))
			avgY = math.min(HEIGHT/2, math.max(-HEIGHT/2, avgY))
		
			--show it there
			manipulatorWidget:moveTo(avgX, avgY)
			
			coroutine.yield ()
		end
		controllers.selection.clearSelection()
	end
	
	manipulatorWidgetThread = MOAIThread.new ()
	manipulatorWidgetThread:run ( selectionMain, nil )

end

function controllers.selection.clearSelection()
	if manipulatorWidgetThread then
		manipulatorWidgetThread:stop()
		manipulatorWidgetThread = nil
	end
	if manipulatorWidget then manipulatorWidget:hide() end
	controllers.selection.selectedSet = {}

end

return controllers.selection
