AudioUtils = {
	sObstructionCalcSwitchName = "ObstrOcclCalcType",
	sObstructionStateNames = {"Ignore", "SingleRay", "MultiRay"},
}

-- =============================================================================
function AudioUtils.LookupTriggerID(sTriggerName)
	local hTriggerID = nil

	if ((sTriggerName ~= nil) and (sTriggerName ~= "")) then
		hTriggerID = Sound.GetAudioTriggerID(sTriggerName)
	end

	return hTriggerID
end

-- =============================================================================
function AudioUtils.LookupRtpcID(sRtpcName)
	local hRtpcID = nil

	if ((sRtpcName ~= nil) and (sRtpcName ~= "")) then
		hRtpcID = Sound.GetAudioRtpcID(sRtpcName)
	end

	return hRtpcID
end

-- =============================================================================
function AudioUtils.LookupSwitchID(sSwitchName)
	local hSwitchID = nil

	if ((sSwitchName ~= nil) and (sSwitchName ~= "")) then
		hSwitchID = Sound.GetAudioSwitchID(sSwitchName)
	end

	return hSwitchID
end

-- =============================================================================
function AudioUtils.LookupSwitchStateIDs(hSwitchID, tStateNames)
	local tStateIDs = {}

	if ((hSwitchID ~= nil) and (tStateNames ~= nil)) then
		for i, name in ipairs(tStateNames) do
			tStateIDs[i] = Sound.GetAudioSwitchStateID(hSwitchID, name)
		end
	end

	return tStateIDs
end

-- =============================================================================
function AudioUtils.LookupAudioEnvironmentID(sEnvironmentName)
	local hEnvironmentID = nil

	if ((sEnvironmentName ~= nil) and (sEnvironmentName ~= "")) then
		hEnvironmentID = Sound.GetAudioEnvironmentID(sEnvironmentName)
	end

	return hEnvironmentID
end

-- =============================================================================
function AudioUtils.LookupObstructionSwitchAndStates()
	local nSwitch = AudioUtils.LookupSwitchID(AudioUtils.sObstructionCalcSwitchName)
	local tStates = AudioUtils.LookupSwitchStateIDs(nSwitch, AudioUtils.sObstructionStateNames)

	return {hSwitchID = nSwitch, tStateIDs = tStates}
end

-- =============================================================================
function AudioUtils.SetAudioTriggerParam(entity, param, value)
	local paramId = AudioUtils.LookupRtpcID(param)

	entity:SetAudioRtpcValue(paramId, value, entity:GetDefaultAuxAudioProxyID())
end

-- =============================================================================
function AudioUtils.SetAudioTriggerParamWUID(entity, param, value)
	AudioUtils.SetAudioTriggerParam(XGenAIModule.GetEntityByWUID(entity), param, value)
end

-- =============================================================================
function AudioUtils.PlayAudioTrigger(entity, param)
	entity:ExecuteAudioTrigger(AudioUtils.LookupTriggerID(param), entity:GetDefaultAuxAudioProxyID())
end

-- =============================================================================
function AudioUtils.PlayAudioTriggerWUID(entity, param)
	AudioUtils.PlayAudioTrigger(XGenAIModule.GetEntityByWUID(entity), param)
end