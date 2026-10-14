
--[[
    CeeHub v1.0
    Made by CeeWorks

    Roblox Studio LocalScript
    Place in StarterPlayer > StarterPlayerScripts

    RightShift = Show / Hide CeeHub

    Features:
    - Player ESP
    - Player Names
    - Team Check
    - Automatic Lock On
    - Mouse Override
    - First/Third Person Camera Tracking
    - FOV Circle
    - Head/Torso Selection
    - CeeWorks Studio Discord Community
]]

local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- REMOVE PREVIOUS INSTANCE

if type(_G.CeeHubCleanup) == "function" then
	pcall(_G.CeeHubCleanup)
end

local previous = playerGui:FindFirstChild("CeeHub")
if previous then
	previous:Destroy()
end

-- THEME

local C = {
	BG = Color3.fromRGB(12, 12, 27),
	SIDE = Color3.fromRGB(17, 17, 37),
	CARD = Color3.fromRGB(27, 25, 52),
	HOVER = Color3.fromRGB(42, 35, 80),
	PURPLE = Color3.fromRGB(151, 96, 255),
	DEEP = Color3.fromRGB(88, 49, 175),
	LIGHT = Color3.fromRGB(212, 188, 255),
	WHITE = Color3.fromRGB(248, 246, 255),
	MUTED = Color3.fromRGB(158, 153, 187),
	BORDER = Color3.fromRGB(65, 53, 102)
}

-- SETTINGS

local state = {
	esp = false,
	names = false,
	teamCheck = true,
	aim = false,
	fov = true,
	radius = 140,
	targetPart = "Head",
	animations = true
}

-- MOUSE OVERRIDE SETTINGS

local mouseOverrideThreshold = 48
local mouseOverrideCooldown = 0.65

local running = true
local connections = {}
local playerConnections = {}
local playerVisuals = {}
local pages = {}
local navButtons = {}
local refreshers = {}

local currentPage = "Home"
local currentTarget = nil
local ignoredTarget = nil
local overrideUntil = 0
local mouseMovement = 0
local previousMouseMovement = 0

-- HELPERS

local function create(className, properties, parent)
	local object = Instance.new(className)

	for property, value in pairs(properties or {}) do
		object[property] = value
	end

	object.Parent = parent
	return object
end

local function connect(signal, callback)
	local connection = signal:Connect(callback)
	table.insert(connections, connection)
	return connection
end

local function corner(parent, radius)
	return create("UICorner", {
		CornerRadius = UDim.new(0, radius or 10)
	}, parent)
end

local function border(parent, color, transparency)
	return create("UIStroke", {
		Color = color or C.BORDER,
		Transparency = transparency or 0,
		Thickness = 1
	}, parent)
end

local function tween(object, properties, duration)
	local animation = TweenService:Create(
		object,
		TweenInfo.new(
			state.animations and (duration or 0.25) or 0.01,
			Enum.EasingStyle.Quint,
			Enum.EasingDirection.Out
		),
		properties
	)

	animation:Play()
	return animation
end

local function text(parent, value, size, color, bold)
	return create("TextLabel", {
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Text = value,
		TextSize = size or 14,
		TextColor3 = color or C.WHITE,
		Font = bold and Enum.Font.GothamBold
			or Enum.Font.Gotham,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Center
	}, parent)
end

-- GUI

local gui = create("ScreenGui", {
	Name = "CeeHub",
	ResetOnSpawn = false,
	IgnoreGuiInset = true,
	DisplayOrder = 100,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling
}, playerGui)

local main = create("Frame", {
	Name = "Main",
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.5),
	Size = UDim2.fromOffset(790, 500),
	BackgroundColor3 = C.BG,
	BorderSizePixel = 0,
	ClipsDescendants = true
}, gui)

corner(main, 16)
border(main, C.PURPLE, 0.35)

local uiScale = create("UIScale", {
	Scale = 1
}, main)

local lastViewport = Vector2.zero

local function updateScale()
	local camera = workspace.CurrentCamera
	if not camera then return end

	local viewport = camera.ViewportSize

	if viewport.X < 100 or viewport.Y < 100 then
		return
	end

	if viewport == lastViewport then
		return
	end

	lastViewport = viewport

	uiScale.Scale = math.clamp(
		math.min(
			(viewport.X - 30) / 790,
			(viewport.Y - 30) / 500
		),
		0.35,
		1
	)
end

updateScale()

-- SIDEBAR

local sidebar = create("Frame", {
	Size = UDim2.new(0, 190, 1, 0),
	BackgroundColor3 = C.SIDE,
	BorderSizePixel = 0
}, main)

