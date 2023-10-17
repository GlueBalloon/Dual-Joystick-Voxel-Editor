ModalDialog = class()

function ModalDialog:init(title, message, confirmAction, cancelAction)
    self.title = title or "Warning"
    self.message = message or "Are you Sure? Please confirm."
    self.confirmAction = confirmAction
    self.cancelAction = cancelAction
    self.isVisible = false
end

function ModalDialog:show(title, message)
    self.title = title or self.title
    self.message = message or self.message
    self.isVisible = true
end

function ModalDialog:hide()
    self.isVisible = false
end

function ModalDialog:draw()
    if not self.isVisible then return end
    
    pushStyle()
    
    -- Make rounded rect behind all
    fill(255)  -- White background
    local dialogWidth = WIDTH/2.5
    textWrapWidth(dialogWidth - 80)
    local w, h = textSize(self.message)
    local dialogHeight = h 
    roundRect(WIDTH/2 - dialogWidth/2, HEIGHT/2 - dialogHeight/2, dialogWidth, dialogHeight, 30)  -- The main rectangle
    
    fill(0)  -- Black text color
    fontSize(24)
    local _, textH = textSize(self.title)
    text(self.title, WIDTH/2, HEIGHT/2 + (dialogHeight/2) - textH - 20)
    
    -- Wrap and measure the text
    text(self.message, WIDTH/2, HEIGHT/2 + 20)
     
    local yesX = WIDTH/2 - dialogWidth/4
    local cancelX = WIDTH/2 + dialogWidth/4
    local buttonAreaH = dialogHeight/3.5 
    local buttonY = HEIGHT/2 - dialogHeight/2 + textH/2 + 20
    local lineY = HEIGHT/2 - dialogHeight/2 + textH*2 + 20
    
    -- Draw line
    stroke(200) -- Gray line
    strokeWidth(1)
    line(WIDTH/2 - dialogWidth/2, lineY, WIDTH/2 + dialogWidth/2, lineY)
    
    -- Yes button
    if CurrentTouch.x > yesX - 30 and CurrentTouch.x < yesX + 30 and CurrentTouch.y > buttonY - 15 and CurrentTouch.y < buttonY + 15 then
        fill(200) -- Gray when pressed
        if CurrentTouch.state == ENDED then
            self:hide()
            self.confirmAction()
        end
    else
        fill(0) -- Black
    end
    text("Yes", yesX, buttonY)
    
    -- Cancel button
    if CurrentTouch.x > cancelX - 60 and CurrentTouch.x < cancelX + 60 and CurrentTouch.y > buttonY - 15 and CurrentTouch.y < buttonY + 15 then
        fill(200) -- Gray when pressed
        if CurrentTouch.state == ENDED then
            self:hide()
            self.cancelAction()
        end
    else
        fill(255, 0, 0) -- Red
    end
    text("Cancel", cancelX, buttonY)
    
    popStyle()
end
