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