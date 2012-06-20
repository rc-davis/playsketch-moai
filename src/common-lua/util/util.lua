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

	util/util.lua

	Random utilities
	
	- debugging.lua:	Debugging helpers
	- pickle.lua		writing tables to disk and loading them back up
	
	
--]]

util = {}

require "util/debugging"
require "util/pickle"


function util.tableDelete(tab, o)
	local index = util.indexOf(tab, o)
	if index then
		table.remove(tab, index)
		return index
	else
		return nil	
	end
end

function util.indexOf(tab, o)
	for i=1,#tab do
		if tab[i] == o then
			return i
		end
	end
	return nil
end

-- this is necessary because #table doesn't work for associative tables
function util.tableIsEmpty(tab)
	if not tab then return true end
	for _,_ in pairs(tab) do
		return false
	end
	return true
end

-- for getting the length of associative tables (urgh)
function util.tableCount(tab)
	local count = 0
	for _,_ in pairs(tab) do
		count = count + 1
	end
	return count
end

function util.anyItem(tab)
	for _,o in pairs(tab) do
		return o
	end
	return nil
end

function util.dictionaryValuesToArray(dict)
	local newarray = {}
	for _,o in pairs(dict) do
		table.insert(newarray, o)
	end
	return newarray
end

function util.clone(t)
	if type(t) ~= "table" then return t end
	local l = {}
	for i,v in pairs(t) do
		l[i] = v
	end
	return l
end

--predicate like: function(key,value) return true end
function util.any(tab, predicate)
	for k,v in pairs(tab) do
		if predicate(k,v) then return true end
	end
	return false
end

function util.interpolate(time, val1, time1, val2, time2)

	if not val1 and not val2 then
		return nil

	elseif val1 and not val2 then
		return val1

	elseif val2 and not val1 then
		return val2
		
	else -- we have both!
		assert(time1 and time2, "Need both times to interpolate")
		local pcnt = (time - time1)/(time2 - time1)	
	
		-- simple number interpolation
		if type(val1) == "number" then
			return val1*(1-pcnt) + val2*(pcnt)

		-- recursively attack tables
		elseif type(val1) == "table" then
			local result = {}
			for k,v in pairs(val1) do
				result[k] = util.interpolate(time, v, time1, val2[k], time2)
			end
			return result
		else
			assert(false, "Can't interpolate type: "..type(val1))
		end
	end
end

return util
