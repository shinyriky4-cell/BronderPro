print("[Coracle] loading...")

--=====================================================================
-- SERVICES
--=====================================================================
local Players      = game:GetService("Players")
local UIS          = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local HttpService  = game:GetService("HttpService")

local LocalPlayer  = Players.LocalPlayer
local PlayerGui    = LocalPlayer:WaitForChild("PlayerGui")

--=====================================================================
-- HELPERS
--=====================================================================
local function create(class, props)
    local inst = Instance.new(class)
    local parent
    for k, v in pairs(props or {}) do
        if k == "Parent" then parent = v else inst[k] = v end
    end
    if parent then inst.Parent = parent end
    return inst
end

local function corner(p, r)
    return create("UICorner", { CornerRadius = UDim.new(0, r or 6), Parent = p })
end

local function tween(inst, props, time, style, dir)
    if not inst then return end
    local t = TweenService:Create(
        inst,
        TweenInfo.new(time or 0.18, style or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out),
        props
    )
    t:Play()
    return t
end

local function addStroke(p, color, thickness)
    pcall(function()
        create("UIStroke", { Color = color, Thickness = thickness or 1, Parent = p })
    end)
end

local function ensureUIScale(inst, initial)
    local s = inst:FindFirstChildOfClass("UIScale")
    if not s then s = create("UIScale", { Name = "UIScale", Parent = inst }) end
    if initial ~= nil then s.Scale = initial end
    return s
end

local function loadImage(url, cacheName)
    if not url or url == "" then return "" end
    if url:sub(1, 8) == "rbxasset" or url:sub(1, 12) == "rbxgameasset" or url:sub(1, 8) == "rbxthumb" then
        return url
    end

    local hasFile = (type(isfile) == "function")
    local hasWrite = (type(writefile) == "function")
    local hasGetAsset = (type(getcustomasset) == "function")
    local hasGet = (type(game.HttpGet) == "function")

    if hasFile and hasWrite and hasGetAsset and hasGet then
        local ok, result = pcall(function()
            cacheName = cacheName or (url:gsub("[^%w]", "_") .. ".png")
            if not isfile(cacheName) then writefile(cacheName, game:HttpGet(url)) end
            return getcustomasset(cacheName)
        end)
        if ok and type(result) == "string" then return result
        else warn("[Coracle] loadImage failed:", result) end
    end

    if hasGet then
        local ok, result = pcall(function()
            local data = game:HttpGet(url)
            local b64 = HttpService:Base64Encode(data)
            return "data:image/png;base64," .. b64
        end)
        if ok then return result end
    end

    warn("[Coracle] Could not load image:", url)
    return ""
end

local Saved = _G.CoracleSaved
if type(Saved) ~= "table" then Saved = {}; _G.CoracleSaved = Saved end

local function save(tab, name, v)
    if not tab or not name then return end
    Saved[tab] = Saved[tab] or {}
    Saved[tab][name] = v
end

local function load(tab, name, default)
    if not tab or not name then return default end
    local t = Saved[tab]
    if t and t[name] ~= nil then return t[name] end
    return default
end

--=====================================================================
-- THEME
--=====================================================================
local Theme = {
    LogoBg       = Color3.fromRGB(42, 42, 48),
    Sidepanel    = Color3.fromRGB(42, 42, 48),
    TabArea      = Color3.fromRGB(31, 31, 36),
    Content      = Color3.fromRGB(25, 25, 29),
    Element      = Color3.fromRGB(40, 40, 47),
    ElementHover = Color3.fromRGB(52, 52, 60),
    Stroke       = Color3.fromRGB(64, 64, 74),
    Text         = Color3.fromRGB(238, 238, 244),
    SubText      = Color3.fromRGB(150, 150, 164),
    Accent       = Color3.fromRGB(0, 205, 125),
    AccentOff    = Color3.fromRGB(72, 72, 82),
    Danger       = Color3.fromRGB(232, 72, 72),
}

--=====================================================================
-- COLOR WHEEL (embedded, MIT — original by Aidan Abdulov)
--=====================================================================
local CW = {}
CW.__index = CW

local wheelMouseDown = false
UIS.InputBegan:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 then wheelMouseDown = true end
end)
UIS.InputEnded:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 then wheelMouseDown = false end
end)

local function updateWheelColor(self)
    local radius = self.Wheel.AbsoluteSize.X / 2
    if radius <= 0 then return end

    self.Pos = self.Pos or Vector2.zero
    local h = (math.pi - math.atan2(self.Pos.Y, self.Pos.X)) / (math.pi * 2)
    local s = self.Pos.Magnitude / radius
    local v = math.abs(
        (self.Slider.AbsolutePosition.Y - self.Bar.AbsolutePosition.Y)
        / math.max(self.Bar.AbsoluteSize.Y, 1) - 1
    )

    self.Color = Color3.fromHSV(math.clamp(h, 0, 1), math.clamp(s, 0, 1), math.clamp(v, 0, 1))
    self.Bright = Color3.fromHSV(math.clamp(h, 0, 1), math.clamp(s, 0, 1), 1)
    self.Preview.ImageColor3 = self.Color

    if self.Changed then self.Changed(self.Color) end
end

function CW.new(container)
    local self = setmetatable({}, CW)

    self.Bar = create("ImageLabel", {
        Name = "Bar", AnchorPoint = Vector2.new(0, 0.5),
        Position = UDim2.new(0, 190, 0.5, 0), Size = UDim2.fromOffset(20, 150),
        BackgroundTransparency = 1, Image = "rbxassetid://3570695787",
        ScaleType = Enum.ScaleType.Slice,
        SliceCenter = Rect.new(100,100,100,100), SliceScale = 0.12,
        ZIndex = 4, Visible = false, Parent = container,
    })
    corner(self.Bar, 4)

    create("UIGradient", {
        Color = ColorSequence.new {
            ColorSequenceKeypoint.new(0, Color3.new(1,1,1)),
            ColorSequenceKeypoint.new(1, Color3.new(0,0,0)),
        },
        Rotation = 90, Parent = self.Bar,
    })

    self.Slider = create("ImageLabel", {
        Name = "Slider", AnchorPoint = Vector2.new(0.5,0.5),
        Position = UDim2.new(0.5,0,1,0), Size = UDim2.fromOffset(26,6),
        BackgroundTransparency = 1, Image = "rbxassetid://3570695787",
        ImageColor3 = Color3.fromRGB(255,74,74),
        ScaleType = Enum.ScaleType.Slice,
        SliceCenter = Rect.new(100,100,100,100), SliceScale = 0.12,
        ZIndex = 5, Parent = self.Bar,
    })

    self.Preview = create("ImageLabel", {
        Name = "Preview", AnchorPoint = Vector2.new(1,0.5),
        Position = UDim2.new(1,-14,0.5,0), Size = UDim2.fromOffset(96,46),
        BackgroundTransparency = 1, Image = "rbxassetid://3570695787",
        ScaleType = Enum.ScaleType.Slice,
        SliceCenter = Rect.new(100,100,100,100), SliceScale = 0.12,
        ZIndex = 4, Visible = false, Parent = container,
    })
    corner(self.Preview, 6)

    self.Wheel = create("ImageButton", {
        Name = "Wheel", AnchorPoint = Vector2.new(0,0.5),
        Position = UDim2.new(0,22,0.5,0), Size = UDim2.fromOffset(150,150),
        BackgroundTransparency = 1, Active = false, Selectable = false,
        Image = "http://www.roblox.com/asset/?id=6020299385",
        ZIndex = 4, Visible = false, Parent = container,
    })

    self.Picker = create("ImageLabel", {
        Name = "Picker", AnchorPoint = Vector2.new(0.5,0.5),
        Position = UDim2.new(0.5,0,0.5,0), Size = UDim2.new(0.09,0,0.09,0),
        BackgroundTransparency = 1,
        Image = "http://www.roblox.com/asset/?id=3678860011",
        ZIndex = 5, Parent = self.Wheel,
    })

    self.Color = Color3.fromHSV(0,0,1)
    self.Bright = Color3.fromHSV(0,0,1)
    self.Pos = Vector2.zero
    self.On = false
    return self
end

function CW:SetColor(color)
    self.Color = color
    self.Preview.ImageColor3 = color
    local h, s, v = color:ToHSV()
    local radius = self.Wheel.AbsoluteSize.X / 2
    if radius <= 0 then self._pending = color; return end

    local angle = math.pi - h * math.pi * 2
    local dir = Vector2.new(math.cos(angle), math.sin(angle))
    self.Pos = dir * (s * radius)
    self.Picker.Position = UDim2.new(0.5 + dir.X * s * 0.5, 0, 0.5 + dir.Y * s * 0.5, 0)
    self.Slider.Position = UDim2.new(0.5, 0, 1 - v, 0)

    updateWheelColor(self)

    self.Bar:FindFirstChildOfClass("UIGradient").Color = ColorSequence.new {
        ColorSequenceKeypoint.new(0, self.Bright),
        ColorSequenceKeypoint.new(1, Color3.new(0,0,0)),
    }
