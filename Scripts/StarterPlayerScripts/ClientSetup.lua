--@localscript

local StarterPlayer = game:GetService("StarterPlayer")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Pronghorn = require(ReplicatedStorage.Source.Pronghorn)
Pronghorn:SetEnabledChannels({
    Remotes = false
})

Pronghorn:Import({
    StarterPlayer.StarterPlayerScripts.Source,
    ReplicatedStorage.Source.SharedModules,
    ReplicatedStorage.Source.ClientModules,
})

print("Pronghorn Client Import Complete.")