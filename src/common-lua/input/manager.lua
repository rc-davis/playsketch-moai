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

	input/manager.lua

	- Abstract away whether we have touches or mouses depending on platform
	- multiplex the input events from moai
	- to register for mouse events, use: add{Up,Down,Moved,Cancelled}Callback()
	- NOTE: Callbacks get called in the order of each layer they are on.
			A callback can return 'true' to say the event has been consumed and it will 
			not get passed on to any other callbacks.
--]]

input.manager = {}

input.manager.UILAYER = 1
input.manager.DRAWINGLAYER = 2


-- addDownCallback(layer,c): Has the form callback(touch_id, x, y)
function input.manager.addDownCallback(layer, c)
	input.manager.callbacks.down[layer] = input.manager.callbacks.down[layer] or {}
	table.insert(input.manager.callbacks.down[layer], c)
end


-- addUpCallback(layer,c): Has the form callback(touch_id, x, y)
function input.manager.addUpCallback(layer, c)
	input.manager.callbacks.up[layer] = input.manager.callbacks.up[layer] or {}
	table.insert(input.manager.callbacks.up[layer], c)
end


-- addMovedCallback(layer,c): Has the form callback(touch_id, x, y)
function input.manager.addMovedCallback(layer, c)
	input.manager.callbacks.moved[layer] = input.manager.callbacks.moved[layer] or {}
	table.insert(input.manager.callbacks.moved[layer], c)
end


-- addCancelledCallback(layer,c): Has the form callback()
function input.manager.addCancelledCallback(layer, c)
	input.manager.callbacks.cancelled[layer] = input.manager.callbacks.cancelled[layer] or {}
	table.insert(input.manager.callbacks.cancelled[layer], c)
end


-- Internal Callbacks for passing along input we've received
local function mouseClickCallbackInternal()
	x,y = drawingLayer:wndToWorld (MOAIInputMgr.device.pointer:getLoc ())
	if MOAIInputMgr.device.mouseLeft:down() then
		for i,l in ipairs({input.manager.UILAYER,input.manager.DRAWINGLAYER}) do
			for i=#input.manager.callbacks.down[l],1,-1 do
				if input.manager.callbacks.down[l][i](1, x, y) then return end
			end
	    end
	else -- mouseLeft is up
		for i,l in ipairs({input.manager.UILAYER,input.manager.DRAWINGLAYER}) do
			for i=#input.manager.callbacks.up[l],1,-1 do
				if input.manager.callbacks.up[l][i](1, x, y) then return end
		    end
	    end
	end
end

local function mouseMoveCallbackInternal()
	x,y = drawingLayer:wndToWorld (MOAIInputMgr.device.pointer:getLoc ())
	for i,l in ipairs({input.manager.UILAYER,input.manager.DRAWINGLAYER}) do
		for i=#input.manager.callbacks.moved[l],1,-1 do
			if input.manager.callbacks.moved[l][i](1, x, y) then return end
		end
	end
end

local function touchCallbackInternal( eventType, id, x_wnd, y_wnd, tapCount )
	
	x,y = drawingLayer:wndToWorld ( x_wnd, y_wnd  )

	if eventType == MOAITouchSensor.TOUCH_DOWN then
		for i,l in ipairs({input.manager.UILAYER,input.manager.DRAWINGLAYER}) do
			if input.manager.callbacks.down[l] then
				for i=#input.manager.callbacks.down[l],1,-1 do
					if input.manager.callbacks.down[l][i](id, x, y) then return end
				end
			end
	    end
	    	
	elseif eventType == MOAITouchSensor.TOUCH_UP  then
		for i,l in ipairs({input.manager.UILAYER,input.manager.DRAWINGLAYER}) do
			if input.manager.callbacks.up[l] then
				for i=#input.manager.callbacks.up[l],1,-1 do
					if input.manager.callbacks.up[l][i](id, x, y) then return end
				end
			end
	    end
	    
	elseif eventType == MOAITouchSensor.TOUCH_MOVE  then
		for i,l in ipairs({input.manager.UILAYER,input.manager.DRAWINGLAYER}) do
			if input.manager.callbacks.moved[l] then
				for i=#input.manager.callbacks.moved[l],1,-1 do
					if input.manager.callbacks.moved[l][i](id, x, y) then return end
				end
			end
		end
	elseif eventType == MOAITouchSensor.TOUCH_CANCEL then
		for i,l in ipairs({input.manager.UILAYER,input.manager.DRAWINGLAYER}) do
			if input.manager.callbacks.cancelled[l] then
				for i=#input.manager.callbacks.cancelled[l],1,-1 do
					if input.manager.callbacks.cancelled[l][i]() then return end
				end
			end
		end
	end

end

--Init the input manager! (this is called only once by 'require')
input.manager.callbacks = {}
input.manager.callbacks.down = {}
input.manager.callbacks.up = {}
input.manager.callbacks.moved = {}
input.manager.callbacks.cancelled = {}

-- Set up the moai callbacks for mouse and touch!

if MOAIInputMgr.device.mouseLeft and MOAIInputMgr.device.pointer then
	MOAIInputMgr.device.mouseLeft:setCallback(mouseClickCallbackInternal)
	MOAIInputMgr.device.pointer:setCallback(mouseMoveCallbackInternal)
elseif MOAIInputMgr.device.touch then
	MOAIInputMgr.device.touch:setCallback(touchCallbackInternal)
else
	assert(false, "No supported input devices found!")
end