end

function CW:TurnOn()
    if self.On then return end
    self.On = true
    self.Bar.Visible = true
    self.Wheel.Visible = true
    self.Preview.Visible = true

    self._wheelConn = UIS.InputChanged:Connect(function(input)
        if not self.On or not wheelMouseDown then return end
        if input.UserInputType ~= Enum.UserInputType.MouseMovement
           and input.UserInputType ~= Enum.UserInputType.Touch then return end

        local mouse = Vector2.new(input.Position.X, input.Position.Y)
        local center = self.Wheel.AbsolutePosition + Vector2.one * (self.Wheel.AbsoluteSize.X / 2)
        local radius = self.Wheel.AbsoluteSize.X / 2
        local off = mouse - center
        if off.Magnitude > radius * 1.4 then return end

        if off.Magnitude > radius then off = off.Unit * radius end
        self.Pos = off
        local pickPos = off / self.Wheel.AbsoluteSize + Vector2.new(0.5, 0.5)
        self.Picker.Position = UDim2.new(pickPos.X, 0, pickPos.Y, 0)
        updateWheelColor(self)
        self.Bar:FindFirstChildOfClass("UIGradient").Color = ColorSequence.new {
            ColorSequenceKeypoint.new(0, self.Bright),
            ColorSequenceKeypoint.new(1, Color3.new(0,0,0)),
        }
    end)

    self._barConn = UIS.InputChanged:Connect(function(input)
        if not self.On or not wheelMouseDown then return end
        if input.UserInputType ~= Enum.UserInputType.MouseMovement
           and input.UserInputType ~= Enum.UserInputType.Touch then return end

        local mouseY = input.Position.Y
        local barTop = self.Bar.AbsolutePosition.Y
        local barBottom = barTop + self.Bar.AbsoluteSize.Y
        if mouseY < barTop - 20 or mouseY > barBottom + 20 then return end

        local localY = math.clamp(mouseY - barTop, 0, self.Bar.AbsoluteSize.Y)
        self.Slider.Position = UDim2.new(0.5, 0, 0, localY)
        updateWheelColor(self)
    end)

    if self._pending then
        local c = self._pending; self._pending = nil
        task.defer(function() self:SetColor(c) end)
    end
end

function CW:TurnOff()
    if not self.On then return end
    self.On = false
    self.Bar.Visible = false
    self.Wheel.Visible = false
    self.Preview.Visible = false
    if self._wheelConn then self._wheelConn:Disconnect() end
    if self._barConn then self._barConn:Disconnect() end
end

--=====================================================================
-- ICON HELPERS
--=====================================================================
local function xIcon(parent, size, color)
    create("Frame", { AnchorPoint = Vector2.new(0.5,0.5), Position = UDim2.new(0.5,0,0.5,0),
        Size = UDim2.fromOffset(size, 2), BackgroundColor3 = color, BorderSizePixel = 0,
        Rotation = 45, Parent = parent })
    create("Frame", { AnchorPoint = Vector2.new(0.5,0.5), Position = UDim2.new(0.5,0,0.5,0),
        Size = UDim2.fromOffset(size, 2), BackgroundColor3 = color, BorderSizePixel = 0,
        Rotation = -45, Parent = parent })
end

local function minusIcon(parent, size, color)
    create("Frame", { AnchorPoint = Vector2.new(0.5,0.5), Position = UDim2.new(0.5,0,0.5,0),
        Size = UDim2.fromOffset(size, 2), BackgroundColor3 = color, BorderSizePixel = 0,
        Parent = parent })
end

local function menuIcon(parent, size, color)
    for i = -1, 1 do
        create("Frame", { AnchorPoint = Vector2.new(0.5,0.5), Position = UDim2.new(0.5,0,0.5,i*5),
            Size = UDim2.fromOffset(size, 2), BackgroundColor3 = color, BorderSizePixel = 0,
            Parent = parent })
    end
end

local function chevron(parent, color)
    local h = create("Frame", { Size = UDim2.fromOffset(10,10), BackgroundTransparency = 1, Parent = parent })
    create("Frame", { AnchorPoint = Vector2.new(0.5,0.5), Position = UDim2.new(0,3.6,0,4.6),
        Size = UDim2.fromOffset(7,2), BackgroundColor3 = color, BorderSizePixel = 0, Rotation = 45, Parent = h })
    create("Frame", { AnchorPoint = Vector2.new(0.5,0.5), Position = UDim2.new(0,6.4,0,4.6),
        Size = UDim2.fromOffset(7,2), BackgroundColor3 = color, BorderSizePixel = 0, Rotation = -45, Parent = h })
    return h
end

local function iconBtn(parent, size)
    local b = create("TextButton", {
        Size = UDim2.fromOffset(size, size),
        BackgroundColor3 = Theme.Element, BackgroundTransparency = 0.15,
        Text = "", AutoButtonColor = false, BorderSizePixel = 0, Parent = parent,
    })
    corner(b, 6)
    return b
end

--=====================================================================
-- CORACLE CLASS
--=====================================================================
local Coracle = {}
Coracle.__index = Coracle

local SIDEBAR_W   = 210
local WIN_W       = 820
local WIN_H       = 520
local HEADER_H    = 56
local LOGO_H      = 140
local ORB_SIZE    = 54

local Container = {}
Container.__index = Container

local function newContainer(win, holder, tab)
    return setmetatable({ Win = win, Holder = holder, Tab = tab, _n = 0 }, Container)
end

function Container:_next() self._n = self._n + 1; return self._n end

local makeToggle, makeSlider, makeDropdown, makeInput, makeKeybind, makeColor, makeGamePlayers

local function attach(fn)
    return function(self, opts)
        local el = fn(self.Holder, opts or {}, self.Win, self.Tab)
        if el and el.Row then el.Row.LayoutOrder = self:_next() end
        return el
    end
end

Container.Toggle      = attach(function(...) return makeToggle(...) end)
Container.Slider      = attach(function(...) return makeSlider(...) end)
Container.Dropdown    = attach(function(...) return makeDropdown(...) end)
Container.Keybind     = attach(function(...) return makeKeybind(...) end)
Container.ColorPicker = attach(function(...) return makeColor(...) end)
Container.Input       = function(self, opts)
    local el = makeInput(self.Holder, opts or {}, self.Win, self.Tab, false)
    if el and el.Row then el.Row.LayoutOrder = self:_next() end
    return el
end
Container.NumberInput = function(self, opts)
    local el = makeInput(self.Holder, opts or {}, self.Win, self.Tab, true)
    if el and el.Row then el.Row.LayoutOrder = self:_next() end
    return el
end

-- NEW: GamePlayersDropdown
Container.GamePlayersDropdown = function(self, opts)
    local el = makeGamePlayers(self.Holder, opts or {}, self.Win, self.Tab)
    if el and el.Row then el.Row.LayoutOrder = self:_next() end
    return el
end

function Container:Label(text, h)
    return create("TextLabel", {
        BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, h or 22),
        Font = Enum.Font.Gotham, Text = text, TextColor3 = Theme.SubText,
        TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left, TextWrapped = true,
        LayoutOrder = self:_next(), Parent = self.Holder,
    })
end

function Container:Section(name)
    local order = self:_next()
    local sect = create("Frame", {
        BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y, LayoutOrder = order, Parent = self.Holder,
    })
    create("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder, Parent = sect })

    create("TextLabel", {
        BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 20),
        Font = Enum.Font.GothamBold, Text = string.upper(tostring(name)),
        TextColor3 = Theme.SubText, TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Left, LayoutOrder = 0, Parent = sect,
    })

    local inner = create("Frame", {
        BackgroundColor3 = Theme.Element, BackgroundTransparency = 0.55,
        BorderSizePixel = 0, Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y, LayoutOrder = 1, Parent = sect,
    })
    corner(inner, 8)
    create("UIPadding", {
        PaddingTop = UDim.new(0, 10), PaddingBottom = UDim.new(0, 10),
        PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 12), Parent = inner,
    })
    create("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder, Parent = inner })

    return newContainer(self.Win, inner, self.Tab)
end

--=====================================================================
-- ELEMENT FACTORIES
--=====================================================================
function makeToggle(parent, opts, win, tab)
    local name = opts.Name or "Toggle"
    local value = load(tab, name, opts.Default and true or false)

    local row = create("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 34), Parent = parent })

    create("TextLabel", {
        BackgroundTransparency = 1, Size = UDim2.new(1, -60, 1, 0),
        Font = Enum.Font.Gotham, Text = name, TextColor3 = Theme.Text,
        TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left, Parent = row,
    })

    local pill = create("TextButton", {
        AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, 0, 0.5, 0),
        Size = UDim2.fromOffset(42, 22),
        BackgroundColor3 = value and Theme.Accent or Theme.AccentOff,
        AutoButtonColor = false, Text = "", BorderSizePixel = 0, Parent = row,
    })
    corner(pill, 11)

    local knob = create("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0, value and 31 or 11, 0.5, 0),
        Size = UDim2.fromOffset(16, 16),
        BackgroundColor3 = Color3.fromRGB(255,255,255),
        BorderSizePixel = 0, Parent = pill,
    })
    corner(knob, 8)

    local el = { Type = "Toggle", Name = name, Row = row }
    function el:Set(v, fire, doSave)
        v = v and true or false
        value = v
        tween(pill, { BackgroundColor3 = v and Theme.Accent or Theme.AccentOff }, 0.15)
        tween(knob, { Position = UDim2.new(0, v and 31 or 11, 0.5, 0) }, 0.18, Enum.EasingStyle.Back)
        if fire ~= false and opts.Callback then task.spawn(opts.Callback, v) end
        if doSave ~= false then save(tab, name, v) end
    end
    function el:Get() return value end
    pill.MouseButton1Click:Connect(function() el:Set(not value, true, true) end)
    table.insert(win.Elements, el)
    return el
