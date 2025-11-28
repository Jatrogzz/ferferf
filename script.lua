-- After 3 AM Premium Hub
-- Dark Theme GUI with Hotkey System

local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer

-- Global Variables
local AutoKillEnabled = false
local ESPEnabled = false
local ItemESPEnabled = false
local SpeedBoostEnabled = false
local InfiniteStaminaEnabled = false
local FullbrightEnabled = false
local NoFogEnabled = false
local AntiLagEnabled = false
local AutoKillConnection = nil
local ESPObjects = {}
local ItemESPObjects = {}
local Hotkeys = {}
local HotkeyNames = {} -- Map hotkey to name
local GUIEnabled = false

-- Dark Theme Colors (Cyberpunk/Gothic Style)
local DarkBackground = Color3.fromRGB(10, 10, 15)
local DarkFrame = Color3.fromRGB(18, 18, 25)
local DarkSection = Color3.fromRGB(22, 22, 30)
local DarkButton = Color3.fromRGB(25, 25, 35)
local AccentRed = Color3.fromRGB(220, 20, 60)
local AccentBlue = Color3.fromRGB(30, 144, 255)
local AccentPurple = Color3.fromRGB(138, 43, 226)
local TextPrimary = Color3.fromRGB(240, 240, 240)
local TextSecondary = Color3.fromRGB(180, 180, 180)
local BorderColor = Color3.fromRGB(40, 40, 50)

-- Item Detection Functions
local function FindItems()
    local items = {}
    
    -- Common item locations in After 3 AM
    local possibleFolders = {
        workspace:FindFirstChild("Items"),
        workspace:FindFirstChild("Collectibles"),
        workspace:FindFirstChild("Pickups"),
        workspace:FindFirstChild("ItemSpawns"),
        workspace:FindFirstChild("Spawns")
    }
    
    -- Check folders
    for _, folder in ipairs(possibleFolders) do
        if folder then
            for _, item in ipairs(folder:GetDescendants()) do
                if item:IsA("BasePart") and item.Parent == folder or item.Parent.Parent == folder then
                    table.insert(items, item)
                end
            end
        end
    end
    
    -- Search workspace for items (BaseParts that might be collectibles)
    -- Look for parts with specific properties or names
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("BasePart") and not obj:IsA("Terrain") then
            -- Check if it's likely an item (has ClickDetector, ProximityPrompt, or specific name patterns)
            if obj:FindFirstChild("ClickDetector") or 
               obj:FindFirstChild("ProximityPrompt") or
               obj.Name:find("Item") or 
               obj.Name:find("Collectible") or
               obj.Name:find("Pickup") or
               (obj:FindFirstChild("BillboardGui") and obj.BillboardGui:FindFirstChild("TextLabel")) then
                -- Make sure it's not a player part or monster
                if not obj:FindFirstAncestorOfClass("Model") or 
                   (obj:FindFirstAncestorOfClass("Model") and 
                    obj:FindFirstAncestorOfClass("Model").Name ~= LocalPlayer.Name and
                    obj:FindFirstAncestorOfClass("Model").Name ~= "CurrentMonsters") then
                    table.insert(items, obj)
                end
            end
        end
    end
    
    return items
end

