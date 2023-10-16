TouchesManager = class()

function TouchesManager:init(player, omniTool, shelf)
    self.player = player
    self.tool = omniTool
    self.shelf = shelf
end

function TouchesManager:touched(touch)
    
    -- Always check for touches on the shelf, regardless of the toolMode
    local shelfTapped = self.shelf:hitTest(touch.x, touch.y) or self.shelf.screenTopPanel:hitTest(touch.x, touch.y)
    if shelfTapped then
    --    print("shelfTapped")
        self.shelf:touched(touch)
        -- Optionally, return here if you don't want to propagate the touch event further when the shelf is tapped
        return true
    end 
    if self.tool.toolMode ~= OmniTool.TOOL_NONE then
   --     print("self.tool.toolMode ~= OmniTool.TOOL_NONE")
            -- Only handle touches with the tool if the shelf wasn't tapped
        self.tool:touched(touch)
        return true
    end    
    
    return false
end