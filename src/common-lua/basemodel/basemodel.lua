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

	basemodel/basemodel.lua
	
	The base-model stores the animations that we create.
	For a full description, see:
	https://github.com/richardcd73/playsketch2/wiki/Base-Model-Spec

--]]


basemodel = {}

basemodel.motionTypes = {SCALE=1, ROTATE=2, TRANSLATE=3, VISIBILITY=4}

require "basemodel/drawable"
require "basemodel/timelistNode"
require "basemodel/path"
require "basemodel/timelist"
require "util/util"
require "controllers/undo"


local allDrawables = {}
local allPaths = {}

function basemodel.allPaths()
	return allPaths
end

function basemodel.allDrawables()
	return allDrawables
end

function basemodel.addNewDrawable(stroke, time)

	controllers.undo.startGroup('New Drawable')

	-- create the drawable (& add it to the scene graph)
	local drawable = basemodel.drawable.newFromStroke(stroke)
	controllers.undo.addAction(	'Table Insert Drawable',
								function () allDrawables[#allDrawables] = nil end,
								function () table.insert(allDrawables, drawable) end )
	table.insert(allDrawables, drawable)

	-- Require that stroke have a centerPoint
	if stroke.centerPoint == nil then stroke.centerPoint = {x=0,y=0} end

	-- create a new path to contain its location
	local path = basemodel.createNewPath({drawable}, nil, time, false, stroke.centerPoint)
	
	-- set path to location
	path:addKeyframedMotion(time, 1, 0, {x=0,y=0}, nil, nil)

	-- set visibility to come on only at current time
	path:setVisibility(time, true)


	--get it to display properly:
	path:displayAtTime(time)

	controllers.undo.endGroup('New Drawable')

	return drawable
end


function basemodel.addNewDrawables(strokeList, timeList)

	controllers.undo.startGroup("New Drawables")

	assert(#strokeList == #timeList,
		"addNewDrawables() requires lists of the same length")

	local addedDrawables = {}
	for i=1,#strokeList do
		local newDrawable = basemodel.addNewDrawable(strokeList[i], timeList[i])
		table.insert(addedDrawables, newDrawable)
	end

	controllers.undo.endGroup("New Drawables")

	return addedDrawables
end


function basemodel.createNewPath(drawablesSet, index, time, defaultVisibility, centerPoint)

	assert( drawablesSet ~= nil and  time ~= nil and centerPoint ~= nil, 
		"basemodel.createNewPath requires drawables, time, and centerPoint")


	controllers.undo.startGroup("Create New Path")

	if not defaultVisibility then defaultVisibility = false end

	if not index then index = #allPaths + 1 end
	assert(index <= #allPaths + 1, "path index must fall within the paths list")
	assert(#drawablesSet > 0, "createNewPath needs some drawables to apply to")

	local path = basemodel.path.newPath(index, defaultVisibility, centerPoint)
	table.insert(allPaths, index, path)
	controllers.undo.addAction(	'Table Insert Path',
								function () table.remove(allPaths, index) end,
								function () table.insert(allPaths, index, path) end )

	-- add a neutral keyframe to anchor us at the current time
	path:addKeyframedMotion(time, 1.0, 0, {x=0,y=0}, nil, nil)

	--update the cached indices
	for i,p in ipairs(allPaths) do
		local oldIndex = p.index
		p.index = i
		controllers.undo.addAction(	'Update Cached Indices',
								function () p.index = oldIndex end,
								function () p.index = i end )
	end

	--inform the drawables
	for _,d in ipairs(drawablesSet) do
		d:addPath(path)
	end

	controllers.undo.endGroup("Create New Path")
	
	return path
end

function basemodel.swapPathOrder(index1, index2)

	controllers.undo.startGroup("Swap Path Order")
	
	assert(index1 > 0 and index1 <= #allPaths and index2 > 0 and index2 <= #allPaths,
		"swapPathOrder needs valid indices to allPaths")
		
	--order correctly
	if index1 > index2 then
		local temp = index1
		index1 = index2
		index2 = temp
	end

	local path1 = allPaths[index1]
	local path2 = allPaths[index2]
	
	--careful to get these operations in the right order so the indices still make sense
	table.remove(allPaths, index1)
	controllers.undo.addAction(	"Swap Path Table Op 1",
								function() table.insert(allPaths, index1, path1) end,
								function() table.remove(allPaths, index1) end )	
	
	table.insert(allPaths, index1, path2)
	controllers.undo.addAction(	"Swap Path Table Op 2",
								function() table.remove(allPaths, index1) end,
								function() table.insert(allPaths, index1, path2) end )

	table.remove(allPaths, index2)	
	controllers.undo.addAction(	"Swap Path Table Op 3",
								function() table.insert(allPaths, index2, path2) end,
								function() table.remove(allPaths, index2) end )	

	table.insert(allPaths, index2, path1)
	controllers.undo.addAction(	"Swap Path Table Op 1",
								function() table.remove(allPaths, index2) end,
								function() table.insert(allPaths, index2, path1) end )	
	

	--update the cached indices
	for i,p in ipairs(allPaths) do
		local oldIndex = p.index
		p.index = i
		controllers.undo.addAction(	"Update cached index",
									function() p.index = oldIndex end,
									function() p.index = i end )
	end

	--inform all the paths of the change
	for i,d in ipairs(allDrawables) do
		d:pathOrdersUpdated({path1, path2})
	end

	controllers.undo.endGroup("Swap Path Order")

end



function basemodel.deleteDrawable(drawable)

	controllers.undo.startGroup("Delete Drawable")

	--tell it to remove itself
	drawable:delete()

	--remove it from our set
	local oldIndex = util.tableDelete(allDrawables, drawable)
	controllers.undo.addAction(	"Delete from allDrawables",
								function() table.insert(allDrawables, oldIndex, drawable) end,
								function() util.tableDelete(allDrawables, drawable) end )



	
	--look for empty paths to delete
	local i=1
	while i <= #allPaths do
		if util.tableIsEmpty(allPaths[i]:allDrawables()) then
			local oldPath = allPaths[i]
			oldPath:delete()
			table.remove(allPaths, i)
			controllers.undo.addAction(	"Remove associated paths",
										function() table.insert(allPaths, i, oldPath) end,
										function() table.remove(allPaths, i) end )

		else
			i = i + 1
		end
	end
	
	--update the cached indices
	for i,p in ipairs(allPaths) do
		local oldIndex = p.index
		p.index = i
		controllers.undo.addAction(	"Update Cached Indices",
										function() p.index = oldIndex end,
										function() p.index = i end )
	end
	
	controllers.undo.endGroup("Delete Drawable")
	
end


function basemodel.deleteDrawables(drawablesList)

	controllers.undo.startGroup("Delete Drawables")

	assert(util.tableCount(drawablesList) > 0, "list should contain some drawables")

	for _,d in pairs(util.clone(drawablesList)) do
		basemodel.deleteDrawable(d)
	end
	
	controllers.undo.endGroup("Delete Drawables")
end


function basemodel.deletePath(path)

	controllers.undo.startGroup('Delete Path')

	-- remove path from all drawables
	for _,d in pairs(path:allDrawables()) do
		d:removePath(path)
	end
	
	-- delete path
	path:delete()
	
	-- remove from collections
	local oldIndex = util.tableDelete(allPaths, path)
	controllers.undo.addAction(	"Delete from allPaths",
								function() table.insert(allPaths, oldIndex, path) end,
								function() util.tableDelete(allPaths, path) end )

	controllers.undo.endGroup('Delete Path')

end


function basemodel.clearAll()

	controllers.undo.startGroup("Clear All")
	
	if util.tableCount(basemodel.allDrawables()) > 0 then 
		basemodel.deleteDrawables(basemodel.allDrawables())
	end
	
	controllers.undo.endGroup("Clear All")
end


--	todo: basemodel.drawablesVisibleAtTime(time) -> drawableList ??


return basemodel
