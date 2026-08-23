-- OmniRal

local WorldUIController = {}

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Services
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Modules
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

local Remotes = require(ReplicatedStorage.Source.Pronghorn.Remotes)
local New = require(ReplicatedStorage.Source.Pronghorn.New)

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Constants
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Remotes
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

local WorldUIService = Remotes.Client.WorldUIService

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Types
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

export type TextDisplayType = "SmallPointInjury" | "NPCStreakAdd" | "Other"

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Variables
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

local ClientVisuals = Workspace.ClientVisuals
local Assets = ReplicatedStorage.Assets

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Private Functions
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--[[local function UpdateHealthLines(Attributes: any, Point: any)
    for _, OldLine in Point.UnitGui.Canvas.Frame.HealthFrame.Back.Lines:GetChildren() do
        OldLine:Destroy()
    end

    local MaxHealth = Attributes.Base:GetAttribute("Health")
    for x = 1, math.round(MaxHealth / 25) - 1  do
        local NewLine = Point.UnitGui.Canvas.Frame.HealthFrame.Back.OGLine:Clone()
        NewLine.Position = UDim2.fromScale( ((25 / MaxHealth) * x), 0.5)
        NewLine.Visible = true
        NewLine.Parent = Point.UnitGui.Canvas.Frame.HealthFrame.Back.Lines
    end
end]]

local function SmallPointInjuryAnimation(Display: any, OtherDetails: {[string]: any})
    local Gui = Display.Gui
    local Container = Gui.Container
    local Label = Container.SmallPointInjury

    Gui.Size = UDim2.fromOffset(1, 1)
    Label.Text = OtherDetails.Amount
    Label.Stroke.Transparency = 0.75
    Label.Visible = true

    local FadeIn = TweenService:Create(Container, TweenInfo.new(0.1), {GroupTransparency = 0})
    local FadeOut = TweenService:Create(Container, TweenInfo.new(0.2), {GroupTransparency = 1})

    FadeIn.Completed:Connect(function() 
        TweenService:Create(Label.Stroke, TweenInfo.new(0.25, Enum.EasingStyle.Sine, Enum.EasingDirection.Out, 0, true), {Thickness = 2}):Play()

        task.wait(0.5)
        FadeOut:Play()
    end)

    FadeOut.Completed:Connect(function()
        Display:Destroy()
    end)

    TweenService:Create(Gui, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {ExtentsOffset = Vector3.new(0, 1, 0)}):Play()
    FadeIn:Play()
end