-- Create ESP for item
local function CreateItemESP(item)
    if not item or not item.Parent then return end
    
    -- Find the main part (could be the item itself or its PrimaryPart)
    local part = item
    if item:IsA("Model") and item.PrimaryPart then
        part = item.PrimaryPart
    elseif item:IsA("BasePart") then
        part = item
    else
        return
    end
    
    if not part or not part.Parent then return end
    
    -- Check if ESP already exists
    if part:FindFirstChild("ItemESP") then return end
    
    local BillboardGui = Instance.new("BillboardGui")
    BillboardGui.Name = "ItemESP"
    BillboardGui.Adornee = part
    BillboardGui.Size = UDim2.new(0, 150, 0, 70)
    BillboardGui.StudsOffset = Vector3.new(0, 3, 0)
    BillboardGui.AlwaysOnTop = true
    BillboardGui.Parent = part
    
    local Frame = Instance.new("Frame")
    Frame.Size = UDim2.new(1, 0, 1, 0)
    Frame.BackgroundColor3 = AccentBlue
    Frame.BackgroundTransparency = 0.5
    Frame.BorderSizePixel = 0
    Frame.Parent = BillboardGui
    
    local Corner = Instance.new("UICorner")
    Corner.CornerRadius = UDim.new(0, 6)
    Corner.Parent = Frame
    
    local Border = Instance.new("UIStroke")
    Border.Color = AccentBlue
    Border.Thickness = 2
    Border.Parent = Frame
    
    local Label = Instance.new("TextLabel")
    Label.Size = UDim2.new(1, -10, 0.6, 0)
    Label.Position = UDim2.new(0, 5, 0, 5)
    Label.BackgroundTransparency = 1
    Label.Font = Enum.Font.GothamBold
    Label.Text = "ITEM"
    Label.TextColor3 = TextPrimary
    Label.TextSize = 14
    Label.TextStrokeTransparency = 0
    Label.Parent = Frame
    
    local NameLabel = Instance.new("TextLabel")
    NameLabel.Size = UDim2.new(1, -10, 0.4, 0)
    NameLabel.Position = UDim2.new(0, 5, 0.6, 0)
    NameLabel.BackgroundTransparency = 1
    NameLabel.Font = Enum.Font.Gotham
    NameLabel.Text = item.Name
    NameLabel.TextColor3 = AccentPurple
    NameLabel.TextSize = 11
    NameLabel.TextStrokeTransparency = 0
    NameLabel.TextWrapped = true
    NameLabel.Parent = Frame
    
    table.insert(ItemESPObjects, {gui = BillboardGui, item = item, part = part})
end

-- Teleport to nearest item
local function TeleportToNearestItem()
    local character = LocalPlayer.Character
    if not character or not character:FindFirstChild("HumanoidRootPart") then return end
    
    local items = FindItems()
    if #items == 0 then
        print("No items found!")
        return
    end
    
    local humanoidRootPart = character.HumanoidRootPart
    local nearestItem = nil
    local nearestDistance = math.huge
    
    for _, item in ipairs(items) do
        local part = nil
        if item:IsA("Model") and item.PrimaryPart then
            part = item.PrimaryPart
        elseif item:IsA("BasePart") then
            part = item
        end
        
        if part and part.Parent then
            local distance = (humanoidRootPart.Position - part.Position).Magnitude
            if distance < nearestDistance then
                nearestDistance = distance
                nearestItem = part
            end
        end
    end
    
    if nearestItem then
        -- Teleport
        humanoidRootPart.CFrame = CFrame.new(nearestItem.Position + Vector3.new(0, 3, 0))
        print("Teleported to item: " .. nearestItem.Name)
    else
        print("No valid item found to teleport to!")
    end
end

-- Create Main GUI
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "After3AMHub"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.DisplayOrder = 999

if LocalPlayer.PlayerGui:FindFirstChild("After3AMHub") then
    LocalPlayer.PlayerGui:FindFirstChild("After3AMHub"):Destroy()
end

ScreenGui.Parent = LocalPlayer.PlayerGui

-- Main Container
local MainContainer = Instance.new("Frame")
MainContainer.Name = "MainContainer"
MainContainer.Size = UDim2.new(0, 550, 0, 0)
MainContainer.Position = UDim2.new(0.5, -275, 0.5, -300)
MainContainer.BackgroundColor3 = DarkFrame
MainContainer.BorderSizePixel = 0
MainContainer.ClipsDescendants = true
MainContainer.Visible = false
MainContainer.Parent = ScreenGui

local ContainerCorner = Instance.new("UICorner")
ContainerCorner.CornerRadius = UDim.new(0, 10)
ContainerCorner.Parent = MainContainer

local ContainerBorder = Instance.new("UIStroke")
ContainerBorder.Color = BorderColor
ContainerBorder.Thickness = 1
ContainerBorder.Parent = MainContainer

-- Header
local Header = Instance.new("Frame")
Header.Name = "Header"
Header.Size = UDim2.new(1, 0, 0, 50)
Header.BackgroundColor3 = DarkSection
Header.BorderSizePixel = 0
Header.Parent = MainContainer

local HeaderCorner = Instance.new("UICorner")
HeaderCorner.CornerRadius = UDim.new(0, 10)
HeaderCorner.Parent = Header

local HeaderBorder = Instance.new("UIStroke")
HeaderBorder.Color = AccentRed
HeaderBorder.Thickness = 2
HeaderBorder.Parent = Header

