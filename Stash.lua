--[[
-- The tools used to apply voxels in the editor

TOOL_NONE = 0
TOOL_ADD = 1
TOOL_REPLACE = 2 
TOOL_ERASE = 3
TOOL_GET = 4

TOOL_TYPE_POINT = 1
TOOL_TYPE_LINE = 2
TOOL_TYPE_BOX = 3
TOOL_TYPE_FLOOD = 4

TOOL_STATE_IDLE = 1
TOOL_STATE_DRAG = 2

COLORS = {
    color(255, 255, 255, 255),
    color(42, 190, 217, 255),
    color(193, 80, 80, 255),
    color(237, 160, 41, 255),
    color(98, 45, 173, 255),
    color(69, 96, 208, 255),
    color(179, 204, 44, 255),
    color(52, 132, 124, 255),
    color(146, 194, 77, 255),
    color(27, 27, 27, 255),
    color(117, 65, 43, 255),
    color(193, 193, 193, 255)
}

Tool = class()

function Tool:init()
    self.state = TOOL_STATE_IDLE
    self.colorUpdaters = {}
end

function Tool:touched(touch)    
    if #snapshots > 0 then
        volume:loadSnapshot(snapshots[#snapshots])
    end
    
    local coord, id, face = raycast(touch.x, touch.y, false)
    
    if coord then
        if toolMode == TOOL_ADD then
            coord = coord + face
        end   
    end  
        
    if toolMode == nil then
        return false
    end
    
    if coord and touch.state == BEGAN and self.state == TOOL_STATE_IDLE then
        if #player.touches > 0 then return false end
        self.startCoord = coord
        self.endCoord = coord
        self.state = TOOL_STATE_DRAG
        self.points = {}
        table.insert(self.points, coord)
        self:apply()
        return true
    elseif touch.state == MOVING and self.state == TOOL_STATE_DRAG then
        if coord then
            self.endCoord = coord
        end
        table.insert(self.points, coord)
        self:apply()
        return true
    elseif touch.state == ENDED and self.state == TOOL_STATE_DRAG then
        self.state = TOOL_STATE_IDLE
        self:apply()
        saveSnapshot()
        return true
    end

    return false
end

function Tool:mirroring(x, y, z, ...)
    local mirrorX, mirrorY, mirrorZ
    mirrorX = (sx-1) - x
    mirrorY = (sy-1) - y
    mirrorZ = (sz-1) - z
    if mirror.x then
        volume:set(mirrorX, y, z, ...) 
    end
    if mirror.y then
        volume:set(x, mirrorY, z, ...) 
    end
    if mirror.z then
        volume:set(x, y, mirrorZ, ...) 
    end
    if mirror.x and mirror.y then
        volume:set(mirrorX, mirrorY, z, ...) 
    end
    if mirror.x and mirror.z then
        volume:set(mirrorX, y, mirrorZ, ...) 
    end
    if mirror.y and mirror.z then
        volume:set(x, mirrorY, mirrorZ, ...) 
    end
    if mirror.x and mirror.y and mirror.z then
        volume:set(mirrorX, mirrorY, mirrorZ, ...) 
    end
end

function Tool:setAndMirror(x, y, z, ...)
    volume:set(x, y, z, ...) 
    self:mirroring(x, y, z, ...)                                                        
end


function Tool:applyPoints(...)
    for k,v in pairs(self.points) do
        self:setAndMirror(v.x, v.y, v.z, ...)
    end    
end

function Tool:applyBox(...)
    local minX = math.min(self.startCoord.x, self.endCoord.x)
    local maxX = math.max(self.startCoord.x, self.endCoord.x)
    local minY = math.min(self.startCoord.y, self.endCoord.y)
    local maxY = math.max(self.startCoord.y, self.endCoord.y)
    local minZ = math.min(self.startCoord.z, self.endCoord.z)
    local maxZ = math.max(self.startCoord.z, self.endCoord.z)
    
    for x = minX, maxX do
        for y = minY, maxY do
            for z = minZ, maxZ do
                if toolMode == TOOL_REPLACE then
                    if volume:get(x, y, z, BLOCK_ID) ~= 0 then
                        self:setAndMirror(x, y, z, ...)                               
                    end
                else
                    self:setAndMirror(x, y, z, ...)                               
                end                
            end
        end
    end
end

function Tool:applyLine(...)
    if self.endCoord == self.startCoord then
        volume:set(self.startCoord, ...)
        self:setAndMirror(self.startCoord.x, self.startCoord.y, self.startCoord.x, ...)
        return
    end
    
    local dir = (self.endCoord-self.startCoord)
    local args = {...}
    volume:raycast(self.startCoord + vec3(0.5, 0.5, 0.5), dir:normalize(), dir:len(), function(coord, id, face) 
        if coord then
            self:setAndMirror(self.startCoord.x, self.startCoord.y, self.startCoord.x, table.unpack(args))
            return false
        else
            return true
        end
    end)    
end

function Tool:apply()
    if toolMode == TOOL_ADD or toolMode == TOOL_REPLACE then
        if toolType == TOOL_TYPE_POINT then
            self:applyPoints("name", "Solid", "color", toolColor)
        elseif toolType == TOOL_TYPE_BOX then
            self:applyBox("name", "Solid", "color", toolColor)
        elseif toolType == TOOL_TYPE_LINE then
            self:applyLine("name", "Solid", "color", toolColor)
        end
    elseif toolMode == TOOL_ERASE then
        if toolType == TOOL_TYPE_POINT then
            self:applyPoints(0)
        elseif toolType == TOOL_TYPE_BOX then
            self:applyBox(0)            
        end
    elseif toolMode == TOOL_GET then
        local s = volume:get(self.startCoord, BLOCK_STATE)
        if s then
            local r = (s>>24) & 255
            local g = (s>>16) & 255   
            local b = (s>>8) & 255     
            toolColor = color(r,g,b)
            Color = toolColor
            for _, func in ipairs(self.colorUpdaters) do
                func(toolColor)
            end
        end
    end 
end
    
-- Helper function for voxel raycasts
function raycast(x,y, sides)
    local origin, dir = scene.camera:get(craft.camera):screenToRay(vec2(x, y))
    
    local blockID = nil
    local blockCoord = nil
    local blockFace = nil
    
    -- The raycast function will go through all voxels in a line starting at a given origin
    -- heading in the specified direction. The traversed voxels are passed to a callback
    -- function which is given the coordinate, id and surface normal (face).
    -- Once true is returned, the raycast will stop
    volume:raycast(origin, dir, 128, function(coord, id, face)
        if id and id ~= 0 then
            blockID = id
            blockCoord = coord
            blockFace = face
            return true
        elseif id == nil then
            
            if coord.x >= -1 and coord.x <= sx and 
            coord.y >= -1 and coord.y <= sy and
            coord.z >= -1 and coord.z <= sz then
                
                for k,v in pairs(grids) do
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
]]