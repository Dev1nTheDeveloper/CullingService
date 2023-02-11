local CLS = game:GetService('CollectionService')
local RS = game:GetService('RunService')

if not (game:IsLoaded()) then
	game.Loaded:Wait()
end

local Signal = require(script.Signal)

type Dictionary<T> = {[string] : T}
type Cullable = BasePart | Attachment
type CullableData = {[Cullable] : {ActivationUpdated : boolean, IsEligible : boolean}}
type TagData = {CullRadius : number, CullInterval : number, Instances : CullableData, InstancesCulledIn : Signal.signal, InstancesCulledOut : Signal.signal}

local CullingService : {Initialized : boolean, Tags : Dictionary<TagData>, Binds : {[string] : boolean}} = {}
setmetatable(CullingService, CullingService)

-- Private functions
local function isInitialized()
	return CullingService.Initialized
end

local function setupTag(tag : string) : TagData
	local data : TagData = {
		CullRadius = 50,
		CullInterval = 0.1,
		Instances = {},
		InstancesCulledIn = Signal.new(),
		InstancesCulledOut = Signal.new()
	}

	CullingService.Tags[tag] = data
	CullingService.Binds["CullingService_"..tag] = true

	return data	
end

function CullingService.__tostring()
	return "Culling Service"
end

function CullingService:GetInstancesCulledInSignal(tag : string) : Signal.signal
	if not (isInitialized()) then
		warn("CullingService has not been initialized")
		return
	end

	if CullingService.Tags[tag] then
		return CullingService.Tags[tag].InstanceCulledIn
	else
		local data : TagData = setupTag(tag)
		return data.InstanceCulledIn
	end
end

function CullingService:GetInstancesCulledOutSignal(tag : string)
	if not (isInitialized()) then
		warn("CullingService has not been initialized")
		return
	end

	if CullingService.Tags[tag] then
		return CullingService.Tags[tag].InstanceCulledOut
	else
		local data : TagData = setupTag(tag)
		return data.InstanceCulledOut
	end
end

function CullingService:SetCullRadius(tag : string, radius : number)
	if not (isInitialized()) then
		warn("CullingService has not been initialized")
		return
	end

	if CullingService.Tags[tag] then
		CullingService.Tags[tag].CullRadius = radius
	else
		warn('CullingService: Created new tag data because '..tag..' is was not already initialized')
		CullingService.Tags[tag] = {CullRadius = radius, CullInterval = 0.1, Instances = {}, InstancesCulledIn = Signal.new(), InstancesCulledOut = Signal.new()}
	end
end

function CullingService:SetCullInterval(tag : string, interval : number)
	if not (isInitialized()) then
		warn("CullingService has not been initialized")
		return
	end

	if CullingService.Tags[tag] then
		CullingService.Tags[tag].CullInterval = interval
	else
		warn('CullingService: Created new tag data because '..tag..' is was not already initialized')
		CullingService.Tags[tag] = {CullRadius = 50, CullInterval = interval, Instances = {}, InstancesCulledIn = Signal.new(), InstancesCulledOut = Signal.new()}
	end
end

function CullingService:Initialize()
	self.Initialized = true
	self.Tags = {}
	self.Binds = {}
end

return CullingService