local logo = text(
	sidebar, "◆  CeeHub", 23, C.WHITE, true
)
logo.Position = UDim2.fromOffset(19, 22)
logo.Size = UDim2.fromOffset(165, 38)

local version = text(
	sidebar, "VERSION 1.0", 10, C.LIGHT, true
)
version.Position = UDim2.fromOffset(24, 61)
version.Size = UDim2.fromOffset(155, 20)

local nav = create("Frame", {
	Position = UDim2.fromOffset(12, 110),
	Size = UDim2.new(1, -24, 0, 270),
	BackgroundTransparency = 1
}, sidebar)

create("UIListLayout", {
	Padding = UDim.new(0, 9),
	SortOrder = Enum.SortOrder.LayoutOrder
}, nav)

-- DISCORD INVITATION

local discordCard = create("Frame", {
	Name = "DiscordInvite",
	Position = UDim2.new(0, 12, 1, -112),
	Size = UDim2.new(1, -24, 0, 68),
	BackgroundColor3 = C.CARD,
	BorderSizePixel = 0
}, sidebar)

corner(discordCard, 10)
border(discordCard, C.PURPLE, 0)

local discordTitle = text(
	discordCard,
	"JOIN OUR DISCORD!",
	12,
	C.WHITE,
	true
)

discordTitle.Position = UDim2.fromOffset(8, 6)
discordTitle.Size = UDim2.new(1, -16, 0, 18)
discordTitle.TextXAlignment = Enum.TextXAlignment.Center

local discordName = text(
	discordCard,
	"CeeWorks Studio",
	11,
	C.LIGHT,
	true
)

discordName.Position = UDim2.fromOffset(8, 24)
discordName.Size = UDim2.new(1, -16, 0, 18)
discordName.TextXAlignment = Enum.TextXAlignment.Center

local discordCode = text(
	discordCard,
	"W5hU4DEJKZ",
	14,
	C.WHITE,
	true
)

discordCode.Position = UDim2.fromOffset(8, 43)
discordCode.Size = UDim2.new(1, -16, 0, 20)
discordCode.TextXAlignment = Enum.TextXAlignment.Center

local footer = text(
	sidebar, "Made by CeeWorks", 11, C.MUTED
)
footer.Position = UDim2.new(0, 19, 1, -37)
footer.Size = UDim2.fromOffset(160, 23)

-- CONTENT

local content = create("Frame", {
	Position = UDim2.fromOffset(190, 0),
	Size = UDim2.new(1, -190, 1, 0),
	BackgroundTransparency = 1
}, main)

local header = create("Frame", {
	Size = UDim2.new(1, 0, 0, 70),
	BackgroundTransparency = 1
}, content)

local heading = text(
	header, "Dashboard", 23, C.WHITE, true
)
heading.Position = UDim2.fromOffset(23, 18)
heading.Size = UDim2.fromOffset(340, 35)

local function headerButton(symbol, offset)
	local button = create("TextButton", {
		Position = UDim2.new(1, offset, 0, 19),
		Size = UDim2.fromOffset(32, 32),
		BackgroundColor3 = C.CARD,
		Text = symbol,
		TextColor3 = C.WHITE,
		TextSize = 18,
		Font = Enum.Font.GothamBold,
		AutoButtonColor = false
	}, header)

	corner(button, 8)

	connect(button.MouseEnter, function()
		tween(button, {BackgroundColor3 = C.DEEP})
	end)

	connect(button.MouseLeave, function()
		tween(button, {BackgroundColor3 = C.CARD})
	end)

	return button
end

local minimizeButton = headerButton("−", -82)
local closeButton = headerButton("×", -43)

local holder = create("Frame", {
	Position = UDim2.fromOffset(23, 76),
	Size = UDim2.new(1, -46, 1, -98),
	BackgroundTransparency = 1,
	ClipsDescendants = true
}, content)

-- NOTIFICATIONS

local function notify(message)
	if not running then return end

	local notification = create("Frame", {
		AnchorPoint = Vector2.new(1, 1),
		Position = UDim2.new(1, -18, 1, 65),
		Size = UDim2.fromOffset(300, 49),
		BackgroundColor3 = C.CARD,
		BorderSizePixel = 0,
		ZIndex = 30
	}, gui)

	corner(notification, 10)
	border(notification, C.PURPLE, 0.2)

	local messageText = text(
		notification,
		"◆  " .. message,
		12,
		C.WHITE,
		true
	)

	messageText.Position = UDim2.fromOffset(14, 6)
	messageText.Size = UDim2.new(1, -28, 1, -12)
	messageText.ZIndex = 31

	tween(notification, {
		Position = UDim2.new(1, -18, 1, -18)
	}, 0.35)

	task.delay(2.2, function()
		if not notification.Parent then return end

		local animation = tween(notification, {
			Position = UDim2.new(1, -18, 1, 65)
		}, 0.3)

		animation.Completed:Wait()

		if notification.Parent then
			notification:Destroy()
		end
	end)
