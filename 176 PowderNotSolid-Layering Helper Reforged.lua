--== Layering Helper Reforged ==--
---- is a remake of "LuaMaster"'s Layering Helper Extended.
---- In it a lot of efforts have been made to condense the code,
---- as well as fixing the bind and exposing the function for opening the menu.

---- Usage:
--- # Ctrl+J (Default) to open the menu
--- # lhr_showWindow() in console to open the menu manually
--- ^ Not recommended as the cursor position might be messed up

--< Local Functions >--
local function testIsNumber(value) return tonumber(value) ~= nil end
local function testElement(element_type) if element_type == nil then return false, 0 end success, ret = pcall(tpt.element, element_type) if success and not testIsNumber(element_type) then return true, ret elseif success and testIsNumber(element_type) then return true, element_type end return false, 0 end

local names_setstring = ""
local names_nilstring = ""
function testExpression(str) -- what have I done
	if string.len(names_setstring) < 1 or string.len(names_nilstring) < 1 then
		local name_count = 0
		local string_buffer = ""
		local vstring_buffer = ""

		for name, tbl in pairs(tpt.el) do
			if name_count >= 5 then
				names_setstring = names_setstring .. string.format("%s = %s; ", string_buffer, vstring_buffer)
				names_nilstring = names_nilstring .. string.format("%s = %s; ", string_buffer, "nil" .. ((name_count > 1) and (string.rep(", nil", name_count * 2 - 1)) or ""))

				string_buffer = ""
				vstring_buffer = ""

				name_count = 0
			end

			local exists, elem_id = testElement(name)
			
			if exists then
				name = string.gsub(name, "%-", "")
				local lname, uname = string.lower(name), string.upper(name)

				string_buffer = string_buffer .. string.rep(", ", name_count > 0 and 1 or 0) .. lname .. ", " .. uname
				vstring_buffer = vstring_buffer .. string.rep(", ", name_count > 0 and 1 or 0) .. elem_id .. ", " .. elem_id
				
				name_count = name_count + 1
			end
		end
		
		if name_count > 0 then
			names_setstring = names_setstring .. string.format("local %s = %s; ", string_buffer, vstring_buffer)
			names_nilstring = names_nilstring .. string.format("%s = %s; ", string_buffer, "nil" .. ((name_count > 1) and (string.rep(", nil", name_count * 2 - 1)) or ""))
		end
		
		string_buffer = nil
		vstring_buffer = nil

		name_count = nil
	end

	local func = loadstring(names_setstring .. "local lresult = (" .. str .. "); " .. names_nilstring .. "return lresult")
	if func then
		local ret, err = func()
		
		if ret == nil and type(err) == "string" then
			return false, err
		end
		
		return true, ret
	end
	
	return false, nil
end

--< Local Variables >--
-- dont set these directly unless you are a wizard or something
local open_key_code = 106

local is_drawing = false
local pos1_x, pos1_y, pos2_x, pos2_y = 0, 0, 0, 0
local color_r, color_g, color_b, color_a = 161, 71, 194, 255

local option_do_lua 	= true
local option_no_overlap = false

--< GUI Components >--
local guiWindow = Window:new(-1, -1, 600, 400)
local guiComponents = {}

local function get_input(use_lua)
	if type(use_lua) ~= "boolean" then use_lua = true end
	local str = tpt.input()
	
	if option_do_lua and use_lua and string.len(str) > 0 then
		local success, result = testExpression(str)
		
		if success then
			if tostring(result) == "nil" then
				result = 0
			end

			return tostring(result)
		end
	end
	
	return str
end

guiComponents["Label"] = Label:new(0, 0, 600, 40, "Layering Helper Reforged")

guiComponents["Type_Set"] = Button:new(1 + 93 * 0, 40, 93, 26 / 2, "Set Types")
guiComponents["Type_Set"]:action(function() local str = get_input(false); if string.len(str) < 1 then return end for i = 1, 5 do guiComponents["Part" .. i .. "_Type"]:text(str) end end)
guiComponents["Type_Clear"] = Button:new(1 + 93 * 0, 40 + 26 / 2, 93, 26 / 2, "Clear Types")
guiComponents["Type_Clear"]:action(function() for i = 1, 5 do guiComponents["Part" .. i .. "_Type"]:text("") end end)

