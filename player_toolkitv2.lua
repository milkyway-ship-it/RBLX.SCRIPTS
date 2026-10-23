




local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

do
	local old = playerGui:FindFirstChild("PlayerToolkit")
	if old then
		old:Destroy()
	end
end

local TAU = math.pi * 2




local THEME = {
	bg = Color3.fromRGB(22, 22, 30),
	title = Color3.fromRGB(34, 34, 50),
	item = Color3.fromRGB(36, 36, 50),
	accent = Color3.fromRGB(80, 110, 230),
	accentDim = Color3.fromRGB(55, 75, 160),
	text = Color3.fromRGB(235, 235, 245),
	sub = Color3.fromRGB(150, 150, 172),
	track = Color3.fromRGB(52, 52, 70),
	off = Color3.fromRGB(70, 70, 92),
}

local function new(className, props, parent)
	local inst = Instance.new(className)
	for k, v in pairs(props) do
		inst[k] = v
	end
	inst.Parent = parent
	return inst
end

local function round(inst, radius)
	new("UICorner", { CornerRadius = UDim.new(0, radius) }, inst)
end

local function thumb(userId)
	return string.format("rbxthumb://type=AvatarHeadShot&id=%d&w=150&h=150", userId)
end




local State = {
	selected = nil,
	
	distance = 8,
	height = 2,
	spectate = true,
	
	mapDistance = 150000,
	mapHeight = 400,
	autoMap = false,
	
	viewActive = false,
	esp = { box = false, skeleton = false, chams = false, names = false },
}


local binds = {}
local bindButtons = {}
local listening = nil


local startOrbit, stopOrbit, startMap, stopMap, setView, teleportToTarget, autoTarget, setSelected
local orbitRow, mapRow, viewRow
local statusLabel

local function setStatus(text)
	if statusLabel then
		statusLabel.Text = text
	end
end




local gui = new("ScreenGui", {
	Name = "PlayerToolkit",
	ResetOnSpawn = false,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	DisplayOrder = 50,
}, playerGui)

local frame = new("Frame", {
	Size = UDim2.fromOffset(340, 480),
	Position = UDim2.fromOffset(20, 80),
	BackgroundColor3 = THEME.bg,
	BorderSizePixel = 0,
	Active = true,
	ClipsDescendants = true,
}, gui)
round(frame, 8)

local title = new("Frame", {
	Size = UDim2.new(1, 0, 0, 34),
	BackgroundColor3 = THEME.title,
	BorderSizePixel = 0,
	Active = true,
}, frame)

new("TextLabel", {
	Size = UDim2.new(1, -50, 1, 0),
	Position = UDim2.fromOffset(12, 0),
	BackgroundTransparency = 1,
	Text = "PLAYER TOOLKIT",
	Font = Enum.Font.GothamBold,
	TextSize = 14,
	TextColor3 = THEME.text,
	TextXAlignment = Enum.TextXAlignment.Left,
}, title)

local minimizeButton = new("TextButton", {
	Size = UDim2.fromOffset(30, 24),
	Position = UDim2.new(1, -36, 0, 5),
	Text = "-",
	Font = Enum.Font.GothamBold,
	TextSize = 18,
	TextColor3 = THEME.text,
	BackgroundColor3 = THEME.off,
	BorderSizePixel = 0,
}, title)
round(minimizeButton, 5)

local contents = new("Frame", {
	Size = UDim2.new(1, 0, 1, -34),
	Position = UDim2.fromOffset(0, 34),
	BackgroundTransparency = 1,
}, frame)

local minimized = false
minimizeButton.MouseButton1Click:Connect(function()
	minimized = not minimized
	contents.Visible = not minimized
	frame.Size = minimized and UDim2.fromOffset(340, 34) or UDim2.fromOffset(340, 480)
	minimizeButton.Text = minimized and "+" or "-"
end)


do
	local dragging = false
	local dragStart, startPos
	title.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			dragStart = input.Position
			startPos = frame.Position
			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					dragging = false
				end
			end)
		end
	end)
	UserInputService.InputChanged:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
			or input.UserInputType == Enum.UserInputType.Touch) then
			local delta = input.Position - dragStart
			frame.Position = UDim2.new(
				startPos.X.Scale, startPos.X.Offset + delta.X,
				startPos.Y.Scale, startPos.Y.Offset + delta.Y
			)
		end
	end)
end


local targetBar = new("Frame", {
	Size = UDim2.new(1, -20, 0, 36),
	Position = UDim2.fromOffset(10, 6),
	BackgroundColor3 = THEME.item,
	BorderSizePixel = 0,
}, contents)
round(targetBar, 6)

local targetAvatar = new("ImageLabel", {
	Size = UDim2.fromOffset(28, 28),
	Position = UDim2.fromOffset(4, 4),
	BackgroundColor3 = THEME.track,
	BorderSizePixel = 0,
	Visible = false,
}, targetBar)
round(targetAvatar, 14)

local targetLabel = new("TextLabel", {
	Size = UDim2.new(1, -44, 1, 0),
	Position = UDim2.fromOffset(40, 0),
	BackgroundTransparency = 1,
	Text = "No target selected",
	Font = Enum.Font.GothamMedium,
	TextSize = 13,
	TextColor3 = THEME.text,
	TextXAlignment = Enum.TextXAlignment.Left,
	TextTruncate = Enum.TextTruncate.AtEnd,
}, targetBar)

local tabBar = new("Frame", {
	Size = UDim2.new(1, -20, 0, 28),
	Position = UDim2.fromOffset(10, 48),
	BackgroundTransparency = 1,
}, contents)
new("UIListLayout", {
	FillDirection = Enum.FillDirection.Horizontal,
	Padding = UDim.new(0, 4),
	SortOrder = Enum.SortOrder.LayoutOrder,
}, tabBar)

local pagesHolder = new("Frame", {
	Size = UDim2.new(1, -20, 0, 326),
	Position = UDim2.fromOffset(10, 82),
	BackgroundTransparency = 1,
}, contents)

statusLabel = new("TextLabel", {
	Size = UDim2.new(1, -20, 0, 24),
	Position = UDim2.fromOffset(10, 416),
	BackgroundColor3 = THEME.item,
	BorderSizePixel = 0,
	Text = "Pick a player in the PLAYERS tab",
	Font = Enum.Font.Gotham,
	TextSize = 12,
	TextColor3 = THEME.sub,
	TextTruncate = Enum.TextTruncate.AtEnd,
}, contents)
round(statusLabel, 5)

