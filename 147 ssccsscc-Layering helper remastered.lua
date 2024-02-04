------------------- Configuration -------------------
local rquiredAPIVersion = 2.42

local resizingGridSize = 30
local safeModeByDefault = true
-----------------------------------------------------
pcall(dofile,"scripts/ssccssccAPI.lua")
if not interface_s or interface_s.Version < rquiredAPIVersion then
  if tpt.confirm("Download and install file", "Layering Helper Remastered script is required (scripts/ssccssccAPI.lua) to run. Download it now?") then
    fs.makeDirectory("scripts")
    tpt.getscript(172, "scripts/ssccssccAPI.lua", 1, 0)
  else
    tpt.log("Layering Helper Remastered script is unavailable due to lack of required files.")
    return
  end
end
--=================================================================--
--                    CODE IS BELOW THIS LINE                      --
--=================================================================--
local DefaultTheme = interface_s.DefaultTheme
--local mouseEvents = interface_s.mouseEvents       --Only for 2.43+
--local mouseButtons = interface_s.mouseButtons     --
local mouseEvents = {
  Down = 1,
  Up = 2
}
local mouseButtons = {
    Left = 1,
    Middle = 2,
    Right = 3
}

local TransparentWindow = {}
TransparentWindow.BackColor = gfx.getHexColor(0,0,0,150)
TransparentWindow.UnfocusedBackColor = gfx.getHexColor(0,0,0,150)
TransparentWindow.BorderColor = gfx.getHexColor(255,255,255,150)
TransparentWindow.UnfocusedBorderColor = gfx.getHexColor(150,150,150,150)
TransparentWindow.HeaderColor = gfx.getHexColor(150,150,255,150)
TransparentWindow.UnfocusedHeaderColor = gfx.getHexColor(32,32,55,150)

local function round(n)
  return math.floor(n+0.5)
end
--==========================Zoom gfx============================--
local isZoomActive = false
local zoomPixelSize = -1
local zoomWidthInRealPixels = -1
local zoomRealPositionX = -1
local zoomRealPositionY = -1
local zoomWindowPositionX = -1
local zoomWindowPositionY = -1
local zoomWindowSize = -1
local function getZoomInfo()
  isZoomActive=false
  if sim.adjustCoords(sim.XRES-1,5)~=sim.XRES-1 then
    isZoomActive=true
    local x,y = sim.adjustCoords(sim.XRES-1,2)
    zoomRealPositionX = x
    zoomRealPositionY = y
    local i=sim.XRES-2
    while x==sim.adjustCoords(i,2) do
      i=i-1
    end
    zoomPixelSize = sim.XRES-i-1
    i=zoomPixelSize
    while sim.adjustCoords(sim.XRES-i,2)~=sim.XRES-i do
      i=i+zoomPixelSize
    end
    zoomWidthInRealPixels = (i-zoomPixelSize)/zoomPixelSize
    zoomRealPositionX=zoomRealPositionX-zoomWidthInRealPixels+1
    zoomWindowPositionX = sim.XRES-i+zoomPixelSize
    if tpt.version.jacob1s_mod~=nil then
      zoomWindowPositionY = 1
    else
      zoomWindowPositionY = 0
    end
    zoomWindowSize = zoomPixelSize*zoomWidthInRealPixels
  else
    if sim.adjustCoords(1,5)~=1 then
      isZoomActive=true
      local x,y = sim.adjustCoords(1,2)
      zoomRealPositionX = x
      zoomRealPositionY = y
      local i=2
      while x==sim.adjustCoords(i,2) do
        i=i+1
      end
      if tpt.version.jacob1s_mod~=nil then
        zoomPixelSize = i-1
      else
        zoomPixelSize = i
      end
      i=zoomPixelSize
      while sim.adjustCoords(i,2)~=i do
        i=i+zoomPixelSize
      end
      zoomWidthInRealPixels = (i-zoomPixelSize)/zoomPixelSize
      if tpt.version.jacob1s_mod~=nil then
        zoomWindowPositionX = 1
        zoomWindowPositionY = 1
      else
        zoomWindowPositionX = 0
        zoomWindowPositionY = 0
      end
      zoomWindowSize = zoomPixelSize*zoomWidthInRealPixels+1
    end
  end
end

