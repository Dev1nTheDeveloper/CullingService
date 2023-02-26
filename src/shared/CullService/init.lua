--!strict

local CLS = game:GetService('CollectionService')
local RS = game:GetService('RunService')
local PS = game:GetService('Players')

if not (game:IsLoaded()) then
	game.Loaded:Wait()
end

-- Signal module for firing custom events
local Signal = require(script.Signal)

local player : Player = PS.LocalPlayer
local camera : Camera = workspace.CurrentCamera

-- string warnings
local NOT_INITIALIZED : string = "CullService: Created new tag data because the '%s' tag was not already initialized"

-- Set some types for easier access in the script
type Dictionary<T> = {[string] : T}
type Cullable = BasePart | Attachment
type CullableData = {[Cullable] : boolean}
export type TagData = {
	IsStatic : boolean, 
	CullRadius : number, 
	CullInterval : number, 
	Instances : CullableData, 
	InstancesCulledIn : Signal.signal, 
	InstancesCulledOut : Signal.signal
}

local CullService = {Tags = {}, Binds = {}}
setmetatable(CullService, CullService)

-- Private functions

-- Check if the instance is in the FoV of the camera, and is within range
local function isInView(lastCFrame : CFrame, position : Vector3, cullRadius : number) : boolean
	local controlVector : Vector3 = lastCFrame.LookVector
	local directionVector : Vector3 = (position - lastCFrame.Position)

	local threshold : number = camera.FieldOfView + 2
	local angle : number = math.floor(math.deg(directionVector.Unit:Angle(controlVector)))

	if angle <= threshold then
		directionVector = (player.Character and player.Character.PrimaryPart) and (position - player.Character.PrimaryPart.Position) or directionVector
		local xzDistance : number = (Vector3.new(directionVector.X, 0, directionVector.Z)).Magnitude

		if xzDistance <= cullRadius then
			return true
		else
			return false
		end
	else
		return false
	end
end

-- Create a function that sets up the culling cycle for a specific tag
local function setupTag(tag : string) : TagData
	local tagData : TagData = {
		IsStatic = true,
		CullRadius = 50,
		CullInterval = 0.1,
		Instances = {},
		InstancesCulledIn = Signal.new(),
		InstancesCulledOut = Signal.new()
	}

	CullService.Tags[tag] = tagData
	CullService.Binds["CullService_"..tag] = true

	local count : number = 0
	
	-- Store the last updated CFrame of the camera
	local lastCFrame : CFrame = camera.CFrame

	local function tagRuntime(dt : number)
		count += dt

		if count > tagData.CullInterval then
			count = 0

			-- If the tag is dynamic (not static), then we update regardless of if the camera moved, because the parts might move.
			-- If the tag is static, then we check if the camera legitametly moved, and update accordingly because new parts might be in view, and other parts might have been removed
			if not tagData.IsStatic or (camera.CFrame.Position - lastCFrame.Position).Magnitude > 1 or camera.CFrame.Rotation ~= lastCFrame.Rotation then
				lastCFrame = camera.CFrame

				local instanceMovedInCount : number = 0
				local instanceMovedOutCount : number = 0
				local instancesMovedIn : {Cullable} = {}
				local instancesMovedOut : {Cullable} = {}

				task.desynchronize()
				for instance, isEligible in tagData.Instances do
					local position : Vector3 = (instance:IsA('BasePart') and instance.Position) or (instance :: Attachment).WorldPosition

					if isInView(lastCFrame, position, tagData.CullRadius) then
						if not isEligible then
							tagData.Instances[instance] = true

							instanceMovedInCount += 1
							instancesMovedIn[instanceMovedInCount] = instance
						end
					else
						if isEligible then
							tagData.Instances[instance] = false

							instanceMovedOutCount += 1
							instancesMovedOut[instanceMovedOutCount] = instance
						end
					end
				end
				task.synchronize()

				-- Not in parallel because connected functions might be using unsafe methods
				if instanceMovedInCount > 0 then
					tagData.InstancesCulledIn:Fire(instancesMovedIn)
				end

				if instanceMovedOutCount > 0 then
					tagData.InstancesCulledOut:Fire(instancesMovedOut)
				end

			end
		end
	end

	local function instanceAdded(instance : Cullable)
		if instance:IsA('BasePart') or instance:IsA('Attachment') then
			tagData.Instances[instance] = false -- starts off false because objects could be in the view, but not actually updated
		end
	end

	local function instanceRemoved(instance : Cullable)
		if tagData.Instances[instance] then
			tagData.Instances[instance] = nil
		end
	end

	for _, tagged in CLS:GetTagged(tag) do
		instanceAdded(tagged)
	end

	RS:BindToRenderStep('CullService_'..tag, Enum.RenderPriority.Camera.Value + 1, tagRuntime)
	CLS:GetInstanceAddedSignal(tag):Connect(instanceAdded)
	CLS:GetInstanceRemovedSignal(tag):Connect(instanceRemoved)


	return tagData