local tabs = {}
local function showTab(name)
	for n, t in pairs(tabs) do
		t.page.Visible = (n == name)
		t.button.BackgroundColor3 = (n == name) and THEME.accent or THEME.item
	end
end

local function makeTab(order, name)
	local button = new("TextButton", {
		LayoutOrder = order,
		Size = UDim2.new(1 / 3, -3, 1, 0),
		BackgroundColor3 = THEME.item,
		BorderSizePixel = 0,
		Text = name,
		Font = Enum.Font.GothamBold,
		TextSize = 12,
		TextColor3 = THEME.text,
	}, tabBar)
	round(button, 5)
	local page = new("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Visible = false,
	}, pagesHolder)
	tabs[name] = { button = button, page = page }
	button.MouseButton1Click:Connect(function()
		showTab(name)
	end)
	return page
end

local playersPage = makeTab(1, "PLAYERS")
local orbitPage = makeTab(2, "ORBIT")
local finderPage = makeTab(3, "FINDER")




local function makePill(parent, default, onChange)
	local pill = new("TextButton", {
		Size = UDim2.fromOffset(40, 20),
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, 0, 0.5, 0),
		Text = "",
		AutoButtonColor = false,
		BorderSizePixel = 0,
	}, parent)
	round(pill, 10)
	local knob = new("Frame", {
		Size = UDim2.fromOffset(16, 16),
		AnchorPoint = Vector2.new(0, 0.5),
		BackgroundColor3 = Color3.new(1, 1, 1),
		BorderSizePixel = 0,
	}, pill)
	round(knob, 8)

	local obj = { Value = default and true or false }
	local function render()
		pill.BackgroundColor3 = obj.Value and THEME.accent or THEME.off
		knob.Position = obj.Value and UDim2.new(1, -18, 0.5, 0) or UDim2.new(0, 2, 0.5, 0)
	end
	function obj:Set(value, silent)
		value = value and true or false
		if value == self.Value then
			return
		end
		self.Value = value
		render()
		if not silent and onChange then
			onChange(value)
		end
	end
	pill.MouseButton1Click:Connect(function()
		obj:Set(not obj.Value)
	end)
	render()
	return obj, pill
end

local function refreshBind(name)
	local b = bindButtons[name]
	if not b then
		return
	end
	if listening == name then
		b.Text = "Press key..."
	else
		b.Text = binds[name] and binds[name].Name or "None"
	end
end

local function makeKeybind(parent, name)
	local b = new("TextButton", {
		Size = UDim2.fromOffset(76, 24),
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, 0, 0.5, 0),
		BackgroundColor3 = THEME.item,
		BorderSizePixel = 0,
		Font = Enum.Font.GothamBold,
		TextSize = 11,
		TextColor3 = THEME.text,
		Text = "None",
	}, parent)
	round(b, 5)
	bindButtons[name] = b
	b.MouseButton1Click:Connect(function()
		local prev = listening
		listening = name
		if prev then
			refreshBind(prev)
		end
		refreshBind(name)
	end)
	return b
end


local function makeRow(parent, y, text, bindName, onChange, onSettings)
	local holder = new("Frame", {
		Size = UDim2.new(1, 0, 0, 28),
		Position = UDim2.fromOffset(0, y),
		BackgroundTransparency = 1,
		Active = true,
	}, parent)
	new("TextLabel", {
		Size = UDim2.new(1, -156, 1, 0),
		BackgroundTransparency = 1,
		Text = text,
		Font = Enum.Font.GothamMedium,
		TextSize = 13,
		TextColor3 = THEME.text,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
	}, holder)
	local obj, pill = makePill(holder, false, onChange)
	pill.Position = UDim2.new(1, -82, 0.5, 0)
	makeKeybind(holder, bindName)

	if onSettings then
		local gear = new("TextButton", {
			Size = UDim2.fromOffset(22, 22),
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, -128, 0.5, 0),
			BackgroundColor3 = THEME.item,
			BorderSizePixel = 0,
			Text = "...",
			Font = Enum.Font.GothamBold,
			TextSize = 12,
			TextColor3 = THEME.text,
		}, holder)
		round(gear, 5)
		gear.MouseButton1Click:Connect(onSettings)
		holder.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton2 then
				onSettings()
			end
		end)
		pill.MouseButton2Click:Connect(onSettings)
	end
	return obj
end


local function makeSwitch(parent, y, text, default, onChange)
	local holder = new("Frame", {
		Size = UDim2.new(1, 0, 0, 26),
		Position = UDim2.fromOffset(0, y),
		BackgroundTransparency = 1,
	}, parent)
	new("TextLabel", {
		Size = UDim2.new(1, -50, 1, 0),
		BackgroundTransparency = 1,
		Text = text,
		Font = Enum.Font.GothamMedium,
		TextSize = 13,
		TextColor3 = THEME.text,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
	}, holder)
	local obj = makePill(holder, default, onChange)
	return obj
end

local function makeBindRow(parent, y, text, bindName)
	local holder = new("Frame", {
		Size = UDim2.new(1, 0, 0, 28),
		Position = UDim2.fromOffset(0, y),
		BackgroundTransparency = 1,
	}, parent)
	new("TextLabel", {
		Size = UDim2.new(1, -84, 1, 0),
		BackgroundTransparency = 1,
		Text = text,
		Font = Enum.Font.GothamMedium,
		TextSize = 13,
		TextColor3 = THEME.text,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
	}, holder)
	makeKeybind(holder, bindName)
	return holder
end

