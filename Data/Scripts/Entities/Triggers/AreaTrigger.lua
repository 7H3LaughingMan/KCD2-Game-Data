--	Crytek Source File.
-- 	Copyright (C), Crytek Studios, 2001-2008.

AreaTrigger =
{
	Properties =
	{
		bEnabled = true,
		bTriggerOnce = 1,
		bOnlyPlayers = 1,
		bOnlyLocalPlayer= 0,
		bCameraOnly = 0,
		esFactionFilter	= "",
		ScriptCommand = "",
		PlaySequence = "",
		bInVehicleOnly = 0,

		MultiplayerOptions=
		{
			bNetworked		= false,
			bPerPlayer		= 0,
		},
	},


	Client={},
	Server={},

	Editor={
		Model="Editor/Objects/T.cgf",
		Icon="AreaTrigger.bmp",
		IsScalable = false,
		IsRotatable = false,
	},
}

-- =============================================================================
Net.Expose{
	Class = AreaTrigger,
	ClientMethods = {
		ClEnter		= { RELIABLE_ORDERED, PRE_ATTACH, ENTITYID, INT8 },
		ClLeave		= { RELIABLE_ORDERED, PRE_ATTACH, ENTITYID, INT8 },
	},
	ServerMethods = {
	},
	ServerProperties = {
	}
}

-- =============================================================================
function AreaTrigger:OnPropertyChange()
	self:OnReset()
end

-- =============================================================================
function AreaTrigger:OnReset()
	self.enabled = nil
	self.triggerOnce = tonumber(self.Properties.bTriggerOnce)~=0
	self.localOnly = self.Properties.MultiplayerOptions.bNetworked==false
	self.perPlayer = tonumber(self.Properties.MultiplayerOptions.bPerPlayer)~=0

	self.isServer=CryAction.IsServer()
	self.isClient=CryAction.IsClient()

	self.inside={}
	self.insideCount=0

	if (not self.localOnly) then
		self.triggeredPP={}
		self.triggeredOncePP={}
	else
		self:SetFlags(ENTITY_FLAG_CLIENT_ONLY,0)
	end

	self.triggeredOnce=nil
	self.triggered=nil

	self:Enable(self.Properties.bEnabled == true)
	self:ActivateOutput("IsInside", 0)
end

-- =============================================================================
function AreaTrigger:Enable(enable)
	self.enabled=enable
	self:RegisterForAreaEvents(enable and 1 or 0)
end

-- =============================================================================
function AreaTrigger:OnSpawn()
	self:OnReset()
end

-- =============================================================================
function AreaTrigger:OnSave(props)
	props.enabled = self.enabled
	props.triggered = self.triggered
	props.triggeredOnce = self.triggeredOnce
end

-- =============================================================================
function AreaTrigger:OnLoad(props)
	self:OnReset()
	self.enabled = props.enabled
	self.triggered = props.triggered
	self.triggeredOnce = props.triggeredOnce
end

-- =============================================================================
function AreaTrigger:CanTrigger(entityId)
	local entity=System.GetEntity(entityId)

	if (not entity) then return end

	local Properties = self.Properties

	if (Properties.bOnlyPlayers ~= 0 and (not entity.actor or not entity.actor:IsPlayer())) then
		return false
	end

	if (Properties.bOnlyLocalPlayer ~= 0 and entity ~= g_localActor) then
		return false
	end

	if (Properties.bInVehicleOnly ~= 0 and not entity.vehicleId) then
		return false
	end

	if (Properties.bCameraOnly ~=0 and entity.class ~= "CameraSource" ) then
      return false
	end

	if (Properties.esFactionFilter ~= "") then
		local faction = AI.GetFactionOf(entity.id) or ""
		if (faction ~= Properties.esFactionFilter) then
			return false
		end
	end

	return true
end

-- =============================================================================
function AreaTrigger:Trigger(entityId, enter)
	self:ActivateOutput("IsInside", self.insideCount)
	self:ActivateOutput("Sender", entityId or NULL_ENTITY)
	self:ActivateOutput("Faction", AI.GetFactionOf(entityId or NULL_ENTITY) or "")

	if (enter) then
		if(self.Properties.ScriptCommand and self.Properties.ScriptCommand~="")then
			local f = loadstring(self.Properties.ScriptCommand)
			if (f~=nil) then
				f()
			end
		end

		local entity = System.GetEntity(entityId)

		-- WH::PH trigger in quest system, self.QuestScriptCommand set from code in quest init
		if (self.QuestScriptCommand and self.QuestScriptCommand~="")then
			_EID = entityId
			local f = loadstring("local entityId=_EID; "..self.QuestScriptCommand)
			if (f~=nil) then
				f()
			end
		end

		if(self.Properties.PlaySequence~="")then
			Movie.PlaySequence(self.Properties.PlaySequence)
		end
	end
end

-- =============================================================================
function AreaTrigger:EnteredArea(entity, areaId)
	if (not self:CanTrigger(entity.id, areaId)) then
		return
	end

	self.inside[entity.id]=true
	self.insideCount=self.insideCount+1

	self:Event_Enter(entity.id)
