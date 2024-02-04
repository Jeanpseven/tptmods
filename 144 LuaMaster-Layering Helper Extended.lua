--Internal Variables--
local mainX = 315 -- 7 * 45
local mainY = 160 -- 8 * 20

local bufferX = 5
local bufferY = 5

--Internal Functions--
local function testIsNumber(value)
	return tonumber(value) ~= nil 
end

local function testElement(_type)
	if _type == nil then return false, 0 end
	success, ret = pcall(tpt.element, _type)
	if success and not testIsNumber(_type) then
		return true, ret
	elseif success and testIsNumber(_type) then
		return true, _type
	end
	return false, 0
end

--Code--
local mainWindow = Window:new(-1, -1, mainX+bufferX*2, mainY+bufferY*4)
local components = {}

components['mainLabel'] = Label:new(bufferX, bufferY, mainX, 20, "Layering Helper Extended")

components['element1_Label'] = Label:new(bufferX, bufferY*2+20, 45, 20, "Element1")
components['element1_Element'] = Textbox:new(bufferX+45*1, bufferY*2+20, 45, 20, nil, "Type")
components['element1_Life'] = Textbox:new(bufferX+45*2, bufferY*2+20, 45, 20, nil, "Life")
components['element1_Ctype'] = Textbox:new(bufferX+45*3, bufferY*2+20, 45, 20, nil, "Ctype")
components['element1_Temp'] = Textbox:new(bufferX+45*4, bufferY*2+20, 45, 20, nil, "Temp")
components['element1_Tmp'] = Textbox:new(bufferX+45*5, bufferY*2+20, 45, 20, nil, "Tmp")
components['element1_Tmp2'] = Textbox:new(bufferX+45*6, bufferY*2+20, 45, 20, nil, "Tmp2")

components['element2_Label'] = Label:new(bufferX, bufferY*3+20*2, 45, 20, "Element2")
components['element2_Element'] = Textbox:new(bufferX+45*1, bufferY*3+20*2, 45, 20, nil, "Type")
components['element2_Life'] = Textbox:new(bufferX+45*2, bufferY*3+20*2, 45, 20, nil, "Life")
components['element2_Ctype'] = Textbox:new(bufferX+45*3, bufferY*3+20*2, 45, 20, nil, "Ctype")
components['element2_Temp'] = Textbox:new(bufferX+45*4, bufferY*3+20*2, 45, 20, nil, "Temp")
components['element2_Tmp'] = Textbox:new(bufferX+45*5, bufferY*3+20*2, 45, 20, nil, "Tmp")
components['element2_Tmp2'] = Textbox:new(bufferX+45*6, bufferY*3+20*2, 45, 20, nil, "Tmp2")

components['element3_Label'] = Label:new(bufferX, bufferY*4+20*3, 45, 20, "Element3")
components['element3_Element'] = Textbox:new(bufferX+45*1, bufferY*4+20*3, 45, 20, nil, "Type")
components['element3_Life'] = Textbox:new(bufferX+45*2, bufferY*4+20*3, 45, 20, nil, "Life")
components['element3_Ctype'] = Textbox:new(bufferX+45*3, bufferY*4+20*3, 45, 20, nil, "Ctype")
components['element3_Temp'] = Textbox:new(bufferX+45*4, bufferY*4+20*3, 45, 20, nil, "Temp")
components['element3_Tmp'] = Textbox:new(bufferX+45*5, bufferY*4+20*3, 45, 20, nil, "Tmp")
components['element3_Tmp2'] = Textbox:new(bufferX+45*6, bufferY*4+20*3, 45, 20, nil, "Tmp2")

components['element4_Label'] = Label:new(bufferX, bufferY*5+20*4, 45, 20, "Element4")
components['element4_Element'] = Textbox:new(bufferX+45*1, bufferY*5+20*4, 45, 20, nil, "Type")
components['element4_Life'] = Textbox:new(bufferX+45*2, bufferY*5+20*4, 45, 20, nil, "Life")
components['element4_Ctype'] = Textbox:new(bufferX+45*3, bufferY*5+20*4, 45, 20, nil, "Ctype")
components['element4_Temp'] = Textbox:new(bufferX+45*4, bufferY*5+20*4, 45, 20, nil, "Temp")
components['element4_Tmp'] = Textbox:new(bufferX+45*5, bufferY*5+20*4, 45, 20, nil, "Tmp")
components['element4_Tmp2'] = Textbox:new(bufferX+45*6, bufferY*5+20*4, 45, 20, nil, "Tmp2")