end

-- PAGES

local function addPage(name)
	local page = create("ScrollingFrame", {
		Name = name,
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		CanvasSize = UDim2.fromOffset(0, 0),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollBarThickness = 3,
		ScrollBarImageColor3 = C.PURPLE,
		Visible = false
	}, holder)

	create("UIListLayout", {
		Padding = UDim.new(0, 12),
		SortOrder = Enum.SortOrder.LayoutOrder
	}, page)

	create("UIPadding", {
		PaddingRight = UDim.new(0, 8),
		PaddingBottom = UDim.new(0, 12)
	}, page)

	pages[name] = page
	return page
end

local function switchPage(name)
	currentPage = name

	for pageName, page in pairs(pages) do
		page.Visible = pageName == name

		if page.Visible then
			page.Position = UDim2.fromOffset(12, 0)

			tween(page, {
				Position = UDim2.fromOffset(0, 0)
			}, 0.3)
		end
	end

	for pageName, button in pairs(navButtons) do
		local selected = pageName == name

		tween(button, {
			BackgroundColor3 =
				selected and C.DEEP or C.SIDE,
			TextColor3 =
				selected and C.WHITE or C.MUTED
		}, 0.25)
	end

	heading.Text = name == "Home"
		and "Dashboard"
		or name
end

local tabs = {
	{"Home", "⌂"},
	{"Visuals", "◈"},
	{"Targeting", "◎"},
	{"Players", "◉"},
	{"Settings", "⚙"}
}

for index, tab in ipairs(tabs) do
	local name = tab[1]
	local symbol = tab[2]

	addPage(name)

	local button = create("TextButton", {
		Name = name,
		LayoutOrder = index,
		Size = UDim2.new(1, 0, 0, 44),
		BackgroundColor3 = C.SIDE,
		Text = "  " .. symbol .. "     " .. name,
		TextColor3 = C.MUTED,
		TextSize = 14,
		Font = Enum.Font.GothamMedium,
		TextXAlignment = Enum.TextXAlignment.Left,
		AutoButtonColor = false
	}, nav)

	corner(button, 9)
	navButtons[name] = button

	connect(button.MouseEnter, function()
		if currentPage ~= name then
			tween(button, {BackgroundColor3 = C.HOVER})
		end
	end)

	connect(button.MouseLeave, function()
		if currentPage ~= name then
			tween(button, {BackgroundColor3 = C.SIDE})
		end
	end)

	connect(button.MouseButton1Click, function()
		switchPage(name)
	end)
end

local function section(page, name)
	local sectionLabel = text(
		page, name, 16, C.WHITE, true
	)
	sectionLabel.Size = UDim2.new(1, 0, 0, 30)
end

local function refreshKey(key)
	for _, refresh in ipairs(refreshers[key] or {}) do
		refresh()
	end
end

-- TOGGLES

local function toggle(page, name, description, key, callback)
	local card = create("Frame", {
		Size = UDim2.new(1, 0, 0, 76),
		BackgroundColor3 = C.CARD,
		BorderSizePixel = 0
	}, page)

	corner(card, 12)
	local outline = border(card)

	local titleLabel = text(
		card, name, 15, C.WHITE, true
	)
	titleLabel.Position = UDim2.fromOffset(18, 12)
	titleLabel.Size = UDim2.new(1, -110, 0, 25)

	local descriptionLabel = text(
		card, description, 11, C.MUTED
	)
	descriptionLabel.Position = UDim2.fromOffset(18, 41)
	descriptionLabel.Size = UDim2.new(1, -110, 0, 19)

	local button = create("TextButton", {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -18, 0.5, 0),
		Size = UDim2.fromOffset(54, 29),
		BackgroundColor3 = C.BORDER,
		Text = "",
		AutoButtonColor = false
	}, card)

	corner(button, 20)

	local knob = create("Frame", {
		Position = UDim2.fromOffset(4, 4),
		Size = UDim2.fromOffset(21, 21),
		BackgroundColor3 = C.WHITE,
		BorderSizePixel = 0
	}, button)

	corner(knob, 20)

	local function refresh()
		local enabled = state[key]

		tween(button, {
			BackgroundColor3 =
				enabled and C.PURPLE or C.BORDER
		})

		tween(knob, {
			Position = enabled
				and UDim2.fromOffset(29, 4)
				or UDim2.fromOffset(4, 4)
		})
	end

	refreshers[key] = refreshers[key] or {}
	table.insert(refreshers[key], refresh)

	connect(card.MouseEnter, function()
		tween(card, {BackgroundColor3 = C.HOVER})
		tween(outline, {Color = C.PURPLE})
	end)

	connect(card.MouseLeave, function()
		tween(card, {BackgroundColor3 = C.CARD})
		tween(outline, {Color = C.BORDER})
	end)

	connect(button.MouseButton1Click, function()
		state[key] = not state[key]

		if callback then
			callback(state[key])
		end

		refreshKey(key)

		notify(
			name .. (
				state[key] and " enabled" or " disabled"
			)
		)
	end)

	refresh()
