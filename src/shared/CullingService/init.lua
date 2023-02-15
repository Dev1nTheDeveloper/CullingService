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

-- Store the last updated CFrame of the camera
local lastCFrame : CFrame = camera.CFrame

-- Set some types for easier access in the script
type Dictionary<T> = {[string] : T}
type Cullable = BasePart | Attachment
type CullableData = {[Cullable] : boolean}
type TagData = {
	IsStatic : boolean, 
	CullRadius : number, 
	CullInterval : number, 
	Instances : CullableData, 
	InstancesCulledIn : Signal.signal, 
	InstancesCulledOut : Signal.signal
}

local CullingService : {Initialized : boolean, Tags : Dictionary<TagData>, Binds : {[string] : boolean}} = {}
setmetatable(CullingService, CullingService)

-- Private functions

-- Check if CullingService has been initialized
local function isInitialized() : boolean
	return CullingService.Initialized or false
end

-- Check if the instance is in the FoV of the camera, and is within range
local function isInView(position : Vector3, cullRadius : number) : boolean
	local controlVector : Vector3 = lastCFrame.LookVector
	local directionVector : Vector3 = (position - lastCFrame.Position)

	local threshold : number = camera.FieldOfView + 2
	local angle : number = math.floor(math.deg(directionVector.Unit:Angle(controlVector)))

	if angle <= threshold then
		directionVector = player.Character and player.Character.PrimaryPart and (position - player.Character.PrimaryPart.Position) 
		local xzDistance : number? = directionVector and (Vector3.new(directionVector.X, 0, directionVector.Z)).Magnitude

		if xzDistance and xzDistance <= cullRadius then
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

	CullingService.Tags[tag] = tagData
	CullingService.Binds["CullingService_"..tag] = true

	local count : number = 0

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
					local position : Vector3 = instance:IsA('BasePart') and instance.Position or instance.WorldPosition

					if isInView(position, tagData.CullRadius) then
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
			tagData.Instances[instance] = true
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

	RS:BindToRenderStep('CullingService_'..tag, Enum.RenderPriority.Camera.Value + 1, tagRuntime)
	CLS:GetInstanceAddedSignal(tag):Connect(instanceAdded)
	CLS:GetInstanceRemovedSignal(tag):Connect(instanceRemoved)

	return tagData
end

function CullingService.__tostring() : string
	return "Culling Service"
end

-- Get the signal for instances culled in of a specific tag
function CullingService:GetInstancesCulledInSignal(tag : string) : Signal.signal
	if not (isInitialized()) then
		warn("CullingService has not been initialized")
		return
	end

	assert(type(tag) == 'string' and #tag > 0, "Bad Argument #1: Argument must be a string that is not empty")

	if CullingService.Tags[tag] then
		return CullingService.Tags[tag].InstancesCulledIn
	else
		local data : TagData = setupTag(tag)
		return data.InstancesCulledIn
	end
end

-- Get the signal for instances culled out of a specific tag
function CullingService:GetInstancesCulledOutSignal(tag : string) : Signal.signal
	if not (isInitialized()) then
		warn("CullingService has not been initialized")
		return
	end

	assert(type(tag) == 'string' and #tag > 0, "Bad Argument #1: Argument must be a string that is not empty")

	if CullingService.Tags[tag] then
		return CullingService.Tags[tag].InstancesCulledOut
	else
		local data : TagData = setupTag(tag)
		return data.InstancesCulledOut
	end
end

-- Change the cull radius of a specific tag
function CullingService:SetCullRadius(tag : string, radius : number)
	if not (isInitialized()) then
		warn("CullingService has not been initialized")
		return
	end

	assert(type(tag) == 'string' and #tag > 0, "Bad Argument #1: Argument must be a string that is not empty")
	assert(type(radius) == 'number' and radius == radius, "Bad Argument #2: Argument must be a number that is not NaN")
	
	if CullingService.Tags[tag] then
		CullingService.Tags[tag].CullRadius = radius
	else
		warn('CullingService: Created new tag data because '..tag..' is was not already initialized')
		local data : TagData = setupTag(tag)
		data.CullRadius = radius
	end
end

-- Change the cull radius of a tag
function CullingService:SetCullInterval(tag : string, interval : number)
	if not (isInitialized()) then
		warn("CullingService has not been initialized")
		return
	end

	assert(type(tag) == 'string' and #tag > 0, "Bad Argument #1: Argument must be a string that is not empty")
	assert(type(interval) == 'number' and interval == interval, "Bad Argument #2: Argument must be a number that is not NaN")

	if CullingService.Tags[tag] then
		CullingService.Tags[tag].CullInterval = interval
	else
		warn('CullingService: Created new tag data because '..tag..' is was not already initialized')
		local data : TagData = setupTag(tag)
		data.CullInterval = interval
	end
end

-- Set whether or not the tag is a static tag or a dynamic tag
function CullingService:SetIsStatic(tag : string, isStatic : boolean)
	if not (isInitialized()) then
		warn("CullingService has not been initialized")
		return
	end

	assert(type(tag) == 'string' and #tag > 0, "Bad Argument #1: Argument must be a string that is not empty")
	assert(type(isStatic) == 'boolean', "Bad Argument #2: Argument must be a boolean")

	if CullingService.Tags[tag] then
		CullingService.Tags[tag].IsStatic = isStatic
	else
		warn('CullingService: Created new tag data because '..tag..' is was not already initialized')
		local data : TagData = setupTag(tag)
		data.IsStatic = isStatic
		CullingService.Tags[tag] = data
	end
end

CullingService.SetupTag = setupTag

-- Initialize function of CullingService
function CullingService:Initialize()
	self.Initialized = true
	self.Tags = {}
	self.Binds = {}
end

return CullingService
