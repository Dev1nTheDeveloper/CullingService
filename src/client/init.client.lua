local RPS = game:GetService('ReplicatedStorage')
local PS = game:GetService('Players')

local CullService = require(RPS.Common.CullService)

local GUI = PS.LocalPlayer.PlayerGui:WaitForChild('Modifier')
local radiusTB : TextBox = GUI.Container.Holder.Buttons.Radius.TextBox
local intervalTB : TextBox = GUI.Container.Holder.Buttons.Interval.TextBox

local radius = 100
local interval = 0.1

local function update()
	radius = tonumber(radiusTB.Text) or radius
	interval = tonumber(intervalTB.Text) or interval

	CullService:SetIsStatic('TestTag', false)
	task.delay(interval + 0.1, function()
		CullService:SetIsStatic('TestTag', true)
	end)
	
	CullService:SetCullRadius('TestTag', radius)
	CullService:SetCullInterval('TestTag', interval)
end

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

CullService:SetCullRadius('TestTag', radius)

radiusTB.FocusLost:Connect(function()
	local value = tonumber(radiusTB.Text)
	if value and value ~= radius then
		update()
	end
end)

intervalTB.FocusLost:Connect(function()
	local value = tonumber(intervalTB.Text)
	if value and value ~= interval then
		update()
	end
end)