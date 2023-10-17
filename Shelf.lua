-- The shelf itself!

Shelf = class(UI.Panel)

function Shelf:init(omniTool, volumeTools, standardizedUnit, buttonRadius, x, y, w, h)
    self.unit = standardizedUnit or math.min(WIDTH / 10, HEIGHT / 10)
    self.buttonRadius = buttonRadius or math.min(self.unit * 1.2, 90) 
    x = x or WIDTH - self.buttonRadius * 1.05
    y = y or 0
    w = w or self.unit * 0.6 
    h = h or HEIGHT - self.unit * 0.07
        --the basics
    UI.Panel.init(self, x, y, w, h)
    self.fill = nil
    self.startColor = color(12, 87, 215)
    self.helpTextColor = color(0, 255, 240)
    self.helpLabelDelay = 13.5 * 60
    self.tool = omniTool
    self.volumeTools = volumeTools
    local paddingBetweenSections = self.unit * 0.3

    --make buttons that have to be accessed outside this class
    self:makeColorChooser()
    self.idleButton = self:makeRoundToolButton("🚁", OmniTool.TOOL_NONE, "move")
    self.idleButton.selected = false
    
    local topPanelWidth = self.buttonRadius * 6
    local buttonFrame = self.idleButton.frame
    local screenTopPanelX = WIDTH - topPanelWidth - self.buttonRadius * 1.05 + paddingBetweenSections 
    local screenTopPanelY = HEIGHT - self.buttonRadius * 1.05
    self.screenTopPanel = UI.Panel(screenTopPanelX, screenTopPanelY, topPanelWidth, buttonFrame.h)
    self.screenTopPanel.fill = color(233, 89, 80, 0)
    
    self.toolTypeButtons = {
        self:makeRoundToolTypeButton("◾️", OmniTool.TOOL_TYPE_POINT, "blocks"),
        self:makeRoundToolTypeButton("⬛️", OmniTool.TOOL_TYPE_BOX, "boxes")
    }

    --set up the different sections on the shelf
    local mirrorX = self:roundButton("x|x", "mirror X")
    mirrorX.action = function(b) 
        b.selected = not b.selected
        self.tool.shouldMirror.x = b.selected
        if b.selected then
            self.toolTip = b.toolTipText
        else
            self.toolTip = ""
        end 
    end
    local mirrorY = self:roundButton("y|y", "mirror Y")
    mirrorY.action = function(b) 
        b.selected = not b.selected
        self.tool.shouldMirror.y = b.selected
        if b.selected then
            self.toolTip = b.toolTipText
        else
            self.toolTip = ""
        end       
    end
    local mirrorZ = self:roundButton("z|z", "mirror Z")
    mirrorZ.action = function(b) 
        b.selected = not b.selected
        self.tool.shouldMirror.z = b.selected
        if b.selected then
        self.toolTip = b.toolTipText
        else
            self.toolTip = ""
        end 
    end
    local spacer = UI.Panel(0, 0, paddingBetweenSections, paddingBetweenSections)
    spacer.fill = nil
    
    self.mirroringContainer = self:makeScreenTopSection("mirroring", 
    { mirrorX, 
    mirrorY, 
    mirrorZ
        })
    
    self:makeScreenTopSection("type buttons", {
        self.toolTypeButtons[1],
        self.toolTypeButtons[2]
    }) 
    
    self:makeScreenTopSection("fps toggle", 
    {self.idleButton})
    
    topPanelWidth = paddingBetweenSections
    for _, container in ipairs(self.screenTopPanel.children) do
        topPanelWidth = topPanelWidth + paddingBetweenSections + container.frame.w
    end
    self.screenTopPanel.frame.w = topPanelWidth
    self.screenTopPanel.frame.x = WIDTH - topPanelWidth - self.buttonRadius * 1.05 
    self.screenTopPanel:layoutHorizontal(paddingBetweenSections, false)
    
    self:makeSection("color chooser", {
        self.colorChooser
    }, true)
    
    self.toolsSection = self:makeSection("tools", 
    {
        self:makeRoundToolButton("✏️", OmniTool.TOOL_ADD, "draw"),
        self:makeRoundToolButton("💣", OmniTool.TOOL_ERASE, "delete"), 
        self:makeRoundToolButton("💅🏻", OmniTool.TOOL_REPLACE, "paint"),
        self:makeRoundToolButton("💉", OmniTool.TOOL_GET, "get color")
    }, true)
    self.toolsSection.children[1].selected = true
    
    local undoButton = self:roundButton("↩️", "undo")
    undoButton.action = function(b) 
        self.volumeTools:undo()
        self.toolTip = undoButton.toolTipText 
    end
    local redoButton = self:roundButton("↪️", "redo")
    redoButton.action = function(b) 
        self.volumeTools:redo() 
        self.toolTip = redoButton.toolTipText 
    end
    self:makeSection("undo/redo", 
    { undoButton, redoButton }, true)  
    
    --make help button
    self.showHelpLabels = false
    self.helpLabelFade = 0
    self:makeHelpButton()
    
    --lay out all the shelf's children vertically
    self:layoutVertical(paddingBetweenSections, false)
    self.frame.y = self.frame.y + paddingBetweenSections --hiding padding at top
    
    --not relevant any more:
    self.toolTip = "This is an immersive voxel editor,\n"..
    "with two-joystick movement controls\n"..
    "like a mobile game.\n\n"..
    "The left stick controls your 'body',\n"..
    "the right stick controls your 'head', and\n"..
    "the helicopter button switches between\n"..
    " movement and editing.\n"..
    "Have fun!"
    self.toolTipFontSize = fontSizeToFitRect(self.toolTip, 0, 0, WIDTH * 0.8, HEIGHT * 0.4)
    self.toolTip = ""
    self.toolTipOpacity = 255
    self.firstToolTipShowing = true
    

    