local function makeSlider(parent, y, name, min, max, default, step, formatter, onChange)
	local holder = new("Frame", {
		Size = UDim2.new(1, 0, 0, 34),
		Position = UDim2.fromOffset(0, y),
		BackgroundTransparency = 1,
	}, parent)
	new("TextLabel", {
		Size = UDim2.new(0.6, 0, 0, 16),
		BackgroundTransparency = 1,
		Text = name,
		Font = Enum.Font.GothamMedium,
		TextSize = 13,
		TextColor3 = THEME.text,
		TextXAlignment = Enum.TextXAlignment.Left,
	}, holder)
	local valueLabel = new("TextLabel", {
		Size = UDim2.new(0.4, 0, 0, 16),
		Position = UDim2.fromScale(0.6, 0),
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamBold,
		TextSize = 13,
		TextColor3 = THEME.sub,
		TextXAlignment = Enum.TextXAlignment.Right,
	}, holder)
	local track = new("TextButton", {
		Size = UDim2.new(1, -8, 0, 8),
		Position = UDim2.fromOffset(4, 22),
		BackgroundColor3 = THEME.track,
		BorderSizePixel = 0,
		Text = "",
		AutoButtonColor = false,
	}, holder)
	round(track, 4)
	local fill = new("Frame", {
		Size = UDim2.fromScale(0, 1),
		BackgroundColor3 = THEME.accent,
		BorderSizePixel = 0,
	}, track)
	round(fill, 4)
	local knob = new("Frame", {
		Size = UDim2.fromOffset(14, 14),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0, 0.5),
		BackgroundColor3 = Color3.new(1, 1, 1),
		BorderSizePixel = 0,
	}, track)
	round(knob, 7)

	local function setValue(v)
		v = math.clamp(math.floor(v / step + 0.5) * step, min, max)
		local alpha = (v - min) / (max - min)
		fill.Size = UDim2.fromScale(alpha, 1)
		knob.Position = UDim2.fromScale(alpha, 0.5)
		valueLabel.Text = formatter(v)
		onChange(v)
	end

	local dragging = false
	local function updateFromX(x)
		local width = track.AbsoluteSize.X
		if width <= 0 then
			return
		end
		local alpha = math.clamp((x - track.AbsolutePosition.X) / width, 0, 1)
		setValue(min + alpha * (max - min))
	end

	track.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			updateFromX(input.Position.X)
		end
	end)
	UserInputService.InputChanged:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
			or input.UserInputType == Enum.UserInputType.Touch) then
			updateFromX(input.Position.X)
		end
	end)
	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			dragging = false
		end
	end)

	setValue(default)
end

local function makeHint(parent, y, height, text)
	new("TextLabel", {
		Size = UDim2.new(1, 0, 0, height),
		Position = UDim2.fromOffset(0, y),
		BackgroundTransparency = 1,
		Text = text,
		Font = Enum.Font.Gotham,
		TextSize = 11,
		TextColor3 = THEME.sub,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top,
	}, parent)
end