end

function makeSlider(parent, opts, win, tab)
    local name = opts.Name or "Slider"
    local mn, mx = opts.Min or 0, opts.Max or 100
    local dec = opts.Decimals or 0
    local suf = opts.Suffix or ""
    local value = load(tab, name, opts.Default or mn)

    local function fmt(v)
        if dec <= 0 then return tostring(math.floor(v + 0.5)) .. suf end
        return string.format("%." .. dec .. "f", v) .. suf
    end

    local row = create("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 46), Parent = parent })

    create("TextLabel", {
        BackgroundTransparency = 1, Size = UDim2.new(1, -80, 0, 20),
        Font = Enum.Font.Gotham, Text = name, TextColor3 = Theme.Text,
        TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left, Parent = row,
    })

    local val = create("TextLabel", {
        BackgroundTransparency = 1, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, 0, 0, 0),
        Size = UDim2.new(0, 80, 0, 20), Font = Enum.Font.Gotham, Text = fmt(value),
        TextColor3 = Theme.SubText, TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Right, Parent = row,
    })

    local bar = create("Frame", {
        AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 0, 1, -6),
        Size = UDim2.new(1, 0, 0, 6), BackgroundColor3 = Theme.Element,
        BorderSizePixel = 0, Parent = row,
    })
    corner(bar, 3)

    local fill = create("Frame", { Size = UDim2.new(0,0,1,0), BackgroundColor3 = Theme.Accent,
        BorderSizePixel = 0, Parent = bar })
    corner(fill, 3)

    local knob = create("Frame", { AnchorPoint = Vector2.new(0.5,0.5), Size = UDim2.fromOffset(14,14),
        BackgroundColor3 = Color3.fromRGB(255,255,255), BorderSizePixel = 0, Parent = bar })
    corner(knob, 7)

    local function apply(v, fire)
        value = v
        local f = (mx - mn > 0) and (v - mn) / (mx - mn) or 0
        fill.Size = UDim2.new(f, 0, 1, 0)
        knob.Position = UDim2.new(f, 0, 0.5, 0)
        val.Text = fmt(v)
        if fire and opts.Callback then task.spawn(opts.Callback, v) end
    end
    apply(value, false)

    local dragging = false
    local function fromX(x)
        local f = math.clamp((x - bar.AbsolutePosition.X) / math.max(bar.AbsoluteSize.X, 1), 0, 1)
        local raw = mn + (mx - mn) * f
        local m = 10 ^ dec
        apply(math.floor(raw * m + 0.5) / m, true)
    end

    bar.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = true; fromX(i.Position.X) end
    end)
    UIS.InputChanged:Connect(function(i)
        if dragging and i.UserInputType == Enum.UserInputType.MouseMovement then fromX(i.Position.X) end
    end)
    UIS.InputEnded:Connect(function(i)
        if dragging and i.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false; save(tab, name, value)
        end
    end)

    local el = { Type = "Slider", Name = name, Row = row }
    function el:Set(v, fire) apply(math.clamp(v, mn, mx), fire ~= false); save(tab, name, value) end
    function el:Get() return value end
    table.insert(win.Elements, el)
    return el
end

function makeDropdown(parent, opts, win, tab)
    local name = opts.Name or "Dropdown"
    local list = opts.Options or {}
    local multi = opts.Multi and true or false
    local headerH = 34
    local optH = 27

    local saved = load(tab, name, opts.Default)
    local sel = {}

    if multi then
        if type(saved) == "table" then for _, v in ipairs(saved) do sel[v] = true end end
    else
        local def = saved or list[1]
        if def ~= nil then sel[def] = true end
    end

    local contentH = 6 + #list * (optH + 2)
    local expandedH = headerH + contentH

    local row = create("Frame", {
        BackgroundColor3 = Theme.Element, BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, headerH), ClipsDescendants = true, Parent = parent,
    })
    corner(row, 6)

    local header = create("TextButton", { BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, headerH), Text = "", AutoButtonColor = false, Parent = row })

    create("TextLabel", {
        BackgroundTransparency = 1, Position = UDim2.new(0, 12, 0, 0), Size = UDim2.new(0.5, 0, 1, 0),
        Font = Enum.Font.Gotham, Text = name, TextColor3 = Theme.Text, TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left, Parent = header,
    })

    local val = create("TextLabel", {
        BackgroundTransparency = 1, AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -32, 0.5, 0), Size = UDim2.new(0.45, 0, 1, 0),
        Font = Enum.Font.Gotham, Text = "", TextColor3 = Theme.SubText,
        TextSize = 13, TextXAlignment = Enum.TextXAlignment.Right,
        TextTruncate = Enum.TextTruncate.AtEnd, Parent = header,
    })

    local chev = create("Frame", { AnchorPoint = Vector2.new(0.5,0.5),
        Position = UDim2.new(1, -16, 0.5, 0), Size = UDim2.fromOffset(10,10),
        BackgroundTransparency = 1, Parent = header })
    chevron(chev, Theme.SubText)

    local listF = create("Frame", {
        BackgroundTransparency = 1, Position = UDim2.new(0, 0, 0, headerH),
        Size = UDim2.new(1, 0, 0, contentH), Parent = row,
    })
    create("UIListLayout", { Padding = UDim.new(0, 2), SortOrder = Enum.SortOrder.LayoutOrder, Parent = listF })
    create("UIPadding", { PaddingTop = UDim.new(0,3), PaddingLeft = UDim.new(0,6),
        PaddingRight = UDim.new(0,6), Parent = listF })

    local function getSel()
        local out = {}
        for _, o in ipairs(list) do if sel[o] then table.insert(out, o) end end
        return out
    end

    local btns = {}
    local function refresh()
        local s = getSel()
        val.Text = #s == 0 and "None" or table.concat(s, ", ")
        for text, b in pairs(btns) do
            local on = sel[text] and true or false
            b.BackgroundColor3 = on and Theme.ElementHover or Theme.Element
            b.TextColor3 = on and Theme.Accent or Theme.SubText
        end
    end

    for i, o in ipairs(list) do
        local b = create("TextButton", {
            Size = UDim2.new(1, 0, 0, optH), BackgroundColor3 = Theme.Element,
            BorderSizePixel = 0, Font = Enum.Font.Gotham, Text = tostring(o),
            TextColor3 = Theme.SubText, TextSize = 13,
            TextXAlignment = Enum.TextXAlignment.Left, AutoButtonColor = false,
            LayoutOrder = i, Parent = listF,
        })
        corner(b, 4)
        create("UIPadding", { PaddingLeft = UDim.new(0, 8), Parent = b })
        btns[o] = b
        b.MouseEnter:Connect(function() if not sel[o] then b.BackgroundColor3 = Theme.ElementHover end end)
        b.MouseLeave:Connect(function() if not sel[o] then b.BackgroundColor3 = Theme.Element end end)
        b.MouseButton1Click:Connect(function()
            if multi then
                sel[o] = (not sel[o]) or nil
                refresh(); local s = getSel()
                save(tab, name, s)
                if opts.Callback then task.spawn(opts.Callback, s) end
            else
                sel = { [o] = true }
                refresh(); save(tab, name, o)
                if opts.Callback then task.spawn(opts.Callback, o) end
                setOpen(false)
            end
        end)
    end
    refresh()

    local open = false
    function setOpen(s)
        open = s
        tween(row, { Size = UDim2.new(1, 0, 0, s and expandedH or headerH) }, 0.22, Enum.EasingStyle.Quart)
        tween(chev, { Rotation = s and 180 or 0 }, 0.22)
    end

    header.MouseButton1Click:Connect(function() setOpen(not open) end)
    header.MouseEnter:Connect(function() tween(row, { BackgroundColor3 = Theme.ElementHover }, 0.12) end)
    header.MouseLeave:Connect(function() tween(row, { BackgroundColor3 = Theme.Element }, 0.12) end)

    local el = { Type = "Dropdown", Name = name, Row = row }
    function el:Get() if multi then return getSel() end; return getSel()[1] end
    function el:Set(v)
        if multi and type(v) == "table" then
            sel = {}; for _, x in ipairs(v) do sel[x] = true end
        else sel = { [v] = true } end
        refresh(); save(tab, name, v)
    end
    table.insert(win.Elements, el)
    return el
