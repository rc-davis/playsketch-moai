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
require "basemodel/path"
require "basemodel/timelist"
require "util/util"


local allDrawables = {}
local allPaths = {}

function basemodel.allPaths()
	return allPaths
end

function basemodel.allDrawables()
	return allDrawables
end

function basemodel.addNewDrawable(prop, time, location)

	-- create the drawable (& add it to the scene graph)
	local drawable = basemodel.drawable.newFromProp(prop)
	table.insert(allDrawables, drawable)

	-- create a new path to contain its location
	local path = basemodel.createNewPath({drawable})
	
	-- set path to location
	path:addKeyframedMotion(time, 1, 0, location, nil, nil)

	-- set visibility to come on only at current time
	path:setVisibility(time, true)


	--get it to display properly:
	path:cacheAtTime(time)
	drawable:refreshPathProps()

	return drawable
end


function basemodel.addNewDrawables(propList, timeList, locationList)

	assert(#propList == #timeList and #propList == #locationList, 
		"addNewDrawables() requires three lists of the same length")

	local addedDrawables = {}
	for i=1,#propList do
		local newDrawable = basemodel.addNewDrawable(propList[i], timeList[i], locationList[i])
		table.insert(addedDrawables, newDrawable)
	end
	return addedDrawables
end


function basemodel.createNewPath(drawablesSet, index)

	if not index then index = #allPaths + 1 end
	assert(index <= #allPaths + 1, "path index must fall within the paths list")
	assert(#drawablesSet > 0, "createNewPath needs some drawables to apply to")

	local path = basemodel.path.newPath(index)
	table.insert(allPaths, index, path)

	--update the cached indices
	for i,p in ipairs(allPaths) do
		p.index = i
	end

	--inform the drawables
	for _,d in ipairs(drawablesSet) do
		d:addPath(path)
	end

	return path
end

function basemodel.swapPathOrder(index1, index2)

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
	table.insert(allPaths, index1, path2)
	table.remove(allPaths, index2)
	table.insert(allPaths, index2, path1)

	--update the cached indices
	for i,p in ipairs(allPaths) do
		p.index = i
	end

	--inform all the paths of the change
	for i,d in ipairs(allDrawables) do
		d:swapPathOrders(path1, path2)
	end

end



function basemodel.deleteDrawable(drawable)

	--tell it to remove itself
	drawable:delete()

	--remove it from our set
	util.tableDelete(allDrawables, drawable)
	
	--look for empty paths to delete
	local i=1
	while i <= #allPaths do
		if util.tableIsEmpty(allPaths[i]:allDrawables()) then
			allPaths[i]:delete()
			table.remove(allPaths, i)
		else
			i = i + 1
		end
	end
	
	--update the cached indices
	for i,p in ipairs(allPaths) do
		p.index = i
	end
	
end


function basemodel.deleteDrawables(drawablesList)
	assert(#drawablesList > 0, "list should contain some drawables")
	for d in pairs(drawablesList) do
		basemodel.deleteDrawable(d)
	end
end


--	todo: basemodel.drawablesVisibleAtTime(time) -> drawableList ??


return basemodel
