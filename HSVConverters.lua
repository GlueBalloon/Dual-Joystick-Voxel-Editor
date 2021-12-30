--[[
--# Main
-- RGBHSV

function setup()
    r,g,b = 0,0,0
    h,s,v = 0,0,0
    parameter.integer("h",0,255,0,hsv)
    parameter.integer("s",0,255,255,hsv)
    parameter.integer("v",0,255,255,hsv)
    parameter.integer("r",0,255,255,rgb)
    parameter.integer("g",0,255,255,rgb)
    parameter.integer("b",0,255,255,rgb)
    parameter.integer("a",0,255,255)
end

function draw()
    background(40,40,50)
    fill(r,g,b,a)
    ellipse(WIDTH/2,HEIGHT/2,200)
end

function rgb()
    h,s,v = rgbToHsv(r,g,b)
    h,s,v = math.floor(h*255),math.floor(s*255),math.floor(v*255)
end

function hsv()
    r,g,b = hsvToRgb(h/255,s/255,v/255)
    r,g,b = math.floor(r),math.floor(g),math.floor(b)
end

function rgbToHsv(r, g, b, a)
    r, g, b = r / 255, g / 255, b / 255
    local max, min = math.max(r, g, b), math.min(r, g, b)
    local h, s, v
    v = max
    
    local d = max - min
    if max == 0 then s = 0 else s = d / max end
    
    if max == min then
        h = 0 -- achromatic
    else
        if max == r then
            h = (g - b) / d
            if g < b then h = h + 6 end
        elseif max == g then h = (b - r) / d + 2
        elseif max == b then h = (r - g) / d + 4
        end
        h = h / 6
    end
    
    return h, s, v, a
end

function hsvToRgb(h, s, v)
    local r, g, b
    
    local i = math.floor(h * 6);
    local f = h * 6 - i;
    local p = v * (1 - s);
    local q = v * (1 - f * s);
    local t = v * (1 - (1 - f) * s);
    
    i = i % 6
    
    if i == 0 then r, g, b = v, t, p
    elseif i == 1 then r, g, b = q, v, p
    elseif i == 2 then r, g, b = p, v, t
    elseif i == 3 then r, g, b = p, q, v
    elseif i == 4 then r, g, b = t, p, v
    elseif i == 5 then r, g, b = v, p, q
    end
    
    return r * 255, g * 255, b * 255
end]]