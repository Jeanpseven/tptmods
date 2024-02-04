-- Version: Unspeakable Crawling Sternum

local fonts, fontmatrix = nil, nil
if Texter then fonts, fontmatrix = Texter._Fonts, Texter._Fontmatrix end
Texter = {}
Texter._LastInput = {
	Str  = "",
	Args = "1, 3",
	Font = "7px",
	Mode = 0
}

------------------ User config zone -------------------
Texter.FONT_FOLDERS_TO_LOAD = {"TexterFonts", "scripts", "%."}   -- All file will be "dofile" under those foler name, the root dir must be written regex form %.
Texter.DISPLAY_MESSAGES     = false              -- Should show the startup message [true: show, false: don't show]
Texter.FONT_SEARCH_DEPTH    = 3                 -- How deep should texter search the font folder [0: only the root folder]
---------------- User config zone ends ----------------

function Texter.Init(register)
	Texter._Fontmatrix = fontmatrix or {}
	Texter._Fonts = fonts or {}
	-- Please don't let Texter too far away from font file :)
	local fontFiles = Texter.LoadAllFontsInFolder(".", Texter.FONT_FOLDERS_TO_LOAD, Texter.FONT_SEARCH_DEPTH)
	local msg = ""
	if(Texter._Fontmatrix ~= nil) then
		for fontName in pairs(Texter._Fontmatrix) do
			table.insert(Texter._Fonts, fontName)
		end
		msg = "Texter: "..#fontFiles.." font file(s) loaded, "..#Texter._Fonts.." font(s) available in total."
	else
		msg = "Texter: No font found."
	end
	if( Texter.DISPLAY_MESSAGES ) then
		tpt.log(msg)
	end
	if( register == nil or register == true ) then
		event.register(event.keypress, Texter._HotkeyHandler)
	end
end

-- Internal methods
function Texter._IsFolder(path)
	local _isFolder = false
	if(path ~= nil) then
		if( fs.isDirectory(path)  ) then
			_isFolder = true
		end
	end
	return _isFolder
end
function Texter._GetFontHeight(fontName)
	local height = 0
	if( Texter._Fontmatrix ~= nil and Texter._Fontmatrix[fontName] ~=nil and Texter._Fontmatrix[fontName].Height ~= nil  ) then
		height = Texter._Fontmatrix[fontName].Height
	else
		height = 7 -- 7 is a lucky number
	end
	return height
end
function Texter._Input(eventHandler, fonts, paramsText, strText, fontText, mode)
	local controlHeight = 17
	local MOD_CTRL, MOD_SHIFT
	if( paramsText == nil  ) then paramsText = "" end
	if( strText    == nil  ) then strText    = "" end
	if( fontText   == nil  ) then fontText   = "" end
	if( mode       == nil  ) then mode       = 0  end
	if( fonts      == nil  ) then fonts      = {} end
	
	local isContains = function(inTable, value)
		local isContain = false
		for i=1, #inTable do
			if( value == inTable[i]  ) then
				isContain = true
				break
			end
		end
		return isContain
	end
	
	local TexterWin     = Window:new(-1, -1, 500, 100)
	local paramsBox     = Textbox:new(10, controlHeight + 15, 150, controlHeight, paramsText, "ptype, hspc, vspc")
	local paramsLabel   = Label:new(11, 9, 130, controlHeight, "Element type and\nhorizontal/vertical spacing.")
	local modeBox       = Button:new(170, controlHeight + 15, 150, controlHeight, "No mode available")
	local modeLabel     = Label:new(171, 9, 150, controlHeight, "Font mode you want to use.")
	local stringBox     = Textbox:new(10, 57, 480, controlHeight, strText, "Input text to create under mouse. Use \\n for new line, \\\\n for \\n. Etc.")
	local fontBtn       = Button:new(330, controlHeight + 15, 150, controlHeight, "No font available")
	local fontLabel     = Label:new(331, 9, 150, controlHeight, "Select the font you want to use.")
	local cancelBtn     = Button:new(0, 83, 251, controlHeight, "Cancel")
    local terminate = function(sender)interface.closeWindow(TexterWin)end
	cancelBtn:action(terminate)
	local okayBtn = Button:new(250, 83, 250, controlHeight, "Okay")
    local function okayAction(sender)
			if( eventHandler ~= nil and type(eventHandler) == "function"  ) then
				-- Use event because I can't make things like tpt.input
				eventHandler(paramsBox:text(), stringBox:text(), fontBtn:text(), tonumber(modeBox:text()))
			end
			interface.closeWindow(TexterWin)
		end
	okayBtn:action(okayAction)
	if( mode >= 0 ) then
		modeBox:text(tostring(mode))
	end
	modeBox:action(
		function(sender)
			local input = tpt.input("Font mode", "The draw mode:\n0  Ignore all additional information\n+1 Keep the ptype in font\n+2 Keep the dcolor in font\nAdd your choices up then type in.")
			local mode = tonumber(input)
			if( mode~= nil and mode >= 0 )then
				sender:text(input)
			else
				sender:text("0")
			end
		end
	)
	if(#fonts > 0) then
		if( isContains(fonts, fontText)  ) then
			fontBtn:text(fontText)
		else
			fontBtn:text(fonts[1])
		end
		fontBtn:action(
			function(sender)
				local winX, winY = TexterWin:position()
				local btnX, btnY = fontBtn:position()
				local btnW, btnH = fontBtn:size()
				local listWin = Window:new(winX+btnX, winY+btnY-controlHeight*(#fonts-1)/2, btnW, (btnH-1)*#fonts)
				for i=1, #fonts do
					local optionBtn = Button:new(0, (btnH-1)*(i-1), btnW, btnH, fonts[i])
					optionBtn:action(
						function(sender)
							interface.closeWindow(listWin)
							fontBtn:text(optionBtn:text())
						end
					)
					listWin:addComponent(optionBtn)
				end
				listWin:onTryExit(function()interface.closeWindow(listWin)end)
				interface.showWindow(listWin)
			end
		)
	end

	local function guiKeyhook(key, scan, shift, ctrl, alt)
		MOD_CTRL, MOD_SHIFT = ctrl, shift
	end

	local function onTryOkay()
		local sender = TexterWin
		if not MOD_CTRL and MOD_SHIFT then
			-- Shift + Enter: Insert newline
			local str = stringBox:text() .. [[\n]]
			if tpt.textwidth(str) < select(1, stringBox:size()) - 8 then
				stringBox:text(str)
			end
		else
			-- Enter: submitting
			okayAction(sender)
		end
	end
	

	TexterWin:addComponent(cancelBtn)
	TexterWin:addComponent(okayBtn)
	TexterWin:addComponent(stringBox)
	TexterWin:addComponent(paramsBox)
	TexterWin:addComponent(paramsLabel)
	TexterWin:addComponent(modeBox)
	TexterWin:addComponent(modeLabel)
	TexterWin:addComponent(fontBtn)
	TexterWin:addComponent(fontLabel)
    TexterWin:onTryExit(terminate)
    TexterWin:onTryOkay(onTryOkay)
	TexterWin:onKeyPress(guiKeyhook)
	TexterWin:onKeyRelease(guiKeyhook)
	
	interface.showWindow(TexterWin)
end
local PATH_SEP = package.config:sub(1,1)
function Texter._FindAllFile(rootPath, foldersToLoad, depth)
	if(  rootPath == nil  ) then
		rootPath = "."
	end
	if(  depth == nil  ) then
		depth = 1
	end
	local files = {}
	local isTargetFolder = false
	for i, folderName in ipairs(foldersToLoad) do 
		if( string.match(rootPath, PATH_SEP.."?"..folderName.."$") ~= nil ) then
			isTargetFolder = true
			break
		end
	end
	if( isTargetFolder ) then  -- If not the folder we want, ignore it
		files = fs.list(rootPath)
	end
	
	-- Trim match array
	local index = 1 -- Lua fool
	for i=1, #files do
		if( files[index] == "Texter.lua" 
		  or string.match(files[index], "%.texterfont$") == nil
		  or Texter._IsFolder(rootPath..PATH_SEP..files[index]) ) then
			table.remove(files, index)
		else
			files[index] = rootPath..PATH_SEP..files[index] -- full path
			index = index + 1
		end
	end
	
	-- Check subs
	if(  depth > 0  ) then
		local subs = fs.list(rootPath)
		local subFiles = nil
		for i=1, #subs do
			if( Texter._IsFolder(rootPath..PATH_SEP..subs[i]) ) then
				subFiles = Texter._FindAllFile(rootPath..PATH_SEP..subs[i], foldersToLoad, depth - 1)
				Texter._AppendArray(files, subFiles)
			end
		end
	end
	return files
end
function Texter._AppendArray(oriArray, arrayToAppend) -- Append an array to the original array
	if(  oriArray~= nil and arrayToAppend ~= nil and #arrayToAppend>0  ) then
		for i=1, #arrayToAppend do
			table.insert(oriArray, arrayToAppend[i])
		end
	end
	return oriArray
end

-- Helper methods and handlers
-- function Texter._HotkeyHandler(key, keyNum, modifier, event) -- Hotkey handler
function Texter._HotkeyHandler(key, keyNum, rep, shift, ctrl, alt) -- Hotkey handler
	if( not rep and ctrl and not shift and not alt and key==116 ) then -- Ctrl + t
		-- Additional settings
		local ptype = elements[tpt.selectedl]
		if( ptype == nil  ) then
			ptype = 1 --"DUST"
		end
		-- Prompt
		Texter._Input(
			Texter._InputHandler,
			Texter._Fonts,
			elements.property(ptype, "Name")..", "..Texter._LastInput.Args,
			Texter._LastInput.Str,
			Texter._LastInput.Font,
			Texter._LastInput.Mode
		)
	end
end
function Texter._InputHandler(params, str, fontName, mode) -- Input handler
	local args = {}
	if( string.len(str) > 0  ) then
		Texter._LastInput.Str = str
		-- it just strips one backslash off the escape sequence for newline ie \\\n -> \\n
		-- same as in Subphoton GUI. See original for actual unescaping.
		str = str:gsub([[(\*)(\n)]], function(backslashes, escaped)
            -- escaped will always have one \ ie \n
            -- backslashes will have 0 or more \'s
            local half = string.rep([[\]],#backslashes - 1)
            -- to actually escape, do: if #backslashes % 2 == 1 then
            if #backslashes > 0 then -- ie \\t or \\\\t ; this will still be escaped
                return string.format("%s%s", half, escaped)
            else -- ie \t or \\\t ; this will be UNescaped
                return '\n'
            end
        end)
	end
	
	if( string.len(params) > 0  ) then Texter._LastInput.Args = string.gsub(params, "%s*[^,]*%s*,%s*(.*)", "%1") end
	local i=1
	for arg in string.gmatch(params, "%s*([^,]*)%s*,?") do
		args[i] = arg
		i = i+1
	end
	Texter._LastInput.Font = fontName
	Texter._LastInput.Mode = mode
	
	if( pcall(tpt.element, args[1]) == false  ) then
		args[1] = "DUST"
	end
    local mx, my = sim.adjustCoords(tpt.mousex, tpt.mousey)
	Texter.Tstr(str, mx, my, args[1], mode, args[2], args[3], fontName)
end

-- APIs
function Texter.LoadAllFontsInFolder(rootPath, foldersToLoad, depth) -- Load all fonts in target folder(s)
	local fonts = Texter._FindAllFile(rootPath, foldersToLoad, depth)
	if(  fonts ~= nil  ) then
		for i=1, #fonts do
			dofile(fonts[i])
		end
	end
	return fonts
end
function Texter.Tchar(char, x, y, ptype, mode, fontName) -- Draw a single character
	local mtx     = {}
	local letter  = {}
	local PTYPE_MASK  = 0xFF
	local DCOLOR_MASH = 0xFFFFFFFF
	local DCOLOR_OFFSET = 8
	local margin_L = 0 -- margin left
	local margin_R = 0 -- margin right
	local margin_T = 0 -- margin top
	-- if given font not available, use the first available one
	if( fontName == nil or Texter._Fontmatrix[fontName] == nil  ) then
		for font in pairs(Texter._Fontmatrix) do
			fontName = font
			break
		end
	end
	-- if still not available, break
	if( fontName == nil  ) then return 0 end
	
	-- get character data
	letter = Texter._Fontmatrix[fontName][char]
	if( letter == nil  ) then
		letter = Texter._Fontmatrix[fontName]["nil"]
	end
	if( letter == nil  ) then return 0 end -- ["nil"] not defined
	mtx = letter.Mtx
	if( mtx == nil  ) then mtx = {} end
	if( letter.Margin ~= nil  ) then
		if(letter.Margin.Left  ~= nil)then margin_L = letter.Margin.Left  end
		if(letter.Margin.Right ~= nil)then margin_R = letter.Margin.Right end
		if(letter.Margin.Top   ~= nil)then margin_T = letter.Margin.Top   end
	end
	
	local width  = 0
	for i=1, #mtx do --mtx height
		if(#mtx[i] > width)then width = #mtx[i] end
		for j=1, width do
			local particle = mtx[i][j]
			if( particle~=0  ) then
				local success = false
				local p = {}
				p.ptype  = bit.band(particle                , PTYPE_MASK )
				p.dcolor = bit.band(particle/2^DCOLOR_OFFSET, DCOLOR_MASH) -- bit.rshift can only handle 5 bits :(
				if( ptype == 0 or ptype == "0" ) then
					pcall(tpt.delete, x+j-1+margin_L, y+i-1+margin_T) 
				else
					-- mode 0 use the given type
					--     +1 use the font ptype only
					--     +2 use the font dcolor only
					if( bit.band(mode, 1) ~= 1 ) then
						p.ptype = ptype
					end
					-- tpt.log("particle is "..particle..", ptype is "..ptype..", to draw is "..p.ptype)-- debug
					pcall(tpt.create, x+j-1+margin_L, y+i-1+margin_T, p.ptype)
					if( bit.band(mode, 2) == 2 ) then -- Paint it even when failed to create. Because there might be existed particle
						-- tpt.log("Try to draw dcolor: "..p.dcolor.." ( 0x"..string.format("%X", p.dcolor).." )") --debug
						pcall(tpt.set_property, "dcolor", p.dcolor, x+j-1+margin_L, y+i-1+margin_T, 1, 1)
					end
				end
			end
		end
	end
	width = width + margin_L + margin_R
	return width
end
function Texter.Tstr(str, x, y, ptype, mode, hspacing, vspacing, fontName) -- Draw a string
	local ox    = 0
	local oy    = 0
	local oy    = 0
	local fontH = Texter._GetFontHeight(fontName)
	if( mode == nil  ) then
		mode = 0
	end
	if( hspacing == nil  ) then
		hspacing = 1
	end
	if( vspacing == nil  ) then
		vspacing = 3
	end
	for i=1,string.len(str) do
		if( string.sub(str, i, i) == "\n"  ) then
			oy = vspacing + oy + fontH
			ox = 0
		else
			ox = hspacing + ox + Texter.Tchar(string.sub(str, i, i), x+ox, y+oy, ptype, mode, fontName)
		end
	end
	return string.len(str)
end
function T(str, ptype, mode, hspc, vspc, fontName) -- Shortcut for better user experience
	if( ptype == nil  ) then
		ptype = elements[tpt.selectedl] -- elements.property(tpt.selectedl, "Name")
	end
	if( ptype == nil  ) then
		ptype = "DUST"
	end
	if( str == nil  ) then str = "" end
	local mx, my = sim.adjustCoords(tpt.mousex, tpt.mousey)
	Texter.Tstr(str, mx, my, ptype, mode, hspc, vspc, fontName)
	return string.len(str)
end

Texter.Init()
