--!strict
--!optimize 2
--!native

local Players = game:GetService("Players")
local localPlayer = Players.LocalPlayer
if not localPlayer then return end
local character = localPlayer.Character
if not character then return end
local rootPart = character.PrimaryPart
if not rootPart then return end

local DESTINATION_X: number = 318.796387
local DESTINATION_Y: number = 536.528137
local DESTINATION_Z: number = 88.513458
local SCAN_INTERVAL: number = 1
local ARRIVAL_THRESHOLD_SQUARED: number = 4
local Y_OFFSET: number = -1.5
local PING_STEP_DIVISOR: number = 5
local MAP_START_DELAY: number = 5

local BASEPART_CLASSNAMES: { [string]: boolean } = {
	Part = true,
	MeshPart = true,
	UnionOperation = true,
	SpawnLocation = true,
	CornerWedgePart = true,
	TrussPart = true,
	WedgePart = true,
}

local function isAlive(): boolean
	return localPlayer:GetAttribute("Alive") == "true"
end

local function interpolateTo(targetX: number, targetY: number, targetZ: number): ()
	local origin = rootPart.CFrame.Position
	local originX = origin.X
	local originY = origin.Y
	local originZ = origin.Z
	local deltaX = targetX - originX
	local deltaY = (targetY + Y_OFFSET) - originY
	local deltaZ = targetZ - originZ
	local overlayFramesPerSecond = get_overlay_fps()
	local stepWait: number = if overlayFramesPerSecond > 0 then 1 / overlayFramesPerSecond else 0.016
	local stepCount = math.max(1, math.round(game:GetPing() / PING_STEP_DIVISOR))
	for i = 1, stepCount do
		local alpha = i / stepCount
		rootPart.CFrame = CFrame.new(
			originX + deltaX * alpha,
			originY + deltaY * alpha,
			originZ + deltaZ * alpha
		)
		task.wait(stepWait)
	end
end

local function runLobby(): ()
	while not isAlive() do
		local origin = rootPart.CFrame.Position
		local deltaX = DESTINATION_X - origin.X
		local deltaY = DESTINATION_Y - origin.Y
		local deltaZ = DESTINATION_Z - origin.Z
		if deltaX * deltaX + deltaY * deltaY + deltaZ * deltaZ > ARRIVAL_THRESHOLD_SQUARED then
			interpolateTo(DESTINATION_X, DESTINATION_Y, DESTINATION_Z)
		else
			task.wait(SCAN_INTERVAL)
		end
	end
end

local function scanCoins(coins: { BasePart }): number
	table.clear(coins)
	for _, descendant in workspace:GetDescendants() do
		if descendant.Name == "Coin_Server" and BASEPART_CLASSNAMES[descendant.ClassName] then
			local success, _ = pcall(function()
				local _ = (descendant :: BasePart).Position
			end)
			if success then
				coins[#coins + 1] = descendant :: BasePart
			end
		end
	end
	return #coins
end

local function runMap(): ()
	local coins: { BasePart } = {}
	local hasWaited = false
	while isAlive() do
		local coinCount = scanCoins(coins)
		if coinCount == 0 then
			hasWaited = false
			task.wait(SCAN_INTERVAL)
			continue
		end
		if not hasWaited then
			task.wait(MAP_START_DELAY)
			hasWaited = true
			continue
		end
		while coinCount > 0 and isAlive() do
			local rootPosition = rootPart.Position
			local rootX = rootPosition.X
			local rootY = rootPosition.Y
			local rootZ = rootPosition.Z
			local nearestCoinIndex = 1
			local nearestDistanceSquared = math.huge
			for i = 1, coinCount do
				local coinPosition = coins[i].Position
				local deltaX = coinPosition.X - rootX
				local deltaY = coinPosition.Y - rootY
				local deltaZ = coinPosition.Z - rootZ
				local distanceSquared = deltaX * deltaX + deltaY * deltaY + deltaZ * deltaZ
				if distanceSquared < nearestDistanceSquared then
					nearestDistanceSquared = distanceSquared
					nearestCoinIndex = i
				end
			end
			local targetPosition = coins[nearestCoinIndex].Position
			coins[nearestCoinIndex] = coins[coinCount]
			coins[coinCount] = nil :: any
			coinCount -= 1
			interpolateTo(targetPosition.X, targetPosition.Y, targetPosition.Z)
		end
	end
end

local lastAlive: boolean? = nil
while true do
	local alive = isAlive()
	if lastAlive == nil then
		print("Autofarm Initialised")
	end
	if lastAlive ~= alive then
		lastAlive = alive
		if alive then
			runMap()
		else
			runLobby()
		end
	end
	task.wait(SCAN_INTERVAL)
end
