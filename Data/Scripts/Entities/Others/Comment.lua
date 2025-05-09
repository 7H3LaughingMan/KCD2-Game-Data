--  Crytek Source File.
--  Copyright (C), Crytek Studios, 2001-2004.

Comment =
{
	Properties =
	{
		bSaved_by_game = false,
		Text = "This is a comment",
		fSize = 1.2,	--[0.0, 100.0 , 0.1, ""]
		bHidden = false,
		fMaxDist = 100,	--[0.0 ,255.0 , 0.1, ""]
		nCharsPerLine = 30,	--[1, 255, 1, ""]
		bFixed = false,
		clrDiffuse = { x=1,y=0.5,z=0 },
	},

	Editor={
		Model="Editor/Objects/comment.cgf",
		Icon="Comment.bmp",
	},

	hidden = false,
	lines = {},
	lineCount = 0,
	fMaxDistSquared = 0,
	bNoUpdateInGame = 1,
}

-- =============================================================================
function Comment:OnLoad(table)
  self.hidden = table.hidden
end

-- =============================================================================
function Comment:OnSave(table)
  table.hidden = self.hidden
end

-- =============================================================================
function Comment:OnInit()
	-- Delete when not in dev-mode.
	if (not System.IsDevModeEnable() ) then
		self:DeleteThis()
		return
	end

	self:OnReset()
end

-- =============================================================================
function Comment:OnPropertyChange()
	self:OnReset()
end

-- =============================================================================
function Comment:OnReset()
	-- Comment is only Active(OnUpdate() will be called) when in Editor or when cl_comment > 0
	local cl_comment = System.GetCVar("cl_comment")
	if (System.IsEditor() or cl_comment > 0) then
--		self:SetUpdatePolicy( ENTITY_UPDATE_VISIBLE )
		self:Activate(1)
	else
		self:Activate(0)
	end

	-- bNoUpdateInGame is checked in OnUpdate() to account for in-editor game mode.
	if (cl_comment == 0) then
		self.bNoUpdateInGame = 1
	else
		self.bNoUpdateInGame = 0
	end

	self.fMaxDistSquared = self.Properties.fMaxDist * self.Properties.fMaxDist

	self.hidden = self.Properties.bHidden
	self.lines = {}

	-- process the text and line-break it
	local maxLength = self.Properties.nCharsPerLine
	local curLength = 0
	local curText = ""
	local curLine = 1

	for char in string.gfind(self.Properties.Text, ".") do
		if (char == " ") then
			-- word finished ... see if we are over the limit
			if (curLength > maxLength) then
				-- commit line
				self.lines[curLine] = curText
				curLine = curLine + 1
				curText = ""
				curLength = 0
				-- "consume" the whitespace
				char = ""
			end
		end
		if (char ~= "") then
			-- append char
			curText = curText..char
			curLength = curLength + 1
		end
	end

	self.lines[curLine] = curText
	self.lineCount = curLine

	self:OnUpdate(0)
end

-- =============================================================================
function Comment:OnUpdate(delta)
	if (self.hidden == true or self:IsHidden() or self.Properties.Text =="" or (self.bNoUpdateInGame == 1 and not System.IsEditing())) then
		return
	end

	-- calculate alpha
	local alpha = 0
	local factor = 0

	if (self.fMaxDistSquared>0) then
		local mypos = g_Vectors.temp_v1

		self:GetWorldPos(mypos)
		mypos = VectorUtils.Subtract(mypos, System.GetViewCameraPos())

		local distSquared = VectorUtils.LengthSquared(mypos)
		factor = distSquared

		if (self.Properties.fMaxDist >= 255.0) then
			alpha = 1.0
		elseif (distSquared<self.fMaxDistSquared) then
			alpha = distSquared/self.fMaxDistSquared
			alpha = 1.0 - alpha*alpha
		end
	end

	-- draw text
	local increment = System.GetViewCameraUpDir()

	if (alpha>0.001) then
		local pos = self:GetWorldPos( g_Vectors.temp_v1 )

		factor = math.sqrt(factor)
		factor = (self.Properties.fSize/60) * factor * System.GetViewCameraFov()

		local incrementAll = g_Vectors.temp_v4
		increment = VectorUtils.Scale(increment, factor)
		incrementAll = VectorUtils.Scale(increment, (self.lineCount / 2 + 1))

		-- start all the way at the top
		pos = VectorUtils.Sum(pos, incrementAll)

		local textColor = { x=0, y=1, z=0 };	-- default color is for (bFixed == true)
		if (self.Properties.bFixed == false) then
			textColor = {x=self.Properties.clrDiffuse.x, y=self.Properties.clrDiffuse.y, z=self.Properties.clrDiffuse.z}
		end

		for i,val in ipairs(self.lines) do
			System.DrawLabel( pos, self.Properties.fSize, val, textColor.x, textColor.y, textColor.z, alpha )
			-- decrement the increment
			pos = VectorUtils.Subtract(pos, increment)
		end
	end
end

-- =============================================================================
function Comment:Event_UnHide(sender)
	EntityCommon.BroadcastEvent(self, "UnHide")
	self.hidden = false
end

-- =============================================================================
function Comment:Event_Hide(sender)
	EntityCommon.BroadcastEvent(self, "Hide")
	self.hidden = true
end

-- =============================================================================
Comment.FlowEvents =
{
	Inputs =
	{
		Hide = { Comment.Event_Hide, "bool" },
		UnHide = { Comment.Event_UnHide, "bool" },
	},
	Outputs =
	{
		Hide = "bool",
		UnHide = "bool",
	},
}