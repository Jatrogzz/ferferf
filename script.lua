local url = "https://raw.githubusercontent.com/dwyl/english-words/refs/heads/master/words.txt"

if not isfile("words.txt") then
    local res = request({Url = url, Method = "GET"})
    if res and res.Body then
        writefile("words.txt", res.Body)
    end
end

-- Pre-indexed words by first letter for faster lookup
local WordsByLetter = {}
for i = 97, 122 do -- a-z
    WordsByLetter[string.char(i)] = {}
end

if isfile("words.txt") then
    local content = readfile("words.txt")
    for w in content:gmatch("[^\r\n]+") do
        local firstLetter = w:sub(1,1):lower()
        if WordsByLetter[firstLetter] then
            table.insert(WordsByLetter[firstLetter], w:lower())
        end
    end
end

local function SuggestWords(prefix, count)
    if #prefix < 1 then return {} end
    
    prefix = prefix:lower()
    local firstLetter = prefix:sub(1,1)
    local wordList = WordsByLetter[firstLetter]
    
    if not wordList then return {} end
    
    local results = {}
    local prefixLen = #prefix
    
    -- Bezpośrednio zbieraj pasujące słowa (max count)
    for i = 1, #wordList do
        local w = wordList[i]
        if w:sub(1, prefixLen) == prefix then
            results[#results + 1] = w
            if #results >= count then
                break
            end
        end
    end
    
    return results
end

local a = Instance.new("ScreenGui", game.CoreGui)
a.Name = "skibidi"

-- Main frame z cieniem
local shadow = Instance.new("ImageLabel", a)
shadow.Name = "Shadow"
shadow.BackgroundTransparency = 1
shadow.Position = UDim2.new(0, 75, 0, 95)
shadow.Size = UDim2.new(0, 270, 0, 360)
shadow.Image = "rbxassetid://6015897843"
shadow.ImageColor3 = Color3.fromRGB(0, 0, 0)
shadow.ImageTransparency = 0.5
shadow.ScaleType = Enum.ScaleType.Slice
shadow.SliceCenter = Rect.new(49, 49, 450, 450)

local b = Instance.new("Frame", a)
b.Name = "MainFrame"
b.Size = UDim2.new(0, 250, 0, 340)
b.Position = UDim2.new(0, 85, 0, 105)
b.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
b.BorderSizePixel = 0
b.Active = true
b.Draggable = true
Instance.new("UICorner", b).CornerRadius = UDim.new(0, 12)

-- Gradient na tle
local gradient = Instance.new("UIGradient", b)
gradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(30, 30, 40)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(20, 20, 25))
})
gradient.Rotation = 45

-- Stroke z gradientem
local stroke = Instance.new("UIStroke", b)
stroke.Thickness = 2
stroke.Color = Color3.fromRGB(100, 80, 200)
local strokeGradient = Instance.new("UIGradient", stroke)
strokeGradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(130, 80, 220)),
    ColorSequenceKeypoint.new(0.5, Color3.fromRGB(80, 150, 255)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(130, 80, 220))
})
strokeGradient.Rotation = 45

-- Sync shadow z głównym frame
b:GetPropertyChangedSignal("Position"):Connect(function()
    shadow.Position = b.Position - UDim2.new(0, 10, 0, 10)
end)

-- Title bar
local titleBar = Instance.new("Frame", b)
titleBar.Name = "TitleBar"
titleBar.Size = UDim2.new(1, 0, 0, 45)
titleBar.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
titleBar.BorderSizePixel = 0
Instance.new("UICorner", titleBar).CornerRadius = UDim.new(0, 12)

-- Fix corners na dole title bara
local titleFix = Instance.new("Frame", titleBar)
titleFix.Size = UDim2.new(1, 0, 0, 15)
titleFix.Position = UDim2.new(0, 0, 1, -15)
titleFix.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
titleFix.BorderSizePixel = 0