local Title = Instance.new("TextLabel")
Title.Name = "Title"
Title.Size = UDim2.new(1, -100, 1, 0)
Title.Position = UDim2.new(0, 20, 0, 0)
Title.BackgroundTransparency = 1
Title.Font = Enum.Font.GothamBold
Title.Text = "AFTER 3 AM PREMIUM HUB"
Title.TextColor3 = AccentRed
Title.TextSize = 18
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = Header

local Subtitle = Instance.new("TextLabel")
Subtitle.Name = "Subtitle"
Subtitle.Size = UDim2.new(0, 80, 0, 20)
Subtitle.Position = UDim2.new(1, -85, 0.5, -10)
Subtitle.BackgroundTransparency = 1
Subtitle.Font = Enum.Font.Gotham
Subtitle.Text = "v1.0"
Subtitle.TextColor3 = TextSecondary
Subtitle.TextSize = 12
Subtitle.TextXAlignment = Enum.TextXAlignment.Right
Subtitle.Parent = Header

-- Close Button
local CloseButton = Instance.new("TextButton")
CloseButton.Name = "CloseButton"
CloseButton.Size = UDim2.new(0, 30, 0, 30)
CloseButton.Position = UDim2.new(1, -40, 0, 10)
CloseButton.BackgroundColor3 = AccentRed
CloseButton.BorderSizePixel = 0
CloseButton.Font = Enum.Font.GothamBold
CloseButton.Text = "×"
CloseButton.TextColor3 = TextPrimary
CloseButton.TextSize = 20
CloseButton.Parent = Header

local CloseCorner = Instance.new("UICorner")
CloseCorner.CornerRadius = UDim.new(0, 6)
CloseCorner.Parent = CloseButton

-- Content Area
local ContentFrame = Instance.new("ScrollingFrame")
ContentFrame.Name = "ContentFrame"
ContentFrame.Size = UDim2.new(1, -30, 1, -100)
ContentFrame.Position = UDim2.new(0, 15, 0, 65)
ContentFrame.BackgroundTransparency = 1
ContentFrame.BorderSizePixel = 0
ContentFrame.ScrollBarThickness = 4
ContentFrame.ScrollBarImageColor3 = AccentRed
ContentFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
ContentFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
ContentFrame.Parent = MainContainer

local ContentLayout = Instance.new("UIListLayout")
ContentLayout.SortOrder = Enum.SortOrder.LayoutOrder
ContentLayout.Padding = UDim.new(0, 12)
ContentLayout.Parent = ContentFrame

-- Hotkey List Frame
local HotkeyFrame = Instance.new("Frame")
HotkeyFrame.Name = "HotkeyFrame"
HotkeyFrame.Size = UDim2.new(1, 0, 0, 0)
HotkeyFrame.BackgroundColor3 = DarkSection
HotkeyFrame.BorderSizePixel = 0
HotkeyFrame.ClipsDescendants = true
HotkeyFrame.LayoutOrder = 1
HotkeyFrame.Parent = ContentFrame

local HotkeyCorner = Instance.new("UICorner")
HotkeyCorner.CornerRadius = UDim.new(0, 8)
HotkeyCorner.Parent = HotkeyFrame

local HotkeyBorder = Instance.new("UIStroke")
HotkeyBorder.Color = BorderColor
HotkeyBorder.Thickness = 1
HotkeyBorder.Parent = HotkeyFrame

local HotkeyTitle = Instance.new("TextLabel")
HotkeyTitle.Size = UDim2.new(1, -20, 0, 30)
HotkeyTitle.Position = UDim2.new(0, 15, 0, 10)
HotkeyTitle.BackgroundTransparency = 1
HotkeyTitle.Font = Enum.Font.GothamBold
HotkeyTitle.Text = "HOTKEY LIST"
HotkeyTitle.TextColor3 = AccentBlue
HotkeyTitle.TextSize = 14
HotkeyTitle.TextXAlignment = Enum.TextXAlignment.Left
HotkeyTitle.Parent = HotkeyFrame

local HotkeyList = Instance.new("TextLabel")
HotkeyList.Name = "HotkeyList"
HotkeyList.Size = UDim2.new(1, -30, 0, 0)
HotkeyList.Position = UDim2.new(0, 15, 0, 40)
HotkeyList.BackgroundTransparency = 1
HotkeyList.Font = Enum.Font.Gotham
HotkeyList.Text = ""
HotkeyList.TextColor3 = TextSecondary
HotkeyList.TextSize = 12
HotkeyList.TextXAlignment = Enum.TextXAlignment.Left
HotkeyList.TextYAlignment = Enum.TextYAlignment.Top
HotkeyList.TextWrapped = true
HotkeyList.Parent = HotkeyFrame

