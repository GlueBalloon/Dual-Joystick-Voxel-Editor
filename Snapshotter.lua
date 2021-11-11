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