local panels = {}
local function makePanel(titleText)
	local p = new("Frame", {
		Size = UDim2.new(1, -20, 0, 360),
		Position = UDim2.fromOffset(10, 48),
		BackgroundColor3 = THEME.bg,
		BorderSizePixel = 0,
		Visible = false,
		Active = true,
		ZIndex = 10,
	}, contents)
	new("TextLabel", {
		Size = UDim2.new(1, -70, 0, 28),
		BackgroundTransparency = 1,
		Text = titleText,
		Font = Enum.Font.GothamBold,
		TextSize = 14,
		TextColor3 = THEME.text,
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 10,
	}, p)
	local back = new("TextButton", {
		Size = UDim2.fromOffset(60, 26),
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, 0, 0, 0),
		BackgroundColor3 = THEME.accentDim,
		BorderSizePixel = 0,
		Text = "Back",
		Font = Enum.Font.GothamBold,
		TextSize = 12,
		TextColor3 = THEME.text,
		ZIndex = 10,
	}, p)
	round(back, 5)
	local body = new("Frame", {
		Size = UDim2.new(1, 0, 1, -36),
		Position = UDim2.fromOffset(0, 36),
		BackgroundTransparency = 1,
		ZIndex = 10,
	}, p)
	back.MouseButton1Click:Connect(function()
		p.Visible = false
	end)
	panels[#panels + 1] = p
	return p, body
end

local function openPanel(p)
	for _, q in ipairs(panels) do
		q.Visible = (q == p)
	end
end

local orbitPanel, orbitBody = makePanel("Orbit settings")
local mapPanel, mapBody = makePanel("Map orbit settings")
local viewPanel, viewBody = makePanel("View settings")




local search = new("TextBox", {
	Size = UDim2.new(1, 0, 0, 28),
	BackgroundColor3 = THEME.item,
	BorderSizePixel = 0,
	PlaceholderText = "Filter players...",
	PlaceholderColor3 = THEME.sub,
	Text = "",
	ClearTextOnFocus = false,
	Font = Enum.Font.Gotham,
	TextSize = 13,
	TextColor3 = THEME.text,
}, playersPage)
round(search, 5)

local list = new("ScrollingFrame", {
	Size = UDim2.new(1, 0, 1, -34),
	Position = UDim2.fromOffset(0, 34),
	BackgroundColor3 = Color3.fromRGB(16, 16, 22),
	BorderSizePixel = 0,
	ScrollBarThickness = 4,
	CanvasSize = UDim2.new(0, 0, 0, 0),
	AutomaticCanvasSize = Enum.AutomaticSize.Y,
}, playersPage)
round(list, 6)
new("UIListLayout", { Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.Name }, list)
new("UIPadding", {
	PaddingTop = UDim.new(0, 4),
	PaddingBottom = UDim.new(0, 4),
	PaddingLeft = UDim.new(0, 4),
	PaddingRight = UDim.new(0, 8),
}, list)

local entries = {}

local function applyFilter()
	local q = string.lower(search.Text)
	for _, e in pairs(entries) do
		e.button.Visible = (q == "") or (string.find(e.key, q, 1, true) ~= nil)
	end
end
search:GetPropertyChangedSignal("Text"):Connect(applyFilter)

local function refreshSelection()
	for p, e in pairs(entries) do
		e.button.BackgroundColor3 = (p == State.selected) and THEME.accentDim or THEME.item
	end
	local p = State.selected
	if p then
		targetAvatar.Image = thumb(p.UserId)
		targetAvatar.Visible = true
		targetLabel.Text = p.DisplayName .. "  (@" .. p.Name .. ")"
	else
		targetAvatar.Visible = false
		targetLabel.Text = "No target selected"
	end
end

function setSelected(p)
	State.selected = p
	refreshSelection()
end

local function addEntry(p)
	if p == player or entries[p] then
		return
	end
	local button = new("TextButton", {
		Name = string.lower(p.DisplayName .. p.Name),
		Size = UDim2.new(1, 0, 0, 40),
		BackgroundColor3 = THEME.item,
		BorderSizePixel = 0,
		Text = "",
	}, list)
	round(button, 6)
	local avatar = new("ImageLabel", {
		Size = UDim2.fromOffset(34, 34),
		Position = UDim2.fromOffset(3, 3),
		BackgroundColor3 = THEME.track,
		BorderSizePixel = 0,
		Image = thumb(p.UserId),
	}, button)
	round(avatar, 17)
	new("TextLabel", {
		Size = UDim2.new(1, -50, 0, 18),
		Position = UDim2.fromOffset(44, 3),
		BackgroundTransparency = 1,
		Text = p.DisplayName,
		Font = Enum.Font.GothamBold,
		TextSize = 13,
		TextColor3 = THEME.text,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
	}, button)
	new("TextLabel", {
		Size = UDim2.new(1, -50, 0, 14),
		Position = UDim2.fromOffset(44, 21),
		BackgroundTransparency = 1,
		Text = "@" .. p.Name,
		Font = Enum.Font.Gotham,
		TextSize = 11,
		TextColor3 = THEME.sub,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
	}, button)
	entries[p] = { button = button, key = string.lower(p.DisplayName .. " " .. p.Name) }
	button.MouseButton1Click:Connect(function()
		setSelected(p)
		setStatus("Target: " .. p.Name)
	end)
	applyFilter()
	refreshSelection()
end

local function removeEntry(p)
	local e = entries[p]
	if e then
		e.button:Destroy()
		entries[p] = nil
	end
end

for _, p in ipairs(Players:GetPlayers()) do
	addEntry(p)
end
Players.PlayerAdded:Connect(addEntry)





makeSlider(orbitBody, 4, "Distance", 4, 60, State.distance, 0.5,
	function(v) return string.format("%.1f", v) end,
	function(v) State.distance = v end)
makeSlider(orbitBody, 44, "Height", 0, 30, State.height, 0.5,
	function(v) return string.format("%.1f", v) end,
	function(v) State.height = v end)
makeSwitch(orbitBody, 90, "Spectate target while orbiting", State.spectate, function(v)
	State.spectate = v
end)
makeHint(orbitBody, 126, 120,
	"Speed is fixed at maximum and can't be changed. The motion is fully random (up, down, left, right, hops, tumbles) and the whole pattern re-rolls every 60 seconds. You can't choose the direction.")


makeSlider(mapBody, 4, "Distance from start", 20000, 600000, State.mapDistance, 5000,
	function(v) return string.format("%d", v) end,
	function(v) State.mapDistance = v end)
makeSlider(mapBody, 44, "Height (Y)", -400, 5000, State.mapHeight, 50,
	function(v) return string.format("%d", v) end,
	function(v) State.mapHeight = v end)
makeSwitch(mapBody, 90, "Auto map orbit when damaged", State.autoMap, function(v)
	State.autoMap = v
end)
makeHint(mapBody, 126, 150,
	"Safe mode: throws you around the map at an extreme distance with fixed max speed and random patterns (new pattern every 60 s). Height never goes below the void kill line. Turning it off puts you back where you started. If you die it just stops.")


makeSwitch(viewBody, 4, "ESP: Box", State.esp.box, function(v) State.esp.box = v end)
makeSwitch(viewBody, 36, "ESP: Skeleton", State.esp.skeleton, function(v) State.esp.skeleton = v end)
makeSwitch(viewBody, 68, "ESP: Chams", State.esp.chams, function(v) State.esp.chams = v end)
makeSwitch(viewBody, 100, "ESP: Names / distance / health", State.esp.names, function(v) State.esp.names = v end)
makeHint(viewBody, 140, 100,
	"ESP draws on every other player, through walls. The selected target is red, everyone else is blue. ESP works whether or not View is on.")




orbitRow = makeRow(orbitPage, 0, "Orbit player", "Orbit", function(on)
	if on then
		startOrbit()
	else
		stopOrbit()
	end
end, function()
	openPanel(orbitPanel)
end)

mapRow = makeRow(orbitPage, 34, "Map orbit (safe mode)", "MapOrbit", function(on)
	if on then
		startMap()
	else
		stopMap()
	end
end, function()
	openPanel(mapPanel)
end)

makeBindRow(orbitPage, 68, "Auto target (cursor / nearest)", "AutoTarget")

makeHint(orbitPage, 108, 120,
	"Pick a target in PLAYERS, then turn on Orbit. Map orbit needs no target.\nRight-click a row (or click ...) for its settings. Click a key box, then press a key to bind it; Esc clears it.")




viewRow = makeRow(finderPage, 0, "View player", "View", function(on)
	setView(on)
end, function()
	openPanel(viewPanel)
end)

do
	local holder = new("Frame", {
		Size = UDim2.new(1, 0, 0, 28),
		Position = UDim2.fromOffset(0, 34),
		BackgroundTransparency = 1,
	}, finderPage)
	local tpButton = new("TextButton", {
		Size = UDim2.new(1, -84, 1, 0),
		BackgroundColor3 = THEME.accentDim,
		BorderSizePixel = 0,
		Text = "Teleport to player",
		Font = Enum.Font.GothamBold,
		TextSize = 12,
		TextColor3 = THEME.text,
	}, holder)
	round(tpButton, 5)
	tpButton.MouseButton1Click:Connect(function()
		teleportToTarget()
	end)
	makeKeybind(holder, "Teleport")
end

makeHint(finderPage, 74, 120,
	"View follows the selected player through respawns; turn the toggle (or its hotkey) off to get your own camera back. Teleport cancels any orbit and puts you just behind the player without flinging you.\nRight-click View (or click ...) for ESP settings.")

showTab("PLAYERS")




local rng = Random.new()
local function rnd(a, b)
	return a + rng:NextNumber() * (b - a)
end
local function rsign()
	return rng:NextNumber() < 0.5 and -1 or 1
end
local function fastW() 
	return rsign() * math.rad(rnd(2200, 5200))
end
local function sph(theta, phi)
	local c = math.cos(phi)
	return Vector3.new(c * math.cos(theta), math.sin(phi), c * math.sin(theta))
end

local STYLES = { "Spin", "Vertical", "Blink", "Cross", "Lissajous", "Tumble" }
local CROSS = {
	Vector3.new(1, 0, 0), Vector3.new(-1, 0, 0), 
	Vector3.new(0, 1, 0), Vector3.new(0, -1, 0), 
	Vector3.new(1, 1, 0).Unit, Vector3.new(-1, 1, 0).Unit,
	Vector3.new(1, -1, 0).Unit, Vector3.new(-1, -1, 0).Unit,
	Vector3.new(0, 0, 1), Vector3.new(0, 0, -1), 
}

local pat = {
	style = "Spin",
	changeAt = 0,
	segLeft = 0,
	t = 0,
	theta = 0, phi = 0.2, w = 0,
	a = 0, az = 0,
	dir = Vector3.new(1, 0, 0),
	crossIdx = 0, cross = CROSS[1],
	f1 = 0, f2 = 0, p1 = 0, p2 = 0, amp = 0.6,
	axis = Vector3.new(0, 1, 0), base = Vector3.new(1, 0, 0), ang = 0,
	lastDir = Vector3.new(1, 0, 0),
}

local function rollPattern(now)
	local choices = {}
	for _, s in ipairs(STYLES) do
		if s ~= pat.style then
			choices[#choices + 1] = s
		end
	end
	pat.style = choices[rng:NextInteger(1, #choices)]
	pat.changeAt = now + 60
	pat.segLeft = 0
	pat.t = 0
	pat.theta = rnd(0, TAU)
	pat.a = rnd(0, TAU)
	pat.ang = 0
	pat.crossIdx = 0
end


local function patternDir(dt, fx, fz)
	local s = pat.style
	pat.segLeft = pat.segLeft - dt
	pat.t = pat.t + dt
	local newSeg = pat.segLeft <= 0
	local out

	if s == "Spin" then
		if newSeg then
			pat.segLeft = rnd(0.04, 0.3)
			pat.w = fastW()
			pat.phi = rnd(-0.5, 1.0)
		end
		pat.theta = pat.theta + pat.w * dt
		out = sph(pat.theta, pat.phi)

	elseif s == "Vertical" then
		if newSeg then
			pat.segLeft = rnd(0.04, 0.3)
			pat.w = fastW()
			pat.az = rnd(0, TAU)
		end
		pat.a = pat.a + pat.w * dt
		local c = math.cos(pat.a)
		out = Vector3.new(c * math.cos(pat.az), math.sin(pat.a), c * math.sin(pat.az))

	elseif s == "Blink" then
		if newSeg then
			pat.segLeft = rnd(0.03, 0.12)
			pat.dir = sph(rnd(0, TAU), rnd(-0.6, 1.1))
		end
		out = pat.dir

	elseif s == "Cross" then
		if newSeg then
			pat.segLeft = rnd(0.04, 0.14)
			local i = pat.crossIdx
			while i == pat.crossIdx do
				i = rng:NextInteger(1, #CROSS)
			end
			pat.crossIdx = i
			pat.cross = CROSS[i]
		end
		local d = pat.cross
		local rx, rz = -fz, fx 
		out = Vector3.new(rx * d.X + fx * d.Z, d.Y, rz * d.X + fz * d.Z)

	elseif s == "Lissajous" then
		if newSeg then
			pat.segLeft = rnd(0.5, 2)
			pat.f1 = fastW()
			pat.f2 = rsign() * rnd(30, 90)
			pat.p1 = rnd(0, TAU)
			pat.p2 = rnd(0, TAU)
			pat.amp = rnd(0.5, 1.1)
			pat.t = 0
		end
		out = sph(pat.p1 + pat.f1 * pat.t, pat.amp * math.sin(pat.p2 + pat.f2 * pat.t))

	else 
		if newSeg then
			pat.segLeft = rnd(0.08, 0.5)
			local axis = Vector3.new(rnd(-1, 1), rnd(-1, 1), rnd(-1, 1))
			if axis.Magnitude < 0.1 then
				axis = Vector3.new(0, 1, 0)
			end
			pat.axis = axis.Unit
			pat.base = pat.lastDir
			pat.ang = 0
			pat.w = fastW()
		end
		pat.ang = pat.ang + pat.w * dt
		out = CFrame.fromAxisAngle(pat.axis, pat.ang) * pat.base
	end

	pat.lastDir = out
	return out
end

local function voidFloor(margin)
	local k = workspace.FallenPartsDestroyHeight
	if k > -1e6 then
		return k + margin
	end
	return -400
end




local orbit = {
	state = "idle", 
	kind = "player", 
	center = Vector3.zero,
	start = nil, 
	camSaved = nil,
	releaseStart = 0,
	last = 0,
}

local noclip = { char = nil, original = {} }

local function applyNoclip(char)
	if noclip.char ~= char then
		noclip.char = char
		noclip.original = {}
	end
	for _, d in ipairs(char:GetDescendants()) do
		if d:IsA("BasePart") then
			if noclip.original[d] == nil then
				noclip.original[d] = d.CanCollide
			end
			d.CanCollide = false
		end
	end
end

local function restoreNoclip()
	for part, was in pairs(noclip.original) do
		if part.Parent then
			part.CanCollide = was
		end
	end
	noclip.original = {}
end

local function groundPos(hrp, hum)
	local filter = {}
	for _, p in ipairs(Players:GetPlayers()) do
		if p.Character then
			filter[#filter + 1] = p.Character
		end
	end
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = filter
	local hip = (hum and hum.HipHeight > 0) and hum.HipHeight or 2
	local lift = hip + hrp.Size.Y / 2 + 0.2
	local pos = hrp.Position
	for _, startY in ipairs({ pos.Y + 3, pos.Y + 300 }) do
		local res = workspace:Raycast(Vector3.new(pos.X, startY, pos.Z), Vector3.new(0, -2000, 0), params)
		if res then
			return Vector3.new(pos.X, res.Position.Y + lift, pos.Z)
		end
	end
	return nil
end


local function finishOrbit(mode)
	if orbit.state ~= "active" then
		return
	end
	local char = player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	local hum = char and char:FindFirstChildOfClass("Humanoid")

	if hrp then
		hrp.AssemblyLinearVelocity = Vector3.zero
		hrp.AssemblyAngularVelocity = Vector3.zero
		if orbit.kind == "map" then
			if mode ~= "none" and orbit.start then
				hrp.CFrame = orbit.start
			end
		elseif mode == "ground" then
			local pos = groundPos(hrp, hum) or hrp.Position
			local look = hrp.CFrame.LookVector
			local flat = Vector3.new(look.X, 0, look.Z)
			if flat.Magnitude < 1e-3 then
				flat = Vector3.new(0, 0, -1)
			end
			hrp.CFrame = CFrame.lookAt(pos, pos + flat.Unit)
		end
		hrp.AssemblyLinearVelocity = Vector3.zero
		hrp.AssemblyAngularVelocity = Vector3.zero
	end

	
	orbit.state = "releasing"
	orbit.releaseStart = os.clock()
end

function startOrbit()
	local target = State.selected
	if not target then
		setStatus("Pick a target first")
		orbitRow:Set(false, true)
		return
	end
	local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	if not hrp then
		setStatus("Your character is unavailable")
		orbitRow:Set(false, true)
		return
	end
	if orbit.state == "active" and orbit.kind == "map" then
		finishOrbit("return")
		mapRow:Set(false, true)
	end
	orbit.kind = "player"
	orbit.last = os.clock()
	rollPattern(os.clock())
	orbit.state = "active"
	setStatus("Orbiting " .. target.Name)
end

function stopOrbit()
	if orbit.state == "active" and orbit.kind == "player" then
		finishOrbit("ground")
		setStatus("Orbit stopped (on the spot)")
	end
end

function startMap()
	local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	if not hrp then
		setStatus("Your character is unavailable")
		mapRow:Set(false, true)
		return
	end
	if orbit.state == "active" and orbit.kind == "player" then
		finishOrbit("ground")
		orbitRow:Set(false, true)
	end
	orbit.start = hrp.CFrame
	orbit.center = hrp.Position
	local cam = workspace.CurrentCamera
	orbit.camSaved = cam and cam.CFrame or nil
	orbit.kind = "map"
	orbit.last = os.clock()
	rollPattern(os.clock())
	orbit.state = "active"
	setStatus("Map orbit on")
end

function stopMap()
	if orbit.state == "active" and orbit.kind == "map" then
		finishOrbit("return")
		setStatus("Map orbit off (back at your start)")
	end
end



local function orbitFrame()
	if orbit.state ~= "active" then
		return
	end
	local now = os.clock()
	local dt = math.min(now - orbit.last, 0.1)
	orbit.last = now

	local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	if not hrp then
		return
	end
	if now >= pat.changeAt then
		rollPattern(now)
	end

	if orbit.kind == "player" then
		local target = State.selected
		local troot = target and target.Character and target.Character:FindFirstChild("HumanoidRootPart")
		if not troot then
			return 
		end
		local look = troot.CFrame.LookVector
		local fx, fz = look.X, look.Z
		local fl = math.sqrt(fx * fx + fz * fz)
		if fl < 1e-3 then
			fx, fz = 0, -1
		else
			fx, fz = fx / fl, fz / fl
		end

		local dir = patternDir(dt, fx, fz)
		local d = State.distance
		local vy = dir.Y >= 0 and dir.Y * d or dir.Y * d * 0.35

		
		local lead = troot.AssemblyLinearVelocity * 0.08
		if lead.Magnitude > 15 then
			lead = lead.Unit * 15
		end
		local c = troot.Position + lead
		local y = math.max(c.Y + State.height + vy, voidFloor(20))
		local pos = Vector3.new(c.X + dir.X * d, y, c.Z + dir.Z * d)

		local face = Vector3.new(troot.Position.X, pos.Y, troot.Position.Z)
		if (face - pos).Magnitude > 0.05 then
			hrp.CFrame = CFrame.lookAt(pos, face)
		else
			hrp.CFrame = CFrame.new(pos)
		end
	else
		local dir = patternDir(dt, 0, -1)
		local hx, hz = dir.X, dir.Z
		local hl = math.sqrt(hx * hx + hz * hz)
		if hl < 1e-3 then
			hx, hz, hl = 1, 0, 1
		end
		local D = State.mapDistance
		local vr = math.min(D, 3000)
		local vy = dir.Y >= 0 and dir.Y * vr or dir.Y * vr * 0.35
		local y = math.max(State.mapHeight + vy, voidFloor(100))
		local pos = Vector3.new(orbit.center.X + hx / hl * D, y, orbit.center.Z + hz / hl * D)
		hrp.CFrame = CFrame.lookAt(pos, Vector3.new(orbit.center.X, y, orbit.center.Z))
	end

	hrp.AssemblyLinearVelocity = Vector3.zero
	hrp.AssemblyAngularVelocity = Vector3.zero
end

RunService.Stepped:Connect(function()
	if orbit.state == "idle" then
		return
	end
	local char = player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	if not hrp then
		if orbit.state == "releasing" then
			noclip.char = nil
			noclip.original = {}
			orbit.state = "idle"
		end
		return
	end

	applyNoclip(char)
	hrp.AssemblyLinearVelocity = Vector3.zero
	hrp.AssemblyAngularVelocity = Vector3.zero

	if orbit.state == "releasing" then
		local held = os.clock() - orbit.releaseStart
		local clear = true
		for _, other in ipairs(Players:GetPlayers()) do
			if other ~= player then
				local oroot = other.Character and other.Character:FindFirstChild("HumanoidRootPart")
				if oroot and (oroot.Position - hrp.Position).Magnitude < 4 then
					clear = false
					break
				end
			end
		end
		if (clear and held > 0.3) or held > 15 then
			restoreNoclip()
			hrp.AssemblyLinearVelocity = Vector3.zero
			hrp.AssemblyAngularVelocity = Vector3.zero
			orbit.state = "idle"
		end
	end
end)

RunService.Heartbeat:Connect(orbitFrame)


player.CharacterAdded:Connect(function()
	noclip.char = nil
	noclip.original = {}
	if orbit.state == "releasing" then
		orbit.state = "idle"
	elseif orbit.state == "active" and orbit.kind == "map" then
		orbit.state = "idle"
		mapRow:Set(false, true)
		setStatus("You died - map orbit stopped")
	end
end)




local forcingCamera = false
local camScriptable = false

local function updateCamera()
	local cam = workspace.CurrentCamera
	if not cam then
		return
	end

	local watch
	if State.viewActive then
		watch = State.selected
	elseif orbit.state == "active" and orbit.kind == "player" and State.spectate then
		watch = State.selected
	end
	local mapFrozen = (not watch) and orbit.state == "active" and orbit.kind == "map" and orbit.camSaved ~= nil

	if watch then
		local hum = watch.Character and watch.Character:FindFirstChildOfClass("Humanoid")
		if hum then
			if camScriptable then
				camScriptable = false
				cam.CameraType = Enum.CameraType.Custom
			end
			forcingCamera = true
			if cam.CameraSubject ~= hum then
				cam.CameraSubject = hum
			end
		end
	elseif mapFrozen then
		
		camScriptable = true
		forcingCamera = true
		cam.CameraType = Enum.CameraType.Scriptable
		cam.CFrame = orbit.camSaved
	else
		if camScriptable then
			camScriptable = false
			cam.CameraType = Enum.CameraType.Custom
		end
		if forcingCamera then
			forcingCamera = false
			local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
			if hum then
				cam.CameraSubject = hum
			end
		end
	end
end

RunService.RenderStepped:Connect(function()
	updateCamera()
	orbitFrame()
end)




function setView(on)
	if on then
		if not State.selected then
			setStatus("Pick a player first")
			viewRow:Set(false, true)
			return
		end
		State.viewActive = true
		setStatus("Viewing " .. State.selected.Name)
	else
		State.viewActive = false
		setStatus("Stopped viewing")
	end
end

function teleportToTarget()
	local t = State.selected
	if not t then
		setStatus("Pick a player first")
		return
	end
	local troot = t.Character and t.Character:FindFirstChild("HumanoidRootPart")
	local myRoot = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	if not (troot and myRoot) then
		setStatus("Character unavailable")
		return
	end

	
	if orbit.state == "active" then
		finishOrbit("none")
	end
	orbitRow:Set(false, true)
	mapRow:Set(false, true)

	local look = troot.CFrame.LookVector
	local flat = Vector3.new(look.X, 0, look.Z)
	if flat.Magnitude < 1e-3 then
		flat = Vector3.new(0, 0, -1)
	end
	flat = flat.Unit
	local tp = troot.Position
	local pos = tp - flat * 6 
	myRoot.CFrame = CFrame.lookAt(pos, Vector3.new(tp.X, pos.Y, tp.Z))
	myRoot.AssemblyLinearVelocity = Vector3.zero
	myRoot.AssemblyAngularVelocity = Vector3.zero

	
	orbit.state = "releasing"
	orbit.releaseStart = os.clock()
	setStatus("Teleported to " .. t.Name)
end




local function playerFromInstance(inst)
	while inst and inst ~= workspace do
		local p = Players:GetPlayerFromCharacter(inst)
		if p then
			return p
		end
		inst = inst.Parent
	end
	return nil
end

function autoTarget()
	local cam = workspace.CurrentCamera
	local found

	if cam then
		local loc = UserInputService:GetMouseLocation()
		local ray = cam:ViewportPointToRay(loc.X, loc.Y)
		local params = RaycastParams.new()
		params.FilterType = Enum.RaycastFilterType.Exclude
		params.FilterDescendantsInstances = { player.Character }
		local result = workspace:Raycast(ray.Origin, ray.Direction * 2000, params)
		if result then
			found = playerFromInstance(result.Instance)
		end
	end

	if not found then
		local myRoot = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
		local origin = myRoot and myRoot.Position or (cam and cam.CFrame.Position)
		if origin then
			local best = math.huge
			for _, p in ipairs(Players:GetPlayers()) do
				if p ~= player then
					local r = p.Character and p.Character:FindFirstChild("HumanoidRootPart")
					if r then
						local d = (r.Position - origin).Magnitude
						if d < best then
							best = d
							found = p
						end
					end
				end
			end
		end
	end

	if found then
		setSelected(found)
		local e = entries[found]
		if e then
			list.CanvasPosition = Vector2.new(
				0,
				math.max(0, e.button.AbsolutePosition.Y - list.AbsolutePosition.Y + list.CanvasPosition.Y - 4)
			)
		end
		setStatus("Auto target: " .. found.Name)
	else
		setStatus("No player found")
	end
end




do
	local lastHum, lastHealth = nil, 0
	RunService.Heartbeat:Connect(function()
		local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
		if not hum then
			lastHum = nil
			return
		end
		if hum ~= lastHum then
			lastHum = hum
			lastHealth = hum.Health
			return
		end
		local h = hum.Health
		local dropped = h < lastHealth
		lastHealth = h
		if dropped and h > 0 and State.autoMap and not (orbit.state == "active" and orbit.kind == "map") then
			mapRow:Set(true)
			setStatus("Damaged - map orbit on")
		end
	end)
end




local espFolder
do
	local function containers()
		return {
			function() return game:GetService("CoreGui") end,
			function() return gethui and gethui() end,
			function() return workspace end,
		}
	end
	for _, get in ipairs(containers()) do
		local ok, c = pcall(get)
		if ok and c then
			local old = c:FindFirstChild("PT_ESP")
			if old then
				old:Destroy()
			end
		end
	end
	local f = Instance.new("Folder")
	f.Name = "PT_ESP"
	for _, get in ipairs(containers()) do
		local ok, c = pcall(get)
		if ok and c then
			local ok2 = pcall(function()
				f.Parent = c
			end)
			if ok2 and f.Parent == c then
				break
			end
		end
	end
	if not f.Parent then
		f.Parent = workspace
	end
	espFolder = f
end

local COLOR_TARGET = Color3.fromRGB(255, 70, 70)
local COLOR_OTHER = Color3.fromRGB(90, 200, 255)

local R15_BONES = {
	{ "Head", "UpperTorso" }, { "UpperTorso", "LowerTorso" },
	{ "UpperTorso", "LeftUpperArm" }, { "LeftUpperArm", "LeftLowerArm" }, { "LeftLowerArm", "LeftHand" },
	{ "UpperTorso", "RightUpperArm" }, { "RightUpperArm", "RightLowerArm" }, { "RightLowerArm", "RightHand" },
	{ "LowerTorso", "LeftUpperLeg" }, { "LeftUpperLeg", "LeftLowerLeg" }, { "LeftLowerLeg", "LeftFoot" },
	{ "LowerTorso", "RightUpperLeg" }, { "RightUpperLeg", "RightLowerLeg" }, { "RightLowerLeg", "RightFoot" },
}
local R6_BONES = {
	{ "Head", "Torso" }, { "Torso", "Left Arm" }, { "Torso", "Right Arm" },
	{ "Torso", "Left Leg" }, { "Torso", "Right Leg" },
}

local esp = {} 

local function clearEntry(e)
	for _, inst in ipairs(e.items) do
		inst:Destroy()
	end
	e.items = {}
	e.bones = {}
	e.hl, e.box, e.tag, e.label, e.col = nil, nil, nil, nil, nil
	e.built = false
end

local function buildEntry(e, char)
	local hum = char:FindFirstChildOfClass("Humanoid")
	local head = char:FindFirstChild("Head")
	if not (hum and head and char:FindFirstChild("HumanoidRootPart")) then
		return false
	end
	local r15 = hum.RigType == Enum.HumanoidRigType.R15
	if r15 and not char:FindFirstChild("UpperTorso") then
		return false
	end
	if (not r15) and not char:FindFirstChild("Torso") then
		return false
	end

	local hl = Instance.new("Highlight")
	hl.Adornee = char
	hl.FillTransparency = 0.45
	hl.OutlineTransparency = 0
	hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
	hl.Enabled = false
	hl.Parent = espFolder

	local box = Instance.new("SelectionBox")
	box.Adornee = char
	box.LineThickness = 0.05
	box.SurfaceTransparency = 1
	box.Visible = false
	box.Parent = espFolder

	local tag = Instance.new("BillboardGui")
	tag.Adornee = head
	tag.Size = UDim2.fromOffset(150, 36)
	tag.StudsOffset = Vector3.new(0, 3.2, 0)
	tag.AlwaysOnTop = true
	tag.Enabled = false
	tag.Parent = espFolder
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamBold
	label.TextSize = 13
	label.TextStrokeTransparency = 0.4
	label.Text = ""
	label.Parent = tag

	e.items = { hl, box, tag }
	e.hl, e.box, e.tag, e.label = hl, box, tag, label
	e.bones = {}

	for _, pair in ipairs(r15 and R15_BONES or R6_BONES) do
		local a, b = char:FindFirstChild(pair[1]), char:FindFirstChild(pair[2])
		if a and b then
			local ad = Instance.new("BoxHandleAdornment")
			ad.Adornee = a
			ad.AlwaysOnTop = true
			ad.ZIndex = 2
			ad.Size = Vector3.new(0.12, 0.12, 0.1)
			ad.Visible = false
			ad.Parent = espFolder
			e.bones[#e.bones + 1] = { ad = ad, a = a, b = b }
			e.items[#e.items + 1] = ad
		end
	end
	return true
end

local lastTag = 0
RunService.RenderStepped:Connect(function()
	local cfg = State.esp
	local any = cfg.box or cfg.skeleton or cfg.chams or cfg.names

	if not any then
		for p, e in pairs(esp) do
			clearEntry(e)
			esp[p] = nil
		end
		return
	end

	local now = os.clock()
	local tagTick = (now - lastTag) > 0.1
	if tagTick then
		lastTag = now
	end

	for _, p in ipairs(Players:GetPlayers()) do
		if p ~= player then
			local e = esp[p]
			if not e then
				e = { items = {}, bones = {}, built = false }
				esp[p] = e
			end
			local char = p.Character
			if e.char ~= char then
				clearEntry(e)
				e.char = char
			end
			if char and not e.built then
				e.built = buildEntry(e, char)
			end

			if e.built then
				local col = (p == State.selected) and COLOR_TARGET or COLOR_OTHER
				if e.col ~= col then
					e.col = col
					e.hl.FillColor = col
					e.hl.OutlineColor = col
					e.box.Color3 = col
					e.label.TextColor3 = col
					for _, b in ipairs(e.bones) do
						b.ad.Color3 = col
					end
				end
				e.hl.Enabled = cfg.chams
				e.box.Visible = cfg.box
				e.tag.Enabled = cfg.names

				for _, b in ipairs(e.bones) do
					if cfg.skeleton and b.a.Parent and b.b.Parent then
						local lb = b.a.CFrame:PointToObjectSpace(b.b.Position)
						local len = lb.Magnitude
						if len > 0.01 then
							local up = math.abs(lb.Unit.Y) > 0.99 and Vector3.new(1, 0, 0) or Vector3.new(0, 1, 0)
							b.ad.CFrame = CFrame.lookAt(lb * 0.5, lb, up)
							b.ad.Size = Vector3.new(0.12, 0.12, len)
							b.ad.Visible = true
						else
							b.ad.Visible = false
						end
					else
						b.ad.Visible = false
					end
				end

				if tagTick and cfg.names then
					local hum = char:FindFirstChildOfClass("Humanoid")
					local hrp = char:FindFirstChild("HumanoidRootPart")
					local mine = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
					local dist = (hrp and mine) and (hrp.Position - mine.Position).Magnitude or 0
					local hp = hum and hum.Health or 0
					e.label.Text = string.format("%s\n[%d studs]  %d HP", p.DisplayName, math.floor(dist), math.floor(hp))
				end
			end
		end
	end
end)




UserInputService.InputBegan:Connect(function(input)
	if input.UserInputType ~= Enum.UserInputType.Keyboard then
		return
	end

	if listening then
		local name = listening
		listening = nil
		if input.KeyCode == Enum.KeyCode.Escape then
			binds[name] = nil
		elseif input.KeyCode ~= Enum.KeyCode.Unknown then
			for other, k in pairs(binds) do
				if k == input.KeyCode and other ~= name then
					binds[other] = nil
					refreshBind(other)
				end
			end
			binds[name] = input.KeyCode
		end
		refreshBind(name)
		return
	end

	if UserInputService:GetFocusedTextBox() then
		return
	end

	local key = input.KeyCode
	if key == Enum.KeyCode.Unknown then
		return
	end
	if key == binds.Orbit then
		orbitRow:Set(not orbitRow.Value)
	elseif key == binds.MapOrbit then
		mapRow:Set(not mapRow.Value)
	elseif key == binds.AutoTarget then
		autoTarget()
	elseif key == binds.View then
		viewRow:Set(not viewRow.Value)
	elseif key == binds.Teleport then
		teleportToTarget()
	end
end)




Players.PlayerRemoving:Connect(function(p)
	removeEntry(p)
	local e = esp[p]
	if e then
		clearEntry(e)
		esp[p] = nil
	end
	if State.selected == p then
		setSelected(nil)
		if orbitRow.Value then
			orbitRow:Set(false) 
		end
		viewRow:Set(false)
		setStatus(p.Name .. " left the server")
	end
end)