end

function Shelf:makeHelpButton()
    local helpButton = self:roundButton("🤔", "help")
    helpButton.action = function(b)
        self.showHelpLabels = not self.showHelpLabels
        self.helpLabelFade = 255  -- Reset the fade value
        self.helpLabelDelay = 13.5 * 60  -- Reset the delay assuming 60 fps.
    end
    self:makeSection("help button", {helpButton}, true)
end


function Shelf:draw()
    UI.Panel.draw(self) 
   -- if CurrentTouch.state ~= 3 then print(CurrentTouch.state) end
    if self.toolTip ~= "" then
        if self.idleButton.selected == false then
            self.firstToolTipShowing = false
        end
        if CurrentTouch.state == MOVING or self.toolTipOpacity < 254 then 
            self.fadeStarted = true 
        end
        pushStyle()
        pushMatrix()
        resetMatrix()
        font("HelveticaNeue-Light")
        fontSize(self.toolTipFontSize)
        textMode(CENTER)
        textAlign(CENTER)
        pushStyle()
        fill(30, 126, 107, self.toolTipOpacity)
        text(self.toolTip, WIDTH/2 + 1, HEIGHT/2 - 2)
        popStyle()
        local c = self.helpTextColor
        fill(c.x, c.y, c.z, self.toolTipOpacity)
        text(self.toolTip, WIDTH/2, HEIGHT/2)
        popMatrix()
        popStyle()
        if self.fadeStarted then
            self.toolTipOpacity = self.toolTipOpacity - 10
        elseif self.firstToolTipShowing == true then
            --sneakily use minor increments in toolTipOpacity as a counter
            self.toolTipOpacity = self.toolTipOpacity - 0.001
        else
            --fade out faster if this isn't the opening info
            self.toolTipOpacity = self.toolTipOpacity - 0.015
        end
        if self.toolTipOpacity <= 0 then 
            self.toolTip = ""
            self.toolTipOpacity = 255
            self.fadeStarted = false
        end
    end
    if self.showHelpLabels then
        -- If there's a delay, decrement it
        if self.helpLabelDelay > 0 then
            self.helpLabelDelay = self.helpLabelDelay - 1
            -- Once delay is over, start fading out the labels
        elseif self.helpLabelFade > 0 then
            self.helpLabelFade = self.helpLabelFade - 5
            -- If completely faded out, turn off help labels
        else
            self.showHelpLabels = false
        end
        
        -- As long as there's delay or visible fade, draw the labels
        if self.helpLabelDelay > 0 or self.helpLabelFade > 0 then
            self:setupTextStyles()
            self:drawShelfLabels()
            self:drawLabelsBelow()
            popStyle()  -- Ensure to pop the style to reset any changes made by setupTextStyles
        end
    end
    
end

function Shelf:setupTextStyles()
    pushStyle()
    font("HelveticaNeue-Light")
    fontSize(self.buttonRadius * 0.3)
    textAlign(CENTER)
    textMode(CORNER)
    local c = self.helpTextColor
    fill(c.x, c.y, c.z, self.helpLabelFade)
end

function Shelf:drawLabelToLeft(button, globalX, globalY)
    if button.toolTipText then
        local textW, textH = textSize(button.toolTipText)
        local labelPosX = globalX - textW - 10
        local labelPosY = globalY + (button.frame.h / 2) - (textH / 2.8)
        text(button.toolTipText, labelPosX, labelPosY)
    end
end

function Shelf:drawLabelsBelow()
    pushStyle()
    textMode(CENTER)
    local yOffset = 0
    local longTexts = {"mirror X", "mirror Y", "mirror Z"}
    local stagger = true -- start with stagger for first longText
    for i, section in pairs(self.screenTopPanel.children) do
        for _, button in ipairs(section.children) do
            local globalX, globalY = button.frame.x + section.frame.x + self.screenTopPanel.frame.x, 
            button.frame.y + section.frame.y + self.screenTopPanel.frame.y
            if button.toolTipText then
                local _, textSizeHeight = textSize(button.toolTipText)
                if table.contains(longTexts, button.toolTipText) then
                    if stagger then
                        yOffset = textSizeHeight * 1.1
                    else
                        yOffset = 0
                    end
                    stagger = not stagger
                else
                    yOffset = 0  -- reset yOffset for short texts
                    stagger = true  -- reset stagger for short texts
                end
                local labelPosX = globalX + (button.frame.w / 2)
                local labelPosY = globalY - yOffset - 20
                text(button.toolTipText, labelPosX, labelPosY)
            end
        end
    end
    popStyle()