-- Ikona/Logo
local icon = Instance.new("TextLabel", titleBar)
icon.Size = UDim2.new(0, 30, 0, 30)
icon.Position = UDim2.new(0, 10, 0.5, -15)
icon.BackgroundColor3 = Color3.fromRGB(100, 80, 200)
icon.Text = "W"
icon.TextColor3 = Color3.fromRGB(255, 255, 255)
icon.Font = Enum.Font.GothamBlack
icon.TextSize = 16
Instance.new("UICorner", icon).CornerRadius = UDim.new(0, 8)

local iconGrad = Instance.new("UIGradient", icon)
iconGrad.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(130, 80, 220)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(80, 120, 255))
})
iconGrad.Rotation = 45

-- Tytuł
local title = Instance.new("TextLabel", titleBar)
title.Size = UDim2.new(1, -100, 0, 20)
title.Position = UDim2.new(0, 48, 0, 8)
title.BackgroundTransparency = 1
title.Text = "Last Letter Suggestions Script"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.Font = Enum.Font.GothamBold
title.TextSize = 16
title.TextXAlignment = Enum.TextXAlignment.Left

-- Podtytuł
local subtitle = Instance.new("TextLabel", titleBar)
subtitle.Size = UDim2.new(1, -100, 0, 14)
subtitle.Position = UDim2.new(0, 48, 0, 26)
subtitle.BackgroundTransparency = 1
subtitle.Text = "by Cáo Mod"
subtitle.TextColor3 = Color3.fromRGB(130, 130, 150)
subtitle.Font = Enum.Font.Gotham
subtitle.TextSize = 11
subtitle.TextXAlignment = Enum.TextXAlignment.Left

-- Close button
local closeBtn = Instance.new("TextButton", titleBar)
closeBtn.Size = UDim2.new(0, 30, 0, 30)
closeBtn.Position = UDim2.new(1, -38, 0.5, -15)
closeBtn.BackgroundColor3 = Color3.fromRGB(255, 80, 80)
closeBtn.Text = "×"
closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 20
closeBtn.AutoButtonColor = true
Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 8)

closeBtn.MouseButton1Click:Connect(function()
    a:Destroy()
end)

-- Warning
local w = Instance.new("TextLabel", b)
w.Size = UDim2.new(1, -20, 0, 25)
w.Position = UDim2.new(0, 10, 0, 52)
w.BackgroundColor3 = Color3.fromRGB(255, 100, 100)
w.BackgroundTransparency = 0.85
w.Text = "⚠ Some words may not be accepted"
w.TextColor3 = Color3.fromRGB(255, 150, 150)
w.Font = Enum.Font.Gotham
w.TextSize = 11
w.TextWrapped = true
Instance.new("UICorner", w).CornerRadius = UDim.new(0, 6)

-- Search container
local searchContainer = Instance.new("Frame", b)
searchContainer.Size = UDim2.new(1, -20, 0, 40)
searchContainer.Position = UDim2.new(0, 10, 0, 85)
searchContainer.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
searchContainer.BorderSizePixel = 0
Instance.new("UICorner", searchContainer).CornerRadius = UDim.new(0, 10)

local searchStroke = Instance.new("UIStroke", searchContainer)
searchStroke.Thickness = 1.5
searchStroke.Color = Color3.fromRGB(60, 60, 80)

-- Search icon
local searchIcon = Instance.new("TextLabel", searchContainer)
searchIcon.Size = UDim2.new(0, 30, 1, 0)
searchIcon.Position = UDim2.new(0, 5, 0, 0)
searchIcon.BackgroundTransparency = 1
searchIcon.Text = "🔍"
searchIcon.TextSize = 16

-- Input
local h = Instance.new("TextBox", searchContainer)
h.Name = "SearchInput"
h.PlaceholderText = "Type letters here..."
h.PlaceholderColor3 = Color3.fromRGB(100, 100, 120)
h.Size = UDim2.new(1, -45, 1, 0)
h.Position = UDim2.new(0, 40, 0, 0)
h.BackgroundTransparency = 1
h.TextColor3 = Color3.fromRGB(255, 255, 255)
h.Text = ""
h.ClearTextOnFocus = false
h.Font = Enum.Font.GothamMedium
h.TextSize = 14
h.TextXAlignment = Enum.TextXAlignment.Left

