function fontSizeToFitRect(textToFit, x, y, w, h) 
    local fSize, fontSizeNotSet, testString, bounds, acceptableInset
    fSize = fontSize()
    fontSizeNotSet = true
    testString = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890-/:;()$&@.,?!'[]{}#%^*+=_\\|~<>€£¥•\""
    
    pushStyle()
    rectMode(CENTER)
    textWrapWidth(w)
    while fontSizeNotSet do
        bounds = vec2(textSize(textToFit))
        pushStyle()
        textWrapWidth(500000000)
        _, acceptableInset = textSize(testString)
        popStyle()
        if math.floor(bounds.y) < math.floor(h - acceptableInset) then
            fSize = fSize + 0.1
        elseif math.floor(bounds.y) > math.floor(h) then
            fSize = fSize - 0.1
        else                
            fontSizeNotSet = false
        end
        fontSize(fSize)
    end    
    return fSize
end

function colorFromInt(int)
    local r = (int>>24) & 255
    local g = (int>>16) & 255   
    local b = (int>>8) & 255     
    return color(r, g, b)
end

function table.contains(table, element)
    for _, value in pairs(table) do
        if value == element then
            return true
        end
    end
    return false
end

function roundRect(x,y,w,h,r)
    pushStyle()
    
    insetPos = vec2(x+r,y+r)
    insetSize = vec2(w-2*r,h-2*r)
    
    --Copy fill into stroke
    local red,green,blue,a = fill()
    stroke(red,green,blue,a)
    
    noSmooth()
    rectMode(CORNER)
    rect(insetPos.x,insetPos.y,insetSize.x,insetSize.y)
    
    if r > 0 then
        smooth()
        lineCapMode(ROUND)
        strokeWidth(r*2)
        
        line(insetPos.x, insetPos.y, 
        insetPos.x + insetSize.x, insetPos.y)
        line(insetPos.x, insetPos.y,
        insetPos.x, insetPos.y + insetSize.y)
        line(insetPos.x, insetPos.y + insetSize.y,
        insetPos.x + insetSize.x, insetPos.y + insetSize.y)
        line(insetPos.x + insetSize.x, insetPos.y,
        insetPos.x + insetSize.x, insetPos.y + insetSize.y)            
    end
    popStyle()
end