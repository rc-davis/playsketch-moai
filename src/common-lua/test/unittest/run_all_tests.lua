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

	run_all_tests.lua
	
	Executes all unit tests.
	Must be run using the moai environment.
	
--]]

local failureCount = 0
local successCount = 0


function verify(stmt, msg)
	if not stmt then
		failureCount = failureCount + 1
		print("!! FAIL !!", msg)
	else
		successCount = successCount + 1
		print("\t", msg)
	end
end


print("Starting unit tests...")

-------------- Individual unit test files get imported here:



--------------- Print results
print("\n\nCompleted unit tests:")
print(failureCount, "\tFailures")
print(successCount, "\tSuccesses")

