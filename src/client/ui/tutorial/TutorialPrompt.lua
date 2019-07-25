local ui    = script.Parent.Parent
local Roact = require(game.ReplicatedStorage.Roact)

local NextPromptButton = require(ui.tutorial.NextPromptButton)
local PreviousPromptButton = require(ui.tutorial.PreviousPromptButton)

local TutorialPrompt = Roact.Component:extend("TutorialPrompt")

local tutorialSequence = {
    {Size = UDim2.new(0, 649, 0, 341), Position = UDim2.new(0, 20, 1, -306), Image = "rbxassetid://3470337276"},
    {Size = UDim2.new(0, 638, 0, 341), Position = UDim2.new(0, 25, 1, -306), Image = "rbxassetid://3470333280"},
    {Size = UDim2.new(0, 653, 0, 341), Position = UDim2.new(0, 670, 1, -315), Image = "rbxassetid://3470328016"},
    {Size = UDim2.new(0, 638, 0, 341), Position = UDim2.new(0, 685, 1, -315), Image = "rbxassetid://3470339354"},
    {Size = UDim2.new(0, 653, 0, 341), Position = UDim2.new(0, 670, 1, -315), Image = "rbxassetid://3470339219"},
    {Size = UDim2.new(0, 638, 0, 341), Position = UDim2.new(1, -700, 0, 20), Image = "rbxassetid://3470327868"},
    {Size = UDim2.new(0, 638, 0, 341), Position = UDim2.new(1, -700, 0, 20), Image = "rbxassetid://3470333025"},
    {Size = UDim2.new(0, 638, 0, 341), Position = UDim2.new(1, -700, 0, 20), Image = "rbxassetid://3470339472"},
    {Size = UDim2.new(0, 638, 0, 341), Position = UDim2.new(1, -700, 0, 20), Image = "rbxassetid://3470328143"},
    {Size = UDim2.new(0, 638, 0, 341), Position = UDim2.new(1, -700, 0, 20), Image = "rbxassetid://3470328252"},
    {Size = UDim2.new(0, 638, 0, 341), Position = UDim2.new(1, -700, 0, 20), Image = "rbxassetid://3470333132"},
    {Size = UDim2.new(0, 638, 0, 341), Position = UDim2.new(1, -700, 0, 20), Image = "rbxassetid://3470332747"},
    {Size = UDim2.new(0, 638, 0, 341), Position = UDim2.new(1, -700, 0, 20), Image = "rbxassetid://3470337406"},
    {Size = UDim2.new(0, 638, 0, 341), Position = UDim2.new(1, -700, 0, 20), Image = "rbxassetid://3470328336"},
    {Size = UDim2.new(0, 638, 0, 341), Position = UDim2.new(1, -700, 0, 20), Image = "rbxassetid://3470332877"},
}

function TutorialPrompt:init()
    self:setState({
        index = 1,
    })
end

function TutorialPrompt:render()
    local children = {}

    if self.state.index ~= 3 and self.state.index ~= 5 then
        children.next = Roact.createElement(NextPromptButton, {
            onClick = (function() self:nextPrompt() end),
        })
    end

    if self.state.index > 1 then
        children.previous = Roact.createElement(PreviousPromptButton, {
            onClick = (function() self:previousPrompt() end),
        })
    end

    return Roact.createElement("ImageLabel", {
        Size                   = tutorialSequence[self.state.index].Size,
        Position               = tutorialSequence[self.state.index].Position,
        AnchorPoint            = Vector2.new(0, 0),
        BackgroundTransparency = 1,
        Image                  = tutorialSequence[self.state.index].Image,
    }, children)
end

function TutorialPrompt:nextPrompt()
    self:setState({index = self.state.index + 1})
    self:dynamicPromptState()
end

function TutorialPrompt:previousPrompt()
    self:setState({index = self.state.index - 1})
    self:dynamicPromptState()
end

function TutorialPrompt:dynamicPromptState()
    if self.state.index == 3 then
        self.props.UIBase.showBuildButton()
        self.props.UIBase.waitForUIState(self.props.UIBase.State.BUILD)
        self:setState({index = 4})
    elseif self.state.index == 5 then
        self.props.UIBase.waitForUIState(self.props.UIBase.State.MAIN)
        self:setState({index = 6})
        self.props.UIBase.enableManagedInput()
    end
end

return TutorialPrompt