-- Function to create section
local function CreateSection(name, order)
    local Section = Instance.new("Frame")
    Section.Name = name
    Section.Size = UDim2.new(1, 0, 0, 35)
    Section.BackgroundColor3 = DarkSection
    Section.BorderSizePixel = 0
    Section.LayoutOrder = order
    Section.Parent = ContentFrame
    
    local SectionCorner = Instance.new("UICorner")
    SectionCorner.CornerRadius = UDim.new(0, 8)
    SectionCorner.Parent = Section
    
    local SectionBorder = Instance.new("UIStroke")
    SectionBorder.Color = BorderColor
    SectionBorder.Thickness = 1
    SectionBorder.Parent = Section
    
    local SectionLabel = Instance.new("TextLabel")
    SectionLabel.Size = UDim2.new(1, -20, 1, 0)
    SectionLabel.Position = UDim2.new(0, 15, 0, 0)
    SectionLabel.BackgroundTransparency = 1
    SectionLabel.Font = Enum.Font.GothamBold
    SectionLabel.Text = name
    SectionLabel.TextColor3 = AccentBlue
    SectionLabel.TextSize = 13
    SectionLabel.TextXAlignment = Enum.TextXAlignment.Left
    SectionLabel.Parent = Section
    
    return Section
end

-- Function to create toggle with hotkey
local function CreateToggle(name, defaultState, hotkey, callback, order)
    local Toggle = Instance.new("Frame")
    Toggle.Name = name
    Toggle.Size = UDim2.new(1, 0, 0, 45)
    Toggle.BackgroundColor3 = DarkButton
    Toggle.BorderSizePixel = 0
    Toggle.LayoutOrder = order
    Toggle.Parent = ContentFrame
    
    local ToggleCorner = Instance.new("UICorner")
    ToggleCorner.CornerRadius = UDim.new(0, 8)
    ToggleCorner.Parent = Toggle
    
    local ToggleBorder = Instance.new("UIStroke")
    ToggleBorder.Color = BorderColor
    ToggleBorder.Thickness = 1
    ToggleBorder.Parent = Toggle
    
    local ToggleLabel = Instance.new("TextLabel")
    ToggleLabel.Size = UDim2.new(1, -140, 1, 0)
    ToggleLabel.Position = UDim2.new(0, 15, 0, 0)
    ToggleLabel.BackgroundTransparency = 1
    ToggleLabel.Font = Enum.Font.Gotham
    ToggleLabel.Text = name
    ToggleLabel.TextColor3 = TextPrimary
    ToggleLabel.TextSize = 13
    ToggleLabel.TextXAlignment = Enum.TextXAlignment.Left
    ToggleLabel.Parent = Toggle
    
    local HotkeyLabel = Instance.new("TextLabel")
    HotkeyLabel.Size = UDim2.new(0, 60, 0, 25)
    HotkeyLabel.Position = UDim2.new(1, -100, 0.5, -12.5)
    HotkeyLabel.BackgroundColor3 = DarkSection
    HotkeyLabel.BorderSizePixel = 0
    HotkeyLabel.Font = Enum.Font.GothamBold
    HotkeyLabel.Text = hotkey
    HotkeyLabel.TextColor3 = AccentPurple
    HotkeyLabel.TextSize = 11
    HotkeyLabel.Parent = Toggle
    
    local HotkeyCorner = Instance.new("UICorner")
    HotkeyCorner.CornerRadius = UDim.new(0, 6)
    HotkeyCorner.Parent = HotkeyLabel
    
    local ToggleButton = Instance.new("TextButton")
    ToggleButton.Name = "ToggleButton"
    ToggleButton.Size = UDim2.new(0, 45, 0, 22)
    ToggleButton.Position = UDim2.new(1, -50, 0.5, -11)
    ToggleButton.BackgroundColor3 = defaultState and AccentRed or Color3.fromRGB(50, 50, 60)
    ToggleButton.BorderSizePixel = 0
    ToggleButton.Text = ""
    ToggleButton.Parent = Toggle
    
    local ToggleButtonCorner = Instance.new("UICorner")
    ToggleButtonCorner.CornerRadius = UDim.new(1, 0)
    ToggleButtonCorner.Parent = ToggleButton
    
    local ToggleCircle = Instance.new("Frame")
    ToggleCircle.Name = "Circle"
    ToggleCircle.Size = UDim2.new(0, 16, 0, 16)
    ToggleCircle.Position = defaultState and UDim2.new(1, -19, 0.5, -8) or UDim2.new(0, 3, 0.5, -8)
    ToggleCircle.BackgroundColor3 = TextPrimary
    ToggleCircle.BorderSizePixel = 0
    ToggleCircle.Parent = ToggleButton
    
    local CircleCorner = Instance.new("UICorner")
    CircleCorner.CornerRadius = UDim.new(1, 0)
    CircleCorner.Parent = ToggleCircle
    
    local isEnabled = defaultState
    
    local function ToggleState()
        isEnabled = not isEnabled
        
        local colorTween = TweenService:Create(ToggleButton, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {
            BackgroundColor3 = isEnabled and AccentRed or Color3.fromRGB(50, 50, 60)
        })
        
        local positionTween = TweenService:Create(ToggleCircle, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {
            Position = isEnabled and UDim2.new(1, -19, 0.5, -8) or UDim2.new(0, 3, 0.5, -8)
        })
        
        colorTween:Play()
        positionTween:Play()
        
        callback(isEnabled)
    end
    
    ToggleButton.MouseButton1Click:Connect(ToggleState)
    
    -- Hover effects
    ToggleButton.MouseEnter:Connect(function()
        TweenService:Create(Toggle, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(30, 30, 40)}):Play()
    end)
    
    ToggleButton.MouseLeave:Connect(function()
        TweenService:Create(Toggle, TweenInfo.new(0.15), {BackgroundColor3 = DarkButton}):Play()
    end)
    
    -- Register hotkey
    Hotkeys[hotkey] = ToggleState
    HotkeyNames[hotkey] = name
    
    return Toggle
