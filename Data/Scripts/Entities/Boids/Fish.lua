Fish =
{
	type = "Fish",
	MapVisMask = 0,
	ENTITY_DETAIL_ID = 1,

	Properties = {
		Flocking =
		{
			bEnableFlocking = false,
			FieldOfViewAngle = 250,
			FactorAlign = 0,
			FactorCohesion = 1,
			FactorSeparation = 10,
			AttractDistMin = 5,
			AttractDistMax = 20,
		},
		Movement =
		{
			HeightMin = 1,
			HeightMax = 20,
			SpeedMin = 0.3,
			SpeedMax = 0.9,
			SpeedScared = 10.0,
			FactorOrigin = 0.2,
			FactorHeight = 1,
			FactorAvoidLand = 10,
			FactorRandomAcceleration = 2,
			MaxAnimSpeed = 1.7,
		},
		Boid =
		{
			nCount = 5, --[0,1000,1,"Specifies how many individual objects will be spawned."]
			object_Model = "objects/characters/animals/fish/salmo_trutta.cdf",
			gravity_at_death = -9.81,
			Mass = 10,
			bInvulnerable = false,

			guidItemSpawnedOnKill = "06be2a3d-4e05-4a78-85cd-33879cd669c9",
		},
		Options =
		{
			bPickableWhenAlive = false,
			bPickableWhenDead = true,
			bFollowPlayer = false,
			bNoLanding = false,
			bObstacleAvoidance = false,
			VisibilityDist = 15,
			bActivate = true,
			Radius = 5,
		},
	},

	Editor =
	{
		Icon = "Fish.bmp"
	},

	Animations =
	{
		"fish_anim",   -- swimming
	},

	BubblesEffect = "",		-- Underwater bubbles for fish breathing
	SplashEffect = "",		-- Splash when fish touches water surface

	params={x=0,y=0,z=0},
	bubble_pos={x=0,y=0,z=0},
	bubble_dir={x=0,y=0,z=1},
}

-- =============================================================================
--function Birds:OnLoad(table)
--end

-- =============================================================================
--function Birds:OnSave(table)
--end

-- =============================================================================
function Fish:OnSpawn()
	self:SetFlags(ENTITY_FLAG_CLIENT_ONLY, 0)
  self:SetFlagsExtended(ENTITY_FLAG_EXTENDED_NEEDS_MOVEINSIDE, 0)
end

-- =============================================================================
function Fish:OnInit()

	self:NetPresent(0)
	--self:EnableSave(1)

	self.flock = 0
	self:CreateFlock()
	if (self.Properties.Options.bActivate == false and self.flock == true) then
		Boids.EnableFlock( self,0 )
		self:RegisterForAreaEvents(0)
	end

	self:CacheResources()
end

-- =============================================================================
function Fish:CacheResources()
	self:PreLoadParticleEffect( self.BubblesEffect )
	self:PreLoadParticleEffect( self.SplashEffect )
end

-- =============================================================================
function Fish:CreateFlock()
	local Flocking = self.Properties.Flocking
	local Movement = self.Properties.Movement
	local Boid = self.Properties.Boid
	local Options = self.Properties.Options

	local params = self.params

	params.count = math.max(0, Boid.nCount)
	params.model = Boid.object_Model

	params.boid_size = 1
	params.boid_size_random = 0
	params.min_height = Movement.HeightMin
	params.max_height = Movement.HeightMax
	params.min_attract_distance = Flocking.AttractDistMin
	params.max_attract_distance = Flocking.AttractDistMax
	params.min_speed = Movement.SpeedMin
	params.max_speed = Movement.SpeedMax
	params.scared_speed = Movement.SpeedScared

	if (Flocking.bEnableFlocking == true) then
		params.factor_align = Flocking.FactorAlign
	else
		params.factor_align = 0
	end
	params.factor_cohesion = Flocking.FactorCohesion
	params.factor_separation = Flocking.FactorSeparation
	params.factor_origin = Movement.FactorOrigin
	params.factor_keep_height = Movement.FactorHeight
	params.factor_avoid_land = Movement.FactorAvoidLand
	params.factor_random_accel = Movement.FactorRandomAcceleration

	params.spawn_radius = Options.Radius
	params.gravity_at_death = Boid.gravity_at_death
	params.boid_mass = Boid.Mass
	params.invulnerable = Boid.bInvulnerable
	params.ondeath_item = Boid.guidItemSpawnedOnKill

	params.fov_angle = Flocking.FieldOfViewAngle

	params.max_anim_speed = Movement.MaxAnimSpeed
	params.follow_player = Options.bFollowPlayer
	params.no_landing = Options.bNoLanding
	params.avoid_obstacles = Options.bObstacleAvoidance
	params.max_view_distance = Options.VisibilityDist

	if (self.flock == 0) then
		self.flock = 1
		Boids.CreateFlock( self, Boids.FLOCK_FISH, params )
	end
	if (self.flock ~= 0) then
		Boids.SetFlockParams( self, params )
	end
end

-- =============================================================================
function Fish:OnPropertyChange()
	if (self.Properties.Options.bActivate == true) then
		self:CreateFlock()
		self:Event_Activate()
	else
		self:Event_Deactivate()
	end
end

-- =============================================================================
function Fish:OnSpawnBubble( pos )
	Particle.SpawnEffect( self.BubblesEffect,pos,self.bubble_dir )
end

-- =============================================================================
function Fish:OnSpawnSplash( pos )
	Particle.SpawnEffect( self.SplashEffect,pos,self.bubble_dir )
end

-- =============================================================================
function Fish:Event_Activate()
	if (self.flock ~= 0) then
		Boids.EnableFlock( self,1 )
		self:RegisterForAreaEvents(1)
	end
end

-- =============================================================================
function Fish:Event_Deactivate()
	if (self.flock ~= 0) then
		Boids.EnableFlock( self,0 )
		self:RegisterForAreaEvents(0)
	end
end

-- =============================================================================
function Fish:OnProceedFadeArea( player,areaId,fadeCoeff )
	if (self.flock ~= 0) then
		Boids.SetFlockPercentEnabled( self,fadeCoeff*100 )
	end
end

-- =============================================================================
Fish.FlowEvents =
{
	Inputs =
	{
		Activate = { Fish.Event_Activate, "bool" },
		Deactivate = { Fish.Event_Deactivate, "bool" },
	},
	Outputs =
	{
		Activate = "bool",
		Deactivate = "bool",
	},
}