guiComponents["Life_Set"] = Button:new(1 + 93 * 1, 40, 93, 26 / 2, "Set Lifes")
guiComponents["Life_Set"]:action(function() local str = get_input(); if string.len(str) < 1 then return end for i = 1, 5 do guiComponents["Part" .. i .. "_Life"]:text(str) end end)
guiComponents["Life_Clear"] = Button:new(1 + 93 * 1, 40 + 26 / 2, 93, 26 / 2, "Clear Lifes")
guiComponents["Life_Clear"]:action(function() for i = 1, 5 do guiComponents["Part" .. i .. "_Life"]:text("") end end)

guiComponents["Ctype_Set"] = Button:new(1 + 93 * 2, 40, 93, 26 / 2, "Set Ctypes")
guiComponents["Ctype_Set"]:action(function() local str = get_input(); if string.len(str) < 1 then return end for i = 1, 5 do guiComponents["Part" .. i .. "_Ctype"]:text(str) end end)
guiComponents["Ctype_Clear"] = Button:new(1 + 93 * 2, 40 + 26 / 2, 93, 26 / 2, "Clear Ctypes")
guiComponents["Ctype_Clear"]:action(function() for i = 1, 5 do guiComponents["Part" .. i .. "_Ctype"]:text("") end end)

guiComponents["Temp_Set"] = Button:new(1 + 93 * 3, 40, 93, 26 / 2, "Set Temps")
guiComponents["Temp_Set"]:action(function() local str = get_input(); if string.len(str) < 1 then return end for i = 1, 5 do guiComponents["Part" .. i .. "_Temp"]:text(str) end end)
guiComponents["Temp_Clear"] = Button:new(1 + 93 * 3, 40 + 26 / 2, 93, 26 / 2, "Clear Temps")
guiComponents["Temp_Clear"]:action(function() for i = 1, 5 do guiComponents["Part" .. i .. "_Temp"]:text("") end end)

guiComponents["Tmp_Set"] = Button:new(1 + 93 * 4, 40, 93, 26 / 2, "Set Tmps")
guiComponents["Tmp_Set"]:action(function() local str = get_input(); if string.len(str) < 1 then return end for i = 1, 5 do guiComponents["Part" .. i .. "_Tmp"]:text(str) end end)
guiComponents["Tmp_Clear"] = Button:new(1 + 93 * 4, 40 + 26 / 2, 93, 26 / 2, "Clear Tmps")
guiComponents["Tmp_Clear"]:action(function() for i = 1, 5 do guiComponents["Part" .. i .. "_Tmp"]:text("") end end)

guiComponents["Tmp2_Set"] = Button:new(1 + 93 * 5, 40, 93, 26 / 2, "Set Tmp2s")
guiComponents["Tmp2_Set"]:action(function() local str = get_input(); if string.len(str) < 1 then return end for i = 1, 5 do guiComponents["Part" .. i .. "_Tmp2"]:text(str) end end)
guiComponents["Tmp2_Clear"] = Button:new(1 + 93 * 5, 40 + 26 / 2, 93, 26 / 2, "Clear Tmp2s")
guiComponents["Tmp2_Clear"]:action(function() for i = 1, 5 do guiComponents["Part" .. i .. "_Tmp2"]:text("") end end)

guiComponents["ClearButton"] = Button:new(1 + 93 * 6, 40, 40, 26, "Clear *")

for i = 1, 5 do
	guiComponents["Part" .. i .. "_Type"]	= Textbox:new(1 + 93 * 0, 40 + 26 * i, 93, 26, nil, "Part " .. i .. ": Type")
	guiComponents["Part" .. i .. "_Life"]	= Textbox:new(1 + 93 * 1, 40 + 26 * i, 93, 26, nil, "Part " .. i .. ": Life")
	guiComponents["Part" .. i .. "_Ctype"]	= Textbox:new(1 + 93 * 2, 40 + 26 * i, 93, 26, nil, "Part " .. i .. ": Ctype")
	guiComponents["Part" .. i .. "_Temp"]	= Textbox:new(1 + 93 * 3, 40 + 26 * i, 93, 26, nil, "Part " .. i .. ": Temp")
	guiComponents["Part" .. i .. "_Tmp"]	= Textbox:new(1 + 93 * 4, 40 + 26 * i, 93, 26, nil, "Part " .. i .. ": Tmp")
	guiComponents["Part" .. i .. "_Tmp2"]	= Textbox:new(1 + 93 * 5, 40 + 26 * i, 93, 26, nil, "Part " .. i .. ": Tmp2")
	guiComponents["Part" .. i .. "_ClearButton"] = Button:new(1 + 93 * 6, 40 + 26 * i, 40, 26, "Clear")
	guiComponents["Part" .. i .. "_ClearButton"]:action(function()
		guiComponents["Part" .. i .. "_Type"]:text("")
		guiComponents["Part" .. i .. "_Life"]:text("")
		guiComponents["Part" .. i .. "_Ctype"]:text("")
		guiComponents["Part" .. i .. "_Temp"]:text("")
		guiComponents["Part" .. i .. "_Tmp"]:text("")
		guiComponents["Part" .. i .. "_Tmp2"]:text("")
	end)