end

function CullService.__tostring() : string
	return "Culling Service"
end

-- Get the signal for instances culled in of a specific tag
function CullService:GetInstancesCulledInSignal(tag : string) : Signal.signal
	assert(type(tag) == 'string' and #tag > 0, "Bad Argument #1: Argument must be a string that is not empty")

	if CullService.Tags[tag] then
		return CullService.Tags[tag].InstancesCulledIn
	else
		warn(NOT_INITIALIZED:format(tag))
		local data : TagData = setupTag(tag)
		return data.InstancesCulledIn
	end
end

-- Get the signal for instances culled out of a specific tag
function CullService:GetInstancesCulledOutSignal(tag : string) : Signal.signal
	assert(type(tag) == 'string' and #tag > 0, "Bad Argument #1: Argument must be a string that is not empty")

	if CullService.Tags[tag] then
		return CullService.Tags[tag].InstancesCulledOut
	else
		warn(NOT_INITIALIZED:format(tag))
		local data : TagData = setupTag(tag)
		return data.InstancesCulledOut
	end
end

-- Change the cull radius of a specific tag
function CullService:SetCullRadius(tag : string, radius : number)
	assert(type(tag) == 'string' and #tag > 0, "Bad Argument #1: Argument must be a string that is not empty")
	assert(type(radius) == 'number' and radius == radius, "Bad Argument #2: Argument must be a number that is not NaN")
	
	if CullService.Tags[tag] then
		CullService.Tags[tag].CullRadius = radius
	else
		warn(NOT_INITIALIZED:format(tag))
		local data : TagData = setupTag(tag)
		data.CullRadius = radius
	end
end

-- Change the cull radius of a tag
function CullService:SetCullInterval(tag : string, interval : number)
	assert(type(tag) == 'string' and #tag > 0, "Bad Argument #1: Argument must be a string that is not empty")
	assert(type(interval) == 'number' and interval == interval, "Bad Argument #2: Argument must be a number that is not NaN")

	if CullService.Tags[tag] then
		CullService.Tags[tag].CullInterval = interval
	else
		warn(NOT_INITIALIZED:format(tag))
		local data : TagData = setupTag(tag)
		data.CullInterval = interval
	end
end

-- Set whether or not the tag is a static tag or a dynamic tag
function CullService:SetIsStatic(tag : string, isStatic : boolean)
	assert(type(tag) == 'string' and #tag > 0, "Bad Argument #1: Argument must be a string that is not empty")
	assert(type(isStatic) == 'boolean', "Bad Argument #2: Argument must be a boolean")

	if CullService.Tags[tag] then
		CullService.Tags[tag].IsStatic = isStatic
	else
		warn(NOT_INITIALIZED:format(tag))
		local data : TagData = setupTag(tag)
		data.IsStatic = isStatic
		CullService.Tags[tag] = data
	end
end

-- Get the cull radius of a tag
function CullService:GetCullRadius(tag : string) : number?
	return CullService.Tags[tag] and CullService.Tags[tag].CullRadius or nil
end

-- Get the cull interval of a tag
function CullService:GetCullInterval(tag : string) : number?
	return CullService.Tags[tag] and CullService.Tags[tag].CullInterval or nil
end

-- Get whether a tag is static
function CullService:GetIsStatic(tag : string) : boolean?
	return CullService.Tags[tag] and CullService.Tags[tag].IsStatic or nil
end

-- Get the tag data of a tag
function CullService:GetTagData(tag : string) : TagData?
	return CullService.Tags[tag] or nil
end

-- Create a new data set of a tag
function CullService:SetupTag(tag : string)
	setupTag(tag)
end

return CullService