local function CoordinatesToZoomWindow(x,y)
  return zoomWindowPositionX+(x-zoomRealPositionX)*zoomPixelSize,zoomWindowPositionY+(y-zoomRealPositionY)*zoomPixelSize
end

local function drawPixelInZoomWindow(x,y,r,g,b,a)
  if isZoomActive then
    x = round(x)
    y = round(y)
    if x>=zoomRealPositionX and x<zoomRealPositionX+zoomWidthInRealPixels and y>=zoomRealPositionY and y<zoomRealPositionY+zoomWidthInRealPixels then
      local posX,posY = CoordinatesToZoomWindow(x,y)
      graphics.fillRect(posX,posY,zoomPixelSize-1,zoomPixelSize-1,r,g,b,a)
    end
  end
end

local function drawRectangleInZoomWindow(x,y,w,h,r,g,b,a)
  if isZoomActive then
    local leftX = math.max(x,zoomRealPositionX)
    local rightX = math.min(x+w,zoomRealPositionX+zoomWidthInRealPixels)
    local topY = math.max(y,zoomRealPositionY)
    local bottomY = math.min(y+h,zoomRealPositionY+zoomWidthInRealPixels)
    if leftX < rightX and topY < bottomY then
      local posX,posY = CoordinatesToZoomWindow(leftX,topY)
      graphics.fillRect(posX,posY,(rightX-leftX)*(zoomPixelSize),(bottomY-topY)*(zoomPixelSize),r,g,b,a)
    end
  end
end
--==========================Zoom gfx end========================--

local function clone(org)
  local temp = {}
  for i=1, #org do
    temp[i]={}
    for k, v in pairs(org[i]) do
      temp[i][k]=v
    end
  end
  return temp
end

local function HSVToRGB( hue, saturation, value )
  if saturation == 0 then
    return value
  end
  local hue_sector = math.floor( hue / 60 )
  local hue_sector_offset = ( hue / 60 ) - hue_sector
  local p = value * ( 1 - saturation )
  local q = value * ( 1 - saturation * hue_sector_offset )
  local t = value * ( 1 - saturation * ( 1 - hue_sector_offset ) )
  if hue_sector == 0 then
    return value, t, p
  elseif hue_sector == 1 then
    return q, value, p
  elseif hue_sector == 2 then
    return p, value, t
  elseif hue_sector == 3 then
    return p, q, value
  elseif hue_sector == 4 then
    return t, p, value
  elseif hue_sector == 5 then
    return value, p, q
  end
end

function layer()
  Layer()
end

