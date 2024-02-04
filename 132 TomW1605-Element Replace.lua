local mods = false
local zoom = false

local function keyfunc(key, keyCode, modifierKeys, event)
	local alt = bit.band(modifierKeys, 0x300) ~= 0
	if key=='r' and alt and mods==false and event==1 then
		mods = true
		return false
	elseif key=='r' and alt and mods==true and event==1 then
		mods = false
		return false
	end
	
	if keyCode==122 and event==1 then  -- key code 122 is the z key
		zoom = true
	elseif keyCode==122 and event==2 then
		zoom = false
	end
end

local function mousefunc(x, y, button, event, wheal)
	if mods and wheal==0 and x<sim.XRES and y<sim.YRES and not zoom then
		local x, y = sim.adjustCoords(x, y)

		local id = sim.partID(x,y)
		
		if id then
			local oldType = sim.partProperty(id,"type")
			
			local typeToReplace = "DEFAULT_PT_NONE";
			if button==1 then
				typeToReplace = tpt.selectedl
			elseif button==4 then
				typeToReplace = tpt.selectedr
			elseif button==2 then
				typeToReplace = tpt.selecteda
			end
			
			if string.match(typeToReplace, "_PT_") then
				for i in sim.parts() do
					local testType = sim.partProperty(i,"type")
				
					if testType==oldType then
						sim.partChangeType(i,elem[typeToReplace])
					end
		
				end
			end
		end
		return false
	end
end

local function display()
	if mods and tpt.hud()==1 then
		local width, height = gfx.textSize("[ELEMENT REPLACE MODE]")
		gfx.fillRect(12,27,width+7,height+5,0, 0, 0, 127)
		gfx.drawText(16,31,"[ELEMENT REPLACE MODE]",32, 216, 255, 191)
	end
end

tpt.register_keypress(keyfunc)
tpt.register_mouseclick(mousefunc)
tpt.register_step(display)