end

function makeInput(parent, opts, win, tab, numeric)
    local name = opts.Name or "Input"
    local value = load(tab, name, opts.Default or (numeric and "" or ""))

    local row = create("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 36), Parent = parent })

    create("TextLabel", {
        BackgroundTransparency = 1, Size = UDim2.new(0.5, 0, 1, 0),
        Font = Enum.Font.Gotham, Text = name, TextColor3 = Theme.Text,
        TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left, Parent = row,
    })

    local box = create("TextBox", {
        AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, 0, 0.5, 0),
        Size = UDim2.new(0.45, 0, 0, 27),
        BackgroundColor3 = Theme.Element, BorderSizePixel = 0, Font = Enum.Font.Gotham,
        Text = tostring(value), PlaceholderText = opts.Placeholder or "Type here...",
        PlaceholderColor3 = Theme.SubText, TextColor3 = Theme.Text, TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left, ClearTextOnFocus = false, Parent = row,
    })
    corner(box, 6)
    create("UIPadding", { PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8), Parent = box })

    if numeric then
        box:GetPropertyChangedSignal("Text"):Connect(function()
            local clean = box.Text:gsub("[^%d%.%-]", "")
            local seen = false
            clean = clean:gsub("%.", function() if seen then return "" end; seen = true; return "." end)
            if clean ~= box.Text then box.Text = clean end
        end)
    end

    box.Focused:Connect(function() tween(box, { BackgroundColor3 = Theme.ElementHover }, 0.15) end)
    box.FocusLost:Connect(function(enter)
        tween(box, { BackgroundColor3 = Theme.Element }, 0.15)
        if numeric then
            local n = tonumber(box.Text) or opts.Default or opts.Min or 0
            if opts.Min then n = math.max(n, opts.Min) end
            if opts.Max then n = math.min(n, opts.Max) end
            value = n; box.Text = tostring(n)
        else value = box.Text end
        save(tab, name, value)
        if opts.Callback then task.spawn(opts.Callback, value, enter) end
    end)

    local el = { Type = numeric and "NumberInput" or "TextInput", Name = name, Row = row }
    function el:Get() return value end
    function el:Set(v) value = v; box.Text = tostring(v); save(tab, name, v) end
    table.insert(win.Elements, el)
    return el
end

function makeKeybind(parent, opts, win, tab)
    local name = opts.Name or "Keybind"
    local savedName = load(tab, name, opts.Default)
    local value = Enum.KeyCode.Unknown
    if typeof(savedName) == "EnumItem" then value = savedName
    elseif type(savedName) == "string" and Enum.KeyCode[savedName] then value = Enum.KeyCode[savedName] end

    local row = create("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 34), Parent = parent })

    create("TextLabel", {
        BackgroundTransparency = 1, Size = UDim2.new(1, -110, 1, 0),
        Font = Enum.Font.Gotham, Text = name, TextColor3 = Theme.Text,
        TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left, Parent = row,
    })

    local btn = create("TextButton", {
        AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, 0, 0.5, 0),
        Size = UDim2.fromOffset(96, 26), BackgroundColor3 = Theme.Element,
        BorderSizePixel = 0, Font = Enum.Font.Gotham,
        Text = value == Enum.KeyCode.Unknown and "None" or value.Name,
        TextColor3 = Theme.Text, TextSize = 12, AutoButtonColor = false, Parent = row,
    })
    corner(btn, 6)

    local listening = false
    local el = { Type = "Keybind", Name = name, Row = row }
    function el:Set(k, fire)
        value = k or Enum.KeyCode.Unknown
        btn.Text = value == Enum.KeyCode.Unknown and "None" or value.Name
        btn.TextColor3 = Theme.Text
        btn.BackgroundColor3 = Theme.Element
        save(tab, name, value.Name)
        if fire ~= false and opts.Callback then task.spawn(opts.Callback, value) end
    end
    function el:Get() return value end

    -- KEYBIND STAYS GRAY WHILE LISTENING
    btn.MouseButton1Click:Connect(function()
        listening = true
        btn.Text = "..."
        btn.TextColor3 = Theme.SubText
        -- background stays Theme.Element (gray)
    end)
    btn.MouseEnter:Connect(function()
        if not listening then tween(btn, { BackgroundColor3 = Theme.ElementHover }, 0.12) end
    end)
    btn.MouseLeave:Connect(function()
        if not listening then tween(btn, { BackgroundColor3 = Theme.Element }, 0.12) end
    end)

    UIS.InputBegan:Connect(function(input, gp)
        if not listening or gp then return end
        listening = false
        btn.BackgroundColor3 = Theme.Element
        btn.TextColor3 = Theme.Text
        if input.UserInputType == Enum.UserInputType.Keyboard then el:Set(input.KeyCode, true) end
    end)

    table.insert(win.Elements, el)
    return el
end

function makeColor(parent, opts, win, tab)
    local name = opts.Name or "Color"
    local headerH = 34
    local panelH  = 172

    local default = opts.Default or Color3.fromRGB(255, 80, 80)
    local color = default
    local saved = load(tab, name, nil)
    if type(saved) == "table" and saved[1] then
        color = Color3.new(saved[1], saved[2], saved[3])
    end

    local row = create("Frame", {
        BackgroundColor3 = Theme.Element, BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, headerH), ClipsDescendants = true, Parent = parent,
    })
    corner(row, 6)

    local header = create("TextButton", { BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, headerH), Text = "", AutoButtonColor = false, Parent = row })

    create("TextLabel", {
        BackgroundTransparency = 1, Position = UDim2.new(0, 12, 0, 0), Size = UDim2.new(0.5, 0, 1, 0),
        Font = Enum.Font.Gotham, Text = name, TextColor3 = Theme.Text, TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left, Parent = header,
    })

    local swatch = create("Frame", {
        AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -32, 0.5, 0),
        Size = UDim2.fromOffset(46, 18), BackgroundColor3 = color,
        BorderSizePixel = 0, Parent = header,
    })
    corner(swatch, 5)

    local chev = create("Frame", { AnchorPoint = Vector2.new(0.5,0.5),
        Position = UDim2.new(1, -16, 0.5, 0), Size = UDim2.fromOffset(10,10),
        BackgroundTransparency = 1, Parent = header })
    chevron(chev, Theme.SubText)

    local panel = create("Frame", {
        BackgroundTransparency = 1, Position = UDim2.new(0, 0, 0, headerH),
        Size = UDim2.new(1, 0, 0, panelH), Parent = row,
    })

    local wheel = CW.new(panel)

    local suppress = false
    wheel.Changed = function(c)
        color = c
        swatch.BackgroundColor3 = c
        if suppress then return end
        save(tab, name, { c.R, c.G, c.B })
        if opts.Callback then task.spawn(opts.Callback, c) end
    end

    local open = false
    function openFunc(s)
        open = s
        tween(row, { Size = UDim2.new(1, 0, 0, s and (headerH + panelH) or headerH) }, 0.25, Enum.EasingStyle.Quart)
        tween(chev, { Rotation = s and 180 or 0 }, 0.25)
        if s then
            wheel:TurnOn()
            task.defer(function()
                suppress = true
                wheel:SetColor(color)
                suppress = false
            end)
        else wheel:TurnOff() end
    end

    header.MouseButton1Click:Connect(function() openFunc(not open) end)
    header.MouseEnter:Connect(function() tween(row, { BackgroundColor3 = Theme.ElementHover }, 0.12) end)
    header.MouseLeave:Connect(function() tween(row, { BackgroundColor3 = Theme.Element }, 0.12) end)

    table.insert(win.Wheels, wheel)

    local el = { Type = "ColorPicker", Name = name, Row = row }
    function el:Get() return color end
    function el:Set(c, fire)
        color = c; swatch.BackgroundColor3 = c
        suppress = true; wheel:SetColor(c); suppress = false
        save(tab, name, { c.R, c.G, c.B })
        if fire ~= false and opts.Callback then task.spawn(opts.Callback, c) end
    end
    table.insert(win.Elements, el)
    return el
end

