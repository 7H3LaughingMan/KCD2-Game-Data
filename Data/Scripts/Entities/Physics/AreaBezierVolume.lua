AreaBezierVolume = {

  type = "AreaBezierVolume",
  Properties =
  {
  	bEnabled = true,
	MultiplayerOptions = {
		bNetworked		= false,
	},
  },
}

-- =============================================================================
function AreaBezierVolume:OnSpawn()
	if (self.Properties.MultiplayerOptions.bNetworked == false) then
		self:SetFlags(ENTITY_FLAG_CLIENT_ONLY,0)
	end
end

-- =============================================================================
function AreaBezierVolume:OnLoad(table)
  self.bEnabled = table.bEnabled
	if(self.bEnabled == true) then
		self:Event_Enable()
	else
		self:Event_Disable()
	end
end

-- =============================================================================
function AreaBezierVolume:OnSave(table)
  table.bEnabled = self.bEnabled
end

-- =============================================================================
function AreaBezierVolume:OnInit()
	if(self.Properties.bEnabled == true) then
		self:Event_Enable()
	else
		self:Event_Disable()
	end
end

-- =============================================================================
function AreaBezierVolume:OnPropertyChange()
	if(self.Properties.bEnabled == true) then
		self:Event_Enable()
	else
		self:Event_Disable()
	end
end

-- =============================================================================
function AreaBezierVolume:OnEnable(enable)
	--DebugUtils.Log("AreaBezierVolume:OnEnable")
	self:SetPhysicParams(PHYSICPARAM_FOREIGNDATA,{foreignData = ZEROG_AREA_ID})
end

-- =============================================================================
function AreaBezierVolume:Event_Enable()
	--self:TriggerEvent(AIEVENT_ENABLE)
	self.bEnabled = true
	EntityCommon.BroadcastEvent(self, "Enable")
end

-- =============================================================================
function AreaBezierVolume:Event_Disable()
	--self:TriggerEvent(AIEVENT_DISABLE)
	self.bEnabled = false
	EntityCommon.BroadcastEvent(self, "Disable")
end

-- =============================================================================
AreaBezierVolume.FlowEvents =
{
	Inputs =
	{
		Disable = { AreaBezierVolume.Event_Disable, "bool" },
		Enable = { AreaBezierVolume.Event_Enable, "bool" },
	},
	Outputs =
	{
		Disable = "bool",
		Enable = "bool",
	},
}