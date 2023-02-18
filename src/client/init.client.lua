local RPS = game:GetService('ReplicatedStorage')

local CullingService = require(RPS.Common.CullingService)
task.wait(10)
CullingService:GetInstancesCulledInSignal('TestTag'):Connect(function(instances : {BasePart | Attachment})
    for _, part in instances do
        if part:IsA('BasePart') then
            part.BrickColor = BrickColor.Yellow()
        end
    end
end)

CullingService:GetInstancesCulledOutSignal('TestTag'):Connect(function(instances : {BasePart | Attachment})
    for _, part in instances do
        if part:IsA('BasePart') then
            part.BrickColor = BrickColor.Black()
        end
    end
end)

CullingService:SetCullRadius('TestTag', 100)