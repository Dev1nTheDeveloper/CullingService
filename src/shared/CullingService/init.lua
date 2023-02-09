local CLS = game:GetService('CollectionService')
local RS = game:GetService('RunService')

if not (game:IsLoaded()) then
	game.Loaded:Wait()
end

local Signal = require(script.Signal)

type TagData = {CullRadius : number, CullInterval : number, InstanceCulledIn : Signal.signal, InstanceCulledOut : Signal.signal}
type Dictionary<T> = {[string] : T}

local CullingService : {Initialized : boolean, Tags : Dictionary<TagData>, Bins : {string}} = {}
setmetatable(CullingService, CullingService)

local function isInitialized()
	return CullingService.Initialized
end

function CullingService.__tostring()
	return "Culling Service"
end

function CullingService:_SetupTag(tag : string) : TagData
	if not (isInitialized()) then
		warn("CullingService has not been initialized")
		return
	end
	
	local data : TagData = {
		CullRadius = 50, 
		CullInterval = 0.1,
		InstanceCulledIn = Signal.new(),
		InstanceCulledOut = Signal.new()
	}

	CullingService.Tags[tag] = data

	return data
end

function CullingService:GetInstanceCulledInSignal(tag : string) : Signal.signal
	if not (isInitialized()) then
		warn("CullingService has not been initialized")
		return
	end

	if CullingService.Tags[tag] then
		return CullingService.Tags[tag].InstanceCulledIn
	else
		local data : TagData = CullingService:_SetupTag(tag)
		return data.InstanceCulledIn
	end
end

function CullingService:GetInstanceCulledOutSignal(tag : string)
	if not (isInitialized()) then
		warn("CullingService has not been initialized")
		return
	end

	if CullingService.Tags[tag] then
		return CullingService.Tags[tag].InstanceCulledIn
	else
		local data : TagData = CullingService:_SetupTag(tag)
		return data.InstanceCulledIn
	end
end

function CullingService:SetTagCullRadius(tag : string, radius : number)
	if not (isInitialized()) then
		warn("CullingService has not been initialized")
		return
	end

	if CullingService.Tags[tag] then
		CullingService.Tags[tag].CullRadius = radius
	else
		warn('CullingService: Created new tag data because '..tag..' is was not already initialized')
		CullingService.Tags[tag] = {CullRadius = radius, CullInterval = 0.1, InstanceCulledIn = Signal.new(), InstanceCulledOut = Signal.new()}
	end
end

function CullingService:SetTagCullInterval(tag : string, interval : number)
	if not (isInitialized()) then
		warn("CullingService has not been initialized")
		return
	end

	if CullingService.Tags[tag] then
		CullingService.Tags[tag].CullInterval = interval
	else
		warn('CullingService: Created new tag data because '..tag..' is was not already initialized')
		CullingService.Tags[tag] = {CullRadius = 50, CullInterval = interval, InstanceCulledIn = Signal.new(), InstanceCulledOut = Signal.new()}
	end
end


function CullingService:Initialize()
	self.Initialized = true
	self.Tags = {}
	self.Counters = {}
	self.Binds = {}
end

function CullingService:UnbindRuntime()
	RS:UnbindFromRenderStep('CullingService')
end


return CullingService