end

-- Function to create button with hotkey
local function CreateButton(name, hotkey, callback, order)
    local Button = Instance.new("TextButton")
    Button.Name = name
    Button.Size = UDim2.new(1, 0, 0, 45)
    Button.BackgroundColor3 = DarkButton
    Button.BorderSizePixel = 0
    Button.Text = ""
    Button.LayoutOrder = order
    Button.Parent = ContentFrame
    
    local ButtonCorner = Instance.new("UICorner")
    ButtonCorner.CornerRadius = UDim.new(0, 8)
    ButtonCorner.Parent = Button
    
    local ButtonBorder = Instance.new("UIStroke")
    ButtonBorder.Color = BorderColor
    ButtonBorder.Thickness = 1
    ButtonBorder.Parent = Button
    
    local ButtonLabel = Instance.new("TextLabel")
    ButtonLabel.Size = UDim2.new(1, -140, 1, 0)
    ButtonLabel.Position = UDim2.new(0, 15, 0, 0)
    ButtonLabel.BackgroundTransparency = 1
    ButtonLabel.Font = Enum.Font.Gotham
    ButtonLabel.Text = name
    ButtonLabel.TextColor3 = TextPrimary
    ButtonLabel.TextSize = 13
    ButtonLabel.TextXAlignment = Enum.TextXAlignment.Left
    ButtonLabel.Parent = Button
    
    local HotkeyLabel = Instance.new("TextLabel")
    HotkeyLabel.Size = UDim2.new(0, 60, 0, 25)
    HotkeyLabel.Position = UDim2.new(1, -50, 0.5, -12.5)
    HotkeyLabel.BackgroundColor3 = DarkSection
    HotkeyLabel.BorderSizePixel = 0
    HotkeyLabel.Font = Enum.Font.GothamBold
    HotkeyLabel.Text = hotkey
    HotkeyLabel.TextColor3 = AccentPurple
    HotkeyLabel.TextSize = 11
    HotkeyLabel.Parent = Button
    
    local HotkeyCorner = Instance.new("UICorner")
    HotkeyCorner.CornerRadius = UDim.new(0, 6)
    HotkeyCorner.Parent = HotkeyLabel
    
    Button.MouseButton1Click:Connect(function()
        TweenService:Create(Button, TweenInfo.new(0.1), {BackgroundColor3 = AccentRed}):Play()
        task.wait(0.1)
        TweenService:Create(Button, TweenInfo.new(0.1), {BackgroundColor3 = DarkButton}):Play()
        callback()
    end)
    
    -- Hover effects
    Button.MouseEnter:Connect(function()
        TweenService:Create(Button, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(30, 30, 40)}):Play()
    end)
    
    Button.MouseLeave:Connect(function()
        TweenService:Create(Button, TweenInfo.new(0.15), {BackgroundColor3 = DarkButton}):Play()
    end)
    
    -- Register hotkey
    Hotkeys[hotkey] = callback
    HotkeyNames[hotkey] = name
    
    return Button
