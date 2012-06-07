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


function util.tableDelete(tab, valref)
	for i=1,#tab do
		if tab[i] == valref then
			table.remove(tab, i)
			return
		end
	end
end

-- this is necessary because #table doesn't work for associative tables
function util.tableIsEmpty(tab)
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

function util.dictionaryValuesToArray(dict)
	local newarray = {}
	for _,o in pairs(dict) do
		table.insert(newarray, o)
	end
	return newarray
end

function util.clone(t)
	local l = {}
	for i,v in pairs(t) do
		l[i] = v
	end
	return l
end

return util