--=====================================================================
-- GAME PLAYERS DROPDOWN
--   Shows every player currently in the game.
--   Left side: avatar headshot.  Right side: username.
--   Live-updates on PlayerAdded / PlayerRemoving.
--=====================================================================
function makeGamePlayers(parent, opts, win, tab)
    local name = opts.Name or "Players"
    local multi = opts.Multi and true or false
    local headerH = 34
    local rowH = 34
    local avatarSize = 26

    local sel = {}

    -- Rebuild the list dynamically, so content height changes with player count
    local contentPadTop = 3
    local contentPadBottom = 3
    local contentH = 100  -- placeholder, updated on refresh

    local row = create("Frame", {
        BackgroundColor3 = Theme.Element, BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, headerH), ClipsDescendants = true, Parent = parent,
    })
    corner(row, 6)

    local header = create("TextButton", {
        BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, headerH),
        Text = "", AutoButtonColor = false, Parent = row,
    })

    create("TextLabel", {
        BackgroundTransparency = 1, Position = UDim2.new(0, 12, 0, 0), Size = UDim2.new(0.5, 0, 1, 0),
        Font = Enum.Font.Gotham, Text = name, TextColor3 = Theme.Text, TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left, Parent = header,
    })

    local val = create("TextLabel", {
        BackgroundTransparency = 1, AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -32, 0.5, 0), Size = UDim2.new(0.45, 0, 1, 0),
        Font = Enum.Font.Gotham, Text = "", TextColor3 = Theme.SubText,
        TextSize = 13, TextXAlignment = Enum.TextXAlignment.Right,
        TextTruncate = Enum.TextTruncate.AtEnd, Parent = header,
    })

    local chev = create("Frame", { AnchorPoint = Vector2.new(0.5,0.5),
        Position = UDim2.new(1, -16, 0.5, 0), Size = UDim2.fromOffset(10,10),
        BackgroundTransparency = 1, Parent = header })
    chevron(chev, Theme.SubText)

    local listF = create("Frame", {
        BackgroundTransparency = 1, Position = UDim2.new(0, 0, 0, headerH),
        Size = UDim2.new(1, 0, 0, contentH), Parent = row,
    })
    create("UIListLayout", {
        Padding = UDim.new(0, 4),
        SortOrder = Enum.SortOrder.LayoutOrder,
        Parent = listF,
    })
    create("UIPadding", {
        PaddingTop = UDim.new(0, contentPadTop),
        PaddingBottom = UDim.new(0, contentPadBottom),
        PaddingLeft = UDim.new(0, 6),
        PaddingRight = UDim.new(0, 6),
        Parent = listF,
    })

    local playerRows = {}   -- [username] = Button

    local function getSelectedList()
        local out = {}
        for _, p in ipairs(Players:GetPlayers()) do
            if sel[p.Name] then table.insert(out, p.Name) end
        end
        return out
    end

    local function refreshHeader()
        local s = getSelectedList()
        val.Text = #s == 0 and "None" or table.concat(s, ", ")
    end

    local function thumbFor(userId, size)
        -- native Roblox thumbnail URI, no HTTP needed
        return ("rbxthumb://type=AvatarHeadShot&id=%d&w=%d&h=%d"):format(userId, size, size)
    end

    local function styleRow(btn, username)
        local on = sel[username] and true or false
        btn.BackgroundColor3 = on and Theme.ElementHover or Theme.Element
        btn.TextColor3 = on and Theme.Accent or Theme.Text
    end

    -- Rebuild every row from scratch
    local function rebuild()
        -- wipe old
        for _, b in pairs(playerRows) do
            b:Destroy()
        end
        playerRows = {}

        local players = Players:GetPlayers()
        table.sort(players, function(a, b)
            return a.Name:lower() < b.Name:lower()
        end)

        for i, plr in ipairs(players) do
            local btn = create("TextButton", {
                Size = UDim2.new(1, 0, 0, rowH),
                BackgroundColor3 = Theme.Element,
                BorderSizePixel = 0,
                Text = "",
                AutoButtonColor = false,
                LayoutOrder = i,
                Parent = listF,
            })
            corner(btn, 6)

            -- avatar on the left
            local avatarFrame = create("Frame", {
                Position = UDim2.new(0, 4, 0.5, 0),
                AnchorPoint = Vector2.new(0, 0.5),
                Size = UDim2.fromOffset(avatarSize, avatarSize),
                BackgroundColor3 = Theme.Sidepanel,
                BorderSizePixel = 0,
                Parent = btn,
            })
            corner(avatarFrame, avatarSize / 2)

            create("ImageLabel", {
                Size = UDim2.fromScale(1, 1),
                BackgroundTransparency = 1,
                Image = thumbFor(plr.UserId, 60),
                Parent = avatarFrame,
            })
            -- keep avatar a circle
            local imgCorner = create("UICorner", {
                CornerRadius = UDim.new(1, 0),
                Parent = avatarFrame:FindFirstChildOfClass("ImageLabel") or avatarFrame,
            })

            -- username on the right
            local nameLbl = create("TextLabel", {
                BackgroundTransparency = 1,
                AnchorPoint = Vector2.new(1, 0.5),
                Position = UDim2.new(1, -10, 0.5, 0),
                Size = UDim2.new(1, -(avatarSize + 22), 1, 0),
                Font = Enum.Font.Gotham,
                Text = plr.Name,
                TextColor3 = Theme.Text,
                TextSize = 13,
                TextXAlignment = Enum.TextXAlignment.Right,
                TextTruncate = Enum.TextTruncate.AtEnd,
                Parent = btn,
            })

            playerRows[plr.Name] = btn
            styleRow(btn, plr.Name)

            btn.MouseEnter:Connect(function()
                if not sel[plr.Name] then
                    btn.BackgroundColor3 = Theme.ElementHover
                end
            end)
            btn.MouseLeave:Connect(function()
                if not sel[plr.Name] then
                    btn.BackgroundColor3 = Theme.Element
                end
            end)
            btn.MouseButton1Click:Connect(function()
                if multi then
                    sel[plr.Name] = (not sel[plr.Name]) or nil
                else
                    -- clear others
                    sel = { [plr.Name] = true }
                    setOpen(false)
                end
                for uname, b in pairs(playerRows) do styleRow(b, uname) end
                refreshHeader()
                if opts.Callback then
                    task.spawn(opts.Callback, multi and getSelectedList() or plr.Name, plr)
                end
            end)
        end

        -- recompute content height & expand if open
        contentH = contentPadTop + contentPadBottom + #players * (rowH + 4)
        listF.Size = UDim2.new(1, 0, 0, contentH)
        if open then
            tween(row, { Size = UDim2.new(1, 0, 0, headerH + contentH) }, 0.22, Enum.EasingStyle.Quart)
        end

        refreshHeader()
    end

    local open = false
    function setOpen(s)
        open = s
        tween(row, { Size = UDim2.new(1, 0, 0, s and (headerH + contentH) or headerH) },
            0.22, Enum.EasingStyle.Quart)
        tween(chev, { Rotation = s and 180 or 0 }, 0.22)
    end

    header.MouseButton1Click:Connect(function() setOpen(not open) end)
    header.MouseEnter:Connect(function() tween(row, { BackgroundColor3 = Theme.ElementHover }, 0.12) end)
    header.MouseLeave:Connect(function() tween(row, { BackgroundColor3 = Theme.Element }, 0.12) end)

    -- initial fill + live updates
    rebuild()
    local connAdd = Players.PlayerAdded:Connect(function() task.defer(rebuild) end)
    local connRem = Players.PlayerRemoving:Connect(function(plr)
        sel[plr.Name] = nil
        task.defer(rebuild)
    end)

    local el = { Type = "GamePlayersDropdown", Name = name, Row = row }
    function el:Get()
        if multi then return getSelectedList() end
        return getSelectedList()[1]
    end
    function el:Set(v)
        if multi and type(v) == "table" then
            sel = {}; for _, x in ipairs(v) do sel[x] = true end
        else sel = { [v] = true } end
        for uname, b in pairs(playerRows) do styleRow(b, uname) end
        refreshHeader()
    end
    function el:Destroy()
        connAdd:Disconnect()
        connRem:Disconnect()
        row:Destroy()
    end

    table.insert(win.Elements, el)
    return el
end

