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

	main.lua

	The main entry point for the app.
	Loads the interface from a file in the interfaces/ directory.

--]]

require "ui/ui"
require "util/util"
require "controllers/controllers"
require "test/test"

-- Set up the infrastructure for our interface hierarchy
ui.init()



--LOAD AN INTERFACE HERE!
require "interactormodel/IM1-interactormodel" 
require "interfaces/IM1-interface" 


-------- MAIN LOOP
function main ()
	while true do		
		coroutine.yield ()
	end
end

thread = MOAIThread.new ()
thread:run ( main )

