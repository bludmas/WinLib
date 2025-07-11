--[[
 .----------------.  .----------------.  .-----------------. .----------------.  .----------------.  .----------------. 
| .--------------. || .--------------. || .--------------. || .--------------. || .--------------. || .--------------. |
| | _____  _____ | || |     _____    | || | ____  _____  | || |   _____      | || |     _____    | || |   ______     | |
| ||_   _||_   _|| || |    |_   _|   | || ||_   \|_   _| | || |  |_   _|     | || |    |_   _|   | || |  |_   _ \    | |
| |  | | /\ | |  | || |      | |     | || |  |   \ | |   | || |    | |       | || |      | |     | || |    | |_) |   | |
| |  | |/  \| |  | || |      | |     | || |  | |\ \| |   | || |    | |   _   | || |      | |     | || |    |  __'.   | |
| |  |   /\   |  | || |     _| |_    | || | _| |_\   |_  | || |   _| |__/ |  | || |     _| |_    | || |   _| |__) |  | |
| |  |__/  \__|  | || |    |_____|   | || ||_____|\____| | || |  |________|  | || |    |_____|   | || |  |_______/   | |
| |              | || |              | || |              | || |              | || |              | || |              | |
| '--------------' || '--------------' || '--------------' || '--------------' || '--------------' || '--------------' |
'----------------'  '----------------'  '----------------'  '----------------'  '----------------'  '----------------' 

Created by @WindowUser2

- A simple library module

]]
--!strict

--// SERVICES

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")

--// MODULE

local Lib = {
	Debugging = true;
	CheckForVersions = true;
	
	AI_ClearMessagesAfter = 500; -- To solve some issues
}

--// MODULES

local Dict = require(script.Dict)
local Types = require(script.Types)
local DictNames = Dict:Get("Names")
local TeamNames = Dict:Get("TeamNames")

--// VARIABLES

local Format, Yield, require, Char, ArrayInsert, Match = string.format, task.wait, require, string.char, table.insert, string.match
local Traceback, RGB = debug.traceback, Color3.fromRGB
local Huge, Vector, Cosine, Sine, ACosine, SquareRoot = math.huge, Vector3.new, math.cos, math.sin, math.acos, math.sqrt
local Randomizer = Random.new()

local Tau = 2*math.pi
local RoundEquation = 2^52 + 2^51

local DefaultParams = RaycastParams.new()

local StudConverter = 0.28
local FootConverter = 3.281
local InchesConverter = 39.37

local StalkDir = Vector3.new(0, -10e4, 0)

local ApplicJSON = Enum.HttpContentType.ApplicationJson

local MaleNames = DictNames.Males
local FemaleNames = DictNames.Females
local Surnames = DictNames.Surnames

--// TYPES

type DiscordWebhook = Types.DiscordWebhook
type AI = Types.AI

--// FUNCTIONS

--\\ PRIVATE

local function Debug(Message: string, TracebackMsg: boolean | nil)
	if Lib.Debugging then
		if TracebackMsg then
			print(Traceback(Message))
		else
			print(Message)
		end
	end
end