--=====================================================================
-- CORACLE CONSTRUCTOR
--=====================================================================
function Coracle.new(config)
    config = config or {}

    local logoSrc = loadImage(config.Logo or "https://files.catbox.moe/8qlr1z.png", "coracle_logo.png")
    local warnSrc = loadImage("https://files.catbox.moe/vkrp0b.png", "coracle_warn.png")

    if _G.CoracleActive and _G.CoracleActive.Gui then
        pcall(function() _G.CoracleActive.Gui:Destroy() end)
    end
    _G.CoracleActive = nil

    local self = setmetatable({}, Coracle)
    self.Config = config
    self.Elements = {}
    self.Wheels = {}
    self.Tabs = {}
    self.TabButtons = {}
    self.Current = nil
    self.PanelOpen = true
    self.Minimized = false
    self.Unloaded = false
    self.Hotkey = config.Keybind or Enum.KeyCode.RightShift
    self.LogoSrc = logoSrc
    self.WarnSrc = warnSrc

    self.Gui = create("ScreenGui", {
        Name = "Coracle", ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        DisplayOrder = 100, Parent = PlayerGui,
    })

    self.Main = create("Frame", {
        Name = "Main", AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        Size = UDim2.fromOffset(WIN_W, WIN_H),
        BackgroundColor3 = Theme.Content, BorderSizePixel = 0,
        ClipsDescendants = true, Parent = self.Gui,
    })
    corner(self.Main, 10)
    addStroke(self.Main, Theme.Stroke, 1)
    self.MainScale = ensureUIScale(self.Main, 1)

    self.Side = create("Frame", {
        Name = "Side", Size = UDim2.new(0, SIDEBAR_W, 1, 0),
        BackgroundColor3 = Theme.Sidepanel, BorderSizePixel = 0,
        ClipsDescendants = true, Parent = self.Main,
    })

    self.LogoBar = create("Frame", {
        Name = "LogoBar", Size = UDim2.new(1, 0, 0, LOGO_H),
        BackgroundColor3 = Theme.LogoBg, BorderSizePixel = 0, Parent = self.Side,
    })

    -- The logo slot itself — destroyed by DeleteLogoExample()
    self.LogoImage = create("ImageLabel", {
        Name = "Logo", AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        Size = UDim2.fromOffset(180, 130), BackgroundTransparency = 1,
        Image = logoSrc, ScaleType = Enum.ScaleType.Fit, Parent = self.LogoBar,
    })

    create("Frame", {
        Name = "LogoDivider",
        AnchorPoint = Vector2.new(0, 1),
        Position = UDim2.new(0, 0, 1, 0),
        Size = UDim2.new(1, 0, 0, 1),
        BackgroundColor3 = Theme.Stroke,
        BackgroundTransparency = 0.6,
        BorderSizePixel = 0,
        Parent = self.LogoBar,
    })

    self.TabArea = create("Frame", {
        Name = "TabArea", Position = UDim2.new(0, 0, 0, LOGO_H),
        Size = UDim2.new(1, 0, 1, -LOGO_H),
        BackgroundColor3 = Theme.TabArea, BorderSizePixel = 0, Parent = self.Side,
    })
    create("UIPadding", { PaddingTop = UDim.new(0,10), PaddingBottom = UDim.new(0,10),
        PaddingLeft = UDim.new(0,8), PaddingRight = UDim.new(0,8), Parent = self.TabArea })
    create("UIListLayout", { Padding = UDim.new(0,6), SortOrder = Enum.SortOrder.LayoutOrder, Parent = self.TabArea })

    self.Content = create("Frame", {
        Name = "Content", Position = UDim2.new(0, SIDEBAR_W, 0, 0),
        Size = UDim2.new(1, -SIDEBAR_W, 1, 0),
        BackgroundColor3 = Theme.Content, BorderSizePixel = 0, Parent = self.Main,
    })

    local header = create("Frame", {
        Name = "Header", Size = UDim2.new(1, 0, 0, HEADER_H),
        BackgroundTransparency = 1, Parent = self.Content,
    })
    create("Frame", { Name = "Line", AnchorPoint = Vector2.new(0,1),
        Position = UDim2.new(0, 0, 1, 0), Size = UDim2.new(1, 0, 0, 1),
        BackgroundColor3 = Theme.Stroke, BackgroundTransparency = 0.5, BorderSizePixel = 0, Parent = header })

    local menuBtn = iconBtn(header, 30)
    menuBtn.AnchorPoint = Vector2.new(0, 0.5)
    menuBtn.Position = UDim2.new(0, 16, 0.5, 0)
    menuIcon(menuBtn, 14, Theme.Text)

    self.Title = create("TextLabel", {
        Name = "Title", BackgroundTransparency = 1,
        Position = UDim2.new(0, 58, 0, 0), Size = UDim2.new(0, 300, 1, 0),
        Font = Enum.Font.GothamBold, Text = config.Title or "Coracle",
        TextColor3 = Theme.Text, TextSize = 16,
        TextXAlignment = Enum.TextXAlignment.Left, Parent = header,
    })

    local closeBtn = iconBtn(header, 30)
    closeBtn.AnchorPoint = Vector2.new(1, 0.5)
    closeBtn.Position = UDim2.new(1, -16, 0.5, 0)
    xIcon(closeBtn, 11, Theme.Text)

    local minBtn = iconBtn(header, 30)
    minBtn.AnchorPoint = Vector2.new(1, 0.5)
    minBtn.Position = UDim2.new(1, -52, 0.5, 0)
    minusIcon(minBtn, 11, Theme.Text)

    self.Pages = create("Frame", {
        Name = "Pages", Position = UDim2.new(0, 0, 0, HEADER_H),
        Size = UDim2.new(1, 0, 1, -HEADER_H), BackgroundTransparency = 1, Parent = self.Content,
    })

    -- ORB
    self.Orb = create("ImageButton", {
        Name = "Orb", AnchorPoint = Vector2.new(0.5, 0),
        Position = UDim2.new(0.5, 0, 0, 20),
        Size = UDim2.fromOffset(ORB_SIZE, ORB_SIZE),
        BackgroundColor3 = Theme.Sidepanel, BorderSizePixel = 0,
        Image = logoSrc, ScaleType = Enum.ScaleType.Fit,
        Visible = false, AutoButtonColor = false, Parent = self.Gui,
    })
    corner(self.Orb, ORB_SIZE / 2)
    addStroke(self.Orb, Theme.Stroke)
    self.OrbScale = ensureUIScale(self.Orb, 1)

    local savedPos = load("_meta", "OrbPosition", nil)
    if type(savedPos) == "table" and #savedPos == 4 then
        self.Orb.Position = UDim2.new(savedPos[1], savedPos[2], savedPos[3], savedPos[4])
    end

    do
        local orbDragging = false
        local orbMoved = false
        local dragStartPos = nil
        local startOrbPos = nil

        self.Orb.InputBegan:Connect(function(input)
            if input.UserInputType ~= Enum.UserInputType.MouseButton1
               and input.UserInputType ~= Enum.UserInputType.Touch then return end
            orbDragging = true
            orbMoved = false
            dragStartPos = input.Position
            startOrbPos = self.Orb.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    orbDragging = false
                    if orbMoved then
                        save("_meta", "OrbPosition", {
                            self.Orb.Position.X.Scale, self.Orb.Position.X.Offset,
                            self.Orb.Position.Y.Scale, self.Orb.Position.Y.Offset,
                        })
                    end
                end
            end)
        end)

        UIS.InputChanged:Connect(function(input)
            if not orbDragging then return end
            if input.UserInputType ~= Enum.UserInputType.MouseMovement
               and input.UserInputType ~= Enum.UserInputType.Touch then return end
            local delta = input.Position - dragStartPos
            if math.abs(delta.X) > 4 or math.abs(delta.Y) > 4 then orbMoved = true end
            self.Orb.Position = UDim2.new(
                startOrbPos.X.Scale, startOrbPos.X.Offset + delta.X,
                startOrbPos.Y.Scale, startOrbPos.Y.Offset + delta.Y
            )
        end)

        self.Orb.MouseButton1Click:Connect(function()
            if orbMoved then orbMoved = false; return end
            self:Minimize(false)
        end)
    end

    -- Notifications (bottom-left)
    self.NotifHolder = create("Frame", {
        Name = "Notifs", AnchorPoint = Vector2.new(0, 1),
        Position = UDim2.new(0, 18, 1, -18),
        Size = UDim2.fromOffset(290, 500),
        BackgroundTransparency = 1, Parent = self.Gui,
    })
    create("UIListLayout", {
        Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder,
        VerticalAlignment = Enum.VerticalAlignment.Bottom,
        HorizontalAlignment = Enum.HorizontalAlignment.Left,
        Parent = self.NotifHolder,
    })
    self._nOrder = 0

    -- Window drag
    local function drag(handle)
        local dragging, dragStart, startPos = false
        handle.InputBegan:Connect(function(input)
            if input.UserInputType ~= Enum.UserInputType.MouseButton1
               and input.UserInputType ~= Enum.UserInputType.Touch then return end
            dragging = true; dragStart = input.Position; startPos = self.Main.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then dragging = false end
            end)
        end)
        UIS.InputChanged:Connect(function(input)
            if not dragging then return end
            if input.UserInputType ~= Enum.UserInputType.MouseMovement
               and input.UserInputType ~= Enum.UserInputType.Touch then return end
            local d = input.Position - dragStart
            self.Main.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + d.X,
                startPos.Y.Scale, startPos.Y.Offset + d.Y)
        end)
    end
    drag(self.LogoBar); drag(header)

    -- Buttons
    menuBtn.MouseButton1Click:Connect(function() self:ToggleSide() end)
    menuBtn.MouseEnter:Connect(function() tween(menuBtn, { BackgroundColor3 = Theme.ElementHover }, 0.12) end)
    menuBtn.MouseLeave:Connect(function() tween(menuBtn, { BackgroundColor3 = Theme.Element, BackgroundTransparency = 0.15 }, 0.12) end)

    closeBtn.MouseEnter:Connect(function() tween(closeBtn, { BackgroundColor3 = Theme.Danger, BackgroundTransparency = 0 }, 0.12) end)
    closeBtn.MouseLeave:Connect(function() tween(closeBtn, { BackgroundColor3 = Theme.Element, BackgroundTransparency = 0.15 }, 0.12) end)
    closeBtn.MouseButton1Click:Connect(function() self:Confirm() end)

    minBtn.MouseEnter:Connect(function() tween(minBtn, { BackgroundColor3 = Theme.ElementHover }, 0.12) end)
    minBtn.MouseLeave:Connect(function() tween(minBtn, { BackgroundColor3 = Theme.Element, BackgroundTransparency = 0.15 }, 0.12) end)
    minBtn.MouseButton1Click:Connect(function() self:Minimize(true) end)

    UIS.InputBegan:Connect(function(input, gp)
        if gp then return end
        if input.UserInputType ~= Enum.UserInputType.Keyboard then return end
        if input.KeyCode == self.Hotkey then self:Minimize(not self.Minimized) end
    end)

    _G.CoracleActive = self
    return self
