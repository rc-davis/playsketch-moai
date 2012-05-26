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
local indent = 0
local sections = {}

function startSection(msg)
	io.write("----------")			
	for i=1,indent do io.write("\t") end
	print("START: " .. msg)
	indent = indent + 1
	table.insert(sections, msg)
end

function endSection()
	io.write("----------")			
	for i=1,indent-1 do io.write("\t") end
	print("DONE: " .. sections[#sections])
	indent = indent - 1
	sections[#sections] = nil
end


function verify(stmt, msg)
	if not stmt then
		failureCount = failureCount + 1
		io.write("!!!FAIL!!!")			
	else
		successCount = successCount + 1
		io.write("   pass   ")
	end
	for i=1,indent do io.write("\t") end
	print(msg)	
end


print("Setting up environment")
drawingLayer = MOAILayer2D.new ()



print("Starting unit tests...")

-------------- Individual unit test files get imported here:

require "test/unittest/run_basemodel"

--------------- Print results
print("\n\nCompleted unit tests:")
print(failureCount, "\tFailures")
print(successCount, "\tSuccesses")