end



function Shelf:drawShelfLabels()
    for _, section in ipairs(self.children) do
        for _, button in ipairs(section.children) do
            local globalX, globalY = button.frame.x + section.frame.x + self.frame.x, button.frame.y + section.frame.y + self.frame.y
            self:drawLabelToLeft(button, globalX, globalY)
        end
    end
end

function Shelf:makeScreenTopSection(name, items)
    local container
        local contentWidth = 0
        container = UI.Panel(0, 0, self.frame.w, items[1].frame.h)
        for k,v in pairs(items) do
            container:addChild(v) 
            contentWidth = contentWidth + v.frame.w
        end
        container.frame.w = contentWidth
    container:layoutHorizontal(1, false)
    container.fill = color(228, 158, 25, 0)
    self.screenTopPanel:addChild(container)
    return container
end

function Shelf:setColor(aColor)
    self.color = aColor
    self.colorChooser.selectedFill = self.color
    self.colorChooser.unselectedFill = self.color   
end

function Shelf:makeColorChooser(buttonRadius)
    pushStyle()
    stroke(166, 43)
    strokeWidth(self.unit * 0.12)
    self.colorChooser = self:roundButton("")
    popStyle()
    self.colorChooser.selectedFill = self.color
    self.colorChooser.unselectedFill = self.color
    self.highlightedFill = color(181, 181, 181, 255)
    self.colorChooser.action = function() 
        if codeaViewer.mode ~= OVERLAY then
            self.toolTip = "show overlay panel"
            codeaViewer.mode = OVERLAY 
        else
            self.toolTip = "hide overlay panel"
            codeaViewer.mode = FULLSCREEN
        end
    end
end

function Shelf:makeSection(name, items, isVertical)
    local container
    if isVertical then
        container = UI.Panel(0, 0, items[1].frame.w, 0)        
        local contentHeight = 0
        for k,v in pairs(items) do
            container:addChild(v) 
            contentHeight = contentHeight + (v.frame.h * 1.06)
        end
        container.frame.h = contentHeight
    else 
        local contentWidth = 0
        container = UI.Panel(0, 0, self.frame.w, 30)
        for k,v in pairs(items) do
            container:addChild(v) 
            contentWidth = contentWidth + v.frame.w
        end
        container.frame.w = contentWidth * 2.5
        container.frame.x = -contentWidth + (items[1].frame.w * 0.9)
    end
    if isVertical then
        container:layoutVertical(1, false) 
    else
        container:layoutHorizontal(0, false)
    end
    container.fill = color(228, 158, 25, 0)
    self:addChild(container)
    return container
end

function Shelf:roundButton(iconChar, toolTipText, buttonRadius)
    buttonRadius = buttonRadius or self.buttonRadius
    fontSize(buttonRadius * 0.62)
    local roundy = UI.Button(0, 0, buttonRadius, buttonRadius, iconChar)  
    roundy.frame.h = buttonRadius
    roundy.cornerRadius = buttonRadius
    roundy.unselectedFill = color(143, 23)
    roundy.selectedFill = color(114, 216, 227, 56)
    roundy.toolTipText = toolTipText
    return roundy
end

function Shelf:makeRoundToolButton(iconChar, mode, toolTipText)
    local toolButton = self:roundButton(iconChar, toolTipText)  
    toolButton.mode = mode
    toolButton.action = function(b) 
        
        for k,v in pairs(self.toolsSection.children) do
            if v ~= toolButton then
                v.selected = false
            end
        end
        
        b.selected = not b.selected
        if b.mode ~= OmniTool.TOOL_NONE then
            if b.selected then
                self.toolTip = b.toolTipText or ""
                self.tool.toolMode = mode
                self.idleButton.selected = false 
            else
                self.tool.toolMode = OmniTool.TOOL_NONE
                self.idleButton.selected = true 
                self.toolTip = self.idleButton.toolTipText
            end 
        end
        
        if b.mode == OmniTool.TOOL_NONE then
            if not b.selected then
                self.tool.toolMode = OmniTool.TOOL_ADD
                self.toolsSection.children[1].selected = true
                self.toolTip = self.toolsSection.children[1].toolTipText or ""
            else 
                self.tool.toolMode = OmniTool.TOOL_NONE
                self.toolTip = b.toolTipText or ""
            end
        end
    end
    
    return toolButton
end

function Shelf:makeRoundToolTypeButton(iconChar, mode, toolTipText)
    local toolButton = self:roundButton(iconChar, toolTipText)  
    
    if mode == self.tool.toolType then
        toolButton.selected = true
    end    
    
    toolButton.action = function(b) 
        for k,v in pairs(self.toolTypeButtons) do
            v.selected = false
        end
        
        b.selected = true
        self.tool.toolType = mode
        
        if b.selected then
            self.toolTip = b.toolTipText or ""
        end 
    end
    
    return toolButton
end