end

-- SLIDERS

local function slider(page, name, minimum, maximum, initial, callback)
	local card = create("Frame", {
		Size = UDim2.new(1, 0, 0, 100),
		BackgroundColor3 = C.CARD,
		BorderSizePixel = 0
	}, page)

	corner(card, 12)
	border(card)

	local nameLabel = text(
		card, name, 15, C.WHITE, true
	)
	nameLabel.Position = UDim2.fromOffset(18, 12)
	nameLabel.Size = UDim2.fromOffset(300, 26)

	local valueLabel = text(
		card, tostring(initial), 15, C.LIGHT, true
	)
	valueLabel.Position = UDim2.new(1, -80, 0, 12)
	valueLabel.Size = UDim2.fromOffset(62, 26)
	valueLabel.TextXAlignment = Enum.TextXAlignment.Right

	local track = create("Frame", {
		Position = UDim2.fromOffset(19, 67),
		Size = UDim2.new(1, -38, 0, 7),
		BackgroundColor3 = C.BORDER,
		BorderSizePixel = 0
	}, card)

	corner(track, 10)

	local initialAlpha =
		(initial - minimum) / (maximum - minimum)

	local fill = create("Frame", {
		Size = UDim2.fromScale(initialAlpha, 1),
		BackgroundColor3 = C.PURPLE,
		BorderSizePixel = 0
	}, track)

	corner(fill, 10)

	local dot = create("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(initialAlpha, 0.5),
		Size = UDim2.fromOffset(18, 18),
		BackgroundColor3 = C.WHITE,
		BorderSizePixel = 0
	}, track)

	corner(dot, 20)

	local hitbox = create("TextButton", {
		Position = UDim2.fromOffset(0, -15),
		Size = UDim2.new(1, 0, 0, 38),
		BackgroundTransparency = 1,
		Text = "",
		ZIndex = 5
	}, track)

	local dragging = false

	local function update(x)
		if track.AbsoluteSize.X <= 0 then return end

		local alpha = math.clamp(
			(x - track.AbsolutePosition.X)
				/ track.AbsoluteSize.X,
			0,
			1
		)

		local value = math.floor(
			minimum + (maximum - minimum) * alpha
		)

		fill.Size = UDim2.fromScale(alpha, 1)
		dot.Position = UDim2.fromScale(alpha, 0.5)
		valueLabel.Text = tostring(value)

		if callback then
			callback(value)
		end
	end

	connect(hitbox.InputBegan, function(input)
		if input.UserInputType ==
			Enum.UserInputType.MouseButton1
			or input.UserInputType ==
			Enum.UserInputType.Touch then

			dragging = true
			update(input.Position.X)
		end
	end)

	connect(UIS.InputChanged, function(input)
		if dragging and (
			input.UserInputType ==
				Enum.UserInputType.MouseMovement
				or input.UserInputType ==
				Enum.UserInputType.Touch
			) then
			update(input.Position.X)
		end
	end)

	connect(UIS.InputEnded, function(input)
		if input.UserInputType ==
			Enum.UserInputType.MouseButton1
			or input.UserInputType ==
			Enum.UserInputType.Touch then

			dragging = false
		end
	end)
end

-- ESP AND NAMES

local function clearVisual(target)
	local objects = playerVisuals[target]

	if objects then
		for _, object in pairs(objects) do
			if object then
				object:Destroy()
			end
		end
	end

	playerVisuals[target] = nil
end

local function eligible(target)
	if target == player then
		return false
	end

	if state.teamCheck
		and not player.Neutral
		and not target.Neutral
		and player.Team == target.Team then

		return false
	end

	return true
end

