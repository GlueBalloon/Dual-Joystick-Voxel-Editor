TouchesManager = class()

function TouchesManager:init(player, omniTool, shelf)
    self.player = player
    self.tool = omniTool
    self.shelf = shelf
end

function TouchesManager:touched(touch)
    if self.tool.toolMode ~= OmniTool.TOOL_NONE then
        self.tool:touched(touch)
    else
        if self.player.touched then
            if self.player.isLegacy then
                self.player:touched(touch) 
            else
                self.player.touched(nil, touch)
            end
        end 
        self.shelf:touched(touch)
    end
    return true
end