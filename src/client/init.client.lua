local RPS = game:GetService('ReplicatedStorage')

local CullService = require(RPS.Common.CullService)
task.wait(10)
CullService:GetInstancesCulledInSignal('TestTag'):Connect(function(instances : {BasePart | Attachment})
    for _, part in instances do
        if part:IsA('BasePart') then
            part.BrickColor = BrickColor.Yellow()
        end
    end
end)

CullService:GetInstancesCulledOutSignal('TestTag'):Connect(function(instances : {BasePart | Attachment})
    for _, part in instances do
        if part:IsA('BasePart') then
            part.BrickColor = BrickColor.Black()
        end
    end
end)

CullService:SetCullRadius('TestTag', 100)