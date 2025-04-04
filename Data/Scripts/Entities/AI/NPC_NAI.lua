NPC_NAI = {
	ActionController = "Animations/Mannequin/ADB/kcd_male_controllerdefs.xml",
	AnimDatabase3P = "Animations/Mannequin/ADB/kcd_male_database.adb",
	--SoundDatabase = "Animations/Mannequin/ADB/humanSounds.adb",

	UseMannequinAGState = true,

	defaultSoulArchetype = "NPC",

	Properties = {
		esNavigationType = "MediumSizedCharacters",
		sWH_AI_EntityCategory = "",
		fileModel = "Objects/Characters/humans/male/skeleton/male.cdf",
		fileHitDeathReactionsParamsDataFile = "Libs/HitDeathReactionsData/HitDeathReactions_SkeletonMale.xml",
		esClothingConfig = "male2",
		voiceType = "enemy",
		esFaction = "Civilians",

		CharacterSounds =
		{
			footstepEffect = "footsteps_npc",			-- Footstep mfx library to use
			foleyEffect = "foley_npc",					-- Foley signal effect name
		},
	},

	gameParams =
	{
		inertia = 0.0, --the more, the faster the speed change: 1 is very slow, 10 is very fast already
		inertiaAccel = 0.0,
	},

	-- the AI movement ability
	AIMovementAbility =
	{
		pathFindPrediction = 0.5,		-- predict the start of the path finding in the future to prevent turning back when tracing the path.
		usePredictiveFollowing = 1,
		walkSpeed = 1.0, -- set up for humans
		runSpeed = 3.5,
		sprintSpeed = 6.4,
		b3DMove = 0,
		pathLookAhead = 1,
		pathRadius = 0.4,
		pathSpeedLookAheadPerSpeed = -1.5,
		cornerSlowDown = 0.75,
		maxAccel = 6.0,
		maneuverSpeed = 1.5,
		velDecay = 0.5,
		minTurnRadius = 0,	-- meters
		maxTurnRadius = 3,	-- meters
		maneuverTrh = 2.0,  -- when cross(dir, desiredDir) > this use manouvering
		resolveStickingInTrace = 1,
		pathRegenIntervalDuringTrace = 4,
		pathType = "AIPATH_HUMAN",
	},
}

-- =============================================================================
-- Note this is called before there's an entity is created, so mainly useful for inheritance
function NPC_NAI:InitNPC_NAI()
	self._Parent.Reset=self.Reset
	self.Reset=self.NullAI_Reset

	self._Parent.OnReset=self.OnReset
	self.OnReset=self.NullAI_OnReset

	self._Parent.ResetCommon=self.ResetCommon
	self.ResetCommon=self.NullAI_ResetCommon

	self._Parent.OnInit=self.OnInit
	self.OnInit=self.NullAI_OnInit

	self._Parent.SetActorModel=self.SetActorModel
	self.SetActorModel=self.NullAI_SetActorModel

	self._Parent.OnSpawn = self.OnSpawn
	self.OnSpawn = self.NullAI_OnSpawn;
end

-- =============================================================================
function NPC_NAI:NPC_NAI_Reset(isFromInit, isReload)
	self:NPC_NAI_ResetCommon(isFromInit, isReload)
end

-- =============================================================================
function NPC_NAI:NPC_NAI_OnReset(isFromInit, isReload)
	self.UpdateTime = 0.05

	self:NetPresent(1)
	self:SetScriptUpdateRate(self.UpdateTime)

	self:NPC_NAI_ResetCommon(isFromInit, isReload)
end

-- =============================================================================
function NPC_NAI:NPC_NAI_ResetCommon(isFromInit, isReload)
	self.AI = {}
end

-- =============================================================================
function NPC_NAI:NPC_NAI_OnInit(isReload)
	self.AI = {}

	if (not isReload or isReload == false) then
		BasicAI.RegisterAI(self)
	end

	self:NPC_NAI_OnReset(true, isReload)
end

-- =============================================================================
function NPC_NAI:RegisterAI(bForce)
	-- do nothing (null AI don't have AI objects)
end

-- =============================================================================
-- Compose entity
-- =============================================================================
table.Merge(
	NPC_NAI,
	BasicAIActions,
    BasicActor,
    BasicAI
)

EntityCommon.MakeSpawnable(NPC_NAI)