end

-- =============================================================================
function AreaTrigger:LeftArea(entity, areaId)
	if (not self:CanTrigger(entity.id, areaId)) then
		return
	end

	self.inside[entity.id]=nil
	self.insideCount=self.insideCount-1

	self:Event_Leave(entity.id)
end

-- =============================================================================
function AreaTrigger.Server:OnEnterArea(entity, areaId)
	if (self:CanTrigger(entity.id)) then
		self:EnteredArea(entity, areaId)
	end
end

-- =============================================================================
function AreaTrigger.Server:OnLeaveArea(entity, areaId)
	self:LeftArea(entity, areaId)
end

-- =============================================================================
function AreaTrigger.Client:OnEnterArea(entity, areaId)
	if (not self:CanTrigger(entity.id)) then return end

	if (not self.localOnly or self.isServer) then return end

	self:EnteredArea(entity, areaId)
end

-- =============================================================================
function AreaTrigger.Client:OnLeaveArea(entity, areaId)
	if (not self.localOnly or self.isServer) then return end

	self:LeftArea(entity, areaId)
end

-- =============================================================================
function AreaTrigger:Event_Enter(entityId)
	if (not self.enabled) then return end -- TODO: might need a self.active here
	if (self.triggerOnce) then
		if (self.localOnly) then
			if (self.triggeredOnce) then
				return
			end
		elseif (self.perPlayer and self.triggeredOncePP[entityId]) then	-- TODO: will need to skip this for non-player entities
			return
		elseif (not self.perPlayer and self.triggeredOnce) then
			return
		end
	end

	self.triggered=true
	self.triggeredOnce=true

	if (not self.localOnly and entityId) then
		self.triggeredPP[entityId]=true
		self.triggeredOncePP[entityId]=true
	end

	self:Trigger(entityId, true)

	--EntityCommon.BroadcastEvent(self, "Enter")
	self:ActivateOutput("Enter", entityId or NULL_ENTITY)

	if (not self.localOnly and self.isServer) then
		self.otherClients:ClEnter(g_localChannelId, entityId or NULL_ENTITY, self.insideCount)
	end
end

-- =============================================================================
function AreaTrigger:Event_Leave(entityId)
	if (not self.enabled) then return end
	if (self.localOnly and not self.triggered) then return end

	if (self.perPlayer) then
		if (not self.localOnly and entityId) then
			if (not self.triggeredPP[entityId]) then return end
		end
	else
		if (not self.triggered) then return end
	end

	--only disable triggered when all players are gone
	if(self.insideCount == 0) then
		self.triggered=nil
	end

	if (not self.localOnly and entityId and self.insideCount == 0) then
		self.triggeredPP[entityId]=nil
	end

	self:Trigger(entityId, false)

	--EntityCommon.BroadcastEvent(self, "Leave")
	self:ActivateOutput("Leave", entityId or NULL_ENTITY)

	if (not self.localOnly and self.isServer) then
		self.otherClients:ClLeave(g_localChannelId, entityId or NULL_ENTITY, self.insideCount)
	end
end

-- =============================================================================
function AreaTrigger.Client:ClEnter(entityId, insideCount)
	self.insideCount = insideCount
	self.inside[entityId] = true

	self:Trigger(entityId, true)

	--EntityCommon.BroadcastEvent(self, "Enter")
	self:ActivateOutput("Enter", entityId)
end

-- =============================================================================
function AreaTrigger.Client:ClLeave(entityId, inside)
	self.insideCount = inside
	self.inside[entityId] = nil

	self:Trigger(entityId, false)

	self:ActivateOutput("Sender", entityId)
	self:ActivateOutput("IsInside", inside)

	--EntityCommon.BroadcastEvent(self, "Leave")
	self:ActivateOutput("Leave", entityId)
end

-- =============================================================================
function AreaTrigger:Event_Enable()
	self:Enable(true)

	local entityIdInside = next(self.inside)
	if (entityIdInside) then
	  self:Event_Enter( entityIdInside )
	end
  self:ActivateOutput("IsInside", self.insideCount)

	EntityCommon.BroadcastEvent(self, "Enable")
end

-- =============================================================================
function AreaTrigger:Event_Disable()
	self:Enable(false)

	EntityCommon.BroadcastEvent(self, "Disable")
end

-- =============================================================================
AreaTrigger.FlowEvents =
{
	Inputs =
	{
		Disable = { AreaTrigger.Event_Disable, "bool" },
		Enable = { AreaTrigger.Event_Enable, "bool" },
		Enter = { AreaTrigger.Event_Enter, "bool" },
		Leave = { AreaTrigger.Event_Leave, "bool" },
	},
	Outputs =
	{
		Disable = "bool",
		Enable = "bool",
		Enter = "entity",
		Leave = "entity",
		IsInside = "int",
		Sender = "entity",
		Faction = "string",
	},
}