local function updateVisual(target)
	clearVisual(target)

	if not eligible(target) then return end

	local character = target.Character
	if not character then return end

	local humanoid =
		character:FindFirstChildOfClass("Humanoid")

	if not humanoid or humanoid.Health <= 0 then
		return
	end

	playerVisuals[target] = {}

	if state.esp then
		local highlight = create("Highlight", {
			Name = "CeeHubESP",
			Adornee = character,
			DepthMode = Enum.HighlightDepthMode.AlwaysOnTop,
			FillColor = C.PURPLE,
			OutlineColor = C.LIGHT,
			FillTransparency = 0.76,
			OutlineTransparency = 0
		}, gui)

		playerVisuals[target].highlight = highlight
	end

	if state.names then
		local head = character:FindFirstChild("Head")

		if head then
			local tag = create("BillboardGui", {
				Name = "CeeHubName",
				Adornee = head,
				Size = UDim2.fromOffset(160, 34),
				StudsOffset = Vector3.new(0, 2.8, 0),
				AlwaysOnTop = true,
				MaxDistance = 1000
			}, gui)

			local nameLabel = text(
				tag,
				target.DisplayName,
				14,
				C.LIGHT,
				true
			)

			nameLabel.Size = UDim2.fromScale(1, 1)
			nameLabel.TextXAlignment =
				Enum.TextXAlignment.Center

			playerVisuals[target].tag = tag
		end
	end
end

local function refreshVisuals()
	for _, target in ipairs(Players:GetPlayers()) do
		updateVisual(target)
	end
end

local function watchPlayer(target)
	if target == player then return end
	if playerConnections[target] then return end

	playerConnections[target] = {}

	local added = target.CharacterAdded:Connect(function()
		task.wait(0.3)

		if running then
			updateVisual(target)
		end
	end)

	local removing = target.CharacterRemoving:Connect(function()
		clearVisual(target)
	end)

	table.insert(playerConnections[target], added)
	table.insert(playerConnections[target], removing)

	if target.Character then
		updateVisual(target)
	end
end

for _, target in ipairs(Players:GetPlayers()) do
	watchPlayer(target)
end

connect(Players.PlayerAdded, watchPlayer)

connect(Players.PlayerRemoving, function(target)
	clearVisual(target)

	for _, connection in ipairs(
		playerConnections[target] or {}
		) do
		connection:Disconnect()
	end

	playerConnections[target] = nil

	if currentTarget and currentTarget.Parent ==
		target.Character then
		currentTarget = nil
	end

	if ignoredTarget == target then
		ignoredTarget = nil
	end
end)

connect(
	player:GetPropertyChangedSignal("Team"),
	refreshVisuals
)

-- FOV CIRCLE

local fov = create("Frame", {
	Name = "FOVCircle",
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.5),
	Size = UDim2.fromOffset(
		state.radius * 2,
		state.radius * 2
	),
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	Visible = false
}, gui)

create("UICorner", {
	CornerRadius = UDim.new(1, 0)
}, fov)

create("UIStroke", {
	Color = C.PURPLE,
	Thickness = 2,
	Transparency = 0.1
}, fov)

local function updateFov()
	fov.Visible = state.fov

	tween(fov, {
		Size = UDim2.fromOffset(
			state.radius * 2,
			state.radius * 2
		)
	}, 0.2)
end

-- LOCK ON TARGETING

local function getAimPart(character)
	if state.targetPart == "Head" then
		return character:FindFirstChild("Head")
	end

	return character:FindFirstChild("UpperTorso")
		or character:FindFirstChild("Torso")
		or character:FindFirstChild("HumanoidRootPart")
end

local function targetInsideFov(part)
	local camera = workspace.CurrentCamera

	if not camera or not part then
		return false, math.huge
	end

	local point, onScreen =
		camera:WorldToViewportPoint(part.Position)

	if not onScreen or point.Z <= 0 then
		return false, math.huge
	end

	local center = camera.ViewportSize / 2

	local distance = (
		Vector2.new(point.X, point.Y) - center
	).Magnitude

	return distance <= state.radius, distance
end

local function validTargetPart(part)
	if not part or not part.Parent then
		return false
	end

	local character = part.Parent

	local targetPlayer =
		Players:GetPlayerFromCharacter(character)

	if not targetPlayer or not eligible(targetPlayer) then
		return false
	end

	local humanoid =
		character:FindFirstChildOfClass("Humanoid")

	return humanoid ~= nil and humanoid.Health > 0
end

