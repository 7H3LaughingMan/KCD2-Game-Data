-- =============================================================================
-- Audio area ambience entity - to be attached to an area
-- Used for convenient implementation of area based audio ambiences
-- =============================================================================
AudioAreaAmbience = {
	type = "AudioAreaAmbience",

	Editor={
		Model="Editor/Objects/Sound.cgf",
		Icon="AudioAreaAmbience.bmp",
	},

	Properties = {
		bSaved_by_game = false,
		bEnabled = true,
		audioTriggerPlayTrigger = "",
		audioTriggerStopTrigger = "",
		audioRTPCRtpc = "",
		audioEnvironmentEnvironment = "",
		eiSoundObstructionType = 1, -- Clamped between 1 and 3. 1=Ignore, 2=SingleRay, 3=MultiRay
		fRtpcDistance = 5.0, -- The RTPC distance also determines the rate of fadeout when entering inner shapes with higher priorities
		fEnvironmentDistance = 5.0,
		audioRTPCGlobalRtpc = "",
	},

	fFadeValue = 0.0,
	nState = 0, -- 0 = far, 1 = near, 2 = inside
	fFadeOnUnregister = 1.0,
	hOnTriggerID = nil,
	hOffTriggerID = nil,
	hCurrentOnTriggerID = nil,
	hCurrentOffTriggerID = nil, -- only used in OnPropertyChange()
	hRtpcID = nil,
	hGlobalRtpcID = nil,
	hEnvironmentID = nil,
	tObstructionType = {},
	bIsHidden = false,
	bIsPlaying = false,
	bOriginalEnabled = true,
}

-- =============================================================================
function AudioAreaAmbience:_LookupControlIDs()
	self.hOnTriggerID = AudioUtils.LookupTriggerID(self.Properties.audioTriggerPlayTrigger)
	self.hOffTriggerID = AudioUtils.LookupTriggerID(self.Properties.audioTriggerStopTrigger)
	self.hRtpcID = AudioUtils.LookupRtpcID(self.Properties.audioRTPCRtpc)
	self.hGlobalRtpcID = AudioUtils.LookupRtpcID(self.Properties.audioRTPCGlobalRtpc)
	self.hEnvironmentID = AudioUtils.LookupAudioEnvironmentID(self.Properties.audioEnvironmentEnvironment)
end

-- =============================================================================
function AudioAreaAmbience:_LookupObstructionSwitchIDs()
	-- cache the obstruction switch and state IDs
	self.tObstructionType = AudioUtils.LookupObstructionSwitchAndStates()
end

-- =============================================================================
function AudioAreaAmbience:_SetObstruction()
	local nStateIdx = self.Properties.eiSoundObstructionType

	if ((self.tObstructionType.hSwitchID ~= nil) and (self.tObstructionType.tStateIDs[nStateIdx] ~= nil)) then
		self:SetAudioSwitchState(self.tObstructionType.hSwitchID, self.tObstructionType.tStateIDs[nStateIdx], self:GetDefaultAuxAudioProxyID())
	end
end

-- =============================================================================
function AudioAreaAmbience:_DisableObstruction()
	-- Ignore is at index 1
	local nStateIdx = 1

	if ((self.tObstructionType.hSwitchID ~= nil) and (self.tObstructionType.tStateIDs[nStateIdx] ~= nil)) then
		self:SetAudioSwitchState(self.tObstructionType.hSwitchID, self.tObstructionType.tStateIDs[nStateIdx], self:GetDefaultAuxAudioProxyID())
	end
end

-- =============================================================================
function AudioAreaAmbience:_UpdateParameters()
	-- Set the distances as the very first thing!
	self:SetFadeDistance(self.Properties.fRtpcDistance)
	self:SetEnvironmentFadeDistance(self.Properties.fEnvironmentDistance)

	if (self.Properties.bEnabled) then
		if (self.hEnvironmentID ~= nil) then
			self:SetAudioEnvironmentID(self.hEnvironmentID)
		end
	else
		self:SetAudioEnvironmentID(INVALID_AUDIO_ENVIRONMENT_ID)
	end
end

-- =============================================================================
function AudioAreaAmbience:_UpdateRtpc()
	if (self.hRtpcID ~= nil) then
		self:SetAudioRtpcValue(self.hRtpcID, self.fFadeValue, self:GetDefaultAuxAudioProxyID())
	end
	if (self.hGlobalRtpcID ~= nil) then
		Sound.SetAudioRtpcValue(self.hGlobalRtpcID, self.fFadeValue)
	end
end

-- =============================================================================
function AudioAreaAmbience:OnSpawn()
	self:SetFlags(ENTITY_FLAG_CLIENT_ONLY, 0)
