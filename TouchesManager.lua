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
        self.player:touched(touch)
        self.shelf:touched(touch)
    end
    return true
end