function Layer()
  tpt.log("Press \"Select\" to start.")
  local pause = false
  if tpt.set_pause() == 1 then
    pause = true
  end
  tpt.set_pause(1)

  local selectionMover = nil
  local selection = nil
  local particlesIndexes = {}
  local virtualParticles = {}
  local virtualParticlesbackup = {}
  local selectionMenu = nil

  local function resetVars()
    selectionMover = nil
    selection = nil
    particlesIndexes = {}
    virtualParticles = {}
    virtualParticlesbackup = {}
  end
  
  local rotateButton = interface_s.Components.Button:new(2, 2, 12, 12,"R", DefaultTheme.Button)
  local resizeButton = interface_s.Components.Button:new(15, 2, 12, 12,"S", DefaultTheme.Button)
  resizeButton.Enabled = not safeModeByDefault

  local startangle = 0
  local lastangle = 0
  local currentangle = 0
  local isfirst = true
  local info = interface_s.ComponentsHelpers.Hint:new()
  local ignoreClicks = false
  local safeMode = safeModeByDefault
  local layerMode = true

  local function copyPart(i,dx,dy,vx,vy)
    local props = {"life","ctype","temp","flags","tmp","tmp2","dcolour","pavg0","pavg1"}
    local t = sim.partProperty(i,"type")
    local ni = sim.partCreate(-3,dx,dy,t)
    sim.partProperty(ni,"vx",vx)
    sim.partProperty(ni,"vy",vy)
    for k,v in pairs(props) do
      sim.partProperty(ni,v,sim.partProperty(i,v))
    end
    return ni
  end

  local function getIndexUsageCount()
    local usageCount = {}
    for i=0, #virtualParticles do
      if virtualParticles[i]~=nil then
        usageCount[virtualParticles[i]["i"]] = (usageCount[virtualParticles[i]["i"]] or 0) + 1
      end
    end
    return usageCount
  end

  local function virtualParticlesToReal()
    sim.takeSnapshot()
    local usageCount = getIndexUsageCount()
    for i=1, #virtualParticles do
      if usageCount[virtualParticles[i]["i"]]==1 then
        sim.partPosition(virtualParticles[i]["i"],virtualParticles[i]["x"],virtualParticles[i]["y"])
        sim.partProperty(virtualParticles[i]["i"],"vx",virtualParticles[i]["vx"])
        sim.partProperty(virtualParticles[i]["i"],"vy",virtualParticles[i]["vy"])
      else
        local id = copyPart(virtualParticles[i]["i"],virtualParticles[i]["x"],virtualParticles[i]["y"],virtualParticles[i]["vx"],virtualParticles[i]["vy"])
        usageCount[id] = 1 -- Prevent part from delete if not in layer mode
      end
    end
    for i=1, #particlesIndexes do
      if usageCount[particlesIndexes[i]]~=1 then
        simulation.partKill(particlesIndexes[i])
      end
    end
    if not layerMode then
      local tempGrid = {}
      for i in sim.parts() do
        local cx,cy = sim.partPosition(i)
        cx,cy=round(cx),round(cy)
        if tempGrid[cx]==nil then tempGrid[cx]={} end
        if tempGrid[cx][cy]==nil then tempGrid[cx][cy]={} end
        tempGrid[cx][cy][#(tempGrid[cx][cy])+1]=i
      end
      for i=1, #virtualParticles do
        if tempGrid[virtualParticles[i]["x"]]~=nil and tempGrid[virtualParticles[i]["x"]][virtualParticles[i]["y"]]~=nil then
          for j=1,#tempGrid[virtualParticles[i]["x"]][virtualParticles[i]["y"]] do
            if usageCount[tempGrid[virtualParticles[i]["x"]][virtualParticles[i]["y"]][j]]==nil or usageCount[tempGrid[virtualParticles[i]["x"]][virtualParticles[i]["y"]][j]]==0 then
              sim.partKill(tempGrid[virtualParticles[i]["x"]][virtualParticles[i]["y"]][j])
            end
          end
        end
      end
    end
  end

  local hue = 0

  local function drawOverOriginal()
    for i=1, #particlesIndexes do
      local r,g,b = HSVToRGB(hue,1,190)
      local cx,cy = sim.partPosition(particlesIndexes[i])
      if cx==nil or cy==nil then
        return
      end
      if not isZoomActive or not (cx>=zoomWindowPositionX and cx<=zoomWindowPositionX+zoomWindowSize and cy>=zoomWindowPositionY and cy<=zoomWindowPositionY+zoomWindowSize) then
        graphics.fillRect(cx,cy,1,1,r,g,b,170)
      end
      drawPixelInZoomWindow(cx,cy,r,g,b,170)
    end
  end

  local function drawVirtualParticles()
    getZoomInfo()
    for i=1, #virtualParticles do
      local r,g,b = HSVToRGB(hue,1,190)
      if not isZoomActive or not (virtualParticles[i]["x"]>=zoomWindowPositionX and virtualParticles[i]["x"]<=zoomWindowPositionX+zoomWindowSize and virtualParticles[i]["y"]>=zoomWindowPositionY and virtualParticles[i]["y"]<=zoomWindowPositionY+zoomWindowSize) then
        graphics.fillRect(virtualParticles[i]["x"],virtualParticles[i]["y"],1,1,r,g,b,170)
      end
      drawPixelInZoomWindow(virtualParticles[i]["x"],virtualParticles[i]["y"],r,g,b,170)
    end
    drawOverOriginal()
    hue = hue+1
    if hue>359 then
      hue=0
    end
  end

  local function saveToVirtual()
    virtualParticles = {}
    for i=1, #particlesIndexes do
      local cx,cy = sim.partPosition(particlesIndexes[i])
      virtualParticles[i]={}
      if selectionMover~=nil then
        virtualParticles[i]["x"] = cx+selectionMover.SumDX
        virtualParticles[i]["y"] = cy+selectionMover.SumDY
      else
        virtualParticles[i]["x"] = cx
        virtualParticles[i]["y"] = cy
      end
      virtualParticles[i]["i"]=particlesIndexes[i]
      virtualParticles[i]["vx"] = sim.partProperty(particlesIndexes[i], "vx") or 0
      virtualParticles[i]["vy"] = sim.partProperty(particlesIndexes[i], "vy") or 0
    end
  end

  local function adjustSelection()
    local maxX = 0
    local maxY = 0
    for i=1, #virtualParticles do
      if virtualParticles[i]~=nil then
        if maxX<virtualParticles[i]["x"] then maxX=virtualParticles[i]["x"] end
        if maxY<virtualParticles[i]["y"] then maxY=virtualParticles[i]["y"] end
      end
    end
    selectionMover.Height = maxY-selectionMover.Y+10
    selectionMover.Width = maxX-selectionMover.X+10
    selectionMenu.X=selectionMover.X+selectionMover.Width
  end

  --==========================Rotation============================--

  local virtualParticlesGrid = {}

  local function toTempGrid()
    virtualParticlesGrid = {}
    for i=1, #virtualParticles do
      local cx,cy=round(virtualParticles[i]["x"]),round(virtualParticles[i]["y"])
      if virtualParticlesGrid[cx]==nil then virtualParticlesGrid[cx]={} end
      if virtualParticlesGrid[cx][cy]==nil then virtualParticlesGrid[cx][cy]={} end
      virtualParticlesGrid[cx][cy][#(virtualParticlesGrid[cx][cy])+1] = {}
      virtualParticlesGrid[cx][cy][#(virtualParticlesGrid[cx][cy])]["i"] = virtualParticles[i]["i"]
      virtualParticlesGrid[cx][cy][#(virtualParticlesGrid[cx][cy])]["vx"] = virtualParticles[i]["vx"]
      virtualParticlesGrid[cx][cy][#(virtualParticlesGrid[cx][cy])]["vy"] = virtualParticles[i]["vy"]
    end
  end

  local function rot(a)
    if safeMode then
      for i=1, #virtualParticles do
        local cx = virtualParticles[i]["x"]
        local cy = virtualParticles[i]["y"]
        cx=cx-selectionMover.X-selectionMover.Width/2
        cy=cy-selectionMover.Y-selectionMover.Height/2
        local cx2 = cx
        cx = -cy*math.sin(math.rad(a))+cx*math.cos(math.rad(a))
        cy = cy*math.cos(math.rad(a))+cx2*math.sin(math.rad(a))
        cx=cx+selectionMover.X+selectionMover.Width/2
        cy=cy+selectionMover.Y+selectionMover.Height/2
        virtualParticles[i]["x"] = cx
        virtualParticles[i]["y"] = cy
        local vx = virtualParticles[i]["vx"]
        local vy = virtualParticles[i]["vy"]
        local vx2 = vx
        vx = -vy*math.sin(math.rad(a))+vx*math.cos(math.rad(a))
        vy = vy*math.cos(math.rad(a))+vx2*math.sin(math.rad(a))
        virtualParticles[i]["vx"] = vx
        virtualParticles[i]["vy"] = vy
      end
    else
      local minX, maxX, minY, maxY = 0, 0, 0, 0
      for i=1, #virtualParticlesbackup do
        local cx = virtualParticlesbackup[i]["x"]
        local cy = virtualParticlesbackup[i]["y"]
        cx=cx-selectionMover.X-selectionMover.Width/2
        cy=cy-selectionMover.Y-selectionMover.Height/2
        local cx2 = cx
        cx = round(-cy*math.sin(math.rad(-currentangle))+cx*math.cos(math.rad(-currentangle)))
        if minX>cx then minX = cx end
        if maxX<cx then maxX = cx end
        cy = round(cy*math.cos(math.rad(-currentangle))+cx2*math.sin(math.rad(-currentangle)))
        if minY>cy then minY = cy end
        if maxY<cy then maxY = cy end
      end
      minX = minX-2
      maxX = maxX+2
      minY = minY-2
      maxY = maxY+2
      virtualParticles={}
      for x=minX,maxX do
        for y=minY,maxY do
          local x2=x+selectionMover.X+selectionMover.Width/2
          local y2=y+selectionMover.Y+selectionMover.Height/2
          x2 = round(x2)
          y2 = round(y2)
          local cx = -y*math.sin(math.rad(currentangle))+x*math.cos(math.rad(currentangle))
          local cy = y*math.cos(math.rad(currentangle))+x*math.sin(math.rad(currentangle))
          cx=cx+selectionMover.X+selectionMover.Width/2
          cy=cy+selectionMover.Y+selectionMover.Height/2
          cx = round(cx)
          cy = round(cy)
          if virtualParticlesGrid[cx]~=nil and virtualParticlesGrid[cx][cy]~=nil then
            for i=1,#virtualParticlesGrid[cx][cy] do
              virtualParticles[#virtualParticles+1]={}
              virtualParticles[#virtualParticles]["x"]=x2
              virtualParticles[#virtualParticles]["y"]=y2
              virtualParticles[#virtualParticles]["i"]=virtualParticlesGrid[cx][cy][i]["i"]
              local vx = virtualParticlesGrid[cx][cy][i]["vx"]
              local vy = virtualParticlesGrid[cx][cy][i]["vy"]
              local vx2 = vx
              vx = -vy*math.sin(math.rad(-currentangle))+vx*math.cos(math.rad(-currentangle))
              vy = vy*math.cos(math.rad(-currentangle))+vx2*math.sin(math.rad(-currentangle))
              virtualParticles[#virtualParticles]["vx"] = vx
              virtualParticles[#virtualParticles]["vy"] = vy
            end
          end
        end
      end
    end
  end

  local function onStepRotate(x,y)
    local angle = currentangle
    if angle<0 then angle=angle+360 end
    info:MouseOver(x,y,"Rotating ("..angle.."). Press RMB to cancel. Press LMB to save.")
    currentangle = math.floor(math.deg(math.atan2(tpt.mousex-selectionMover.X-selectionMover.Width/2,tpt.mousey-selectionMover.Y-selectionMover.Height/2)))-startangle
    if isfirst then
      isfirst = false
    else
      rot(lastangle-currentangle)
    end
    lastangle = currentangle
  end

  local function onClickRotate(x,y,e,b)
    if e==mouseEvents.Up and b==mouseButtons.Left then
      interface_s.RemoveOnClickAction(onClickRotate)
      interface_s.RemoveOnStepAction(onStepRotate)
      ignoreClicks = false
      rotateButton.Enabled = true
      resizeButton.Enabled = not safeMode
    end
    if e==mouseEvents.Up and (b==mouseButtons.Right or b==4) then --Reset
      virtualParticles = clone(virtualParticlesbackup)
      interface_s.RemoveOnClickAction(onClickRotate)
      interface_s.RemoveOnStepAction(onStepRotate)
      ignoreClicks = false
      rotateButton.Enabled = true
      resizeButton.Enabled = not safeMode
    end
    return true
  end

  rotateButton.OnPressed = (function()
    toTempGrid()
    virtualParticlesbackup = clone(virtualParticles)
    startangle = math.floor(math.deg(math.atan2(tpt.mousex-selectionMover.X-selectionMover.Width/2,tpt.mousey-selectionMover.Y-selectionMover.Height/2)))
    lastangle = startangle
    isfirst = true
    info.HintFrames = 41
    interface_s.AddOnStepAction(onStepRotate)
    interface_s.AddOnClickAction(onClickRotate)
    ignoreClicks = true
    rotateButton.Enabled = false
    resizeButton.Enabled = false
  end)
  --=================================================================--
  
  --=============================Resize==============================--
  local resizePosX = -1
  local resizePosY = -1
  local SizeX = 1
  local SizeY = 1

  local function removeDeletedFromTable(tbl)
    local newTable = {}
    for i=1,#tbl do
      if tbl[i]~=123 then
        newTable[#newTable+1]=tbl[i]
      end
    end
    return newTable
  end

  local function onStepResize(x,y)
    SizeX = math.ceil((x-resizePosX)/resizingGridSize)+1
    SizeY = math.ceil((y-resizePosY)/resizingGridSize)+1
    local sizeXStr = SizeX
    local sizeYStr = SizeY
    if sizeXStr==0 then sizeXStr=1 end
    if sizeYStr==0 then sizeYStr=1 end
    if sizeXStr<0 then
      sizeXStr="1/"..math.abs(sizeXStr-1)
    end
    if sizeYStr<0 then
      sizeYStr="1/"..math.abs(sizeYStr-1)
    end
    info:MouseOver(tpt.mousex,tpt.mousey,"Resizing ("..sizeXStr.."x, "..sizeYStr.."y). Press RMB to cancel. Press LMB to save.")
    virtualParticles = clone(virtualParticlesbackup)
    local minX = 900
    local minY = 900
    
    for i=1, #virtualParticles do
      if minX>virtualParticles[i]["x"] then minX=virtualParticles[i]["x"] end
      if minY>virtualParticles[i]["y"] then minY=virtualParticles[i]["y"] end
    end
    if SizeX>0 then
      for i=1, #virtualParticles do
        virtualParticles[i]["x"]=math.ceil(minX+(virtualParticles[i]["x"]-minX)*(SizeX))
        for j=virtualParticles[i]["x"]+1,virtualParticles[i]["x"]+SizeX-1 do
          virtualParticles[#virtualParticles+1]={}
          virtualParticles[#virtualParticles]["x"]=j
          virtualParticles[#virtualParticles]["y"]=virtualParticles[i]["y"]
          virtualParticles[#virtualParticles]["i"]=virtualParticles[i]["i"]
          virtualParticles[#virtualParticles]["vx"]=virtualParticles[i]["vx"]
          virtualParticles[#virtualParticles]["vy"]=virtualParticles[i]["vy"]
        end
      end
    else
      local s = 1/math.abs(SizeX-1)
      for i=1, #virtualParticles do
        if (virtualParticles[i]["x"]-minX)%math.abs(SizeX-1)~= 0 then 
          virtualParticles[i]=123
        else
          virtualParticles[i]["x"]=math.ceil(minX+(virtualParticles[i]["x"]-minX)*s)
          for j=virtualParticles[i]["x"]+1,virtualParticles[i]["x"]+s-1 do
            virtualParticles[#virtualParticles+1]={}
            virtualParticles[#virtualParticles]["x"]=j
            virtualParticles[#virtualParticles]["y"]=virtualParticles[i]["y"]
            virtualParticles[#virtualParticles]["i"]=virtualParticles[i]["i"]
            virtualParticles[#virtualParticles]["vx"]=virtualParticles[i]["vx"]
            virtualParticles[#virtualParticles]["vy"]=virtualParticles[i]["vy"]
          end
        end
      end
      virtualParticles=removeDeletedFromTable(virtualParticles)
    end
    if SizeY>0 then
      for i=1, #virtualParticles do
        virtualParticles[i]["y"]=math.ceil(minY+(virtualParticles[i]["y"]-minY)*(SizeY))
        for j=virtualParticles[i]["y"]+1,virtualParticles[i]["y"]+SizeY-1 do
          virtualParticles[#virtualParticles+1]={}
          virtualParticles[#virtualParticles]["y"]=j
          virtualParticles[#virtualParticles]["x"]=virtualParticles[i]["x"]
          virtualParticles[#virtualParticles]["i"]=virtualParticles[i]["i"]
          virtualParticles[#virtualParticles]["vx"]=virtualParticles[i]["vx"]
          virtualParticles[#virtualParticles]["vy"]=virtualParticles[i]["vy"]
        end
      end
    else
      local s = 1/math.abs(SizeY-1)
      for i=1, #virtualParticles do
        if (virtualParticles[i]["y"]-minY)%math.abs(SizeY-1) ~= 0 then 
          virtualParticles[i]=123
        else
          virtualParticles[i]["y"]=math.ceil(minY+(virtualParticles[i]["y"]-minY)*(s))
          for j=virtualParticles[i]["y"]+1,virtualParticles[i]["y"]+s-1 do
            virtualParticles[#virtualParticles+1]={}
            virtualParticles[#virtualParticles]["y"]=j
            virtualParticles[#virtualParticles]["x"]=virtualParticles[i]["x"]
            virtualParticles[#virtualParticles]["i"]=virtualParticles[i]["i"]
            virtualParticles[#virtualParticles]["vx"]=virtualParticles[i]["vx"]
            virtualParticles[#virtualParticles]["vy"]=virtualParticles[i]["vy"]
          end
        end
      end
      virtualParticles=removeDeletedFromTable(virtualParticles)
    end
    adjustSelection()
  end

  local function onClickResize(x,y,e,b)
    if e==mouseEvents.Up and b==mouseButtons.Left then
      interface_s.RemoveOnClickAction(onClickResize)
      interface_s.RemoveOnStepAction(onStepResize)
      rotateButton.Enabled = true
      resizeButton.Enabled = not safeMode
      ignoreClicks = false
    end
    if e==mouseEvents.Up and (b==mouseButtons.Right or b==4) then --Reset
      virtualParticles = clone(virtualParticlesbackup)
      adjustSelection()
      interface_s.RemoveOnClickAction(onClickResize)
      interface_s.RemoveOnStepAction(onStepResize)
      rotateButton.Enabled = true
      resizeButton.Enabled = not safeMode
      ignoreClicks = false
    end
    return true
  end
  
  resizeButton.OnPressed = (function(x,y)
    virtualParticlesbackup = clone(virtualParticles)
    resizePosX=tpt.mousex
    resizePosY=tpt.mousey
    interface_s.AddOnStepAction(onStepResize)
    interface_s.AddOnClickAction(onClickResize)
    ignoreClicks = true
    rotateButton.Enabled = false
    resizeButton.Enabled = false
  end)
  --=================================================================--

  --=================================================================--
  local Zkey = false
  local function ZKeyPress(key, scan, r, ctrl, shift, alt)
    if key==122 then
      Zkey = true
    end
  end
  local function ZKeyRelease(key, scan, r, ctrl, shift, alt)
    if key==122 then
      Zkey = false
    end
  end
  
  local function ZkeyforOldAPI(a,b,c,d)
    if d==1 then
      ZKeyPress(b)
    else
      ZKeyRelease(b)
    end
  end

  if tpt.version.major<=93 and tpt.version.jacob1s_mod==nil or tpt.version.jacob1s_mod~=nil and tpt.version.jacob1s_mod<42 then
    tpt.register_keypress(ZkeyforOldAPI)
  else
    event.register(event.keyrelease, ZKeyRelease)
    event.register(event.keypress, ZKeyPress)
  end
  --=================================================================--
  selectionMenu = interface_s.Components.Window:new(10, 10, 65, 40,false, TransparentWindow)
  selectionMenu.IsShowing = false
  selectionMenu.AlwaysFocused = true
  selectionMenu.AllowResize = false
  interface_s.addComponent(selectionMenu)

  local layerModeCheckbox = interface_s.Components.Checkbox:new(2, 27, 10, "Layer", DefaultTheme.Checkbox)
  layerModeCheckbox.Checked = layerMode
  layerModeCheckbox.OnStateChanged = function(checked)
    layerMode = checked
  end

  local safeModeCheckbox = interface_s.Components.Checkbox:new(2, 15, 10, "Safe mode", DefaultTheme.Checkbox)
  safeModeCheckbox.Checked = safeMode
  safeModeCheckbox.OnStateChanged = function(checked)
    safeMode = checked
    resizeButton.Enabled = not safeMode
  end

  local mainWindow = interface_s.Components.Window:new(10, 10, 60, 60,true, DefaultTheme.Window)
  mainWindow.AllowResize = false
  interface_s.addComponent(mainWindow)

  local blockClicks = false
  local function blockAllClicks()
    if blockClicks and not Zkey then
      return true
    end
  end
  interface_s.AddOnClickAction(blockAllClicks)

  local Exit = interface_s.Components.Button:new(5, 40, 50, 15,"Exit", DefaultTheme.Button)
  Exit.OnPressed = (function()
    interface_s.RemoveComponent(mainWindow)
    interface_s.RemoveComponent(selectionMover)
    interface_s.RemoveComponent(selection)
    interface_s.RemoveComponent(selectionMenu)
    interface_s.RemoveOnClickAction(onClickRotate)
    interface_s.RemoveOnStepAction(onStepRotate)
    interface_s.RemoveOnClickAction(blockAllClicks)
    interface_s.RemoveOnStepAction(drawVirtualParticles)
    if pause == true then
      tpt.set_pause(1)
    else
      tpt.set_pause(0)
    end
    if tpt.version.major<=93 and tpt.version.jacob1s_mod==nil or tpt.version.jacob1s_mod~=nil and tpt.version.jacob1s_mod<42 then
      tpt.unregister_keypress(ZkeyforOldAPI)
    else
      event.unregister(event.keyrelease, ZKeyRelease)
      event.unregister(event.keypress, ZKeyPress)
    end
  end)

  local selectButton = interface_s.Components.Button:new(5, 10, 50, 15,"Select", DefaultTheme.Button)
  selectButton.OnPressed = (function()
    selectButton.Enabled = false
    tpt.log("Select area that you need to layer.")
    resetVars()
    if selectionMover ~= nil then
      interface_s.RemoveComponent(selectionMover)
    end
    selection = interface_s.Components.Selection:new(50, 50, DefaultTheme.Selection) 
    selection.OnDraw = function(IsFocused,x,y)
      x,y = sim.adjustCoords(x,y)
      if selection.IsPointSet then
        getZoomInfo()
        local x2,y2 = sim.adjustCoords(selection.V2StartX,selection.V2StartY)
        drawRectangleInZoomWindow(x2,y2,selection.V2EndWidth,selection.V2EndHeight,gfx.getColors(selection.Theme.BackColor))
      end
      return IsFocused,x,y
    end
    selection.OnClick = function(x,y,e,b)
      if b==3 then    --
        b=4           -- To make it correctly work while 2.43 interface API update is not approved
      end             --
      x,y = sim.adjustCoords(x,y)
      return x,y,e,b
    end
    selection.OnSelected = function(x,y,x2,y2,v2x,v2y,v2w,v2h)
      if v2w<5 or v2h<5 then
        interface_s.RemoveComponent(selection)
        selectButton.Enabled=true
        return
      end
      interface_s.AddOnStepAction(drawVirtualParticles)
      tpt.log("Now move the selection on the other particles. Press RMB to cancel. Press LMB to finish.")
      interface_s.RemoveComponent(selection)
      selectionMenu.X = v2x+v2w
      selectionMenu.Y = v2y
      selectionMenu:Show()
      particlesIndexes={}
      for i in sim.parts() do
        local cx,cy = sim.partPosition(i)
        cx = round(cx)
        cy = round(cy)
        if (cx>v2x) and (cx<v2x+v2w) and (cy>v2y) and (cy<v2y+v2h) then
          particlesIndexes[#particlesIndexes+1]=i
        end
      end

      blockClicks = true

      saveToVirtual()

      selectionMover = interface_s.Components.SelectionMover:new(v2x,v2y,v2w,v2h, DefaultTheme.Selection) 
      selectionMover.OnClick = (function(x,y,e,b)
        if Zkey or ignoreClicks then return nil end
        if b==3 then    --
          b=4           -- To make it correctly work while 2.43 interface API update is not approved
        end             --
        x,y = sim.adjustCoords(x,y)
        return x,y,e,b
      end)
      selectionMover.OnMove = (function(x,y,e,b)
        if Zkey then return nil end
        x,y = sim.adjustCoords(x,y)
        return x,y,e,b
      end)
      selectionMover.OnDraw = (function(f,x,y)
        drawRectangleInZoomWindow(selectionMover.X,selectionMover.Y,selectionMover.Width,selectionMover.Height,gfx.getColors(selectionMover.Theme.BackColor))
      end)
      selectionMover.OnDone = (function()
        interface_s.RemoveComponent(selectionMover)
        interface_s.RemoveOnStepAction(drawVirtualParticles)
        virtualParticlesToReal()
        selectionMenu:Hide()
        blockClicks = false
        selectButton.Enabled=true
      end)
      selectionMover.OnAbort = (function(tdx,tdy)
        interface_s.RemoveOnStepAction(drawVirtualParticles)
        interface_s.RemoveComponent(selectionMover)
        selectionMenu:Hide()
        blockClicks = false
        selectButton.Enabled=true
      end)
      selectionMover.OnMovement = (function(xd,yd)
        selectionMenu.X=selectionMenu.X+xd
        selectionMenu.Y=selectionMenu.Y+yd
          for i=0, #virtualParticles do
            if virtualParticles[i]~=nil then
              virtualParticles[i]["x"] = virtualParticles[i]["x"]+xd
              virtualParticles[i]["y"] = virtualParticles[i]["y"]+yd
            end
          end
        end)
        interface_s.addComponent(selectionMover)
    end
    selection.OnSelectionAborted = function()
      interface_s.RemoveComponent(selection)
      selectButton.Enabled=true
    end
    interface_s.addComponent(selection)
  end)
  mainWindow:AddComponent(selectButton)
  mainWindow:AddComponent(Exit)
  selectionMenu:AddComponent(rotateButton)
  selectionMenu:AddComponent(resizeButton)
  selectionMenu:AddComponent(safeModeCheckbox)
  selectionMenu:AddComponent(layerModeCheckbox)
end
--=================================================================--
--                    CODE IS ABOVE THIS LINE                      --
--=================================================================--