local function CheckVersion()
	if script:HasTag("VersionChecked") then
		return
	end
	local CurrentVersion = script:GetAttribute("Version")
	
	if not CurrentVersion then
		warn("There's no version attribute, why did you delete it..?")
		return
	end
	
	local ModuleVersion = require(123399476691947) -- Ignore yellow mark, annoying >:(
	
	if ModuleVersion and type(ModuleVersion) == "string" then
		if CurrentVersion == ModuleVersion then
			Debug("No new updates for this module.", false)
		else
			warn(Format("New update! (%s) Please update the module named \"WinLib\".", ModuleVersion))
		end
		script:AddTag("VersionChecked")
	else
		warn("Something went wrong trying to check for the version.")
	end
end

local function TableIsEmpty(Tb: { any })
	return next(Tb) == nil
end

local function GetAmountKeysAndFirstKeyStored(Tb: { any }): (number, any | nil)
	if TableIsEmpty(Tb) then return 0 end
	
	local I = 0
	local F = nil
	for n, v in pairs(Tb) do
		I += 1
		if I == 1 then
			F = n
		end
	end
	
	return I, F
end

local function GetRandomFromArray(Array: { any }): any
	return Array[Randomizer:NextInteger(1, #Array)] or warn("Invalid table provided.")
end

--\\ PUBLIC

-- HTTP and Web

--[[
Webhook Creating function

You should note that you can find the ID and Token from your webhook's url
Remember to keep the url safe!

@param ID - The ID of your webhook.
@param Token - The Token of your webhook.
]]
function Lib.CreateWebhook(ID: string, Token: string): DiscordWebhook
	local NewWebhook: DiscordWebhook = {
		URL = Format("https://webhook.lewisakura.moe/api/webhooks/%s/%s", ID, Token)
	}
	
	return NewWebhook
end

--[[
Webhook Posting function

@param Webhook - The "premade" variable with the type "DiscordWebhook" (Use the CreateWebhook function if not already)
@param Message - The message your webhook should send.
]]
function Lib.WebhookPost(Webhook: DiscordWebhook, Message: string): (boolean, string | nil)
	local Success, Response = pcall(function()
		HttpService:PostAsync(Webhook.URL,
			HttpService:JSONEncode({
				content = Message
			})
		)
	end)
	
	return Success, Response
end

--[[
AI Creating (using Gemini 1.5 Flash) function

Get your API key here: https://aistudio.google.com/app/apikey

TextFormat Arguments:
1 - Instructions (aka Personality)
2 - History/Memory (in text)
3 - The messager, who sent it.
4 - The prompt

@param APIKey - The API key
@param Instructions - The AI instructions (or aka personality) to set as. This is optional.
@param TextFormat - How should the text be formatted as? (optional)
]]
function Lib.CreateAI(APIKey: string, Instructions: string | nil, TextFormat: string | nil): AI | nil
	if not APIKey or type(APIKey) ~= "string" then
		warn("No API key/Invalid API Key.")
		return
	end
	if Instructions and (Instructions == "" or type(Instructions) ~= "string") then
		if Instructions ~= "" then
			warn("Invalid Instructions.")
		end
		Instructions = "You are an helpful AI assistant."
	elseif not Instructions then
		Debug("Default instructions selected.")
		Instructions = "You are an helpful AI assistant."
	end
	
	local NewAI: AI = {
		History = {};
		URL = "https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key="..APIKey,
		Instructions = Instructions or "You are an helpful AI assistant."; -- to get rid of a annoying yellow checkmark
		MainFormat = TextFormat or "[Instructions] %s \n [History] %s \n [Current Interaction] %s tells you: %s"
	}
	
	return NewAI
end

--[[
AI Generating (using Gemini 1.5 Flash) function

@param AI - The variable of AI type
@param Prompt - What should the prompt be?
@param AddToHistory - Should this be added to the memory/history? (optional)
@param Messager - Who said the prompt? An addition to "AddToHistory". (optional)
]]
function Lib.GenerateAI(AI: AI, Prompt: string, AddToHistory: boolean | nil, Messager: string | nil): string | nil
	if AI == nil then
		warn("AI is nil.")
		return
	elseif Prompt == "" then
		warn("Prompt cannot be empty.")
		return
	elseif Messager == "" then
		warn("Messager cannot be empty.")
		return
	end
	
	local HistoryText = ""
	
	if TableIsEmpty(AI.History) then
		Debug("History is empty, Set to \"None\"")
		HistoryText = "None"
	else
		for i, v in pairs(AI.History) do
			local N1 = v[1]
			local N2 = v[2]
			
			if N1 and N2 then
				HistoryText = Format("%s\n[Timestamp: +%is CPU Time]\n%s\n%s", HistoryText, i, N1, N2)
			end
		end
	end
	
	local Len, First = GetAmountKeysAndFirstKeyStored(AI.History)
	if Len >= Lib.AI_ClearMessagesAfter and First then
		Debug("Len is over limit, deleting first key.")
		AI.History[First] = nil
	end
	
	local Text = Format(AI.MainFormat, AI.Instructions, HistoryText, Messager or "Someone", Prompt)

	local RequestBody = HttpService:JSONEncode({
		contents = {
			{
				parts = {
					{ text = Text}
				}
			}
		}
	})

	local S, R = pcall(function()
		return HttpService:PostAsync(AI.URL, RequestBody, ApplicJSON, false)
	end)

	-- Handle the response
	if S then
		local Decoded = HttpService:JSONDecode(R)

		local FinalMessage

		for index,text in pairs(Decoded["candidates"][1]["content"]["parts"][1]) do
			FinalMessage = text
		end
		
		if AddToHistory then
			AI.History[time()] = {
				[1] = Format("User (%s): %s", Messager or "Someone", Prompt);
				[2] = Format("You: %s", FinalMessage);
			}
		end
		
		Debug(FinalMessage)
		
		return FinalMessage
	else
		warn("A problem has occured while trying to AI generate text: "..R)
	end
	
	return "HTTP Error"
end

-- Simple Game Functions

--[[
Attempting Function

Repeats a process over and over again until its succesfull or reached max attempts.

@param Function - Your function that should run
@param DelayTime - The delaytime between attempts (DEFAULT: 1)
@param MaxAttempts - Maximum attempts to run the function (DEFAULT: 15)
]]
function Lib.AttemptFunction(Function: () -> any, DelayTime: number, MaxAttempts: number)
	assert(Function, "No function provided.")
	
	if not DelayTime then DelayTime = 1 end
	if not MaxAttempts then MaxAttempts = 15 end
	
	local function Call()
		local S, R = pcall(Function)
		return S, R
	end
	
	local Worked, Response = Call()
	
	if not Worked then
		Debug(Response)
		
		local I = 0
		repeat
			local Worked, Response = Call()
			
			if not Worked then
				I += 1
				Debug(Format("Attempt: %i | Response: %s", I, Response))
			else
				Debug(Format("Operation Succesfull. Attempts: %i", I), false)
				break
			end
			Yield(DelayTime)
		until I >= MaxAttempts
	end
end

--[[
	GetRandomFromArray Function
	
	Gets a random value stored within a array.
	If your array has string keys, consider using GetRandomFromArrayWithStringKey
	
	@param Array - The array to get a random value from
]]
function Lib.GetRandomFromArray(Array: { any })
	return GetRandomFromArray(Array)
end

--[[
	GetRandomFromArrayWithStringKey Function
	
	Gets a random value stored within a array with string keys.
	Also returns the name.

	@param Array - The array to get a random value from
]]
function Lib.GetRandomFromArrayWithStringKey(Array: { [string]: any }): (string, any)
	local I = 0
	local F = {}
	for n, v in pairs(Array) do
		if n and type(n) == "string" then
			I += 1
			F[I] = {n, v}
		else
			warn("There's a value without a string key, what a messy array you got.")
		end
	end
	
	local RandomV = GetRandomFromArray(F)
	if RandomV and #RandomV >= 2 then
		return RandomV[1], RandomV[2]
	end
	
	return "nil", nil
end

--[[
	GetChildrenOfClass Function
	
	Gets children from a instance that are of a type.
	
	@param Obj - The instance to get the children of type.
	@param ClassName - The class name to insert into the table.
	@param GetDescendantsInstead - Get descendants instead of children? (OPTIONAL)
]]
function Lib.GetChildrenOfClass(Obj: Instance, ClassName: string, GetDescendantsInstead: boolean | nil): { Instance }
	local Return = {}
	local Children -- tnickles reference
	if GetDescendantsInstead then
		Children = Obj:GetDescendants()
	else
		Children = Obj:GetChildren()
	end
	
	if Lib.IsTableEmpty(Children) then
		return Return
	end
	
	for _, v in pairs(Children) do
		if v and (v:IsA(ClassName) or v.ClassName == ClassName) then
			ArrayInsert(Return, v)
		end
	end
	
	return Return
end

--[[
	WaitForDescendant Function
	
	WaitForChild expect it instead goes through the descendants
	Why wasn't this a thing?
	
	@param Parent - The parent to search and wait for the target.
	@param Name - Name of the target
	@param Timeout - A optional timeout (incase we have waited for too long)
]]
function Lib.WaitForDescendant(Parent: Instance, Name: string, Timeout: number | nil): Instance | nil
	assert(Parent, "No parent provided.")
	assert(Name, "No target name provided.")
	
	local Target = Parent:FindFirstChild(Name, true)
	
	if Target then
		return Target
	else
		if Timeout == nil or type(Timeout) ~= "number" then
			Timeout = Huge
		end
		
		local Printed = false
		local Start = time()
		
		repeat
			Target = Parent:FindFirstChild(Name, true)
			if Target then
				break
			elseif not Printed and (time()-Start) >= 5 then
				Printed = true
				Debug(Format("Infinite Yield possible on '%s.%s'", Parent:GetFullName(), Name), true)
			end
			Yield()
		until time() >= (Timeout or Huge)
		
		return Target
	end
end

--[[
	PlayRandomSoundInInstance Function
	
	Plays a random sound within a instance
	
	@param Obj - The instance to play a random sound from
	@param GetDescendantsInstead - Get descendants instead of children? (OPTIONAL)
	@param StopAllSounds - Should other sounds be stopped for this one to be played?
]]
function Lib.PlayRandomSoundInInstance(Obj: Instance, GetDescendantsInstead: boolean | nil, StopAllSounds: boolean | nil)
	local Sounds = Lib.GetChildrenOfClass(Obj, "Sound", GetDescendantsInstead)
	
	if Sounds and not Lib.IsTableEmpty(Sounds) then
		if StopAllSounds then
			for _, v in pairs(Sounds) do
				pcall(function() -- PCalling because i dont wanna break your code :(
					if v and v:IsA("Sound") and v.IsPlaying then
						v:Stop()
					end
				end)
			end
		end
		
		local RandomSound = Lib.GetRandomFromArray(Sounds)
		
		if RandomSound then
			RandomSound:Play()
		end
	else
		Debug("No Sounds found.", true)
	end
end

--[[
	In Sight Function

	Sees if a target part is in the LOS (Line Of Sight) of something else

	Note: DotProduct needs to be in the range -1 and 1

	@param Viewer - The origin
	@param Target - The target
	@param MaxDist - Maximum distance (Default: math.huge)
	@param DotProduct - The view threshold that the target needs to be in (Default: nil)
]]
function Lib.InSight(Viewer: BasePart, Target: BasePart, MaxDist: number, DotProduct: number?, RayParams: RaycastParams)
	assert(Viewer, "No Viewer Part.")
	assert(Target, "No Target Part.")

	if not MaxDist then MaxDist = Huge end

	local CFrameOfOrigin = Viewer.CFrame
	local Origin = CFrameOfOrigin.Position
	local Direction = (Target.Position - Origin).Unit * MaxDist

	local Result = workspace:Raycast(Origin, Direction, RayParams or DefaultParams)
	if Result then	
		local Hit = Result.Instance
		if Hit == Origin or Hit:IsDescendantOf(Target.Parent) then
			if DotProduct ~= nil and type(DotProduct) == "number" then
				local MainUnit = Direction.Unit
				local NewDotProduct = CFrameOfOrigin.LookVector:Dot(MainUnit)
				if NewDotProduct >= DotProduct then
					return true
				else
					return false
				end
			end
			return true
		end
	end

	return false
end

--[[
	TransformWithUserID Function
	
	Transform a humanoid model with someone's userid
	
	@param Humanoid - The humanoid to apply the UserID's HumanoidDescription.
	@param UserID - The ID of the player
]]
function Lib.TransformWithUserID(Humanoid: Humanoid, UserID: number)
	local Descript
	local S, R = pcall(function()
		Descript =  Players:GetHumanoidDescriptionFromUserId(UserID)
	end)
	
	if S and Descript then
		Humanoid:ApplyDescription(Descript)
	else
		Debug(R, true)
	end
end

--[[
	GetPlayersAlive Function
	
	Gets players that are currently alive
]]
function Lib.GetPlayersAlive(): {Player}
	local Alive = {}
	for _, Player in pairs(Players:GetPlayers()) do
		if Player and Player.Character then
			local Humanoid = Player.Character:FindFirstChildOfClass("Humanoid")

			if Humanoid and Humanoid.Health > 0 then
				ArrayInsert(Alive, Player)
			end
		end
	end
	return Alive
end

--[[
	GetPlayersAlive Function
	
	Gets players that are currently dead
]]
function Lib.GetPlayersDead(): {Player}
	local Alive = {}
	for _, Player in pairs(Players:GetPlayers()) do
		if Player and Player.Character then
			local Humanoid = Player.Character:FindFirstChildOfClass("Humanoid")

			if Humanoid and Humanoid.Health <= 0 then
				ArrayInsert(Alive, Player)
			end
		end
	end
	return Alive
end

--[[
	IsCloseToPlayers Function
	
	Returns a boolean if a player is close to others
	
	@param Player - The player to check
	@param Dist - The distance it would be considered "close to the player"
]]
function Lib.IsCloseToPlayers(Player: Player, Dist: number)
	local IsClose = false

	for _, Friend in pairs(Players:GetPlayers()) do
		if Friend ~= Player then
			local Char = Friend.Character
			if Char then
				local Root = Char:FindFirstChild("HumanoidRootPart")
				if Root and Root:IsA("BasePart") then
					local Dist = Player:DistanceFromCharacter(Root.Position)
					if Dist < Dist then
						IsClose = true
						break
					end
				end
			end
		end
	end

	return IsClose
end

--[[
	IsTableEmpty Function
	
	Returns a boolean if a table is empty (Since # doesn't work sometimes)
	
	@param Table - The table to check if empty
]]
function Lib.IsTableEmpty(Table: { any })
	return TableIsEmpty(Table)
end

--[[
	GetAmountKeysAndFirstKeyStored Function (long name huh)
	
	Useful for deleting old logs or removing keys (with random numbers/strings) from tables whenever its above a limit.
	
	Returns 2 values:
	1 - Is the amount of keys stored
	2 - The first key stored
	
	@param Table - The table to get amount of keys and first key stored
]]
function Lib.GetAmountKeysAndFirstKeyStored(Table: { any }): ( number, any | nil )
	return GetAmountKeysAndFirstKeyStored(Table)
end

--[[
	RemoveNewLines Function
	
	Removes newlines from texts
	
	@param Text - The text to remove new lines
]]
function Lib.RemoveNewLines(Text: string)
	return Text:gsub("[\n\r]", " ") 
end

--[[
	IsNight Function
	
	Returns boolean if its considered night
	Condition: Time is above 18 or below 6
]]
function Lib.IsNight()
	return Lighting.ClockTime >= 18 or Lighting.ClockTime < 6
end

--[[
	IsDay Function
	
	Returns boolean if its considered day (Reuses IsNightFunction)
]]
function Lib.IsDay()
	return not Lib.IsNight() -- too smart bro
end

--[[
	GetBehindPos Function
	
	Returns CFrame position, meant to be behind another position
	
	@param Origin - The original Position
	@param Offset - How far should the returned CFrame be?
]]
function Lib.GetBehindPos(Origin: CFrame, Offset: number)
	assert(Origin, "No origin.")
	assert(Offset, "No offset.")
	
	return Origin * CFrame.new(0,0,Offset)
end

--[[
	MixColors Function
	
	Returns a Color3 Value of 2 colors mixed with a specified ratio/percent
	
	@param Color1 - First Color
	@param Color2 - Second color
	@param Ratio - The ratio between the colors (Ex: if its 0.7 then 30% the first and 70% the other)
]]
function Lib.MixColors(Color1: Color3, Color2: Color3, Ratio: number)
	local Mix
	local RM = (1 - Ratio)
	local R = (Color1.R * 255) * RM + (Color2.R * 255) * Ratio
	local G  = (Color1.G * 255) * RM + (Color2.G * 255) * Ratio
	local B = (Color1.B * 255) * RM + (Color2.B * 255) * Ratio
	return RGB(R,G,B)
end

--[[
	FindInstancesClosestByName Function
	
	Returns an array of instances whose names match a string
	
	@param Parent - The parent, The instance to go through the children
	@param Name - The string the instance's name need to match, also known as "pattern"
	@param LowerStrings - Optional boolean to lower all of the strings, so even if it has a uppercase T it still gets added in
	@param DescendantsInstead - Get descendants instead of children.
]]
function Lib.FindInstancesClosestByName(Parent: Instance, Name: string, LowerStrings: boolean | nil, DescendantsInstead: boolean | nil): { Instance }
	local L = {}
	
	if LowerStrings then
		Name = Name:lower()
	end
	
	local ParentList = DescendantsInstead and Parent:GetDescendants() or Parent:GetChildren()
	
	for _, v in pairs(ParentList) do
		if v and Match(LowerStrings and v.Name:lower() or v.Name, Name) ~= nil then
			ArrayInsert(L, v)
		end
	end
	
	return L
end

-- Random

--[[
	GetRandomPosInCircle Function
	
	Returns a Vector3 position meant to be in a circle
	Can be also used for horror, or "innocent" games
	Also has "collision support" to always be ontop parts
	
	Dist parameter should be like this:
	Dist = {
		50, -- Min Radius of circle
		150, -- Max Radius of circle
		500 -- Starting Y pos (works like a offset and is for collisionsupport)
	}
	
	@param StartPoint - The original position
	@param Dist - Optional distance array (Min, Max and StartYpos) to keep from starting point
	@param RayParams - Optional raycast params
]]
function Lib.GetRandomPosInCircle(StartPoint: Vector3, Dist: { number } | nil, RayParams: RaycastParams?)
	assert(StartPoint, "No original position.")
	if Dist == nil or type(Dist) ~= "table" then
		Dist = {
			50,
			150,
			500
		}
	end
	
	assert(Dist, "Dist is not real anymore.") -- Rare error
	
	local R = Randomizer:NextNumber(Dist[1], Dist[2])
	
	local theta = Randomizer:NextNumber(0, Tau)

	local X = StartPoint.X + R * Cosine(theta)
	local Z = StartPoint.Z + R * Sine(theta)
	
	local Origin = Vector(X, Dist[3], Z)

	local Result = workspace:Raycast(Origin, StalkDir, RayParams or DefaultParams)
	if Result then
		return Result.Position
	end

	return Origin
end

--[[
	RandomName Function
	
	Returns a random name with a optional specified gender
	
	@param Gender - The gender. (OPTIONAL)
	@param IncludeSurname - Should it include surname in the returned string? (OPTIONAL)
]]
function Lib.RandomName(Gender: string | nil, IncludeSurname: boolean | nil): string
	if not Gender then
		Gender = GetRandomFromArray({"Male", "Female"})
	end
	
	local MainArray

	if Gender == "Male" then
		MainArray = MaleNames
	elseif Gender == "Female" then
		MainArray = FemaleNames
	else
		warn("Invalid Gender.")
		MainArray = MaleNames
	end
	
	local Name = GetRandomFromArray(MainArray)
	
	if IncludeSurname then
		Name = Format("%s %s", Name, GetRandomFromArray(Surnames))
	end
	
	return Name
end
--[[
	RandomTeamName Function
	
	Returns a random FICTIONAL Team Name
	
	@param IsAdversary - Is it a adversary team? (To avoid multiple names)
]]
function Lib.RandomTeamName(IsAdversary: boolean): string
	if IsAdversary == nil or type(IsAdversary) ~= "boolean" then
		warn("IsAdversary cannot be nil or something else other than boolean.")
		
		return ""
	end
	local TB
	if IsAdversary then
		TB = TeamNames.Adversary
	else
		TB = TeamNames.Ally
	end
	return GetRandomFromArray(TB)
end

-- Mathematics / Physics

--[[
	RoundWithDecimalPlaces Function
	
	Rounds a number (with the extra addition of decimal places)
	
	@param N - Number to round
	@param DecimalPlaces - How many decimal places for there to be
]]
function Lib.RoundWithDecimalPlaces(N: number, DecimalPlaces: number)
	local Scale = 10^DecimalPlaces
	return ((N * Scale + RoundEquation) - RoundEquation) / Scale
end

--[[
	Sum Function
	
	Calculates the sum of every number in a table

	@param Table - The array of numbers
]]
function Lib.Sum(Table: { number }): number
	local I = 0
	for _, v in pairs(Table) do
		I += v
	end
	return I
end

--[[
	Mean Function
	
	Calculates the "average" for a table of numbers (Useful for calculating grades)

	@param Table - The array of numbers
]]
function Lib.Mean(Table: { number }): number
	return Lib.Sum(Table)/#Table
end

--[[
	IsOdd Function
	
	Gives you a boolean if a number is odd or even.

	@param Number - The number (yeah duh)
]]
function Lib.IsOdd(Number: number)
	if Number % 2 == 0 then
		return true
	else
		return false
	end
end

--[[
	DividesWith Function
	
	Gives you a boolean if a number Divides with another number

	@param Number - The first number
	@param Divider - The number that the first number has to divide with
]]
function Lib.DividesWith(Number: number, Divider: number)
	if Number % Divider == 0 then
		return true
	else
		return false
	end
end

--[[
	IsPrimeNumber Function
	
	Checks if a number is a prime number

	(WARNING: PERFOMANCE HEAVY ON HIGHER NUMBERS)

	@param Number - The number to check
]]
function Lib.IsPrimeNumber(Number: number)
	if Number <= 1 then
		return false
	else
		for i=2, (Number^0.5)+1 do
			if Number % i == 0 then
				return false
			end
		end
		
		return true
	end
end

--[[
	Factorial Function

	Calculates the Factorial of a number

	(WARNING: PERFOMANCE HEAVY ON HIGHER NUMBERS)

	@param Number - The number to calculate
]]
function Lib.Factorial(Number: number)
	local R = 1
	for i=1, Number do
		R *= i
	end
	return R
end

--[[
	GetAngleBetween3Points Function

	Calculates the angle between 3 points.

	@param Pos1 - First position.
	@param Pos2 - Second position, also known as the "peak" of the angle
	@param Pos3 - Third and last position.
]]
function Lib.GetAngleBetween3Points(Pos1: Vector3, Pos2: Vector3, Pos3: Vector3)
	if Pos1 and typeof(Pos1) == "Vector3" and Pos2 and typeof(Pos2) == "Vector3" and Pos3 and typeof(Pos3) == "Vector3" then
		return ACosine((Pos2 - Pos1).Unit:Dot((Pos3 - Pos1).Unit))
	else
		warn("Invalid Arguments.")
		return 0
	end
end

--[[
	Quadratic Function

	Calculates the quadratic of 3 numbers so you don't have to (how nice from me) 
]]
function Lib.Quadratic(a: number, b: number, c: number): (number, number)
	local discriminant = b^2 - 4*a*c
	
	local root1
	local root2

	if discriminant >= 0 then
		root1 = (-b + discriminant ^ 0.5) / (2 * a)
		root2 = (-b - discriminant ^ 0.5) / (2 * a)
	else
		root1 = (-b + SquareRoot(discriminant)) / (2 * a)
		root2 = (-b - SquareRoot(discriminant)) / (2 * a)
	end
	
	return root1, root2
end

--[[
	GetSpeed Function
	
	Calculates the speed based on time and distance

	ProTip: Time is in seconds and Distance is in meters, therefore the speed is in m/s

	@param Time - The time elapsed
	@param Distance - The distance that took in the time.
]]
function Lib.GetSpeed(Time: number, Distance: number): number
	return Distance / Time
end

--[[
	GetDistance Function

	Calculates the distance based on speed and time

	ProTip: Speed is in m/s, therefore the distance is in meters

	@param Time - The time elapsed
	@param Speed - The speed the object was in
]]
function Lib.GetDistance(Time: number, Speed: number): number
	return Speed * Time
end

--[[
	GetTime Function
	
	Calculates the time elapsed based on speed and distance

	ProTip: Speed is in m/s, therefore time is in seconds.

	@param Distance - The distance
	@param Speed - The speed the object was in
]]
function Lib.GetTime(Distance: number, Speed: number): number
	return Distance / Speed
end

-- Converters

--[[
	StudsToMetres Function

	Turns ROBLOX Studs into Metres

	@param Studs - The amount of studs to turn into metres
]]
function Lib.StudsToMetres(Studs: number)
	return Studs * StudConverter
end

--[[
	MetresToStuds Function

	Turns Metres into ROBLOX Studs

	@param Metres - The amount of metres to turn into studs
]]
function Lib.MetresToStuds(Metres: number)
	return Metres / StudConverter
end

--[[
	FootToMetres Function

	Turns Foot into metres

	@param Foot - The amount of Foot to turn into Metres
]]
function Lib.FootToMetres(Foot: number)
	return Foot / FootConverter
end

--[[
	MetresToFoot Function

	Turns Metres into foot

	@param Metres - The amount of Metres to turn into Foot
]]
function Lib.MetresToFoot(Metres: number)
	return Metres * FootConverter
end

--[[
	InchesToMetres Function

	Turns Inches into metres

	@param Inches - The amount of Inches to turn into Metres
]]
function Lib.InchesToMetres(Inches: number)
	return Inches / InchesConverter
end

--[[
	MetresToInches Function

	Turns Metres into Inches

	@param Metres - The amount of Metres to turn into Inches
]]
function Lib.MetresToInches(Metres: number)
	return Metres * InchesConverter
end

--[[
	HeightInMetres Function

	Turns Height (Foot and Inches) into Metres

	@param Foot - First Number in your height
	@param Inches - Second Number in your height
]]
function Lib.HeightInMetres(Foot: number, Inches: number)
	return Lib.FootToMetres(Foot)+Lib.InchesToMetres(Inches)
end

--// RETURN

if Lib.CheckForVersions then 
	local s, r = pcall(function() 
		task.spawn(CheckVersion) 
	end) 
	
	if not s then
		warn(r)
	end
end

return Lib
