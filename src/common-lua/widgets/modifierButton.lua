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

	widgets/modifierButton.lua
	
	A button to take the place of the shift key.
	
	Defaults to drawing mode, hold to get to select mode, 
	release with a selection, get to recording mode
	
--]]




function widgets.newModifierButton(centerX, centerY, width, height, 
									imgSelectPath, imgSelectDownPath,
									imgRecordPath, imgRecordDownPath,
									callbackStartSelect, callbackStopSelect,
									callbackStartRecord, callbackStopRecord)

	local states = {SELECT_UP=1, SELECT_DOWN=2, RECORD_UP=3, RECORD_DOWN=4}

	local modifier = {}

	--load graphics
	modifier.graphics = {}
	modifier.graphics[states.SELECT_UP] = MOAIGfxQuad2D.new ()
	modifier.graphics[states.SELECT_DOWN] = MOAIGfxQuad2D.new ()
	modifier.graphics[states.RECORD_UP] = MOAIGfxQuad2D.new ()
	modifier.graphics[states.RECORD_DOWN] = MOAIGfxQuad2D.new ()
	modifier.graphics[states.SELECT_UP]:setTexture(imgSelectPath)
	modifier.graphics[states.SELECT_DOWN]:setTexture(imgSelectDownPath)
	modifier.graphics[states.RECORD_UP]:setTexture(imgRecordPath)
	modifier.graphics[states.RECORD_DOWN]:setTexture(imgRecordDownPath)
	modifier.graphics[states.SELECT_UP]:setRect ( -width/2, -height/2, width/2, height/2 )
	modifier.graphics[states.SELECT_DOWN]:setRect ( -width/2, -height/2, width/2, height/2 )
	modifier.graphics[states.RECORD_UP]:setRect ( -width/2, -height/2, width/2, height/2 )
	modifier.graphics[states.RECORD_DOWN]:setRect ( -width/2, -height/2, width/2, height/2 )

	--create prop
	modifier.prop = MOAIProp2D.new ()
	modifier.prop:setLoc ( centerX, centerY )
	widgets.layer:insertProp (modifier.prop)	
	
	--store variables
	modifier.callbackStartSelect = callbackStartSelect
	modifier.callbackStopSelect = callbackStopSelect
	modifier.callbackStartRecord = callbackStartRecord
	modifier.callbackStopRecord = callbackStopRecord
	
	--register for touch callbacks
	input.manager.addDownCallback(input.manager.UILAYER, 
		function (id,px,py)
			if modifier.touchID == nil and modifier.prop:inside(px,py) then
				modifier.touchID = id
				if modifier.state == states.SELECT_UP then
					modifier:setState(states.SELECT_DOWN)
					return true
				elseif modifier.state == states.RECORD_UP then
					modifier:setState(states.RECORD_DOWN)
					return true
				elseif modifier.state == states.SELECT_DOWN then
					modifier:setState(states.SELECT_UP)
					return true
				elseif modifier.state == states.RECORD_DOWN then
					modifier:setState(states.RECORD_UP)
					return true
				end
			end
			return false
		end)

	input.manager.addUpCallback(input.manager.UILAYER, 
		function (id,px,py)
			if modifier.touchID ~= nil and id == modifier.touchID then
				modifier.touchID = nil
				
				-- On a touchscreen, you have to hold the button
				if MOAIInputMgr.device.touch then
					if modifier.state == states.SELECT_DOWN then
						modifier:setState(states.SELECT_UP)
						return true
					elseif modifier.state == states.RECORD_DOWN then
						modifier:setState(states.RECORD_UP)
						return true
					end
				end
				
			end
			return false			
		end)

	function modifier:setState(state)

		--callbacks for the state we are leaving
		if modifier.state == states.SELECT_DOWN and modifier.callbackStopSelect then
			modifier.callbackStopSelect()
		elseif modifier.state == states.RECORD_DOWN and modifier.callbackStopRecord then
			modifier.callbackStopRecord()
		end

		--update graphics
		modifier.state = state
		modifier.prop:setDeck(modifier.graphics[state])
		
		--callbacks for the state we are starting
		if state == states.SELECT_DOWN and modifier.callbackStartSelect then
			modifier.callbackStartSelect()
		elseif state == states.RECORD_DOWN and modifier.callbackStartRecord then
			modifier.callbackStartRecord()
		end
	end

	function modifier:setSelectionMode()
		self:setState(states.SELECT_UP)
	end
	function modifier:setRecordingMode()
		self:setState(states.RECORD_UP)
	end

	--set state
	modifier.state = nil
	modifier:setState(states.SELECT_UP)
	
	return modifier
end