end

-- =============================================================================
function AudioAreaAmbience:OnLoad(load)
	self.fFadeValue = load.fFadeValue
	self.fFadeOnUnregister = load.fFadeOnUnregister
	self.nState = 0; -- We start out being far, in a subsequent update we will determine our actual state!
end

-- =============================================================================
function AudioAreaAmbience:OnPostLoad()
	self:_UpdateParameters()
end

-- =============================================================================
function AudioAreaAmbience:OnSave(save)
	save.fFadeValue = self.fFadeValue
	save.fFadeOnUnregister = self.fFadeOnUnregister
end

-- =============================================================================
function AudioAreaAmbience:OnPropertyChange()
	if (self.Properties.eiSoundObstructionType < 1) then
		self.Properties.eiSoundObstructionType = 1
	elseif (self.Properties.eiSoundObstructionType > 3) then
		self.Properties.eiSoundObstructionType = 3
	end

	self:_LookupControlIDs()
	self:_UpdateParameters()
	self:SetCurrentAudioEnvironments()
	self:SetAudioProxyOffset(g_Vectors.v000, self:GetDefaultAuxAudioProxyID())

	if (self.nState == 1) then -- near
		self:_SetObstruction()
	elseif (self.nState == 2) then -- inside
		self:_DisableObstruction()
	end

	if ((self.bIsPlaying) and (self.hCurrentOnTriggerID ~= self.hOnTriggerID)) then
		-- Stop a possibly playing instance if the on-trigger changed!
		self:StopAudioTrigger(self.hCurrentOnTriggerID, self:GetDefaultAuxAudioProxyID())
		self.hCurrentOnTriggerID = self.hOnTriggerID
		self.bIsPlaying = false
		self.bHasMoved = false
	end

	if (not self.bIsPlaying) then
		-- Try to play, if disabled, hidden or invalid on-trigger Play() will fail!
		self:Play()
	end

	if (not self.Properties.bEnabled and ((self.bOriginalEnabled) or (self.hCurrentOffTriggerID ~= self.hOffTriggerID))) then
		self.hCurrentOffTriggerID = self.hOffTriggerID
		self:Stop(); -- stop if disabled, either stops running StartTrigger or executes StopTrigger!
	end

	self.bOriginalEnabled = self.Properties.bEnabled
end

-- =============================================================================
function AudioAreaAmbience:OnReset(bToGame)
	if (bToGame) then
		-- store the entity's "bEnabled" property's value so we can adjust back to it if changed over the course of the game
		self.bOriginalEnabled = self.Properties.bEnabled

		-- re-execute this AAA once upon entering game mode
		self:Stop()
		self:Play()
	else
		self.Properties.bEnabled = self.bOriginalEnabled
	end
end

-- =============================================================================
function AudioAreaAmbience:Play()
	if ((self.hOnTriggerID ~= nil) and (self.Properties.bEnabled) and (not self.bIsHidden) and ((self.nState == 1) or ((self.nState == 2)))) then
		self:SetCurrentAudioEnvironments()
		self:ExecuteAudioTrigger(self.hOnTriggerID, self:GetDefaultAuxAudioProxyID())
		self.bIsPlaying = true
		self.hCurrentOnTriggerID = self.hOnTriggerID
	end
end

-- =============================================================================
function AudioAreaAmbience:Stop()
	if (not self.bIsHidden and ((self.nState == 1) or ((self.nState == 2)))) then
		-- cannot check against "self.bIsPlaying" otherwise we won't execute the StopTrigger if there's no StartTrigger set!
		if (self.hOffTriggerID ~= nil) then
			self:ExecuteAudioTrigger(self.hOffTriggerID, self:GetDefaultAuxAudioProxyID())
		elseif (self.hOnTriggerID ~= nil) then
			self:StopAudioTrigger(self.hOnTriggerID, self:GetDefaultAuxAudioProxyID())
		end
	end

	self.bIsPlaying = false
end

-- =============================================================================
function AudioAreaAmbience:CliSrv_OnInit()
	self.nState = 0
	self.fFadeValue = 0.0
	self.fFadeOnUnregister = 1.0
	self:SetFlags(ENTITY_FLAG_VOLUME_SOUND,0)
	self:_UpdateParameters()
	self.bIsPlaying = false
	self:NetPresent(0)
end

-- =============================================================================
function AudioAreaAmbience:UpdateFadeValue(player, fFade, fDistSq)
	if (not(self.Properties.bEnabled) or (fFade == 0.0 and fDistSq == 0.0)) then
		self.fFadeValue = 0.0
		self:_UpdateRtpc()
		do return end
	end

	if (self.Properties.fRtpcDistance > 0.0) then
		if (self.nState == 2) then
			if (self.fFadeValue ~= fFade) then
				self.fFadeValue = fFade
				self:_UpdateRtpc()
			end
		else
			self.fFadeValue = fFade
			self:_UpdateRtpc()
		end
	end
