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


widgets.modifierButton = {}
widgets.modifierButton.states = {SELECT_UP=1, SELECT_DOWN=2, RECORD_UP=3, RECORD_DOWN=4}


function widgets.modifierButton.init(centerX, centerY, width, height, 
									imgSelectPath, imgSelectDownPath,
									imgRecordPath, imgRecordDownPath,
									callbackStartSelect, callbackStopSelect,
									callbackStartRecord, callbackStopRecord)

	local states = widgets.modifierButton.states

	--load graphics
	widgets.modifierButton.graphics = {}
	widgets.modifierButton.graphics[states.SELECT_UP] = MOAIGfxQuad2D.new ()
	widgets.modifierButton.graphics[states.SELECT_DOWN] = MOAIGfxQuad2D.new ()
	widgets.modifierButton.graphics[states.RECORD_UP] = MOAIGfxQuad2D.new ()
	widgets.modifierButton.graphics[states.RECORD_DOWN] = MOAIGfxQuad2D.new ()
	widgets.modifierButton.graphics[states.SELECT_UP]:setTexture(imgSelectPath)
	widgets.modifierButton.graphics[states.SELECT_DOWN]:setTexture(imgSelectDownPath)
	widgets.modifierButton.graphics[states.RECORD_UP]:setTexture(imgRecordPath)
	widgets.modifierButton.graphics[states.RECORD_DOWN]:setTexture(imgRecordDownPath)
	widgets.modifierButton.graphics[states.SELECT_UP]:setRect ( -width/2, -height/2, width/2, height/2 )
	widgets.modifierButton.graphics[states.SELECT_DOWN]:setRect ( -width/2, -height/2, width/2, height/2 )
	widgets.modifierButton.graphics[states.RECORD_UP]:setRect ( -width/2, -height/2, width/2, height/2 )
	widgets.modifierButton.graphics[states.RECORD_DOWN]:setRect ( -width/2, -height/2, width/2, height/2 )

	--create prop
	widgets.modifierButton.prop = MOAIProp2D.new ()
	widgets.modifierButton.prop:setLoc ( centerX, centerY )
	widgets.layer:insertProp (widgets.modifierButton.prop)	
	
	--store variables
	widgets.modifierButton.callbackStartSelect = callbackStartSelect
	widgets.modifierButton.callbackStopSelect = callbackStopSelect
	widgets.modifierButton.callbackStartRecord = callbackStartRecord
	widgets.modifierButton.callbackStopRecord = callbackStopRecord
	
	--register for touch callbacks
	input.manager.addDownCallback(input.manager.UILAYER, 
		function (id,px,py)
			if widgets.modifierButton.touchID == nil and widgets.modifierButton.prop:inside(px,py) then
				widgets.modifierButton.touchID = id
				if widgets.modifierButton.state == states.SELECT_UP then
					widgets.modifierButton:setState(states.SELECT_DOWN)
					return true
				elseif widgets.modifierButton.state == states.RECORD_UP then
					widgets.modifierButton:setState(states.RECORD_DOWN)
					return true
				elseif widgets.modifierButton.state == states.SELECT_DOWN then
					widgets.modifierButton:setState(states.SELECT_UP)
					return true
				elseif widgets.modifierButton.state == states.RECORD_DOWN then
					widgets.modifierButton:setState(states.RECORD_UP)
					return true
				end
			end
			return false
		end)

	input.manager.addUpCallback(input.manager.UILAYER, 
		function (id,px,py)
			if widgets.modifierButton.touchID ~= nil and id == widgets.modifierButton.touchID then
				widgets.modifierButton.touchID = nil
				
				-- On a touchscreen, you have to hold the button
				if MOAIInputMgr.device.touch then
					if widgets.modifierButton.state == states.SELECT_DOWN then
						widgets.modifierButton:setState(states.SELECT_UP)
						return true
					elseif widgets.modifierButton.state == states.RECORD_DOWN then
						widgets.modifierButton:setState(states.RECORD_UP)
						return true
					end
				end
				
			end
			return false			
		end)

	function widgets.modifierButton:setState(state)

		--callbacks for the state we are leaving
		if widgets.modifierButton.state == states.SELECT_DOWN and widgets.modifierButton.callbackStopSelect then
			widgets.modifierButton.callbackStopSelect()
		elseif widgets.modifierButton.state == states.RECORD_DOWN and widgets.modifierButton.callbackStopRecord then
			widgets.modifierButton.callbackStopRecord()
		end

		--update graphics
		widgets.modifierButton.state = state
		widgets.modifierButton.prop:setDeck(widgets.modifierButton.graphics[state])
		
		--callbacks for the state we are starting
		if state == states.SELECT_DOWN and widgets.modifierButton.callbackStartSelect then
			widgets.modifierButton.callbackStartSelect()
		elseif state == states.RECORD_DOWN and widgets.modifierButton.callbackStartRecord then
			widgets.modifierButton.callbackStartRecord()
		end
	end

	function widgets.modifierButton:setSelectionMode()
		self:setState(states.SELECT_UP)
	end
	function widgets.modifierButton:setRecordingMode()
		self:setState(states.RECORD_UP)
	end

	--set state
	widgets.modifierButton.state = nil
	widgets.modifierButton:setState(states.SELECT_UP)
end