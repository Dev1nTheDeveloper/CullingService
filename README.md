# CullingService
Cull BaseParts and/or Attachments within range and within the field of view, and assign functions when said objects are culled in or out

CullingService utilizes Roblox's CollectionService to track objects of a certain tag entering and leaving the camera's fieldOfView, as well as the object's relative distance from the player's character. This is extremely useful for conserving the lua

At the moment, only attachments and baseparts are eligible to be culled. Models will be in the future.
This is strictly a client-based service, so using this on the server will do nothing for you, and probably cause errors.

## Installation
You can access the CullingService from [roblox](https://www.roblox.com/library/12498403225/CullingService-Module), and then you can put the module in ReplicatedStorage

## Examples
Require the module in a localscript, initialize the service, and then use the GetInstanceCullIn and GetInstanceCulledOut signals to start culling parts of a specific tag.

### 1. Grass

This just prints out all the grass culled in and out.

```lua
local CullingService = require(game.ReplicatedStorage.CullingService)
CullingService:Initialize()

local grassCulledIn = CullingService:GetInstancesCulledInSignal('Grass'):Connect(function(instancesCulledIn)
    print(instancesCulledIn)
end)

local grassCulledOut = CullingService:GetInstancesCulledOutSignal('Grass'):Connect(function(instancesCulledOut)
    print(instancesCulledOut)
end)

```
### 2. Particles

This one takes all the instances culled in, and enables a descendant particle. If they get culled out, then the attachment stops emitting the particle.

```lua
local CullingService = require(game.ReplicatedStorage.CullingService)
CullingService:Initialize()

local grassCulledIn = CullingService:GetInstancesCulledInSignal('Particle'):Connect(function(instancesCulledIn)
    for _, attachment in instancesCulledIn do
        attachment.Particle.Enabled = true
    end
end)

local grassCulledOut = CullingService:GetInstancesCulledOutSignal('Particle'):Connect(function(instancesCulledOut)
    for _, attachment in instancesCulledOut do
        attachment.Particle.Enabled = false
    end
end)

```
### 3. Test Place 
You can also test it out in this [test place](\CullingService.rbxl)


