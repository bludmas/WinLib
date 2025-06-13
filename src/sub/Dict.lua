local Dict = {}

function Dict:Get(Name: string): any
	if Name or type(Name) ~= "string" then
		local Mod = script:FindFirstChild(Name)
		
		if Mod and Mod:IsA("ModuleScript") then
			return require(Mod)
		else
			warn("No module found.")
		end
	else
		warn("Invalid Name.")
	end
end

return Dict
