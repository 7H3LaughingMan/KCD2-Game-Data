--	Crytek Source File.
-- 	Copyright (C), Crytek Studios, 2001-2005.

ScriptCommand = {
	Category = "advanced",
	Inputs = {{"t_Activate","bool"},{"Command","string"}},
	Outputs = {{"Done","bool"}},
	Implementation=function(bActivate,sCommand)
		if(sCommand~="")then
			local f=loadstring(sCommand)
			if (f~=nil) then
				f()
				return 1
			else
				return 0
			end
		else
			return 0
		end
	end
}