end

guiComponents["Label2"] = Label:new(0, 40 + 26 * 6, 600, 40, "Options")

guiComponents["doLuaToggle"] = Button:new(1, 40 * 2 + 26 * 6, 600 - 2, 26, "Do Lua: ON (Values will be evaluated by Lua on creation and in mass-set buttons)")
guiComponents["doLuaToggle"]:action(function() 
	option_do_lua = not option_do_lua
	
	if option_do_lua then 
		guiComponents["doLuaToggle"]:text("Do Lua: ON (Values will be evaluated by Lua on creation and in mass-set buttons)")
	else
		guiComponents["doLuaToggle"]:text("Do Lua: OFF (Values will be used as-is when creating parts)")
	end
end)

guiComponents["noOverlapToggle"] = Button:new(1, 40 * 2 + 26 * 7, 600 - 2, 26, "No Overlap: OFF (LHR will try to place things regardless of what is there)")
guiComponents["noOverlapToggle"]:action(function() 
	option_no_overlap = not option_no_overlap
	
	if option_no_overlap then 
		guiComponents["noOverlapToggle"]:text("No Overlap: ON (LHR only place parts somewhere if that place is empty)")
	else
		guiComponents["noOverlapToggle"]:text("No Overlap: OFF (LHR will try to place things regardless of what is there)")
	end
end)

guiComponents["TimesBox"]		= Textbox:new(1, 400 - 40 - 26, 600 - 2, 26, nil, "Times (def: 1)")
guiComponents["CreateButton"]	= Button:new((600 / 2) * 0 + 1, 400 - 40 - 1, 600 / 2, 40, "Create Parts")
guiComponents["CancelButton"]	= Button:new((600 / 2) * 1, 400 - 40 - 1, 600 / 2 - 1, 40, "Cancel")

local function makePart(x, y, data)
	local index = -1
	
	index = sim.partCreate(-3, x, y, data.type)
	if index >= 0 then
		for k, v in pairs(data) do
			if k ~= "type" then
				sim.partProperty(index, k, v)
			end
		end
	end
	
	return index >= 0
end