components['element5_Label'] = Label:new(bufferX, bufferY*6+20*5, 45, 20, "Element5")
components['element5_Element'] = Textbox:new(bufferX+45*1, bufferY*6+20*5, 45, 20, nil, "Type")
components['element5_Life'] = Textbox:new(bufferX+45*2, bufferY*6+20*5, 45, 20, nil, "Life")
components['element5_Ctype'] = Textbox:new(bufferX+45*3, bufferY*6+20*5, 45, 20, nil, "Ctype")
components['element5_Temp'] = Textbox:new(bufferX+45*4, bufferY*6+20*5, 45, 20, nil, "Temp")
components['element5_Tmp'] = Textbox:new(bufferX+45*5, bufferY*6+20*5, 45, 20, nil, "Tmp")
components['element5_Tmp2'] = Textbox:new(bufferX+45*6, bufferY*6+20*5, 45, 20, nil, "Tmp2")

components['TimesBox'] = Textbox:new(bufferX, bufferY*7+20*6, 35, 20, nil, "Times")
components['CreateButton'] = Button:new(bufferX+35, bufferY*7+20*6, 180, 20, "Create Elements")
components['CreateButton']:action(function()
	local times = 1
	if testIsNumber(components['TimesBox']:text()) then
		if tonumber(components['TimesBox']:text()) >= 0 then 
			times = tonumber(components['TimesBox']:text())
		end
	end
	
	interface.closeWindow(mainWindow)
	
	local x, y = sim.adjustCoords(tpt.mousex, tpt.mousey)
	local index = -1
	local _1, _2 = false, 0
	
	for _ = 1, times do
	if components['element5_Element']:text() ~= '' then
		elementExists, elementNumber = testElement(components['element5_Element']:text()) 
		if elementExists then
			index = sim.partCreate(-3, x, y, elementNumber)
			if index >= 0 then 
				if testIsNumber(components['element5_Life']:text()) then
					sim.partProperty(index, 'life', components['element5_Life']:text())
				elseif components['element5_Life']:text() ~= '' then
					print('element5: Life invalid!')
				end
				
				_1, _2 = testElement(components['element5_Ctype']:text())
				
				if _1 then
					sim.partProperty(index, 'ctype', _2)
				elseif components['element5_Ctype']:text() ~= '' then
					print('element5: Ctype invalid!')
				end
				
				if testIsNumber(components['element5_Temp']:text()) then
					sim.partProperty(index, 'temp', components['element5_Temp']:text())
				elseif components['element5_Temp']:text() ~= '' then
					print('element5: Temp invalid!')
				end
				
				if testIsNumber(components['element5_Tmp']:text()) then
					sim.partProperty(index, 'tmp', components['element5_Tmp']:text())
				elseif components['element5_Tmp']:text() ~= '' then
					print('element5: Tmp invalid!')
				end
				
				if testIsNumber(components['element5_Tmp2']:text()) then
					sim.partProperty(index, 'tmp2', components['element5_Tmp2']:text())
				elseif components['element5_Tmp2']:text() ~= '' then
					print('element5: Tmp2 invalid!')
				end
			else 
				print('element5: Element failed to be created')
			end
		else
			print('element5: Element invalid')
		end
		index = -1
	end
	
	if components['element4_Element']:text() ~= '' then
		elementExists, elementNumber = testElement(components['element4_Element']:text()) 
		if elementExists then
			index = sim.partCreate(-3, x, y, elementNumber)
			if index >= 0 then 
				if testIsNumber(components['element4_Life']:text()) then
					sim.partProperty(index, 'life', components['element4_Life']:text())
				elseif components['element4_Life']:text() ~= '' then
					print('element4: Life invalid!')
				end
				
				_1, _2 = testElement(components['element4_Ctype']:text())
				
				if _1 then
					sim.partProperty(index, 'ctype', _2)
				elseif components['element4_Ctype']:text() ~= '' then
					print('element4: Ctype invalid!')
				end
				
				if testIsNumber(components['element4_Temp']:text()) then
					sim.partProperty(index, 'temp', components['element4_Temp']:text())
				elseif components['element4_Temp']:text() ~= '' then
					print('element4: Temp invalid!')
				end
				
				if testIsNumber(components['element4_Tmp']:text()) then
					sim.partProperty(index, 'tmp', components['element4_Tmp']:text())
				elseif components['element4_Tmp']:text() ~= '' then
					print('element4: Tmp invalid!')
				end
				
				if testIsNumber(components['element4_Tmp2']:text()) then
					sim.partProperty(index, 'tmp2', components['element4_Tmp2']:text())
				elseif components['element4_Tmp2']:text() ~= '' then
					print('element4: Tmp2 invalid!')
				end
			else 
				print('element4: Element failed to be created')
			end
		else
			print('element4: Element invalid')
		end
		index = -1
	end
	
	if components['element3_Element']:text() ~= '' then
		elementExists, elementNumber = testElement(components['element3_Element']:text()) 
		if elementExists then
			index = sim.partCreate(-3, x, y, elementNumber)
			if index >= 0 then 
				if testIsNumber(components['element3_Life']:text()) then
					sim.partProperty(index, 'life', components['element3_Life']:text())
				elseif components['element3_Life']:text() ~= '' then
					print('element3: Life invalid!')
				end
				
				_1, _2 = testElement(components['element3_Ctype']:text())
				
				if _1 then
					sim.partProperty(index, 'ctype', _2)
				elseif components['element3_Ctype']:text() ~= '' then
					print('element3: Ctype invalid!')
				end
				
				if testIsNumber(components['element3_Temp']:text()) then
					sim.partProperty(index, 'temp', components['element3_Temp']:text())
				elseif components['element3_Temp']:text() ~= '' then
					print('element3: Temp invalid!')
				end
				
				if testIsNumber(components['element3_Tmp']:text()) then
					sim.partProperty(index, 'tmp', components['element3_Tmp']:text())
				elseif components['element3_Tmp']:text() ~= '' then
					print('element3: Tmp invalid!')
				end
				
				if testIsNumber(components['element3_Tmp2']:text()) then
					sim.partProperty(index, 'tmp2', components['element3_Tmp2']:text())
				elseif components['element3_Tmp2']:text() ~= '' then
					print('element3: Tmp2 invalid!')
				end
			else 
				print('element3: Element failed to be created')
			end
		else
			print('element3: Element invalid')
		end
		index = -1
	end
	
	if components['element2_Element']:text() ~= '' then
		elementExists, elementNumber = testElement(components['element2_Element']:text()) 
		if elementExists then
			index = sim.partCreate(-3, x, y, elementNumber)
			if index >= 0 then 
				if testIsNumber(components['element2_Life']:text()) then
					sim.partProperty(index, 'life', components['element2_Life']:text())
				elseif components['element2_Life']:text() ~= '' then
					print('element2: Life invalid!')
				end
				
				_1, _2 = testElement(components['element2_Ctype']:text())
				
				if _1 then
					sim.partProperty(index, 'ctype', _2)
				elseif components['element2_Ctype']:text() ~= '' then
					print('element2: Ctype invalid!')
				end
				
				if testIsNumber(components['element2_Temp']:text()) then
					sim.partProperty(index, 'temp', components['element2_Temp']:text())
				elseif components['element2_Temp']:text() ~= '' then
					print('element2: Temp invalid!')
				end
				
				if testIsNumber(components['element2_Tmp']:text()) then
					sim.partProperty(index, 'tmp', components['element2_Tmp']:text())
				elseif components['element2_Tmp']:text() ~= '' then
					print('element2: Tmp invalid!')
				end
				
				if testIsNumber(components['element2_Tmp2']:text()) then
					sim.partProperty(index, 'tmp2', components['element2_Tmp2']:text())
				elseif components['element2_Tmp2']:text() ~= '' then
					print('element2: Tmp2 invalid!')
				end
			else 
				print('element2: Element failed to be created')
			end
		else
			print('element2: Element invalid')
		end
		index = -1
	end
	
	if components['element1_Element']:text() ~= '' then
		elementExists, elementNumber = testElement(components['element1_Element']:text()) 
		if elementExists then
			index = sim.partCreate(-3, x, y, elementNumber)
			if index >= 0 then 
				if testIsNumber(components['element1_Life']:text()) then
					sim.partProperty(index, 'life', components['element1_Life']:text())
				elseif components['element1_Life']:text() ~= '' then
					print('element1: Life invalid!')
				end
				
				_1, _2 = testElement(components['element1_Ctype']:text())
				
				if _1 then
					sim.partProperty(index, 'ctype', _2)
				elseif components['element1_Ctype']:text() ~= '' then
					print('element1: Ctype invalid!')
				end
				
				if testIsNumber(components['element1_Temp']:text()) then
					sim.partProperty(index, 'temp', components['element1_Temp']:text())
				elseif components['element1_Temp']:text() ~= '' then
					print('element1: Temp invalid!')
				end
				
				if testIsNumber(components['element1_Tmp']:text()) then
					sim.partProperty(index, 'tmp', components['element1_Tmp']:text())
				elseif components['element1_Tmp']:text() ~= '' then
					print('element1: Tmp invalid!')
				end
				
				if testIsNumber(components['element1_Tmp2']:text()) then
					sim.partProperty(index, 'tmp2', components['element1_Tmp2']:text())
				elseif components['element1_Tmp2']:text() ~= '' then
					print('element1: Tmp2 invalid!')
				end
			else 
				print('element1: Element failed to be created')
			end
		else
			print('element1: Element invalid')
		end
		index = -1
	end
	end
end)

components['CancelButton'] = Button:new(bufferX+215, bufferY*7+20*6, 100, 20, "Cancel")
components['CancelButton']:action(function()
	interface.closeWindow(mainWindow)
end)

for _, component in pairs(components) do
	mainWindow:addComponent(component)
end
 
local function showWindowHook(key, nKey, modifier, event)
	if modifier==64 and key=="j" and event==1 then
		interface.showWindow(mainWindow)
	end
end

tpt.register_keypress(showWindowHook)
