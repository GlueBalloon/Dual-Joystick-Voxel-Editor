-- A reusable grid class for drawing the voxel editor grid
SingleGrid = class()

function SingleGrid:init(scene, viewPointSource, normal, origin, spacing, size, enabled)
    self.scene = scene
    self.viewPointSource = viewPointSource
    self.normal = normal
    self.origin = origin
    self.spacing = spacing
    self.size = size
    self.axes = {vec3(), vec3()}
    self.enabled = enabled

    if self.normal.x ~= 0 then
        self.axes[1].y = 1
        self.axes[2].z = 1
        self.axes2 = {3, 2, 1}
    elseif self.normal.y ~= 0 then
        self.axes[1].x = 1
        self.axes[2].z = 1
        self.axes2 = {1, 3, 2}
    elseif self.normal.z ~= 0 then
        self.axes[1].x = 1
        self.axes[2].y = 1
        self.axes2 = {1, 2, 3}
    end

    self.entity = self.scene:entity()
    self.r = self.entity:add(craft.renderer, craft.model.cube(vec3(1,1,1), vec3(0.5,0.5,0.5)))
    self.r.material = craft.material(asset.builtin.Materials.Specular)
    self.r.material.blendMode = NORMAL
    self:modified()
end

-- Checks if the grid is visible based on where the camera is pointed
function SingleGrid:isVisible()
    local camVec = self.viewPointSource.worldPosition - self.origin
  return self.enabled and self.normal:dot(camVec) > 0.0
end

function SingleGrid:modified()
    local gx = self.size[self.axes2[1]]
    local gy = self.size[self.axes2[2]]
    self.img = image((gx + 10) * 20, (gy + 10) * 20)
    self.r.material.map = self.img

    -- Pre-render the grid to an image to make it look nicer (anti-aliasing)
    setContext(self.img)
    background(48, 217, 211, 25)
    background(217, 48, 177, 25)
    pushStyle()
   -- local gridColor = color(225, 175, 124, 186)
     local gridColor = color(214, 25, 247, 186)
    stroke(gridColor)
    strokeWidth(5)
    noFill()
    rectMode(CORNER)
    rect(-2,-2,self.img.width+4, self.img.height+4)

    strokeWidth(2)
    stroke(gridColor)

    for x = 1, gx-1 do
        line(x * (self.img.width/gx), 3, x * (self.img.width/gx), self.img.height-3)
    end

    for y = 1,gy-1 do
        line(3, y * (self.img.height/gy), self.img.width-3, y * (self.img.height/gy))
    end

    popStyle()
    setContext()

    local s = vec3()
    s[self.axes2[1]] = self.size[self.axes2[1]]
    s[self.axes2[2]] = self.size[self.axes2[2]]
    self.entity.scale = s
    local p = vec3()
    p[self.axes2[3]] = self.origin[self.axes2[3]]
    self.entity.position = p
end

function SingleGrid:update()
    self.entity.active = self:isVisible()
end
