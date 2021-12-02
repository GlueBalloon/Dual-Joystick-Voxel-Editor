Snapshotter = class()

function Snapshotter:init(volume)
    self.volume = volume
    self.snapshots = {}
    self.snapshots.redoQueue = {}
    self.currentSnapshotGridSize = vec3(0, 0, 0)
end

-- Save a snapshot of the current voxel volume (for editing and undo)
function Snapshotter:saveSnapshot()
    table.insert(self.snapshots, self.volume:saveSnapshot()) 
    if self.snapshots.redoQueue.emptyOnNextSnapshot then
        for i=#self.snapshots.redoQueue, 1, -1 do
            table.remove(self.snapshots.redoQueue, i)
            self.snapshots.redoQueue.emptyOnNextSnapshot = nil
        end
    end
end

function Snapshotter:saveFile(filename)
    self.volume:save("Documents:"..filename..".cvox")
end

--load a saved file
function Snapshotter:loadFile(filename, delegates)
    self.volume:load("Documents:"..Filename)
    local sizeX, sizeY, sizeZ = self.volume:size()
    self.currentSnapshotGridSize = vec3(sizeX, sizeY, sizeZ)
    viewer.target = vec3(sizeX/2 + 0.5, sizeY/2 + 0.5, sizeZ/2 + 0.5)
    --delegates must have an updateGrids function
    for _, delegate in ipairs(delegates) do
        delegate:updateGrids(sizeX, sizeY, sizeZ)
    end
    self:saveSnapshot()
    print(table.unpack(G.scene.voxels.blocks:all()))
end

--undo
function Snapshotter:undo()
    local spShots = self.snapshots
    if #spShots > 1 then
        table.insert(spShots.redoQueue, spShots[#spShots])
        table.remove(spShots, #spShots)
        self.volume:loadSnapshot(spShots[#spShots])
    end
end

--redo
function Snapshotter:redo()
    local spShots = self.snapshots
    local redoQueue = spShots.redoQueue
    if #redoQueue >= 1 then
        table.insert(spShots, redoQueue[#redoQueue])
        table.remove(redoQueue, #redoQueue)
        self.volume:loadSnapshot(spShots[#spShots])
    end
    redoQueue.emptyOnNextSnapshot = true
end

function nudgeCheck()
    if nudgeTimer == 0 then
        if nudgeX ~= 0 then
            move(nudgeX, 0, 0)
            nudgeTimer = ElapsedTime
        end
        if nudgeY ~= 0 then
            move(0, nudgeY, 0)
            nudgeTimer = ElapsedTime
        end
        if nudgeZ ~= 0 then
            move(0, 0, nudgeZ)
            nudgeTimer = ElapsedTime
        end
    elseif ElapsedTime - nudgeTimer > 0.25 then
        nudgeX, nudgeY, nudgeZ = 0, 0, 0
        nudgeTimer = 0
    end
end

function extractPositions()   
    -- read the voxel area
    -- save block data
    -- clear blocks with EMPTY
    tab={}
    local vX, vY, vZ = G.volume:size()
    vX, vY, vZ = vX - 1, vY - 1, vZ -1
    for x=0, vX do
        for y=0, vY do
            for z=0, vZ do
                -- get the name of the voxel at x,y,z
                local name=G.volume:get(x,y,z,BLOCK_ID)
                local pos = vec3(x, y, z)
                local colorInt = G.volume:get(x, y, z, BLOCK_STATE)
                local blockTable = {vec3(x,y,z), BLOCK_ID, name}
                if colorInt ~= 0 then
                    table.insert(blockTable, COLOR)
                    table.insert(blockTable, colorFromInt(colorInt))
                end
                -- put x,y,z and name in a table for later
                table.insert(tab,blockTable)
                -- set voxel block to EMPTY
                G.scene.voxels:fill(EMPTY)
                G.scene.voxels:block(x,y,z)
            end
        end
    end 
end

function move(x,y,z)  
    extractPositions() 
    local vX, vY, vZ = G.volume:size()
    vX, vY, vZ = vX - 1, vY - 1, vZ -1
    for a,b in pairs(tab) do 
        local pos = table.remove(b, 1)
        if pos.x+x>vX then
            pos = vec3(0,pos.y,pos.z)
        elseif pos.y+y>vY then
            pos = vec3(pos.x+x,0,pos.z)
        elseif pos.z+z>vZ then
            pos = vec3(pos.x+x,pos.y,0)
        elseif pos.x+x<0 then
            pos = vec3(vX, pos.y, pos.z)
        elseif pos.y+y<0 then
            pos = vec3(pos.x+x,vY,pos.z)
        elseif pos.z+z<0 then
            pos = vec3(pos.x+x,pos.y,vZ)
        else
            pos = vec3(pos.x+x,pos.y+y,pos.z+z)
        end
        G.volume:set(pos,table.unpack(b))
    end
end