end

--=====================================================================
-- CORACLE METHODS
--=====================================================================
function Coracle:ToggleSide(state)
    if state == nil then state = not self.PanelOpen end
    self.PanelOpen = state
    local w = state and SIDEBAR_W or 0
    tween(self.Side, { Size = UDim2.new(0, w, 1, 0) }, 0.26, Enum.EasingStyle.Quart)
    tween(self.Content, { Position = UDim2.new(0, w, 0, 0), Size = UDim2.new(1, -w, 1, 0) },
        0.26, Enum.EasingStyle.Quart)
end

function Coracle:_orbCenterAsMainPos()
    local p = self.Orb.Position
    return UDim2.new(p.X.Scale, p.X.Offset, p.Y.Scale, p.Y.Offset + (ORB_SIZE / 2))
end

function Coracle:Minimize(state)
    if state == nil then state = not self.Minimized end
    if state == self.Minimized then return end
    self.Minimized = state

    local mainScale = ensureUIScale(self.Main, self.MainScale.Scale)
    self.MainScale = mainScale
    local orbScale = ensureUIScale(self.Orb, self.OrbScale.Scale)
    self.OrbScale = orbScale

    if state then
        self._mainRestorePos = self.Main.Position
        local collapseTarget = self:_orbCenterAsMainPos()

        self.Orb.Visible = true
        orbScale.Scale = 0

        tween(mainScale, { Scale = 0 }, 0.28, Enum.EasingStyle.Back, Enum.EasingDirection.In)
        tween(self.Main, { Position = collapseTarget }, 0.28, Enum.EasingStyle.Quart, Enum.EasingDirection.In)

        task.delay(0.28, function()
            if not self.Minimized then return end
            self.Main.Visible = false
            self.Main.Position = self._mainRestorePos
            mainScale.Scale = 1
        end)

        task.delay(0.22, function()
            if not self.Minimized then return end
            tween(orbScale, { Scale = 1 }, 0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
        end)
    else
        self._mainRestorePos = self._mainRestorePos or UDim2.new(0.5, 0, 0.5, 0)
        self.Main.Position = self:_orbCenterAsMainPos()
        self.Main.Visible = true
        mainScale.Scale = 0

        tween(orbScale, { Scale = 0 }, 0.2, Enum.EasingStyle.Back, Enum.EasingDirection.In)

        task.delay(0.1, function()
            if self.Minimized then return end
            tween(mainScale, { Scale = 1 }, 0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
            tween(self.Main, { Position = self._mainRestorePos }, 0.4, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
        end)

        task.delay(0.5, function()
            if self.Minimized then return end
            self.Orb.Visible = false
            orbScale.Scale = 1
        end)
    end
end

function Coracle:Tab(name)
    name = tostring(name)
    local order = #self.Tabs + 1

    local btn = create("TextButton", {
        Name = "Tab_" .. name, Size = UDim2.new(1, 0, 0, 36),
        BackgroundColor3 = Theme.Sidepanel, BackgroundTransparency = 1,
        Text = "", AutoButtonColor = false, LayoutOrder = order, Parent = self.TabArea,
    })
    corner(btn, 7)

    local ind = create("Frame", { AnchorPoint = Vector2.new(0, 0.5),
        Position = UDim2.new(0, 0, 0.5, 0), Size = UDim2.fromOffset(3, 0),
        BackgroundColor3 = Theme.Accent, BorderSizePixel = 0, Parent = btn })
    corner(ind, 2)

    local lbl = create("TextLabel", {
        BackgroundTransparency = 1, Position = UDim2.new(0, 16, 0, 0),
        Size = UDim2.new(1, -16, 1, 0), Font = Enum.Font.Gotham, Text = name,
        TextColor3 = Theme.SubText, TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left, Parent = btn,
    })

    local page = create("ScrollingFrame", {
        Name = "Page_" .. name, Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1, BorderSizePixel = 0,
        ScrollBarThickness = 4, ScrollBarImageColor3 = Theme.Stroke,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        ScrollBarImageTransparency = 0.4, Visible = false, Parent = self.Pages,
    })
    create("UIPadding", { PaddingTop = UDim.new(0,14), PaddingBottom = UDim.new(0,14),
        PaddingLeft = UDim.new(0,16), PaddingRight = UDim.new(0,16), Parent = page })
    create("UIListLayout", { Padding = UDim.new(0,10), SortOrder = Enum.SortOrder.LayoutOrder, Parent = page })

    local container = newContainer(self, page, name)

    btn.MouseEnter:Connect(function()
        if self.Current ~= name then tween(btn, { BackgroundTransparency = 0.35 }, 0.12) end
    end)
    btn.MouseLeave:Connect(function()
        if self.Current ~= name then tween(btn, { BackgroundTransparency = 1 }, 0.12) end
    end)
    btn.MouseButton1Click:Connect(function() self:Select(name) end)

    self.TabButtons[name] = { Button = btn, Label = lbl, Ind = ind, Page = page }
    table.insert(self.Tabs, name)

    if #self.Tabs == 1 then self:Select(name) end
    return container
end

function Coracle:Select(name)
    if self.Current == name then return end
    self.Current = name
    for tabName, d in pairs(self.TabButtons) do
        local active = tabName == name
        d.Page.Visible = active
        tween(d.Label, { TextColor3 = active and Theme.Text or Theme.SubText }, 0.15)
        tween(d.Button, { BackgroundTransparency = active and 0.45 or 1 }, 0.15)
        tween(d.Ind, { Size = UDim2.fromOffset(3, active and 18 or 0) }, 0.22, Enum.EasingStyle.Quart)
    end
    if self.Title then self.Title.Text = name end
end

--=====================================================================
-- NEW: DeleteExamples  /  DeleteLogoExample
--=====================================================================

-- Removes the Example tab entirely (button, page, tracked entry).
-- If the Example tab was active, switches to the first remaining tab
-- (or clears the header title if nothing is left).
function Coracle:DeleteExamples()
    local tabName = self.ExampleTab
    if not tabName then return end

    local d = self.TabButtons[tabName]
    if d then
        d.Button:Destroy()
        d.Page:Destroy()
        self.TabButtons[tabName] = nil
    end

    for i, t in ipairs(self.Tabs) do
        if t == tabName then table.remove(self.Tabs, i); break end
    end

    if self.Current == tabName then
        self.Current = nil
        if #self.Tabs > 0 then
            self:Select(self.Tabs[1])
        elseif self.Title then
            self.Title.Text = self.Config.Title or "Coracle"
        end
    end

    self.ExampleTab = nil
end

-- Removes the big logo image in the top-left header.
-- The empty logo bar is left in place so the user can drop in their own.
function Coracle:DeleteLogoExample()
    if self.LogoImage then
        self.LogoImage:Destroy()
        self.LogoImage = nil
    end
end

--=====================================================================
-- BUILD EXAMPLES
--=====================================================================
function Coracle:BuildExamples()
    local tabName = "Example"
    local main = self:Tab(tabName)
    self.ExampleTab = tabName

    local general = main:Section("General")
    general:Toggle({
        Name = "Enable Feature", Default = true,
        Callback = function(v) print("[Coracle] Enable Feature:", v) end,
    })
    general:Slider({
        Name = "Speed", Min = 1, Max = 100, Default = 50,
        Callback = function(v) print("[Coracle] Speed:", v) end,
    })
    general:Dropdown({
        Name = "Mode", Options = { "Legit", "Rage", "Custom" },
        Callback = function(v) print("[Coracle] Mode:", v) end,
    })

    local players = main:Section("Players")
    players:GamePlayersDropdown({
        Name = "Target",
        Callback = function(v, plr) print("[Coracle] Target:", v) end,
    })
    players:GamePlayersDropdown({
        Name = "Ignored (Multi)", Multi = true,
        Callback = function(list) print("[Coracle] Ignored:", table.concat(list, ", ")) end,
    })

    local inputs = main:Section("Inputs")
    inputs:Input({ Name = "Username", Placeholder = "Enter name" })
    inputs:NumberInput({ Name = "Amount", Min = 0, Max = 1000, Default = 10 })
    inputs:Keybind({ Name = "Activate", Default = "F" })

    local appearance = main:Section("Appearance")
    appearance:ColorPicker({
        Name = "Highlight", Default = Color3.fromRGB(100, 150, 255),
        Callback = function(c) print("[Coracle] Color:", c) end,
    })

    return main
end

--=====================================================================
-- NOTIFICATION + CONFIRM + UNLOAD  (unchanged from previous build)
--=====================================================================
function Coracle:Notify(opts)
    opts = opts or {}
    local title = opts.Title or "Coracle"
    local text = opts.Text or ""
    local dur = opts.Duration or 4
    local accent = opts.Color or Theme.Accent

    self._nOrder = self._nOrder + 1

    local holder = create("Frame", {
        Name = "Notif", Size = UDim2.fromOffset(290, 62),
        BackgroundTransparency = 1, LayoutOrder = self._nOrder, Parent = self.NotifHolder,
    })

    local card = create("Frame", {
        Size = UDim2.new(1, 0, 1, 0), Position = UDim2.new(-1, -30, 0, 0),
        BackgroundColor3 = Theme.Sidepanel, BackgroundTransparency = 1,
        BorderSizePixel = 0, Parent = holder,
    })
    corner(card, 8)
    local strk = create("UIStroke", { Color = Theme.Stroke, Transparency = 1, Parent = card })

    local bar = create("Frame", { Size = UDim2.new(0, 3, 1, 0),
        BackgroundColor3 = accent, BorderSizePixel = 0,
        BackgroundTransparency = 1, Parent = card })
    corner(bar, 2)

    local tL = create("TextLabel", {
        BackgroundTransparency = 1, Position = UDim2.new(0, 14, 0, 10),
        Size = UDim2.new(1, -24, 0, 18), Font = Enum.Font.GothamBold, Text = title,
        TextColor3 = Theme.Text, TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left,
        TextTransparency = 1, Parent = card,
    })
    local xL = create("TextLabel", {
        BackgroundTransparency = 1, Position = UDim2.new(0, 14, 0, 29),
        Size = UDim2.new(1, -24, 0, 26), Font = Enum.Font.Gotham, Text = text,
        TextColor3 = Theme.SubText, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left,
        TextWrapped = true, TextTransparency = 1, Parent = card,
    })

    tween(card, { Position = UDim2.new(0,0,0,0), BackgroundTransparency = 0 }, 0.3, Enum.EasingStyle.Quart)
    tween(strk, { Transparency = 0 }, 0.3)
    tween(bar, { BackgroundTransparency = 0 }, 0.3)
    tween(tL, { TextTransparency = 0 }, 0.3)
    tween(xL, { TextTransparency = 0 }, 0.3)

    task.delay(dur, function()
        tween(card, { Position = UDim2.new(-1, -30, 0, 0), BackgroundTransparency = 1 }, 0.25, Enum.EasingStyle.Quart)
        tween(tL, { TextTransparency = 1 }, 0.2)
        tween(xL, { TextTransparency = 1 }, 0.2)
        tween(bar, { BackgroundTransparency = 1 }, 0.2)
        tween(strk, { Transparency = 1 }, 0.2)
        task.delay(0.3, function() holder:Destroy() end)
    end)
end

function Coracle:Confirm()
    if self._confirmOpen then return end
    self._confirmOpen = true

    local ov = create("Frame", {
        Name = "Confirm", Size = UDim2.new(1, 0, 1, 0),
        BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 1,
        BorderSizePixel = 0, ZIndex = 50, Parent = self.Main,
    })
    corner(ov, 10)

    local p = create("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0.5, 0),
        Size = UDim2.fromOffset(340, 250), BackgroundColor3 = Theme.Sidepanel,
        BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = 51, Parent = ov,
    })
    corner(p, 12)
    local pstk = create("UIStroke", { Color = Theme.Stroke, Transparency = 1, Parent = p })

    local wl = create("ImageLabel", {
        AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 22),
        Size = UDim2.fromOffset(72, 72), BackgroundTransparency = 1,
        Image = self.WarnSrc or "", ScaleType = Enum.ScaleType.Fit,
        ImageTransparency = 1, ZIndex = 52, Parent = p,
    })

    local tL = create("TextLabel", {
        BackgroundTransparency = 1, Position = UDim2.new(0, 0, 0, 106),
        Size = UDim2.new(1, 0, 0, 24), Font = Enum.Font.GothamBold, Text = "Are you sure?",
        TextColor3 = Theme.Text, TextSize = 18, TextTransparency = 1, ZIndex = 52, Parent = p,
    })
    local sL = create("TextLabel", {
        BackgroundTransparency = 1, Position = UDim2.new(0, 20, 0, 132),
        Size = UDim2.new(1, -40, 0, 40), Font = Enum.Font.Gotham,
        Text = "This will turn off all features. Your saved settings are kept and will reload next time you execute.",
        TextColor3 = Theme.SubText, TextSize = 12, TextWrapped = true,
        TextTransparency = 1, ZIndex = 52, Parent = p,
    })

    local back = create("TextButton", {
        Position = UDim2.new(0, 20, 1, -64), Size = UDim2.new(0.5, -28, 0, 40),
        BackgroundColor3 = Theme.Element, BackgroundTransparency = 1, BorderSizePixel = 0,
        Font = Enum.Font.Gotham, Text = "Go Back", TextColor3 = Theme.Text,
        TextTransparency = 1, TextSize = 14, AutoButtonColor = false, ZIndex = 52, Parent = p,
    })
    corner(back, 8)
    local cont = create("TextButton", {
        AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -20, 1, -64),
        Size = UDim2.new(0.5, -28, 0, 40), BackgroundColor3 = Theme.Danger,
        BackgroundTransparency = 1, BorderSizePixel = 0, Font = Enum.Font.Gotham,
        Text = "Continue", TextColor3 = Theme.Text, TextTransparency = 1,
        TextSize = 14, AutoButtonColor = false, ZIndex = 52, Parent = p,
    })
    corner(cont, 8)

    tween(ov, { BackgroundTransparency = 0.55 }, 0.2)
    tween(p, { BackgroundTransparency = 0 }, 0.2)
    tween(pstk, { Transparency = 0 }, 0.2)
    tween(wl, { ImageTransparency = 0 }, 0.25)
    tween(tL, { TextTransparency = 0 }, 0.25)
    tween(sL, { TextTransparency = 0 }, 0.25)
    tween(back, { BackgroundTransparency = 0, TextTransparency = 0 }, 0.25)
    tween(cont, { BackgroundTransparency = 0, TextTransparency = 0 }, 0.25)

    local function close()
        self._confirmOpen = false
        tween(ov, { BackgroundTransparency = 1 }, 0.18)
        tween(p, { BackgroundTransparency = 1 }, 0.18)
        tween(pstk, { Transparency = 1 }, 0.18)
        tween(wl, { ImageTransparency = 1 }, 0.15)
        tween(tL, { TextTransparency = 1 }, 0.15)
        tween(sL, { TextTransparency = 1 }, 0.15)
        tween(back, { BackgroundTransparency = 1, TextTransparency = 1 }, 0.15)
        tween(cont, { BackgroundTransparency = 1, TextTransparency = 1 }, 0.15)
        task.delay(0.22, function() ov:Destroy() end)
    end

    back.MouseEnter:Connect(function() tween(back, { BackgroundColor3 = Theme.ElementHover }, 0.12) end)
    back.MouseLeave:Connect(function() tween(back, { BackgroundColor3 = Theme.Element }, 0.12) end)
    back.MouseButton1Click:Connect(close)

    cont.MouseEnter:Connect(function() tween(cont, { BackgroundColor3 = Color3.fromRGB(255,92,92) }, 0.12) end)
    cont.MouseLeave:Connect(function() tween(cont, { BackgroundColor3 = Theme.Danger }, 0.12) end)
    cont.MouseButton1Click:Connect(function()
        close()
        task.delay(0.1, function() self:Unload() end)
    end)
