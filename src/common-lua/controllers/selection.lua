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

	When the selection changes, the interaction model is notified
	
--]]

require "widgets/widgets"

controllers.selection = {}

local _selectedSet = {} -- {stroke -> drawable} for easy lookups


-- startStroke(): begin a new selection lasso stroke
function controllers.selection.startStroke()

	controllers.selection.clearSelection()

	local selection_stroke = controllers.stroke.new()
	selection_stroke.color = {1, 1, 0}
	selection_stroke.penWidth = 10.0
	
	local last_x, last_y, first_x, first_y = nil,nil,nil,nil
	local crossing_counts = {}

	--cache the current pixel points for ALL objects 
	-- this might get expensive?
	local cached_points = {}
	for _,o in pairs(interactormodel.selectableDrawables(controllers.timeline.currentTime())) do
		cached_points[o] = o:correctedPointsAtCurrentTime()
		_selectedSet = {}
	end

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
				if o_matches then _selectedSet[o.stroke] = o end
			end
		end
		
		last_x = x
		last_y = y
		
	end


	-- doneStroke(): 	For when the lasso is finished. 
	function selection_stroke:doneStroke()
		ui.drawing.animationLayer:removeProp (self.prop)
		if util.tableIsEmpty(_selectedSet) then
			interactormodel.selectionCleared()
		else
			local fixedSet = util.dictionaryValuesToArray(_selectedSet)
			interactormodel.selectionMade(fixedSet)
		end
	end

	--cancel():	Cancel the drawing of the selection stroke	
	function selection_stroke:cancel()
		ui.drawing.animationLayer:removeProp (self.prop)
		controllers.selection.clearSelection()
	end

	return selection_stroke
end


function controllers.selection.setSelectedDrawables(drawablesList)
	_selectedSet = {}	
	for _,d in pairs(drawablesList) do
		_selectedSet[d.stroke] = d
	end
end

function controllers.selection.clearSelection()
	_selectedSet = {}
	interactormodel.selectionCleared()
end


function controllers.selection.isSelected(stroke)
	return _selectedSet[stroke] ~= nil
end

function controllers.selection.getSelectedDrawables()
	return util.dictionaryValuesToArray(_selectedSet)
end

function controllers.selection.selectionIsEmpty()
	return util.tableIsEmpty(_selectedSet)
end

return controllers.selection