end

-- Update hotkey list
local function UpdateHotkeyList()
    local hotkeyText = ""
    for key, func in pairs(Hotkeys) do
        local name = HotkeyNames[key] or "Unknown"
        hotkeyText = hotkeyText .. key .. " - " .. name .. "\n"
    end
    HotkeyList.Text = hotkeyText
    HotkeyFrame.Size = UDim2.new(1, 0, 0, 40 + (HotkeyList.TextBounds.Y > 0 and HotkeyList.TextBounds.Y + 10 or 30))
end

-- Create sections and toggles
CreateSection("COMBAT", 2)

CreateToggle("Auto Kill Monsters", false, "F1", function(enabled)
    AutoKillEnabled = enabled
    
    if enabled then
        local function setupAutoKill()
            if AutoKillConnection then
                AutoKillConnection:Disconnect()
            end
            
            AutoKillConnection = RunService.Heartbeat:Connect(function()
                if not AutoKillEnabled then return end
                
                local character = LocalPlayer.Character
                if character and character:FindFirstChild("Shotgun") then
                for _, monster in ipairs(workspace.CurrentMonsters:GetChildren()) do
                    if monster:FindFirstChild("Humanoid") and monster.Humanoid.Health > 0 and monster:FindFirstChild("HumanoidRootPart") then
                            character.Shotgun.DamageTargetEvent:FireServer(monster.HumanoidRootPart, monster.HumanoidRootPart.Position)
                        end
                    end
                end
            end)
        end
        
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Shotgun") then
            setupAutoKill()
        end
        
        LocalPlayer.Character.ChildAdded:Connect(function(child)
            if child.Name == "Shotgun" and AutoKillEnabled then
                setupAutoKill()
            end
        end)
    else
        if AutoKillConnection then
            AutoKillConnection:Disconnect()
            AutoKillConnection = nil
        end
    end
end, 3)

CreateToggle("Monster ESP", false, "F2", function(enabled)
    ESPEnabled = enabled
    
    if enabled then
        local function CreateESP(monster)
            if not monster:FindFirstChild("HumanoidRootPart") then return end
            
            local BillboardGui = Instance.new("BillboardGui")
            BillboardGui.Name = "ESP"
            BillboardGui.Adornee = monster.HumanoidRootPart
            BillboardGui.Size = UDim2.new(0, 120, 0, 60)
            BillboardGui.StudsOffset = Vector3.new(0, 3, 0)
            BillboardGui.AlwaysOnTop = true
            BillboardGui.Parent = monster.HumanoidRootPart
            
            local Frame = Instance.new("Frame")
            Frame.Size = UDim2.new(1, 0, 1, 0)
            Frame.BackgroundColor3 = AccentRed
            Frame.BackgroundTransparency = 0.6
            Frame.BorderSizePixel = 0
            Frame.Parent = BillboardGui
            
            local Corner = Instance.new("UICorner")
            Corner.CornerRadius = UDim.new(0, 6)
            Corner.Parent = Frame
            
            local Label = Instance.new("TextLabel")
            Label.Size = UDim2.new(1, 0, 0.5, 0)
            Label.BackgroundTransparency = 1
            Label.Font = Enum.Font.GothamBold
            Label.Text = "MONSTER"
            Label.TextColor3 = TextPrimary
            Label.TextSize = 13
            Label.TextStrokeTransparency = 0
            Label.Parent = Frame
            
            local HealthLabel = Instance.new("TextLabel")
            HealthLabel.Size = UDim2.new(1, 0, 0.5, 0)
            HealthLabel.Position = UDim2.new(0, 0, 0.5, 0)
            HealthLabel.BackgroundTransparency = 1
            HealthLabel.Font = Enum.Font.Gotham
            HealthLabel.TextColor3 = AccentBlue
            HealthLabel.TextSize = 11
            HealthLabel.TextStrokeTransparency = 0
            HealthLabel.Parent = Frame
            
            local updateConnection
            updateConnection = RunService.Heartbeat:Connect(function()
                if monster and monster:FindFirstChild("Humanoid") then
                    HealthLabel.Text = "HP: " .. math.floor(monster.Humanoid.Health)
                else
                    updateConnection:Disconnect()
                    BillboardGui:Destroy()
                end
            end)
            
            table.insert(ESPObjects, {gui = BillboardGui, connection = updateConnection})
        end
        
        for _, monster in ipairs(workspace.CurrentMonsters:GetChildren()) do
            CreateESP(monster)
        end
        
        workspace.CurrentMonsters.ChildAdded:Connect(function(monster)
            if ESPEnabled then
                task.wait(0.1)
                CreateESP(monster)
            end
        end)
    else
        for _, espData in ipairs(ESPObjects) do
            if espData.gui then espData.gui:Destroy() end
            if espData.connection then espData.connection:Disconnect() end
        end
        ESPObjects = {}
    end
end, 4)