local function makeParts(x, y, datas)
	local valid_data = {}

	for i, data in ipairs(datas) do
		if makePart(x, y, data) then
			valid_data[#valid_data + 1] = data
		end
	end
	
	return valid_data
end

local function evaluateStr(value)
	if option_do_lua and string.len(value) > 0 and value ~= nil then
		local success, result = testExpression(value)
		
		if success then
			if tostring(result) == "nil" then
				result = 0
			end

			return tostring(result)
		end
	end
	
	return value
end 

local function collectPartDatas()
	local datas = {}
	local data = {}
	local tmpv = ""

	local ctype_exists, ctype_id = false, 0

	for _i = 1, 5 do
		local i = 6 - _i

		if guiComponents["Part" .. i .. "_Type"]:text() ~= "" then
			typeExists, typeIndex = testElement(guiComponents["Part" .. i .. "_Type"]:text())
			if typeExists then
				data = {type = typeIndex}
			
				tmpv = evaluateStr(guiComponents["Part" .. i .. "_Life"]:text())
				if testIsNumber(tmpv) then
					data.life = tmpv
				elseif tmpv ~= "" then
					print("part" .. i .. ": Life invalid!")
				end

				tmpv = evaluateStr(guiComponents["Part" .. i .. "_Ctype"]:text())
				ctype_exists, ctype_id = testElement(tmpv)
				if ctype_exists then
					data.ctype = ctype_id
				elseif tmpv ~= "" then
					print("part" .. i .. ": Ctype invalid!")
				end

				tmpv = evaluateStr(guiComponents["Part" .. i .. "_Temp"]:text())
				if testIsNumber(tmpv) then
					data.temp = tmpv
				elseif tmpv ~= "" then
					print("part" .. i .. ": Temp invalid!")
				end

				tmpv = evaluateStr(guiComponents["Part" .. i .. "_Tmp"]:text())
				if testIsNumber(tmpv) then
					data.tmp = tmpv
				elseif tmpv ~= "" then
					print("part" .. i .. ": Tmp invalid!")
				end

				tmpv = evaluateStr(guiComponents["Part" .. i .. "_Tmp2"]:text())
				if testIsNumber(tmpv) then
					data.tmp2 = tmpv
				elseif tmpv ~= "" then
					print("part" .. i .. ": Tmp2 invalid!")
				end

				datas[#datas + 1] = data
			else
				print("part" .. i .. ": Type invalid")
			end
		end
	end
	
	return datas
end

guiComponents["CreateButton"]:action(function()
	local times = 1

	local tmpv = guiComponents["TimesBox"]:text()
	if testIsNumber(tmpv) and tonumber(tmpv) >= 0 then
		times = tonumber(tmpv)
	end

	interface.closeWindow(guiWindow)
	
	local datas = collectPartDatas()
	if #datas > 0 then
		if pos1_x == pos2_x and pos1_y == pos2_y then
			if (option_no_overlap and sim.partID(x, y) == nil) or option_no_overlap == false then
				for _ = 1, times do
					datas = makeParts(pos2_x, pos2_y, datas)

					if #datas < 1 then return end
				end
			end
		else
			local x_start, x_end = pos1_x, pos2_x
			if pos2_x < pos1_x then x_start = pos2_x; x_end = pos1_x end

			local y_start, y_end = pos1_y, pos2_y
			if pos2_y < pos1_y then y_start = pos2_y; y_end = pos1_y end

			local width, height = x_end - x_start, y_end - y_start

			for x = x_start, x_end do
				for y = y_start, y_end do
					if (option_no_overlap and sim.partID(x, y) == nil) or option_no_overlap == false then
						for _ = 1, times do
							datas = makeParts(x, y, datas)

							if #datas < 1 then return print("[LHR] Creation ended early"), print("[LHR] It is possible the part limit was reached") end
						end
					end
				end
			end
		end
	end
end)

guiComponents["CancelButton"]:action(function()
	interface.closeWindow(guiWindow)
end)

guiComponents["ClearButton"]:action(function()
	for i = 1, 5 do
		guiComponents["Part" .. i .. "_Type"]:text("")
		guiComponents["Part" .. i .. "_Life"]:text("")
		guiComponents["Part" .. i .. "_Ctype"]:text("")
		guiComponents["Part" .. i .. "_Temp"]:text("")
		guiComponents["Part" .. i .. "_Tmp"]:text("")
		guiComponents["Part" .. i .. "_Tmp2"]:text("")
	end
end)

for _, component in pairs(guiComponents) do
	guiWindow:addComponent(component)
end

function lhr_showWindow() interface.showWindow(guiWindow) end

event.register(evt.tick, function()
	if is_drawing then
		if pos1_x == pos2_x or pos1_y == pos2_y then
			graphics.drawLine(pos1_x, pos1_y, pos2_x, pos2_y, color_r, color_g, color_b, color_a)
		else
			local dist_x, dist_y = math.abs(pos2_x - pos1_x) + 1, math.abs(pos2_y - pos1_y) + 1
			local chosen_x, chosen_y = (pos1_x < pos2_x and pos1_x or pos2_x), (pos1_y < pos2_y and pos1_y or pos2_y)
			
			graphics.drawRect(chosen_x, chosen_y, dist_x, dist_y, color_r, color_g, color_b, color_a)

			local txt = dist_x .. "x" .. dist_y
			local text_x, text_y = graphics.textSize(txt)

			if (text_x + 2) < dist_x and (text_y + 2) < dist_y then
				graphics.drawText(chosen_x + dist_x / 2 - text_x / 2 + 1, chosen_y + dist_y / 2 - text_y / 2 + 2, txt, color_r, color_g, color_b, color_a)
			end
		end
	end
end)

event.register(evt.mousemove, function(x, y, dx, dy)
	if is_drawing then
		pos2_x, pos2_y = sim.adjustCoords(tpt.mousex, tpt.mousey)
	end
end)

event.register(evt.keypress, function(key, _, _, _, ctrl)
	if key == open_key_code and ctrl and not is_drawing then
		pos1_x, pos1_y = sim.adjustCoords(tpt.mousex, tpt.mousey)
		pos2_x, pos2_y = sim.adjustCoords(tpt.mousex, tpt.mousey)

		is_drawing = true
	end
end)

event.register(evt.keyrelease, function(key, _, _, _, ctrl)
	if key == open_key_code and is_drawing then
		is_drawing = false
		pos2_x, pos2_y = sim.adjustCoords(tpt.mousex, tpt.mousey)

		lhr_showWindow()
	end
end)

print("LHR Ready.")