end

-- =============================================================================
AudioAreaAmbience.Server={
	-- =============================================================================
	OnInit = function(self)
		self:CliSrv_OnInit()
	end,

	-- =============================================================================
	OnShutDown = function(self)
	end,
}

-- =============================================================================
AudioAreaAmbience.Client={
	-- =============================================================================
	OnInit = function(self)
		self:RegisterForAreaEvents(1)
		self:_LookupControlIDs()
		self:_LookupObstructionSwitchIDs()
		self:_SetObstruction()
		self:CliSrv_OnInit()
	end,

	-- =============================================================================
	OnShutDown = function(self)
		self:Stop()
		self.nState = 0
		self:RegisterForAreaEvents(0)
	end,

	-- =============================================================================
	OnHidden = function(self)
		self:Stop()
		self.bIsHidden = true
	end,

	-- =============================================================================
	OnUnHidden = function(self)
		self.bIsHidden = false
		self:Play()
	end,

	-- =============================================================================
	OnAudioListenerEnterNearArea = function(self, player, nAreaID, fFade)
		if (self.nState == 0) then
			self.nState = 1
			self:Play()
			self.fFadeValue = 0.0
			self:_UpdateRtpc()
		end
	end,

	-- =============================================================================
	OnAudioListenerMoveNearArea = function(self, player, areaId, fFade, fDist)
		self.nState = 1
		if (self.Properties.fRtpcDistance > 0) then
			local actualFadeValue = (self.Properties.fRtpcDistance - fDist) / self.Properties.fRtpcDistance
			if (actualFadeValue < 0) then
				actualFadeValue = 0.0
			end
			self:UpdateFadeValue(player, actualFadeValue, 0.0)
		end
	end,

	-- =============================================================================
	OnAudioListenerEnterArea = function(self, player, areaId, fFade)
		if (self.nState == 0) then
			-- possible if the listener is teleported or gets spawned inside the area
			-- technically, the listener enters the Near Area and the Inside Area at the same time
			self.nState = 2
			self:Play()
		else
			self.nState = 2
		end

		self.fFadeValue = 1.0
		self:_UpdateRtpc()
		self:_DisableObstruction()
	end,

	-- =============================================================================
	OnAudioListenerProceedFadeArea = function(self, player, areaId, fExternalFade, fDistance)
		local fade = 0
		local inner_fade_distance = self.Properties.fRtpcDistance;
		if (inner_fade_distance > 0) then
			fade = (inner_fade_distance - fDistance) / inner_fade_distance;
			if (fade < 0) then fade = 0 end
		else
			fade = fExternalFade
		end

		if fExternalFade > fade then fade = fExternalFade end

		if (fade > 0) then
			self.nState = 2
			self:UpdateFadeValue(player, fade, 0.0)
		else
			self:UpdateFadeValue(player, 0.0, 0.0)
		end
	end,

	-- =============================================================================
	OnAudioListenerLeaveArea = function(self, player, nAreaID, fFade)
		self.nState = 1
		self:_SetObstruction()
	end,

	-- =============================================================================
	OnAudioListenerLeaveNearArea = function(self, player, nAreaID, fFade)
		self:Stop()
		self.nState = 0
		self.fFadeValue = 0.0
		self:_UpdateRtpc()
	end,

	-- =============================================================================
	OnBindThis = function(self)
		self:RegisterForAreaEvents(1)
	end,

	-- =============================================================================
	OnUnBindThis = function(self)
		self:Stop()
		self.nState = 0
		self:RegisterForAreaEvents(0)
	end,

	-- =============================================================================
	OnSoundDone = function(self, hTriggerID)
		if (self.hOnTriggerID == hTriggerID) then
			self:ActivateOutput( "Done",true )
		end
	end,
}

-- =============================================================================
-- Event Handlers
-- =============================================================================
function AudioAreaAmbience:Event_Enable(sender)
	self.Properties.bEnabled = true
	self:OnPropertyChange()
end

-- =============================================================================
function AudioAreaAmbience:Event_Disable(sender)
	self.Properties.bEnabled = false
	self:OnPropertyChange()
end

-- =============================================================================
AudioAreaAmbience.FlowEvents =
{
	Inputs =
	{
		Enable = { AudioAreaAmbience.Event_Enable, "bool" },
		Disable = { AudioAreaAmbience.Event_Disable, "bool" },
	},

	Outputs =
	{
	  Done = "bool",
	},
}
