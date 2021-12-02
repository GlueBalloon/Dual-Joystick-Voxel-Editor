-----------------------------------------
-- First-Person Voxel Editor
-- Description:
-- First-Person version of John Millard's original Voxel Editor.
-- Use overlay editor to save and load voxels models in the cvox format (Codea Voxel).
-----------------------------------------

viewer.mode = OVERLAY

function setup()
    --make a table for globals, to keep track of 'em
    G = {}

    --set up scene
    G.scene = craft.scene()
    G.scene.ambientColor = color(255, 39)
    G.scene.sun.rotation = quat.eulerAngles(25, 125, 0)
    G.scene.physics.gravity = vec3(0,0,0)    
    --create a volume for rendering our voxel model in
    G.volume = G.scene:entity():add(craft.volume, 20, 20, 20)
    G.sizeX, G.sizeY, G.sizeZ = G.volume:size()   
    --make save/load and undo/redo system
    G.snapshotter = Snapshotter(G.volume)
    --make player
    makePlayer(G)
    --make grids
    makeGrids(G)    
    --set up voxel drawing tool
    G.tool = OmniTool(G.scene, G.volume, G.grids, G.snapshotter, color(189, 205, 207), G.player.rig.joystickView.camera)
    G.tool.toolType = OmniTool.TOOL_TYPE_BOX
    --make toolbars
    G.shelf = Shelf(G.tool, G.snapshotter)
    G.shelf:setColor(G.tool.toolColor)
    table.insert(G.tool.runAtColorChange, function(aColor) 
        G.shelf:setColor(aColor)
        red, green, blue = aColor.r, aColor.g, aColor.b
        Color = aColor
    end)    
    --set up a traffic cop for touches
    G.touchesManager = TouchesManager(G.player, G.tool, G.shelf)
    touches.addHandler(G.touchesManager, -1, true)
    --create the controls in the overlay panel
    addParameters()
    --export any demo models that need exporting    
    setUpSavedStates({
        "VE_Blank",
        "VE_LittleFantasyDude",
        "VE_Frog",
        "VE_Bear",
        "VE_Castle",
        "VE_RoboDog",
        "VE_Car",
    })
    --load last saved model or default model
    local nameToLoad = readProjectData("filename", "VE_Blank")
    G.snapshotter:loadFile(nameToLoad, {G.tool})
    GridSizeX, GridSizeY, GridSizeZ = G.volume:size()
    
    --[[
    textOpacity = 255
    textTime = DeltaTime
    fadeStarted = false
    ]]
end

function colorFromInt(int)
    local r = (int>>24) & 255
    local g = (int>>16) & 255   
    local b = (int>>8) & 255     
    return color(r, g, b)
end

function move(up) -- move in selected direction 
    local sizeX, sizeY, sizeZ = G.volume:size()
    local volumeTable = {}
    if not up then
        for z = 0, sizeZ - 1 do
            for y = 0, sizeY - 1 do
                for x = 0, sizeX - 1 do
                    local blockTable
                    local id = G.volume:get(vec3(x, y, z), BLOCK_ID)
                    local newVec = vec3(x, y, z) - vec3(0, 1, 0)
                    if y == 0 then
                        newVec.y = sizeY - 1
                    end
                    local colorInt = G.volume:get(x, y, z, BLOCK_STATE)
                    if colorInt ~= 0 then
                        blockTable = {newVec, BLOCK_ID, id, "color", colorFromInt(colorInt)}
                    else 
                        blockTable = {newVec, BLOCK_ID, id}
                    end
                    table.insert(volumeTable, blockTable)
                end
            end
        end
    else
        for z = sizeZ - 1, 0, -1 do
            for y = sizeY - 1, 0, -1 do
                for x = sizeX - 1, 0, -1 do
                    local blockTable
                    local id = G.volume:get(vec3(x, y, z), BLOCK_ID)
                    local newVec = vec3(x, y, z) + vec3(0, 1, 0)
                    if newVec.y == sizeY then
                        newVec.y = 0
                    end
                    local colorInt = G.volume:get(x, y, z, BLOCK_STATE)
                    if colorInt then
                        blockTable = {newVec, BLOCK_ID, id, "color", colorFromInt(colorInt)}
                    else 
                        blockTable = {newVec, BLOCK_ID, id}
                    end
                    table.insert(volumeTable, blockTable)
                end
            end
        end
    end
    for i, blockTable in ipairs(volumeTable) do
        G.volume:set(table.unpack(blockTable))
    end