end

function Coracle:Unload()
    if self.Unloaded then return end
    self.Unloaded = true

    for _, el in ipairs(self.Elements) do
        if el.Type == "Toggle" then pcall(function() el:Set(false, true, false) end) end
    end
    for _, w in ipairs(self.Wheels) do pcall(function() w:TurnOff() end) end

    if self.Gui then
        tween(self.Main, { BackgroundTransparency = 1 }, 0.18)
        for _, c in ipairs(self.Main:GetChildren()) do
            if c:IsA("GuiObject") then c.Visible = false end
        end
        task.delay(0.2, function()
            if self.Gui then self.Gui:Destroy() end
            if _G.CoracleActive == self then _G.CoracleActive = nil end
        end)
    end
end
Coracle.Destroy = Coracle.Unload

--=====================================================================
-- ██ AUTO-RUN ██
--=====================================================================
local ok, err = pcall(function()
    local win = Coracle.new({
        Title  = "Coracle",
        Logo   = "https://files.catbox.moe/8qlr1z.png",
        Keybind = Enum.KeyCode.RightShift,
    })

    -- Build the deletable Example tab
    win:BuildExamples()

    -- Uncomment to remove the demo content / logo:
    -- win:DeleteExamples()
    -- win:DeleteLogoExample()

    -- Add your own tabs afterwards, e.g.:
    -- local myTab = win:Tab("MyTab")
    -- local mySection = myTab:Section("My Section")
    -- mySection:Toggle({ Name = "Cool Feature", Default = true })

    win:Notify({
        Title = "Coracle",
        Text = "Loaded. Press RightShift to minimize.",
        Duration = 5,
    })

    print("[Coracle] loaded successfully.")
end)

if not ok then
    warn("[Coracle] Failed to load: " .. tostring(err))
end