local function findNearestTarget()
	local nearest = nil
	local nearestDistance = state.radius

	for _, target in ipairs(Players:GetPlayers()) do
		if eligible(target)
			and target ~= ignoredTarget
			and target.Character then

			local humanoid =
				target.Character:FindFirstChildOfClass("Humanoid")

			local part = getAimPart(target.Character)

			if humanoid and humanoid.Health > 0 and part then
				local inside, distance = targetInsideFov(part)

				if inside and distance <= nearestDistance then
					nearest = part
					nearestDistance = distance
				end
			end
		end
	end

	return nearest
end

-- FIRST PERSON DETECTION

local function isFirstPerson()
	local camera = workspace.CurrentCamera
	local character = player.Character

	if not camera or not character then
		return false
	end

	local head = character:FindFirstChild("Head")
	if not head then return false end

	local distance = (
		camera.CFrame.Position - head.Position
	).Magnitude

	return distance < 1.5
end

-- MOUSE OVERRIDE
-- A strong mouse movement breaks the current lock.
-- The old target is temporarily ignored until you
-- move it outside the FOV circle.

connect(UIS.InputChanged, function(input, processed)
	if not running or not state.aim then return end

	if input.UserInputType ==
		Enum.UserInputType.MouseMovement then

		-- Avoid counting movement while interacting with the GUI.
		if processed and UIS:GetFocusedTextBox() then
			return
		end

		mouseMovement = mouseMovement + input.Delta.Magnitude
	end
end)

local function breakLock()
	if not currentTarget then return end

	local character = currentTarget.Parent

	ignoredTarget =
		Players:GetPlayerFromCharacter(character)

	currentTarget = nil
	overrideUntil = os.clock() + mouseOverrideCooldown
end

-- CAMERA CONTROLLER

local aimRenderName = "CeeHubAimAssist"

RunService:BindToRenderStep(
	aimRenderName,
	Enum.RenderPriority.Camera.Value + 2,
	function()
		if not running then return end

		updateScale()

		local movement = mouseMovement
		mouseMovement = 0

		if not state.aim then
			currentTarget = nil
			ignoredTarget = nil
			previousMouseMovement = 0
			return
		end

		local camera = workspace.CurrentCamera
		if not camera then return end

		-- Allow a player to be selected again after
		-- they leave the targeting circle.
		if ignoredTarget then
			local character = ignoredTarget.Character
			local part = character and getAimPart(character)

			if not part or not validTargetPart(part) then
				ignoredTarget = nil
			else
				local inside = targetInsideFov(part)

				if not inside then
					ignoredTarget = nil
				end
			end
		end

		-- Detect intentional fast camera movement.
		if currentTarget then
			local combinedMovement =
				movement + previousMouseMovement * 0.5

			if combinedMovement >= mouseOverrideThreshold then
				breakLock()
				previousMouseMovement = 0
				return
			end
		end

		previousMouseMovement = movement

		-- Cooldown prevents instant re-locking.
		if os.clock() < overrideUntil then
			return
		end

		-- Acquire another player when available.
		if not validTargetPart(currentTarget) then
			currentTarget = findNearestTarget()
		end

		if not currentTarget then
			return
		end

		local origin = camera.CFrame.Position
		local targetPosition = currentTarget.Position
		local direction = targetPosition - origin

		if direction.Magnitude < 0.01 then
			return
		end

		-- Instant camera tracking.
		local lockedCamera =
			CFrame.lookAt(origin, targetPosition)

		camera.CFrame = lockedCamera

		-- Align character facing in first person.
		if isFirstPerson() then
			local character = player.Character

			if character then
				local root =
					character:FindFirstChild("HumanoidRootPart")

				local humanoid =
					character:FindFirstChildOfClass("Humanoid")

				if root and humanoid and humanoid.Health > 0 then
					local look = lockedCamera.LookVector
					local flatLook =
						Vector3.new(look.X, 0, look.Z)

					if flatLook.Magnitude > 0.001 then
						local rootPosition = root.Position

						root.CFrame = CFrame.lookAt(
							rootPosition,
							rootPosition + flatLook.Unit
						)
					end
				end
			end
		end
	end
)

-- HOME DASHBOARD

local home = pages.Home

local banner = create("Frame", {
	Size = UDim2.new(1, 0, 0, 136),
	BackgroundColor3 = C.DEEP,
	BorderSizePixel = 0,
	ClipsDescendants = true
}, home)

corner(banner, 14)

local gradient = create("UIGradient", {
	Color = ColorSequence.new({
		ColorSequenceKeypoint.new(
			0, Color3.fromRGB(48, 25, 112)
		),
		ColorSequenceKeypoint.new(
			0.5, Color3.fromRGB(112, 57, 210)
		),
		ColorSequenceKeypoint.new(
			1, Color3.fromRGB(26, 18, 70)
		)
	}),
	Rotation = 20
}, banner)

