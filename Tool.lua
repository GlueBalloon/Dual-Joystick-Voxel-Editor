
-- The tools used to apply voxels in the editor
OmniTool = class()

OmniTool.TOOL_NONE = 0
OmniTool.TOOL_ADD = 1
OmniTool.TOOL_REPLACE = 2 
OmniTool.TOOL_ERASE = 3
OmniTool.TOOL_GET = 4

OmniTool.TOOL_TYPE_POINT = 1
OmniTool.TOOL_TYPE_LINE = 2
OmniTool.TOOL_TYPE_BOX = 3
OmniTool.TOOL_TYPE_FLOOD = 4

OmniTool.TOOL_STATE_IDLE = 1
OmniTool.TOOL_STATE_DRAG = 2



function OmniTool:init(scene, volumeToAffect, grids, volumeTools, startColor, raycastCamera)
    self.raycastCamera = raycastCamera
    self.grids = grids
    self.scene = scene
    self.volumeTools = volumeTools
    self.state = self.TOOL_STATE_IDLE
    self.runAtColorChange = {}
    self.runAtColorChange.trackedColor = startColor
    self.volume = volumeToAffect
    local sizeX, sizeY, sizeZ = self.volume:size()
    self.volSize = vec3(sizeX, sizeY, sizeZ)
    self.toolMode = self.TOOL_NONE
    self.toolType = self.TOOL_TYPE_BOX
    self.toolColor = startColor
    self.shouldMirror = {x = false, y = false, z = false}
    self.shouldResize = false
end

