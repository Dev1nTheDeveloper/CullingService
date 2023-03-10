# CullService
Cull BaseParts and/or Attachments within range and within the field of view, and assign functions when said objects are culled in or out

At the moment, only attachments and baseparts are eligible to be culled. Models will be in the future.
This is strictly a client-based service, so using this on the server will do nothing for you, and probably cause errors.

Here is a [video](https://youtu.be/XJVEiDr-wZc) showcasing this tool.

## Details
CullService utilizes Roblox's CollectionService to track objects of a certain tag entering and leaving the camera's fieldOfView, as well as the object's relative distance from the player's character. This is extremely useful for conserving the lua heap and memory, as memory being conserved for visual things that you don't see is a waste of memory space.

Each subscribed tag has its own `Cull Radius`, `Cull Interval`, `Is Static` property, and instance culling `signals`.

### **Cull Radius**

The `Cull Radius` tells the CullService to ignore parts beyond a certain stud length. The default value is 50 studs. 
You can change a tag's `Cull Radius` through the `SetCullRadius` method.

### **Cull Interval**

The `Cull Interval` tells the CullService when to update parts of a specific tag. The default value is 0.1 seconds. So every 0.1 seconds, the CullService will look for the instances that have entered the view, and for the instances that have left. It will then fire the corresponding signals according to the instance's tags.
You can changes a tag's `Cull Interval` through the `SetCullInverval` method.

### **Is Static**

The `Is Static` property tells the CullService whether or not to update based on if the camera has moved or not. The default value is `true`.
If this property is `true`, then, at every `CullInterval` the CullService will check if the camera has moved. If the camera moved, the CullService will check which parts have moved in/out of view.
If this property is `false`, then, at every `CullInterval` the CullService will disregard whether the camera has moved and check for instances that entered/left the view.
Set this property to `false` if you are going to deal with moving objects, otherwise keep it set to `true`

## Installation
You can access the CullService from [roblox](https://www.roblox.com/library/12498403225/CullService-Module), and then you can put the module in ReplicatedStorage
From there, you can require the module with a **[LocalScript](https://create.roblox.com/docs/reference/engine/classes/LocalScript)** with the following code:

```lua
local CullService = require(game:GetService('ReplicatedStorage').CullService)
```

## Examples
Use the GetInstancesCulledIn and GetInstancesCulledOut signals to start culling parts of a specific tag.

### 1. Grass

This just prints out all the grass culled in and out.

```lua
local CullService = require(game.ReplicatedStorage.CullService)

local grassCulledIn = CullService:GetInstancesCulledInSignal('Grass'):Connect(function(instancesCulledIn)
    print(instancesCulledIn)
end)

local grassCulledOut = CullService:GetInstancesCulledOutSignal('Grass'):Connect(function(instancesCulledOut)
    print(instancesCulledOut)
end)

```
### 2. Particles

This one takes all the instances culled in, and enables a descendant particle. If they get culled out, then the attachment stops emitting the particle.

```lua
local CullService = require(game.ReplicatedStorage.CullService)

local grassCulledIn = CullService:GetInstancesCulledInSignal('Particle'):Connect(function(instancesCulledIn)
    for _, attachment in instancesCulledIn do
        attachment.Particle.Enabled = true
    end
end)

local grassCulledOut = CullService:GetInstancesCulledOutSignal('Particle'):Connect(function(instancesCulledOut)
    for _, attachment in instancesCulledOut do
        attachment.Particle.Enabled = false
    end
end)
```

## API

| Name | Description |
| ----- | ---------- |
| `CullService:GetInstancesCulledInSignal(tagName)` | Returns a `signal` that sends a table of all new instances culled in, granted they have the corresponding tag |
| `CullService:GetInstancesCulledOutSignal(tagName)` | Returns a `signal` that sends a table of all new instances culled out, granted they have the corresponding tag |
| `CullService:SetCullInterval(tagName, interval)` | Changes the interval at which the CullService fires each signal of a certain tag |
| `CullService:SetCullRadius(tagName, radius)` | Changes the radius distance at which the CullService culls instances in/out of a certain tag |
| `CullService:SetIsStatic(tagName, isStatic)` | Changes whether or not any signals will fire based on if the camera has moved, or on a continuous set interval regardless of if the camera has moved |
| `CullService:GetCullInterval(tagName)` | Returns the cull interval of a specified tag. If CullService does not have data on this tag, this will return `nil`|
| `CullService:GetCullRadius(tagName)` | Returns the cull radius of a specified tag. If CullService does not have data on this tag, this will return `nil`|
| `CullService:GetIsStatic(tagName)` | Returns whether the specified tag is static. If CullService does not have data on this tag, this will return `nil`|
| `CullService:GetTagData(tagName)` | Returns the tag data of a specified tag. If CullService does not have data on this tag, this will return `nil`|
| `CullService:SetupTag(tagName)` | Creates new data settings for the specified tag |