local gradientAnimation = TweenService:Create(
	gradient,
	TweenInfo.new(
		5,
		Enum.EasingStyle.Sine,
		Enum.EasingDirection.InOut,
		-1,
		true
	),
	{Rotation = -20}
)

gradientAnimation:Play()

local welcome = text(
	banner,
	"Welcome to CeeHub",
	24,
	C.WHITE,
	true
)
welcome.Position = UDim2.fromOffset(22, 22)
welcome.Size = UDim2.new(1, -44, 0, 38)

local subtitle = text(
	banner,
	"Visuals & Targeting Dashboard",
	12,
	C.LIGHT
)
subtitle.Position = UDim2.fromOffset(23, 64)
subtitle.Size = UDim2.new(1, -45, 0, 24)

local credit = text(
	banner,
	"MADE BY CeeWorks  •  v1.0",
	10,
	C.WHITE,
	true
)
credit.Position = UDim2.fromOffset(23, 104)
credit.Size = UDim2.new(1, -45, 0, 20)

section(home, "Quick Features")

toggle(
	home,
	"Player ESP",
	"Highlight other players through walls",
	"esp",
	refreshVisuals
)

toggle(
	home,
	"Lock On",
	"Automatic tracking with mouse override",
	"aim",
	function(enabled)
		if not enabled then
			currentTarget = nil
			ignoredTarget = nil
		end
	end
)

toggle(
	home,
	"FOV Circle",
	"Show the adjustable targeting radius",
	"fov",
	updateFov
)

-- VISUALS

local visualsPage = pages.Visuals

section(visualsPage, "Player Visuals")

toggle(
	visualsPage,
	"Player ESP",
	"Purple outlines visible through walls",
	"esp",
	refreshVisuals
)

toggle(
	visualsPage,
	"Player Names",
	"Display player names above characters",
	"names",
	refreshVisuals
)

toggle(
	visualsPage,
	"Team Check",
	"Ignore players on your team",
	"teamCheck",
	function()
		refreshVisuals()
		currentTarget = nil
	end
)

-- TARGETING

local targeting = pages.Targeting

section(targeting, "Lock On")

toggle(
	targeting,
	"Lock On",
	"Automatic lock with fast mouse release",
	"aim",
	function(enabled)
		if not enabled then
			currentTarget = nil
			ignoredTarget = nil
		end
	end
)

toggle(
	targeting,
	"Show FOV Circle",
	"Display targeting range on screen",
	"fov",
	updateFov
)

slider(
	targeting,
	"FOV Radius",
	40,
	350,
	140,
	function(value)
		state.radius = value
		updateFov()
	end
)

slider(
	targeting,
	"Mouse Override Strength",
	15,
	120,
	48,
	function(value)
		mouseOverrideThreshold = value
	end
)

-- TARGET PART SELECTION

local targetCard = create("Frame", {
	Size = UDim2.new(1, 0, 0, 95),
	BackgroundColor3 = C.CARD,
	BorderSizePixel = 0
}, targeting)

corner(targetCard, 12)
border(targetCard)

local targetLabel = text(
	targetCard,
	"Target Part",
	15,
	C.WHITE,
	true
)
targetLabel.Position = UDim2.fromOffset(18, 10)
targetLabel.Size = UDim2.new(1, -36, 0, 27)

local function targetButton(name, x)
	local button = create("TextButton", {
		Position = UDim2.new(x, 0, 0, 45),
		Size = UDim2.new(0.45, 0, 0, 35),
		BackgroundColor3 = C.BORDER,
		Text = name,
		TextColor3 = C.WHITE,
		TextSize = 13,
		Font = Enum.Font.GothamBold,
		AutoButtonColor = false
	}, targetCard)

	corner(button, 8)

	connect(button.MouseButton1Click, function()
		state.targetPart = name
		currentTarget = nil
	end)

	return button
end

local headButton = targetButton("Head", 0.035)
local torsoButton = targetButton("Torso", 0.515)

local function refreshTargetButtons()
	tween(headButton, {
		BackgroundColor3 =
			state.targetPart == "Head"
			and C.DEEP or C.BORDER
	})

	tween(torsoButton, {
		BackgroundColor3 =
			state.targetPart == "Torso"
			and C.DEEP or C.BORDER
	})
end

connect(headButton.MouseButton1Click, refreshTargetButtons)
connect(torsoButton.MouseButton1Click, refreshTargetButtons)

refreshTargetButtons()

-- PLAYERS

local playersPage = pages.Players

section(playersPage, "Player Profile")

