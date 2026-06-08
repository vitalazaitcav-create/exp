--!strict
-- Remotes: shared accessor for the game's RemoteEvents.
-- On the server it creates the events; on the client it waits for them.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local FOLDER_NAME = "Remotes"
local EVENT_NAMES = {
	"RequestRoll", -- client -> server: "please roll me a creature"
	"RequestLock", -- client -> server: "upgrade my base lock"
	"RequestRebirth", -- client -> server: "rebirth me"
	"ToggleDisguise", -- client -> server: "toggle my disguise"
	"Notify", -- server -> client: toast message
}

local Remotes = {}

if RunService:IsServer() then
	local folder = ReplicatedStorage:FindFirstChild(FOLDER_NAME)
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = FOLDER_NAME
		folder.Parent = ReplicatedStorage
	end
	for _, name in EVENT_NAMES do
		local event = folder:FindFirstChild(name)
		if not event then
			event = Instance.new("RemoteEvent")
			event.Name = name
			event.Parent = folder
		end
		Remotes[name] = event
	end
else
	local folder = ReplicatedStorage:WaitForChild(FOLDER_NAME)
	for _, name in EVENT_NAMES do
		Remotes[name] = folder:WaitForChild(name)
	end
end

return Remotes