-- Focus effect (simplified)
h.Focused:Connect(function()
    h.Text = ""
    searchStroke.Color = Color3.fromRGB(100, 80, 200)
end)

h.FocusLost:Connect(function()
    searchStroke.Color = Color3.fromRGB(60, 60, 80)
end)

-- Results label
local resultsLabel = Instance.new("TextLabel", b)
resultsLabel.Size = UDim2.new(1, -20, 0, 20)
resultsLabel.Position = UDim2.new(0, 10, 0, 132)
resultsLabel.BackgroundTransparency = 1
resultsLabel.Text = "Suggestions:"
resultsLabel.TextColor3 = Color3.fromRGB(150, 150, 170)
resultsLabel.Font = Enum.Font.GothamMedium
resultsLabel.TextSize = 12
resultsLabel.TextXAlignment = Enum.TextXAlignment.Left

-- List container
local listContainer = Instance.new("Frame", b)
listContainer.Size = UDim2.new(1, -20, 0, 175)
listContainer.Position = UDim2.new(0, 10, 0, 155)
listContainer.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
listContainer.BorderSizePixel = 0
Instance.new("UICorner", listContainer).CornerRadius = UDim.new(0, 10)

local list = Instance.new("ScrollingFrame", listContainer)
list.Name = "ResultsList"
list.Size = UDim2.new(1, -10, 1, -10)
list.Position = UDim2.new(0, 5, 0, 5)
list.BackgroundTransparency = 1
list.ScrollBarThickness = 4
list.ScrollBarImageColor3 = Color3.fromRGB(100, 80, 200)
list.CanvasSize = UDim2.new(0, 0, 0, 0)
list.AutomaticCanvasSize = Enum.AutomaticSize.Y
list.BorderSizePixel = 0

local uiList = Instance.new("UIListLayout", list)
uiList.Padding = UDim.new(0, 4)
uiList.SortOrder = Enum.SortOrder.LayoutOrder

local lastUpdate = 0
local debounceTime = 0.15

local function ClearList()
    for _, child in ipairs(list:GetChildren()) do
        if child:IsA("TextButton") then
            child:Destroy()
        end
    end
end

local function UpdateSuggestions()
    local currentTime = tick()
    lastUpdate = currentTime
    
    -- Debounce - poczekaj chwilę przed aktualizacją
    task.delay(debounceTime, function()
        if lastUpdate ~= currentTime then return end -- Nowy input przyszedł, anuluj
        
        ClearList()
        
        local text = h.Text
        if #text < 1 then 
            resultsLabel.Text = "Suggestions:"
            return 
        end

        local suggests = SuggestWords(text, 50) -- Zmniejszone z 100 do 50
        resultsLabel.Text = "Suggestions: " .. #suggests .. " found"

        for i, word in ipairs(suggests) do
            local btn = Instance.new("TextButton")
            btn.Name = "Word_" .. i
            btn.Size = UDim2.new(1, -5, 0, 26)
            btn.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
            btn.TextColor3 = Color3.fromRGB(255, 255, 255)
            btn.Font = Enum.Font.GothamMedium
            btn.TextSize = 13
            btn.Text = "  " .. word
            btn.TextXAlignment = Enum.TextXAlignment.Left
            btn.AutoButtonColor = true
            btn.Selectable = false
            btn.BorderSizePixel = 0
            btn.Parent = list
            
            Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
            
            -- Click to copy
            btn.MouseButton1Click:Connect(function()
                if setclipboard then
                    setclipboard(word)
                end
                local originalText = btn.Text
                btn.Text = "  ✓ Copied!"
                btn.BackgroundColor3 = Color3.fromRGB(80, 180, 100)
                task.delay(0.4, function()
                    if btn and btn.Parent then
                        btn.Text = originalText
                        btn.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
                    end
                end)
            end)
        end
    end)
end

h:GetPropertyChangedSignal("Text"):Connect(UpdateSuggestions)
