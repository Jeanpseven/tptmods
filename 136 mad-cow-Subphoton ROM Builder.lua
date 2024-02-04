--[[ Subphoton ROM Builder
02/11/2022 12:15PM
v2.7: Fixed unescape code again. \\\n correctly "escapes" to \\n
v2.6: Added string.split, oops.
v2.5: Fixed unescape code. \\n -> \n now works correctly (and is a little more user friendly).
      FilePrinter() now minimizes the console before opening.
      Escape now resumes the original pause like the cancel button.
      Added the keybind to the config so that it persists through updates.
v2.4: Added shortcuts inside the GUI.
      Cancel now resumes the original pause state as intended
v2.3: Settings are now saved if you use the script manager.
v2.2: Found a work around to the issue of needing to pause before using the GUI.
      sp_string now sends a null in the beginning of the string, since the printer can eat input during the first 4 frames.
      Updated code to use sim.partPropery over tpt.set_property
      Added a button and function to delete photon stacks before placing the new stack.
      Added a button to open the Printer Demo.
v2.1: Sorry, fixed the version numbering. v0.1->v1.0, v0.2->v2.0
v2.0: Added a GUI.
      Changed sp_string to only input strings and accepts x/y coords.
      Created sp_file for printing files.
      The script now correctly gets the mouse position when inside the zoom window without overwriting the global mousex/y values.
      Updated the documentation.
      Filehandles are now properly used and closed. Oops.
      Made the name less wordy. 'Subphoton Text Generator - User Edition' -> 'Subphoton ROM Builder'
v1.0: Initial Release.
--]]