local function NPCStreakAddAnimation(Display: any, OtherDetails: {[string]: any})
    local Gui = Display.Gui
    local Container = Gui.Container
    local Label = Container.NPCStreakAdd
    local HangTime = 0.6

    Gui.Size = UDim2.fromScale(3, 3)
    Label.Text = OtherDetails.Amount
    Label.Visible = true

    local FadeIn = TweenService:Create(Container, TweenInfo.new(0.2), {GroupTransparency = 0})
    local FadeOut = TweenService:Create(Container, TweenInfo.new(0.2), {GroupTransparency = 1})

    FadeIn.Completed:Connect(function() 
        TweenService:Create(Label.Stroke, TweenInfo.new(0.2, Enum.EasingStyle.Sine, Enum.EasingDirection.Out, 0, true), {Thickness = 6}):Play()

        task.wait(HangTime)
        FadeOut:Play()
    end)

    FadeOut.Completed:Connect(function()
        Display:Destroy()
    end)

    local RiseTween_1 = TweenService:Create(Gui, TweenInfo.new(0.2, Enum.EasingStyle.Sine, Enum.EasingDirection.In), {ExtentsOffset = Vector3.new(0, 2, 0)})
    local RiseTween_2 = TweenService:Create(Gui, TweenInfo.new(HangTime, Enum.EasingStyle.Linear, Enum.EasingDirection.Out), {ExtentsOffset = Vector3.new(0, 2.25, 0)})
    local RiseTween_3 = TweenService:Create(Gui, TweenInfo.new(0.2, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {ExtentsOffset = Vector3.new(0, 4.25, 0)})

    RiseTween_1.Completed:Connect(function() 
        RiseTween_2:Play()
    end)
    RiseTween_2.Completed:Connect(function()
        RiseTween_3:Play()
    end)

    FadeIn:Play()
    RiseTween_1:Play()
end

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Public API
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

function WorldUIController.SpawnTextDisplay(DisplayType: TextDisplayType, Position: Vector3, OtherDetails: {[string]: any}?)
    --print("From: ", From, Affects, DisplayType, Position, OtherDetails)

    local Display = Assets.Particles.TextDisplay:Clone()
    Display.Transparency = 1
    Display.CFrame = CFrame.new(Position)
    Display.Parent = ClientVisuals

    if DisplayType == "SmallPointInjury" and OtherDetails and 1 == 0 then
        SmallPointInjuryAnimation(Display, OtherDetails)

    elseif DisplayType == "NPCStreakAdd" and OtherDetails then
        NPCStreakAddAnimation(Display, OtherDetails)
    end

end

function WorldUIController.AddGradientChangingValues(Gradient: UIGradient, AddForColor: {}?, AddForTransparency: {}?): {}?
    if not Gradient then return end

    local NewValues = {}
    if AddForColor then
        local A = New.Instance("Color3Value", "ColorA", Gradient, {Value = AddForColor[1]})
        local B = New.Instance("Color3Value", "ColorB", Gradient, {Value = AddForColor[2]})
        NewValues["ColorA"] = A
        NewValues["ColorB"] = B

        A.Changed:Connect(function()
            Gradient.Color = ColorSequence.new{
                ColorSequenceKeypoint.new(0, A.Value),
                ColorSequenceKeypoint.new(1, B.Value)
            }
        end)

        B.Changed:Connect(function()
            Gradient.Color = ColorSequence.new{
                ColorSequenceKeypoint.new(0, A.Value),
                ColorSequenceKeypoint.new(1, B.Value)
            }
        end)

        Gradient.Color = ColorSequence.new{
            ColorSequenceKeypoint.new(0, A.Value),
            ColorSequenceKeypoint.new(1, B.Value)
        }
    end
        
    if AddForTransparency then
        local A = New.Instance("NumberValue", "TransA", Gradient, {Value = AddForTransparency[1]})
        local B = New.Instance("NumberValue", "TransB", Gradient, {Value = AddForTransparency[2]})
        NewValues["TransA"] = A
        NewValues["TransB"] = B

        A.Changed:Connect(function()
            Gradient.Transparency = NumberSequence.new{
                NumberSequenceKeypoint.new(0, A.Value),
                NumberSequenceKeypoint.new(1, B.Value)
            }
        end)

        B.Changed:Connect(function()
            Gradient.Transparency = NumberSequence.new{
                NumberSequenceKeypoint.new(0, A.Value),
                NumberSequenceKeypoint.new(1, B.Value)
            }
        end)

        Gradient.Transparency = NumberSequence.new{
            NumberSequenceKeypoint.new(0, A.Value),
            NumberSequenceKeypoint.new(1, B.Value)
        }
    end

    if not AddForColor and not AddForTransparency then return end
    return NewValues
end

--[[function WorldUIController.GuiPointForUnit(Unit: Model)
    if not Unit then return end
    local Human, Root, Attributes = Unit:FindFirstChild("Humanoid"), Unit:FindFirstChild("HumanoidRootPart"), Unit:FindFirstChild("UnitAttributes")
    if not Human or not Root or not Attributes then return end

    local Connections = {}

    local CurrentDebuff = nil
    local DebuffTimerConnection = nil
    local Events = {"ChildAdded", "ChildRemoved"}

    local Point = Assets.Misc.BillboardGuiContainer.GuiPoint:Clone()
    Point.UnitGui.Canvas.Frame.HealthFrame.Back.OGLine.Visible = false
    Point.UnitGui.Canvas.Frame.HealthFrame.Back.Bar.Size = UDim2.fromScale(1, 1)
    Point.UnitGui.Canvas.Frame.HealthFrame.Back.White.Size = UDim2.fromScale(1, 1)
    Point.StateGui.Canvas.GroupTransparency = 1
    Point.StateGui.SizeOffset = Vector2.new(0, 1.9)

    Point.StateGui:SetAttribute("Hidden", true)
    Point.StateGui:GetAttributeChangedSignal("Hidden"):Connect(function()
        local GoalTransparency, GoalOffset = 1, Vector2.new(0, 1.9)
        if not Point.StateGui:GetAttribute("Hidden") then
            GoalTransparency = 0
            GoalOffset = Vector2.new(0, 2)
        end

        TweenService:Create(Point.StateGui, TweenInfo.new(UIBasics.BaseTweenTime, Enum.EasingStyle.Linear), {SizeOffset = GoalOffset}):Play()
        TweenService:Create(Point.StateGui.Canvas, TweenInfo.new(UIBasics.BaseTweenTime, Enum.EasingStyle.Linear), {GroupTransparency = GoalTransparency}):Play()
    end)

    Point.Parent = Root

    Point.UnitGui.Canvas.Frame.UnitName.Text = Unit.Name

    Attributes.Base:GetAttributeChangedSignal("Health"):Connect(function()
        UpdateHealthLines(Attributes, Point)
    end)

    Attributes.Current.Health.Changed:Connect(function()
        GeneralUILibrary:UpdateHealthBar(Attributes.Current.Health.Value, Attributes.Base:GetAttribute("Health"), Point.UnitGui.Canvas.Frame.HealthFrame.Back.Bar, Point.UnitGui.Canvas.Frame.HealthFrame.Back.White)
        if Attributes.Current.Health.Value <= 0 then
            for _, OldConnection in Connections do
                OldConnection:Disconnect()
            end
        end
    end)

    for _, Event in Events do
        Attributes.Effects[Event]:Connect(function(Effect: any)
            local GotDebuff, GotState = UpdateCurrentDebuff(Attributes)
            if GotDebuff and GotState then
                CurrentDebuff = GotDebuff
                if DebuffTimerConnection then
                    DebuffTimerConnection:Disconnect()
                end
    
                DebuffTimerConnection = CurrentDebuff.Timer.Changed:Connect(function()
                    Point.StateGui.Canvas.Frame.BarFrame.Back.Bar.Size = UDim2.fromScale(CurrentDebuff.Timer.Value / CurrentDebuff:GetAttribute("Duration"), 1)
                end)

                Point.StateGui.Canvas.Frame.StateType.Text = GotState
                Point.StateGui:SetAttribute("Hidden", false)
            else
                Point.StateGui:SetAttribute("Hidden", true)
            end
        end)
    end

    UpdateHealthLines(Attributes, Point)
    --Attributes.States
end]]

function WorldUIController:Init()

end

function WorldUIController:Deferred()
    WorldUIService.SpawnTextDisplay:Connect(function(DisplayType: TextDisplayType, Position: Vector3, OtherDetails: {[string]: any}?)
        WorldUIController.SpawnTextDisplay(DisplayType, Position, OtherDetails)
    end)
end

return WorldUIController