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

return util