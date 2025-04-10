WaterVolume =
{
	type = "WaterVolume",

	Properties =
	{
		StreamSpeed = 0,
		FogDensity = 0.5,
		color_FogColor = {x=0.005,y=0.01,z=0.02},
		FogColorMultiplier = 0.5,
		bFogColorAffectedBySun = true,
		FogShadowing = 0.5,
		bCapFogAtVolumeDepth = false,
		bCaustics = true,
		CausticIntensity = 1,
		CausticTiling = 1,
		CausticHeight = 0.5,
		UScale = 1,
		VScale = 1,
		Depth = 5,
		ViewDistanceRatio = 100,
		MinSpec = 0,
		MaterialLayerMask = 0,
		bAwakeAreaWhenMoving = false, -- Entities in area are physically awake when game volume is moving
		bIsRiver = false,
		MultiplayerOptions =
		{
			bNetworked		= false,
		},
	},

	Editor =
	{
		Model = "Editor/Objects/T.cgf",
		Icon = "Water.bmp",
		ShowBounds = 1,
		IsScalable = false,
		IsRotatable = true,
	},
}

-- =============================================================================
function WaterVolume:OnSpawn()
	if (self.Properties.MultiplayerOptions.bNetworked == false) then
		self:SetFlags(ENTITY_FLAG_CLIENT_ONLY,0)
	end
end

-- =============================================================================
function WaterVolume:OnPropertyChange()

end

-- =============================================================================
function WaterVolume:IsShapeOnly()
	return 1
end

-- =============================================================================
function WaterVolume:Event_Hide()
	self:Hide(1)
	self:ActivateOutput( "Hidden", true )
end

-- =============================================================================
function WaterVolume:Event_UnHide()
	self:Hide(0)
	self:ActivateOutput( "UnHidden", true )
end

-- =============================================================================
function WaterVolume:Event_PhysicsEnable()
	Game.SendEventToGameObject( self.id, "PhysicsEnable" )
end

-- =============================================================================
function WaterVolume:Event_PhysicsDisable()
	Game.SendEventToGameObject( self.id, "PhysicsDisable" )
end

-- =============================================================================
WaterVolume.FlowEvents =
{
	Inputs =
	{
		Hide = { WaterVolume.Event_Hide, "bool" },
		UnHide = { WaterVolume.Event_UnHide, "bool" },
		PhysicsEnable = { WaterVolume.Event_PhysicsEnable, "bool" },
		PhysicsDisable = { WaterVolume.Event_PhysicsDisable, "bool" },
	},
	Outputs =
	{
		Hidden = "bool",
		UnHidden = "bool",
	},
}