function OmniTool:touched(touch)   
    local vTools = self.volumeTools
    if #vTools.snapshots > 0 then
        self.volume:loadSnapshot(vTools.snapshots[#vTools.snapshots])
    end

    local coord, id, face = self:raycast(touch.x, touch.y, false)
    
    if coord then
        if self.toolMode == self.TOOL_ADD then
            coord = coord + face
        end   
    end  
        
    if self.toolMode == nil then
        return false
    end
    
    if coord and touch.state == BEGAN and self.state == self.TOOL_STATE_IDLE then
        --if #G.player.touches > 0 then return false end
        self.startCoord = coord
        self.endCoord = coord
        self.state = self.TOOL_STATE_DRAG
        self.points = {}
        table.insert(self.points, coord)
        self:apply()
        return true
    elseif touch.state == MOVING and self.state == self.TOOL_STATE_DRAG then
        if coord then
            self.endCoord = coord
        end
        table.insert(self.points, coord)
        self:apply()
        return true
    elseif touch.state == ENDED and self.state == self.TOOL_STATE_DRAG then
        self.state = self.TOOL_STATE_IDLE
        self:apply()
        self.volumeTools:saveSnapshot()
        return true
    end

    return false
end


function OmniTool:update(dt)
    if self.runAtColorChange.trackedColor ~= self.toolColor then
        for _, func in ipairs(self.runAtColorChange) do
            func(self.toolColor)
        end 
        self.runAtColorChange.trackedColor = self.toolColor
    end
end

function OmniTool:mirroring(x, y, z, ...)
    if not (self.shouldMirror.x or self.shouldMirror.y or self.shouldMirror.z) then 
        return 
    end
    local idToCopy = self.volume:get(x, y, z, BLOCK_ID)
    local mirrorX, mirrorY, mirrorZ
    mirrorX = (self.volSize.x-1) - x
    mirrorY = (self.volSize.y-1) - y
    mirrorZ = (self.volSize.z-1) - z
    local mX, mY, mZ = x, y, z
    if self.shouldMirror.x then            
        mX = mirrorX
    end
    if self.shouldMirror.y then
        mY = mirrorY
    end
    if self.shouldMirror.z then
        mZ = mirrorZ
    end
    if self.volume:get(mX, mY, mZ, BLOCK_NAME) == "Empty" 
    and self.toolMode == self.TOOL_REPLACE then 
        return 
    end
    self.volume:set(mX, mY, mZ, ...) 
end


function OmniTool:setAndMirror(x, y, z, ...)
    self.volume:set(x, y, z, ...) 
    self:mirroring(x, y, z, ...)                                                        
end


function OmniTool:applyPoints(...)
    for k,v in pairs(self.points) do
        self:setAndMirror(v.x, v.y, v.z, ...)
    end    
end

function OmniTool:applyBox(...)
    local minX = math.min(self.startCoord.x, self.endCoord.x)
    local maxX = math.max(self.startCoord.x, self.endCoord.x)
    local minY = math.min(self.startCoord.y, self.endCoord.y)
    local maxY = math.max(self.startCoord.y, self.endCoord.y)
    local minZ = math.min(self.startCoord.z, self.endCoord.z)
    local maxZ = math.max(self.startCoord.z, self.endCoord.z)
    for x = minX, maxX do
        for y = minY, maxY do
            for z = minZ, maxZ do
                if self.toolMode == self.TOOL_REPLACE then
                    if self.volume:get(x, y, z, BLOCK_ID) ~= 0 
                    and self.volume:get(x, y, z, BLOCK_ID) ~= nil then
                        self:setAndMirror(x, y, z, ...)                               
                    end
                else
                    self:setAndMirror(x, y, z, ...)                               
                end                
            end
        end
    end
end

function OmniTool:applyLine(...)
    if self.endCoord == self.startCoord then
        self.volume:set(self.startCoord, ...)
        self:setAndMirror(self.startCoord.x, self.startCoord.y, self.startCoord.x, ...)
        return
    end    
    local dir = (self.endCoord-self.startCoord)
    local args = {...}
    self.volume:raycast(self.startCoord + vec3(0.5, 0.5, 0.5), dir:normalize(), dir:len(), function(coord, id, face) 
        if coord then
            self:setAndMirror(self.startCoord.x, self.startCoord.y, self.startCoord.x, table.unpack(args))
            return false
        else
            return true
        end
    end)    
end

function OmniTool:apply()
    if self.toolMode == self.TOOL_ADD or self.toolMode == self.TOOL_REPLACE then
        if self.toolType == self.TOOL_TYPE_POINT then
            self:applyPoints("name", "Solid", "color", self.toolColor)
        elseif self.toolType == self.TOOL_TYPE_BOX then
            self:applyBox("name", "Solid", "color", self.toolColor)
        elseif self.toolType == self.TOOL_TYPE_LINE then
            self:applyLine("name", "Solid", "color", self.toolColor)
        end
    elseif self.toolMode == self.TOOL_ERASE then
        if self.toolType == self.TOOL_TYPE_POINT then
            self:applyPoints(0)
        elseif self.toolType == self.TOOL_TYPE_BOX then
            self:applyBox(0)            
        end
    elseif self.toolMode == self.TOOL_GET then
        local s = self.volume:get(self.startCoord, BLOCK_STATE)
        if s then
            local r = (s>>24) & 255
            local g = (s>>16) & 255   
            local b = (s>>8) & 255     
            self.toolColor = color(r,g,b)
        end
    end 
end

function OmniTool:updateGrids(sizeX, sizeY, sizeZ)
    self.grids.right.origin.x = sizeX
    self.grids.back.origin.z = sizeZ
    self.grids.top.origin.y = sizeY
    for _,grid in pairs(self.grids) do
        grid.size.x = sizeX
        grid.size.y = sizeY
        grid.size.z = sizeZ
        grid:modified()
    end
end

function OmniTool:resizeVolume(sizeX, sizeY, sizeZ)
    if self.volume and sizeX and sizeY and sizeZ then
        self.volume:resize(sizeX, sizeY, sizeZ)
        
        self.volSize.x, self.volSize.y, self.volSize.z = self.volume:size()
        self:updateGrids(sizeX, sizeY, sizeZ)
        
        viewer.target = vec3(sizeX/2 + 0.5, sizeY/2 + 0.5, sizeZ/2 + 0.5)
        viewer.origin = viewer.target
        
        self.shouldResize = false
        self.volumeTools:saveSnapshot()
    end
end

-- Helper function for voxel raycasts
function OmniTool:raycast(x,y,z)
    local origin, dir = self.raycastCamera:screenToRay(vec2(x, y))
    local blockID = nil
    local blockCoord = nil
    local blockFace = nil
    
    -- The raycast function will go through all voxels in a line starting at a given origin
    -- heading in the specified direction. The traversed voxels are passed to a callback
    -- function which is given the coordinate, id and surface normal (face).
    -- Once true is returned, the raycast will stop
    self.volume:raycast(origin, dir, 128, function(coord, id, face)
        if id and id ~= 0 then
            blockID = id
            blockCoord = coord
            blockFace = face
            return true
        elseif id == nil then
            
            if coord.x >= -1 and coord.x <= self.volSize.x and 
            coord.y >= -1 and coord.y <= self.volSize.y and
            coord.z >= -1 and coord.z <= self.volSize.z then
                
                for k,v in pairs(self.grids) do
                    if v.enabled and v:isVisible() then
                        local d = math.abs(v.normal:dot(coord + face - v.origin))
                        if d == 0 then
                            blockID = 0
                            blockCoord = coord
                            blockFace = face  
                            return true   
                        end
                    end
                end
            end
            
        end
        return false
    end)
    return blockCoord, blockID, blockFace
end