--[[
This script builds Photon ROMs for id:2201761 from text, file, or the clipboard.
----------------------
--   Using the GUI  --
----------------------
~  Ctrl + Shift + B  ~
----------------------
To open the GUI, press Ctrl + Shift + B (default) or use this function: FilePrinter()
You can change this keybind using FilePrinterKeybind(key, ctrl, shift, alt)
where key is the letter and ctrl/shift/alt are true/false

Features:
    Import text from the clipboard, file, or by typing into the GUI.
    Can be opened via keybind. (default Ctrl+Shift+B)
    Automatically places the ROM into the printer.
    The GUI has a button to open the printer.
    Adds a [+] button to the printer save to open the GUI. (It's next to the clear button)
    Can delete the existing ROM and replace it with the new one.
    A lock button to save coordinates when the GUI is closed.
    Newlines and tabs can be entered with \n and \t respectively. \\n -> \n, \\\n -> \\n, etc.
    Settings are saved if you use the save manager.

Keyboard shortcuts inside the GUI:
    Shift+Enter: Inserts a newline(\n) to the text.
    Ctrl+Enter: Treats text as file.
    Ctrl+Shift+Enter: Imports the clipboard.
    Ctrl/Shift+clicking Import-as-file: Import without confirmation
    Ctrl/Shift+clicking Open-Printer: Opens without confirmation


--]]
-- Default keybind: Ctrl + Shift + B
-- Changing this won't change your keybind; use FilePrinterKeybind() (see below for syntax)
local kb_key   = "b"
local kb_ctrl  = true
local kb_shift = true
local kb_alt   = false

function FilePrinterKeybind(key, ctrl, shift, alt)
    if key==nil then
        print("The syntax is FilePrinterKeybind((char)key, (bool)ctrl, (bool)shift, (bool)alt)")
        return
    end
    kb_key = key:sub(1,1)
    kb_ctrl = ctrl
    kb_shift = shift
    kb_alt = alt
end
FilePrinterKeybind(kb_key, kb_ctrl, kb_shift, kb_alt)

--[[

----------------------
-- Scripting access --
----------------------
The photon stack will be placed at the mouse coords or the supplied x,y coords.
To print a string, use this function:
    sp_string(string, x, y)
To import a file, put them in the TPT install directory or supply the full path.
    sp_file(filename, x, y)

Ex:
    sp_string("foo bar")  -- this prints "foo bar"
    sp_string("foo\nbar")  -- this prints  "foo
                                            bar"  since \n is newline

    sp_file("foobar.txt") -- this prints the contents of the file 'foobar.txt' from the TPT directory.
    sp_file("text/foobar.txt") -- same as above, but demonstrating files can be in a folder in the TPT directory.
    sp_file("C:/Users/YOURNAME/somefolder/foobar.txt") -- same as above, but demonstrating an absolute path.
--]]
--  Windows users beware. Since windows directories are formatted like with backslashes C:\,
--  they cause issues with escape sequences (ie \n is newline, \t is tab, etc).
--  To avoid this issue in directory paths in scripts, you can use a string literal: [[ ]] ie:
--      sp_file([[C:\Users\YOURNAME\TPT\foobar.txt]])
--  The double brackets signify a string literal. Every character is taken literally
--  and not interpreted as an escape sequence. (\n is just \n, as opposed to a newline)
--  You DON'T need to do this in the GUI since user input is interpretted as a string literal already.
--
--  And if you needed it for something, photprop spawns a photon at the mouse or (x,y) with a given ctype.
--      photprop(ctype, x, y)
--


--[[
--------------------------------
-- How the bits are organized --
--------------------------------

Okay lets think
we want to print the string 1234567890 right?
Well it gets reversed first 0987654321 because of particle order.
Then we take the first 4 characters (0987) and put those into 1 photon
so we can encode each character and lshift them 7*position they need to be at
so ie if we have 00 0000000 0000000 0000000 0010100
we would end w/  00 0000000 0000000 0010100 0000000 and repeat this with the other characters
So we encode the first character in our 4 character string 0987 and end up with
      0       9       8       7
00 0110111 0111000 0111001 0110000
We continue doing this for the entire string to encode it while respecting particle order.

--]]


--[[ TODO
LOW    Feature    : Might not even be needed tbh. Make a "send raw" mode without any padding before/after the string.
NORMAL Improvement: Make the clipboard button greyout when no text
--]]

local SAVEID = 2201761

if DEBUGCLEAN then DEBUGCLEAN() end

function photprop(n,x,y) --local function create and place photons, optionally supply coords. Default is mouse x,y
    if (not x) and (not y) then
        x, y = sim.adjustCoords(tpt.mousex,tpt.mousey) -- corrects coords if in a zoom window.
    end
    local p=tpt.create(-1,-1,"phot") --spawn the particle out of bounds so we don't overwrite anything or have problems.
    sim.partProperty(p, sim.FIELD_X, x)
    sim.partProperty(p, sim.FIELD_Y, y)
    sim.partProperty(p, sim.FIELD_VX, 0)
    sim.partProperty(p, sim.FIELD_VY, 0)
    sim.partProperty(p, sim.FIELD_LIFE, 0)
    sim.partProperty(p, sim.FIELD_CTYPE, n)
end

local function fileExists(filename)
    local file = io.open(filename,"r")
	if file~=nil then
        file:close()
        return true
    else
        return false
    end
end

local function readFile(filename)
    local str={}
    local file = io.open(filename,"r")
	if file~=nil then --(verify it has a name and isn't just some weird error) verify the file exists
        -- Prints from file
        for i in file:lines() do --read the file into a string.
            table.insert(str,i)
        end
        file:close()
        -- print("FilePrinter: Found and printed file")
        return table.concat(str, "\n")
    else
        error(string.format("FilePrinter: File '%s' could not be found.", file))
    end
end

-- borrowed from script 146, who borrowed it from the internet
string.split = string.split or function(str, delimiter)
    if str==nil or str=='' or delimiter==nil then
        return nil
    end
    
    local result = {}
    for match in (str..delimiter):gmatch("(.-)"..delimiter) do
        table.insert(result, match)
    end
    return result
end

function sp_file(file, x, y) -- wrapper function for sp_string to print files
    sp_string(readFile(file), x, y)
end

function sp_string(file, x, y) -- Supply a string to print
    local paused = tpt.set_pause() == 1
    if not paused then
        -- for the record, tpt.set_pause(1) isn't enough to fix this.
        -- I'm not sure when scripts run during a frame, but this script requires pause to work consistently.
        error("FilePrinter: Can't print when unpaused.")
    end
    file = tostring(file or "")
    if (not x) and (not y) then
        x, y = sim.adjustCoords(tpt.mousex,tpt.mousey) -- corrects coords if in a zoom window.
    end

    if #file~=0 then
    -- photprop(67637280+2^29) --its 4 spaces, particle order makes it print last. If you want we could encode char(3) which is "end of text"
        photprop(2^29, x, y) --its a null,
        for i=0,math.floor((#file-1)/4),1 do --important note: "file" is the INPUT STRING. "str" is the WORKING STRING, as in what we do operations on.
            local n=0
            local strpos1,strpos2=#file-(i+1)*4+1,#file-(i+1)*4+4
            if (strpos1<=0) then strpos1=1 end --ugh, have a PSEUDO CODE DEMO string.sub(string, negative number,positive number) fails to work. quickfix: just sets the negative to the 1. Why did i complicate this.
            local str=string.reverse(string.sub(file,strpos1,strpos2))
            for j=4,1,-1 do
            n=n+bit.lshift(string.byte(str,j) or 10,7*(4-j)) --explained in notes at the end.
            end
            photprop(n+2^29, x, y) --places our photon basically. (and adds the 30th(29th?)bit)
        end
    photprop(558007562, x, y) --4 newlines to prep for new string
    photprop(2^29, x, y) --its a null,
    end
end

function deletePhotonStack(x, y)
    -- Deletes a photon stack at x,y
    for p in sim.parts() do
        if sim.partProperty(p, sim.FIELD_TYPE) == tpt.el.phot.id and sim.partProperty(p, sim.FIELD_X) == x and sim.partProperty(p, sim.FIELD_Y) == y then
            sim.partKill(p)
        end
    end
end

---------
-- GUI --
---------
local loadPresets, savePresets
local sx, sy = 0, 0
local w, h = 500, 20*5 + 4
local xi, yi = (gfx.WIDTH - w)/2, (gfx.HEIGHT - h)/2
local gui = Window:new(xi, yi, w, h)

local currentY = 10
local currentX = 10


local label_title = Label:new(currentX, currentY-4, nil, nil, "\x0F\xFF\xFD\x4FSubphoton ROM Builder")
label_title:size(tpt.textwidth(label_title:text()), 16)
currentX = currentX + 3 + select(1, label_title:size())
local btn_gotoprinter = Button:new(currentX, currentY-4, 16, 16, "\x0F\xAF\xC9\xFF\xEE\x80\x81")
btn_gotoprinter:size(tpt.textwidth(btn_gotoprinter:text())+6, 16)
btn_gotoprinter:position(w-select(1, btn_gotoprinter:size())-10, currentY)

currentX, currentY = 10, currentY + 18
local label_coords = Label:new(currentX, currentY, nil, nil, "Coordinates")
label_coords:size(tpt.textwidth(label_coords:text()), 16)
currentX = currentX + 3 + select(1, label_coords:size())
local textbox_x = Textbox:new(currentX, currentY, 27, 16)
currentX = currentX + 2 + select(1, textbox_x:size())
local textbox_y = Textbox:new(currentX, currentY, 27, 16)
currentX = currentX + 3 + select(1, textbox_y:size())
local checkbox_lockcoords = Checkbox:new(currentX, currentY, 16, 16)
currentX = currentX + 1 + select(1, checkbox_lockcoords:size())
local label_lockcoords = Label:new(currentX, currentY, nil, nil, "Lock")
label_lockcoords:size(tpt.textwidth(label_lockcoords:text()), 16)
currentX = currentX + 10 + select(1, checkbox_lockcoords:size())
local checkbox_preset = Checkbox:new(currentX, currentY, 16, 16)
checkbox_preset:visible(false)
checkbox_preset:checked(true)
currentX = currentX + 1 + select(1, checkbox_lockcoords:size())
local label_preset = Label:new(currentX, currentY, nil, nil, "\x0F\xF5\xB6\x14Autodetect ROM position")
label_preset:size(tpt.textwidth(label_preset:text()), 16)
label_preset:visible(false)

local label_deleteStack = Label:new(currentX, currentY, nil, nil, "\blAutodelete stack")
label_deleteStack:size(tpt.textwidth(label_deleteStack:text()), 16)
label_deleteStack:position(w-select(1, label_deleteStack:size())-10, currentY)
currentX = select(1, label_deleteStack:position()) - 17
local checkbox_deleteStack = Checkbox:new(currentX, currentY, 16, 16)

currentX, currentY = 10, currentY + 20
local textbox_input = Textbox:new(currentX, currentY, w-20, 16, "", [[Type one of the following: (The text you want. Use \n for newlines.) OR (A filename/filepath.)]])

currentX, currentY = 10, currentY + 20

local label_status = Label:new(currentX, currentY-1, nil, nil, "Status: ")
label_status:size(tpt.textwidth(label_status:text()), 16)
currentX = currentX + select(1, label_status:size())
local label_feedback = Label:new(currentX, currentY-1)


local function setFeedback(status, color)
    status = status or "Ok!"
    color = color or "\x0F\x48\xFE\x4B"
    local status = string.format("%s%s", color, status)
    label_feedback:text(status)
    label_feedback:size(tpt.textwidth(status),16)
end
setFeedback("Enter some text.", "\bg")


currentX, currentY = 0, currentY + 20
local btn_cancel = Button:new(currentX, currentY, w*3/7+1, 16, "Cancel")
currentX = currentX - 1 + select(1, btn_cancel:size())
local btn_clipboard = Button:new(currentX, currentY, w*4/7/3+1, 16, "Import clipboard")
currentX = currentX - 1 + select(1, btn_clipboard:size())
local btn_file = Button:new(currentX, currentY, w*4/7/3+1, 16, "Treat as file")
btn_file:enabled(false)
currentX = currentX - 1 + select(1, btn_file:size())
local btn_plaintext = Button:new(currentX, currentY, w*4/7/3+1, 16, "Treat as text")
btn_plaintext:enabled(false)




local xc,yc = btn_clipboard:position()
local wc,hc = btn_clipboard:size()
local btn_preview = Button:new(xc,yc, wc*2-1, hc, "Clipboard")
btn_preview:enabled(false)
local preview_mode = false
local preview_offset = 0
local MOD_CTRL, MOD_SHIFT = false, false

local wasPaused = false
local function gui_exit(sender)
    savePresets()
    interface.closeWindow(gui)
    tpt.set_console(0)
    if not wasPaused and (sender == btn_cancel or not checkbox_deleteStack:checked()) then
        tpt.set_pause(0)
    end
    preview_offset = 0
    preview_mode = false
    btn_preview:position(xc,yc)
    interface.dropTextInput()
end

btn_gotoprinter:action(function(sender)
    gui_exit(sender)
    sim.loadSave(SAVEID, (MOD_CTRL or MOD_SHIFT) and 1 or 0)
end)

checkbox_lockcoords:action(function(sender, checked)
    if checkbox_preset:visible() and checkbox_preset:checked() then
        sender:checked(true)
    elseif not checked then
        sx, sy = sim.adjustCoords(tpt.mousex, tpt.mousey)
        textbox_x:text(sx)
        textbox_y:text(sy)
    end
end)

btn_cancel:action(gui_exit)

local lookup = {
    -- ['\a'] = [[(\*)(\a)]],
    -- ['\b'] = [[(\*)(\b)]],
    ['\n'] = [[(\*)(\n)]],
    -- ['\r'] = [[(\*)(\r)]],
    ['\t'] = [[(\*)(\t)]]
}
local function unescape_string(str)
    -- As opposed to really unescaping a string (ie \\\\ -> \\),
    -- this "unescaped" strings in a more user friendly way.
    -- it just strips one backslash off an "escape sequence" ie \\\n -> \\n
    for unescaped, pattern in pairs(lookup) do
        str = str:gsub(pattern, function(backslashes, escaped)
            -- escaped will always have one \ ie \n
            -- backslashes will have 0 or more \'s
            
            -- to actually escape:
            -- local half = string.rep([[\]],math.floor(#backslashes/2))
            -- if #backslashes % 2 == 1 then -- ie \\t or \\\\t ; this will still be escaped
            --     return string.format("%s%s", half, escaped)
            -- else -- ie \t or \\\t -- this will be UNescaped
            --     return string.format("%s%s", half, unescaped)
            -- end
            
            local half = string.rep([[\]],#backslashes - 1)
            -- to actually escape, do: if #backslashes % 2 == 1 then
            if #backslashes > 0 then -- ie \\t or \\\\t ; this will still be escaped
                return string.format("%s%s", half, escaped)
            else -- ie \t or \\\t ; this will be UNescaped
                -- to actually escape, do: string.format("%s%s", half, unescaped)
                return unescaped
            end
        end)
    end
    return str
end

local queue = {str="", ready=false}
local function sp_proxy(str)

    if checkbox_deleteStack:checked() then
        deletePhotonStack(sx,sy)
        queue.str = str
        queue.ready = true
    else
        sp_string(str, sx, sy)
    end

    gui_exit()
end

local function eventhandler_textbox_input(sender)

    local changedStatus = false
    if fileExists(textbox_input:text()) then
        setFeedback("\xEE\x80\x93 Found a file!")
        btn_file:enabled(true)
        changedStatus = true
    else
        btn_file:enabled(false)
    end
    if #textbox_input:text() > 0 then
        btn_plaintext:enabled(true)
    else
        btn_plaintext:enabled(false)
        changedStatus = true
        setFeedback("Enter some text.", "\bg")
    end

    if not changedStatus then
        setFeedback()
    end

end

local function eventhandler_clipboard(sender)
    if btn_clipboard:enabled() then
        sp_proxy(tpt.get_clipboard())
    end
end

local function eventhandler_file(sender)
    if btn_file:enabled() then
        local noerr, str = pcall(readFile, textbox_input:text())
        if noerr and (sender ~= gui and (MOD_CTRL or MOD_SHIFT) or tpt.confirm("Import '"..textbox_input:text().."' ?", str)) then
            sp_proxy(str)
        end
    end
end
local function eventhandler_plaintext(sender)
    if btn_plaintext:enabled() then
        sp_proxy(unescape_string(textbox_input:text()))
    end
end
local function eventhandler_tryOkay()
    local sender = gui
    if MOD_CTRL and not MOD_SHIFT then
        -- Ctrl + Enter: try file input
        eventhandler_file(sender)
    elseif MOD_CTRL and MOD_SHIFT then
        -- Ctrl + Shift + Enter: try clipboard
        eventhandler_clipboard(sender)
    elseif not MOD_CTRL and MOD_SHIFT then
        -- Shift + Enter: Insert newline
        local str = textbox_input:text() .. [[\n]]
        if tpt.textwidth(str) < select(1, textbox_input:size()) - 8 then
            textbox_input:text(str)
            btn_plaintext:enabled(true)
        end
        eventhandler_textbox_input(sender)
    else
        -- Enter: Try submitting
        eventhandler_plaintext(sender)
    end
end

btn_clipboard:action(eventhandler_clipboard)
btn_file:action(eventhandler_file)
btn_plaintext:action(eventhandler_plaintext)
gui:onTryOkay(eventhandler_tryOkay)

textbox_input:onTextChanged(eventhandler_textbox_input)

textbox_x:onTextChanged(function(sender) -- prevent invalid inputs
    local n = tonumber(sender:text())
    if type(n) == 'number' and n >= 0 then
        sx = math.min(sim.XRES, math.max(0, n))
        sender:text(sx)
    elseif #sender:text() > 0 then -- it can be annoying not being able to backspace the last character
        sender:text(sx)
    end
end)

textbox_y:onTextChanged(function(sender) -- prevent invalid inputs
    local n = tonumber(sender:text())
    if type(n) == 'number' and n >= 0 then
        sy = math.min(sim.YRES, math.max(0, n))
        sender:text(sy)
    elseif #sender:text() > 0 then -- it can be annoying not being able to backspace the last character
        sender:text(sy)
    end
end)

local HOMEX, HOMEY = 424,364
checkbox_preset:action(function(sender, checked)
    if checked then
        checkbox_lockcoords:checked(true)
        sx, sy = HOMEX, HOMEY
        textbox_x:text(sx)
        textbox_y:text(sy)
    end
end)


gui:onTick(function()
    -- clipboard preview animation
    if preview_mode and preview_offset < hc-1 then
        preview_offset = math.min(hc-1, preview_offset + (3.33/(1+preview_offset/10)-1))
        btn_preview:position(xc,yc+preview_offset)
    elseif not preview_mode and preview_offset > 0 then
        preview_offset = math.max(0, preview_offset - (3.33/(1+preview_offset/10)-1))
        btn_preview:position(xc,yc+preview_offset)
    end
end)

local hover_clip = {}
hover_clip.x1, hover_clip.y1 = btn_clipboard:position()
hover_clip.x1, hover_clip.y1 = hover_clip.x1 + xi, hover_clip.y1 + yi
hover_clip.x2, hover_clip.y2 = btn_clipboard:size()
hover_clip.x2, hover_clip.y2 = hover_clip.x1 + hover_clip.x2, hover_clip.y1 + hover_clip.y2
gui:onMouseMove(function(x,y,dx,dy)
    if (x <= hover_clip.x2 and x >= hover_clip.x1 and y <= hover_clip.y2 and y >= hover_clip.y1) then
        local clipboard = tpt.get_clipboard()
        local newline = select(1, clipboard:find('\r?\n'))
        if newline~=nil then
            clipboard = clipboard:sub(1,newline-1) .. '...'
        end
        btn_preview:text(clipboard)
        preview_mode = true
    else
        preview_mode = false
    end
end)

local function guiKeyhook(key, scan, shift, ctrl, alt)
    MOD_CTRL, MOD_SHIFT = ctrl, shift
end
gui:onKeyPress(guiKeyhook)
gui:onKeyRelease(guiKeyhook)

gui:onTryExit(function() gui_exit(btn_cancel) end) -- work around so that we still unpause since user canceled

local GUIcountdown = 0
function FilePrinter()
    -- this is used later on tick_FilePrinter to open the GUI when appropriate
    GUIcountdown = 2
    wasPaused = tpt.set_pause() == 1
    if not wasPaused then
        tpt.set_pause(1)
    end
    tpt.set_console(0)
end


gui:addComponent(label_title)
gui:addComponent(btn_gotoprinter)

gui:addComponent(label_coords)
gui:addComponent(textbox_x)
gui:addComponent(textbox_y)
gui:addComponent(label_lockcoords)
gui:addComponent(checkbox_lockcoords)
gui:addComponent(checkbox_deleteStack)
gui:addComponent(label_deleteStack)
gui:addComponent(checkbox_preset)
gui:addComponent(label_preset)

gui:addComponent(textbox_input)
gui:addComponent(label_status)
gui:addComponent(label_feedback)

gui:addComponent(btn_preview)
gui:addComponent(btn_cancel)
gui:addComponent(btn_clipboard)
gui:addComponent(btn_file)
gui:addComponent(btn_plaintext)

-------------
-- Keyhook --
-------------

local function FilePrinterKeyhook(key, scan, rep, shift, ctrl, alt)
    if rep then
        return true
    end
    if key == string.byte(string.lower(kb_key)) and (shift==kb_shift) and (ctrl==kb_ctrl) and (alt==kb_alt) then
        FilePrinter()
        return false
    end
end



-----------
-- other --
-----------

-- Adds additional functionality to the printer save
local btn_printerSave = Button:new(374, 358, 9, 15, "\x0F\x48\xFE\x4F+")
btn_printerSave:visible(false)
btn_printerSave:action(function()
    FilePrinter()
end)

local printerSave = false
local function tick_FilePrinter()
    -- this adds the + button to the printer save and displays a message
    if (sim.getSaveID() == SAVEID) ~= printerSave then
        -- only run this code once when the state changes
        printerSave = not printerSave
        if printerSave then
            print("Click the \bo+\bw next to \boClear\bw to open the GUI.")
            print(string.format("Or press \bo%s%s%s%s\bw",
                  kb_ctrl and "Ctrl+" or "",
                  kb_alt and "Alt+" or "",
                  kb_shift and "Shift+" or "",
                  kb_key))
        end
        btn_printerSave:visible(printerSave)
    end

    -- A work around for printing text 1 frame AFTER deleting a photon stack
    if queue.ready then
        queue.ready = false
        sp_string(queue.str, sx, sy)
        if not wasPaused and checkbox_deleteStack:checked() then
            tpt.set_pause(0)
        end
    end

    -- a tick function that checks every frame whether the game is paused and if the GUI is queued to be opened. Allows us to pause BEFORE opening the GUI
    if GUIcountdown > 0 then
        GUIcountdown = GUIcountdown - 1
    end
    if GUIcountdown == 1 and tpt.set_pause() == 1 then
        interface.grabTextInput()
        if not checkbox_lockcoords:checked() then
            sx, sy = sim.adjustCoords(tpt.mousex, tpt.mousey)
            textbox_x:text(sx)
            textbox_y:text(sy)
        end

        if sim.getSaveID() == SAVEID then -- we're home, babie -3- (the printer save)
            -- We'll show a preset button to set the coords to the ROM input
            checkbox_preset:visible(true)
            label_preset:visible(true)
        else
            checkbox_preset:visible(false)
            label_preset:visible(false)
        end
        if checkbox_preset:visible() and checkbox_preset:checked() then
            checkbox_lockcoords:checked(true)
            sx, sy = HOMEX, HOMEY
            textbox_x:text(sx)
            textbox_y:text(sy)
        end

        interface.showWindow(gui)
    end


end

local function mouse_printerSave(x,y,button)
    if printerSave and x >= 374 and x <=374+9 and y >=358 and y <=358+15 then
        -- drop mouse clicks within the bounding box of the button
        FilePrinter()
        return false
    end
end


event.register(event.keypress, FilePrinterKeyhook)
event.register(event.tick,  tick_FilePrinter)
event.register(event.mousedown, mouse_printerSave)
interface.addComponent(btn_printerSave)

----------------------
-- Save / Load data --
----------------------
local tobool = {
    ["false"]=false, ["true"]=true,
      [false]=false,   [true]=true,
        ['0']=false,    ['1']=true,
          [0]=false,      [1]=true}

local IDENTIFIER = "TMC_PHOTON_ROM"
function savePresets()
    if MANAGER then
        MANAGER.savesetting(IDENTIFIER, "keybind", string.format("%s:%s:%s:%s", kb_key, kb_ctrl and 1 or 0, kb_shift and 1 or 0, kb_alt and 1 or 0))
        MANAGER.savesetting(IDENTIFIER, "lock", checkbox_lockcoords:checked())
        if checkbox_lockcoords:checked() then
            MANAGER.savesetting(IDENTIFIER, "x", sx)
            MANAGER.savesetting(IDENTIFIER, "y", sy)
        else
            MANAGER.delsetting(IDENTIFIER, "x")
            MANAGER.delsetting(IDENTIFIER, "y")
        end
        MANAGER.savesetting(IDENTIFIER, "autoselect", checkbox_preset:checked())
        MANAGER.savesetting(IDENTIFIER, "autodelete", checkbox_deleteStack:checked())
    end
end
function loadPresets()
    if MANAGER then
        if MANAGER.getsetting(IDENTIFIER, "keybind")~=nil then
            local k,c,s,a = unpack(MANAGER.getsetting(IDENTIFIER, "keybind"):split(':'))
            kb_key, kb_ctrl, kb_shift, kb_alt = k or kb_key, tobool[c] or kb_ctrl, tobool[s] or kb_shift, tobool[a] or kb_alt
        end
        checkbox_lockcoords:checked(tobool[MANAGER.getsetting(IDENTIFIER, "lock")])
        sx = tonumber(MANAGER.getsetting(IDENTIFIER, "x") or 0)
        textbox_x:text(sx)
        sy = tonumber(MANAGER.getsetting(IDENTIFIER, "y") or 0)
        textbox_y:text(sy)
        checkbox_preset:checked(tobool[MANAGER.getsetting(IDENTIFIER, "autoselect")])
        checkbox_deleteStack:checked(tobool[MANAGER.getsetting(IDENTIFIER, "autodelete")])
        savePresets()
    end
end

loadPresets()

function DEBUGCLEAN()
    event.unregister(event.keypress, FilePrinterKeyhook)
    event.unregister(event.tick,  tick_FilePrinter)
    event.unregister(event.mousedown, mouse_printerSave)
    interface.removeComponent(btn_printerSave)
end
