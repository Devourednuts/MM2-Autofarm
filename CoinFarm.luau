--!strict
local Players = game:GetService("Players")

local localPlayer = Players.LocalPlayer
if not localPlayer then return end

local character = localPlayer.Character
if not character then return end

local rootPart = character.PrimaryPart
if not rootPart then return end

local DESTINATION_X = 318.796387
local DESTINATION_Y = 536.528137
local DESTINATION_Z = 88.513458
local TELEPORT_STEPS = 4
local TELEPORT_STEP_WAIT = 0.25
local SCAN_INTERVAL = 1

local function interpolateTo(tx: number, ty: number, tz: number): ()
	local origin = rootPart.CFrame.Position
	local ox = origin.X
	local oy = origin.Y
	local oz = origin.Z
	for i = 1, TELEPORT_STEPS do
		local alpha = i / TELEPORT_STEPS
		rootPart.CFrame = CFrame.new(
			ox + (tx - ox) * alpha,
			oy + (ty - oy) * alpha,
			oz + (tz - oz) * alpha
		)
		task.wait(TELEPORT_STEP_WAIT)
	end
end

local function runLobby(): ()
	while localPlayer:GetAttribute("Alive") ~= "true" do
		interpolateTo(DESTINATION_X, DESTINATION_Y, DESTINATION_Z)
	end
end

local function runMap(): ()
	while localPlayer:GetAttribute("Alive") == "true" do
		local coins: { BasePart } = {}
		for _, descendant in workspace:GetDescendants() do
			if descendant.Name == "Coin_Server" then
				table.insert(coins, descendant :: BasePart)
			end
		end

		if #coins == 0 then
			task.wait(SCAN_INTERVAL)
			continue
		end

		while #coins > 0 and localPlayer:GetAttribute("Alive") == "true" do
			local rp = rootPart.Position
			local rx = rp.X
			local ry = rp.Y
			local rz = rp.Z

			local nearestIndex = 1
			local nearestDistSq = math.huge

			for i = 1, #coins do
				local cp = coins[i].Position
				local dx = cp.X - rx
				local dy = cp.Y - ry
				local dz = cp.Z - rz
				local dSq = dx * dx + dy * dy + dz * dz
				if dSq < nearestDistSq then
					nearestDistSq = dSq
					nearestIndex = i
				end
			end

			local pos = coins[nearestIndex].Position
			local last = #coins
			coins[nearestIndex] = coins[last]
			coins[last] = nil :: any

			interpolateTo(pos.X, pos.Y, pos.Z)
		end
	end
end

local lastAlive: boolean? = nil

print("Autofarm Initilised")

while true do
	local alive = localPlayer:GetAttribute("Alive") == "true"
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
