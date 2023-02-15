local RPS = game:GetService('ReplicatedStorage')

local CullingService = require(RPS.Common.CullingService)

CullingService:Initialize()

CullingService:GetInstancesCulledInSignal('TestTag'):Connect(function(instances : {BasePart | Attachment})
    print ('Instances culled in:', instances)
end)

CullingService:GetInstancesCulledOutSignal('TestTag'):Connect(function(instances : {BasePart | Attachment})
    print ('Instances culled out:', instances)
end)

CullingService:SetCullRadius('TestTag', 300)