local profile = create("Frame", {
	Size = UDim2.new(1, 0, 0, 125),
	BackgroundColor3 = C.CARD,
	BorderSizePixel = 0
}, playersPage)

corner(profile, 12)
border(profile)

local avatar = create("ImageLabel", {
	Position = UDim2.fromOffset(18, 19),
	Size = UDim2.fromOffset(84, 84),
	BackgroundColor3 = C.DEEP,
	BorderSizePixel = 0
}, profile)

corner(avatar, 12)

task.spawn(function()
	local success, image = pcall(function()
		return Players:GetUserThumbnailAsync(
			player.UserId,
			Enum.ThumbnailType.HeadShot,
			Enum.ThumbnailSize.Size150x150
		)
	end)

	if success and avatar.Parent then
		avatar.Image = image
	end
end)

local displayName = text(
	profile,
	player.DisplayName,
	19,
	C.WHITE,
	true
)
displayName.Position = UDim2.fromOffset(118, 20)
displayName.Size = UDim2.new(1, -135, 0, 30)

local username = text(
	profile,
	"@" .. player.Name,
	13,
	C.MUTED
)
username.Position = UDim2.fromOffset(118, 53)
username.Size = UDim2.new(1, -135, 0, 22)

local userId = text(
	profile,
	"User ID: " .. player.UserId,
	12,
	C.LIGHT
)
userId.Position = UDim2.fromOffset(118, 81)
userId.Size = UDim2.new(1, -135, 0, 20)

-- SETTINGS

local settingsPage = pages.Settings

section(settingsPage, "Interface Settings")

toggle(
	settingsPage,
	"Animations",
	"Enable smooth UI transitions",
	"animations"
)

-- DRAG WINDOW

local draggingWindow = false
local dragStart
local startPosition

connect(header.InputBegan, function(input)
	if input.UserInputType ==
		Enum.UserInputType.MouseButton1
		or input.UserInputType ==
		Enum.UserInputType.Touch then

		draggingWindow = true
		dragStart = input.Position
		startPosition = main.Position
	end
end)

connect(UIS.InputChanged, function(input)
	if draggingWindow and (
		input.UserInputType ==
			Enum.UserInputType.MouseMovement
			or input.UserInputType ==
			Enum.UserInputType.Touch
		) then

		local delta = input.Position - dragStart

		main.Position = UDim2.new(
			startPosition.X.Scale,
			startPosition.X.Offset + delta.X,
			startPosition.Y.Scale,
			startPosition.Y.Offset + delta.Y
		)
	end
end)

connect(UIS.InputEnded, function(input)
	if input.UserInputType ==
		Enum.UserInputType.MouseButton1
		or input.UserInputType ==
		Enum.UserInputType.Touch then

		draggingWindow = false
	end
end)

-- MINIMIZE

local minimized = false

connect(minimizeButton.MouseButton1Click, function()
	minimized = not minimized

	sidebar.Visible = not minimized
	holder.Visible = not minimized

	content.Position = minimized
		and UDim2.fromOffset(0, 0)
		or UDim2.fromOffset(190, 0)

	content.Size = minimized
		and UDim2.fromScale(1, 1)
		or UDim2.new(1, -190, 1, 0)

	heading.Text = minimized
		and "CeeHub"
		or (currentPage == "Home"
			and "Dashboard" or currentPage)

	minimizeButton.Text = minimized and "+" or "−"

	tween(main, {
		Size = minimized
			and UDim2.fromOffset(380, 72)
			or UDim2.fromOffset(790, 500)
	}, 0.35)
end)

-- CLEANUP

local function cleanup()
	if not running then return end

	running = false

	RunService:UnbindFromRenderStep(aimRenderName)

	for _, connection in ipairs(connections) do
		connection:Disconnect()
	end

	for _, list in pairs(playerConnections) do
		for _, connection in ipairs(list) do
			connection:Disconnect()
		end
	end

	for target in pairs(playerVisuals) do
		clearVisual(target)
	end

	gradientAnimation:Cancel()

	if gui.Parent then
		gui:Destroy()
	end

	if _G.CeeHubCleanup == cleanup then
		_G.CeeHubCleanup = nil
	end
end

_G.CeeHubCleanup = cleanup

connect(closeButton.MouseButton1Click, cleanup)

connect(UIS.InputBegan, function(input, processed)
	if processed then return end

	if input.KeyCode == Enum.KeyCode.RightShift then
		main.Visible = not main.Visible
	end
end)

-- STARTUP

switchPage("Home")
updateFov()

print(
	"[CeeHub] v1.0 loaded - Mouse Override - Made by CeeWorks"
)