end

function makeLegacyPlayer(globals)
    G.player = voxelWalkerMaker(G.scene, G.sizeX/2 + 10, G.sizeY/2 + 10, G.sizeZ/2 - 9)
    G.player.isLegacy = true
    G.player.position = vec3(G.sizeX/2 + 10, G.sizeY/2 + 10, G.sizeZ/2 - 9)
    
    G.player.camera.farPlane=1000000
    G.player.viewer.rx = 32 --rx goes -90 to 90
    G.player.viewer.ry = -49 --ry goes to -179 to 180
    
    G.player.contollerYInputAllowed = true
    G.scene.physics.gravity = vec3(0,0,0)
    G.player.linearDamping = 5.95

    touches.removeHandler(G.player)
end

function makeRigBasedPlayer(globals)
    --make a camera/entity hybrid
    local camThing = makeCameraViewerEntityThing(G.scene)    
    G.player = camThing
    --its camera is initially placed inside the body for a first-person view
    G.player = joystickWalkerRig(camThing, G.scene)
    --G.player = doubleJoystickRig(camThing)
    G.player.position = vec3(G.sizeX/2 + 10, G.sizeY/2 + 10, G.sizeZ/2 - 9)
    G.player.rig.joystickView.rx = 32 --rx goes -90 to 90
    G.player.rig.joystickView.ry = -49 --ry goes to -179 to 180
    G.player.rig.joystickView.farPlane(1000000)
    
    G.player.rig.contollerYInputAllowed = true
    G.scene.physics.gravity = vec3(0,0,0)
    G.player.rig.linearDamping = 0.95

    touches.removeHandler(G.player)
    G.player.rig.joystickView.rx = 29
    G.player.rig.joystickView.ry = -38
    G.player.rig.joystickView.rig.camRxRy(29, -38)
end

function makePlayer(globals)
    local G = globals
    -- makeLegacyPlayer(G)
    makeRigBasedPlayer(G)
end

function makeGrids(globals)
    local G = globals
    local camThing = G.player.rig.joystickView
    G.grids = 
    {
        bottom = SingleGrid(G.scene, camThing, vec3(0,1,0), vec3(0,0,0), 1, vec3(G.sizeX,G.sizeY,G.sizeZ), true),
        top = SingleGrid(G.scene, camThing, vec3(0,-1,0), vec3(0,G.sizeY,0), 1, vec3(G.sizeX,G.sizeY,G.sizeZ), true),
        left = SingleGrid(G.scene, camThing, vec3(1,0,0), vec3(0,0,0), 1, vec3(G.sizeX,G.sizeY,G.sizeZ), true),
        right = SingleGrid(G.scene, camThing, vec3(-1,0,0), vec3(G.sizeX,0,0), 1, vec3(G.sizeX,G.sizeY,G.sizeZ), true),
        front = SingleGrid(G.scene, camThing, vec3(0,0,1), vec3(0,0,0), 1, vec3(G.sizeX,G.sizeY,G.sizeZ), true),
        back = SingleGrid(G.scene, camThing, vec3(0,0,-1), vec3(0,0,G.sizeZ), 1, vec3(G.sizeX,G.sizeY,G.sizeZ), true) 
    }
end