CreateToggle("Item ESP", false, "F8", function(enabled)
    ItemESPEnabled = enabled
    
    if enabled then
        local function UpdateItemESP()
            -- Clear existing ESP
            for _, espData in ipairs(ItemESPObjects) do
                if espData.gui then espData.gui:Destroy() end
            end
            ItemESPObjects = {}
            
            -- Find and create ESP for all items
            local items = FindItems()
            for _, item in ipairs(items) do
                CreateItemESP(item)
            end
        end
        
        UpdateItemESP()
        
        -- Update ESP periodically
        local itemESPConnection
        itemESPConnection = RunService.Heartbeat:Connect(function()
            if not ItemESPEnabled then
                itemESPConnection:Disconnect()
                return
            end
            
            -- Check if items still exist
            for i = #ItemESPObjects, 1, -1 do
                local espData = ItemESPObjects[i]
                if not espData.part or not espData.part.Parent or not espData.part:FindFirstChild("ItemESP") then
                    if espData.gui then espData.gui:Destroy() end
                    table.remove(ItemESPObjects, i)
                end
            end
            
            -- Find new items
            local items = FindItems()
            for _, item in ipairs(items) do
                local part = item
                if item:IsA("Model") and item.PrimaryPart then
                    part = item.PrimaryPart
                end
                if part and part.Parent and not part:FindFirstChild("ItemESP") then
                    CreateItemESP(item)
                end
            end
        end)
        
        table.insert(ItemESPObjects, {connection = itemESPConnection})
    else
        -- Remove all item ESP
        for _, espData in ipairs(ItemESPObjects) do
            if espData.gui then espData.gui:Destroy() end
            if espData.connection then espData.connection:Disconnect() end
        end
        ItemESPObjects = {}
    end
end, 5)

CreateSection("MOVEMENT", 6)

CreateToggle("Speed Boost", false, "F3", function(enabled)
    SpeedBoostEnabled = enabled
    
    if enabled then
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
            LocalPlayer.Character.Humanoid.WalkSpeed = 25
        end
    else
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
            LocalPlayer.Character.Humanoid.WalkSpeed = 16
        end
    end
end, 7)

CreateToggle("Infinite Stamina", false, "F4", function(enabled)
    InfiniteStaminaEnabled = enabled
end, 8)

CreateButton("Teleport to Nearest Item", "F9", function()
    TeleportToNearestItem()
end, 9)

CreateSection("VISUAL", 10)

CreateButton("Fullbright", "F5", function()
    FullbrightEnabled = not FullbrightEnabled
    local Lighting = game:GetService("Lighting")
    if FullbrightEnabled then
        Lighting.Brightness = 2
        Lighting.ClockTime = 14
        Lighting.FogEnd = 100000
        Lighting.GlobalShadows = false
        Lighting.OutdoorAmbient = Color3.fromRGB(128, 128, 128)
    else
        Lighting.Brightness = 1
        Lighting.ClockTime = 12
        Lighting.FogEnd = 10000
        Lighting.GlobalShadows = true
    end
end, 11)