function setUpSavedStates(saveFileNames)
    function moveVolumeToDocumentsIfNeeded(volumeName)
        --check if file is in documents already
        local nameTest=asset.documents..volumeName..".cvox"
        local testFile = io.open(nameTest.path,"r")
        if testFile then 
            --print(volumeName.." already there, not moving")
            goto done
        end
        --if not, copy it there
        local fullFilename = volumeName..".cvox"
        local inName=asset..fullFilename
        local outName = nameTest
        local inFile=io.open(inName.path,"r")
        local data=nil
        if inFile then
            data=inFile:read("*all") 
            inFile:close()
            print(volumeName.." read from project OK")        
            local outFile=io.open(outName.path,"w")
            if outFile then
                outFile:write(data)
                outFile:close()
                print(volumeName .." write to documents OK")        
            else
                print(volumeName .." write file error")
            end
        else
            print(volumeName .." read file error")
        end
        ::done::
    end
    for _, saved in ipairs(saveFileNames) do
        moveVolumeToDocumentsIfNeeded(saved)
    end
    local saves = "\t"
    for i=2, #saveFileNames do
        saves = saves..saveFileNames[i].."\n\t"
    end
    print("To clear everything load the file VE_Blank.\n\nAlso try loading these examples:\n\n"..saves)
end

function addParameters()
    nudgeTimer = 0
    parameter.integer("nudgeX", -1, 1, 0)
    parameter.integer("nudgeY", -1, 1, 0)
    parameter.integer("nudgeZ", -1, 1, 0)
        
    parameter.watch("_________________________")
    _________________________ = "Select block color below"
    parameter.color("Color", G.shelf.color, function(c)
        G.tool.toolColor = c
     --   G.shelf:setColor(c)
    end)
    
    parameter.number("red", 0, 255, G.tool.toolColor.r, function(c)
        G.tool.toolColor = color(c, green, blue)
    end)
    parameter.number("green", 0, 255, G.tool.toolColor.g, function(c)
        G.tool.toolColor = color(red, c, blue)
    end)
    parameter.number("blue", 0, 255, G.tool.toolColor.b, function(c)
        G.tool.toolColor = color(red, green, c)
    end)
    
    parameter.text("Filename", readProjectData("filename") or "VE_LittleFantasyDude",
    function(t)
        saveProjectData("filename", Filename)
    end)
    
    parameter.integer("GridSizeX", 5, 50, 20, function(s)
        G.sizeX = s
        G.tool.shouldResize = true
    end)

    parameter.integer("GridSizeY", 5, 50, 20, function(s)
        G.sizeY = s
        G.tool.shouldResize = true
    end)

    parameter.integer("GridSizeZ", 5, 50, 20, function(s)
        G.sizeZ = s
        G.tool.shouldResize = true
    end)
        
    parameter.action("Load", function()
        G.snapshotter:loadFile("Documents:"..Filename, {G.tool})
        G.snapshotter:saveSnapshot()
        GridSizeX, GridSizeY, GridSizeZ = G.volume:size()
    end)
    
    parameter.action("Save", function() 
        G.snapshotter:saveFile(Filename)
    end)    

end

function update(dt) 
    G.scene:update(dt)

    for k,v in pairs(G.grids) do
        v:update()
    end

    if G.tool.shouldResize then
        G.tool:resizeVolume(G.sizeX, G.sizeY, G.sizeZ)
    end

    nudgeCheck()
end

-- Perform 2D drawing (UI)
function draw()
    update(DeltaTime)
    G.scene:draw()
    G.tool:update()
    
    G.shelf:update()
    G.shelf:draw()
    Color = G.shelf.color
    
    G.shelf.screenTopPanel:update()
    G.shelf.screenTopPanel:draw()
    
    if G.player.isLegacy then
        G.player:update()
        G.player:draw() 
    else
        if G.player.update then G.player.update() end
        if G.player.draw then G.player.draw() end
    end
end