CreateButton("Remove Fog", "F6", function()
    NoFogEnabled = not NoFogEnabled
    local Lighting = game:GetService("Lighting")
    if NoFogEnabled then
        Lighting.FogEnd = 100000
        for _, effect in ipairs(Lighting:GetChildren()) do
            if effect:IsA("Atmosphere") then
                effect.Density = 0
            end
        end
    else
        Lighting.FogEnd = 10000
    end
end, 12)

CreateSection("PERFORMANCE", 13)

CreateButton("Anti-Lag", "F7", function()
    AntiLagEnabled = not AntiLagEnabled
    local Terrain = workspace:FindFirstChildOfClass('Terrain')
    if Terrain then
        if AntiLagEnabled then
            Terrain.WaterWaveSize = 0
            Terrain.WaterWaveSpeed = 0
            Terrain.WaterReflectance = 0
            Terrain.WaterTransparency = 0
        end
    end
    
    if AntiLagEnabled then
        settings().Rendering.QualityLevel = 1
        
        for _, obj in pairs(workspace:GetDescendants()) do
            if obj:IsA("ParticleEmitter") or obj:IsA("Trail") then
                obj.Enabled = false
            elseif obj:IsA("Explosion") then
                obj.BlastPressure = 1
                obj.BlastRadius = 1
            end
        end
    end
end, 14)

-- Register GUI toggle hotkey
HotkeyNames["INSERT"] = "Toggle GUI"

-- Update hotkey list
task.wait(0.1)
UpdateHotkeyList()

-- Hotkey handler
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    
    local keyCode = input.KeyCode.Name
    if Hotkeys[keyCode] then
        Hotkeys[keyCode]()
    end
end)

-- Toggle GUI hotkey (INSERT key)
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    
    if input.KeyCode == Enum.KeyCode.Insert then
        GUIEnabled = not GUIEnabled
        MainContainer.Visible = GUIEnabled
        
        if GUIEnabled then
            MainContainer.Size = UDim2.new(0, 550, 0, 0)
            MainContainer.Position = UDim2.new(0.5, -275, 0.5, -300)
            
            local openTween = TweenService:Create(MainContainer, TweenInfo.new(0.4, Enum.EasingStyle.Back), {
                Size = UDim2.new(0, 550, 0, 600),
                Position = UDim2.new(0.5, -275, 0.5, -300)
            })
            openTween:Play()
        else
            local closeTween = TweenService:Create(MainContainer, TweenInfo.new(0.3), {
                Size = UDim2.new(0, 550, 0, 0),
                Position = UDim2.new(0.5, -275, 0.5, -300)
            })
            closeTween:Play()
        end
    end
end)

-- Close button
CloseButton.MouseButton1Click:Connect(function()
    GUIEnabled = false
    local closeTween = TweenService:Create(MainContainer, TweenInfo.new(0.3), {
        Size = UDim2.new(0, 550, 0, 0),
        Position = UDim2.new(0.5, -275, 0.5, -300)
    })
    closeTween:Play()
    closeTween.Completed:Connect(function()
        MainContainer.Visible = false
    end)
end)

-- Dragging
local dragging = false
local dragInput, mousePos, framePos

Header.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        mousePos = input.Position
        framePos = MainContainer.Position
        
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)

Header.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement then
        dragInput = input
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if input == dragInput and dragging then
        local delta = input.Position - mousePos
        MainContainer.Position = UDim2.new(
            framePos.X.Scale,
            framePos.X.Offset + delta.X,
            framePos.Y.Scale,
            framePos.Y.Offset + delta.Y
        )
    end
end)

-- Maintain speed boost on respawn
LocalPlayer.CharacterAdded:Connect(function(character)
    character:WaitForChild("Humanoid")
    if SpeedBoostEnabled then
        character.Humanoid.WalkSpeed = 25
    end
end)

-- Initial GUI open
GUIEnabled = true
MainContainer.Visible = true
MainContainer.Size = UDim2.new(0, 0, 0, 0)
MainContainer.Position = UDim2.new(0.5, 0, 0.5, 0)

local initialTween = TweenService:Create(MainContainer, TweenInfo.new(0.5, Enum.EasingStyle.Back), {
    Size = UDim2.new(0, 550, 0, 600),
    Position = UDim2.new(0.5, -275, 0.5, -300)
})
initialTween:Play()

print("After 3 AM Premium Hub v1.0 - Loaded Successfully")
print("Press INSERT to toggle GUI")

print("After 3 AM Hub v1.0 - Załadowany pomyślnie!")
