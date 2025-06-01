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

--// MODULE

local Lib = {
	Debugging = true;
	CheckForVersions = true;
}

--// VARIABLES

local Types = require(script.Types)

local Format, Yield, require, Char, ArrayInsert = string.format, task.wait, require, string.char, table.insert
local Traceback = debug.traceback
local Huge = math.huge

local DefaultParams = RaycastParams.new()

local StudConverter = 0.28
local FootConverter = 3.281
local InchesConverter = 39.37

--// TYPES

type DiscordWebhook = Types.DiscordWebhook

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
	local CurrentVersion = script:GetAttribute("Version")
	
	if not CurrentVersion then
		warn("There's no version attribute, why did you delete it..?")
		return
	end
	
	local ModuleVersion = require(123399476691947) -- Ignore yellow mark, annoying >:(
	
	if ModuleVersion and type(ModuleVersion) == "string" then
		if CurrentVersion == ModuleVersion then
			Debug("No new updates for this module.", true)
		else
			warn(Format("New update! (%s) Please update the module named \"WinLib\".", ModuleVersion))
		end
	else
		warn("Something went wrong trying to check for the version.")
	end
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

-- Simple Game Functions

--[[
Attempting Function
* Repeats a process over and over again until its succesfull or reached max attempts.

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
In Sight Function
* Sees if a target part is in the LOS (Line Of Sight) of something else

Note: DotProduct needs to be in the range -1 and 1

@param Viewer - The origin
@param Target - The target
@param MaxDist - Maximum distance (Default: math.huge)
@param DotProduct - The view threshold that the target needs to be in (Default: nil)
]]
function Lib.InSight(Viewer: BasePart, Target: BasePart, MaxDist: number, DotProduct: number, RayParams: RaycastParams)
	assert(Viewer, "No Viewer Part.")
	assert(Target, "No Target Part.")
	
	if not MaxDist then MaxDist = Huge end

	local CFrameOfOrigin = Viewer.CFrame
	local Origin = CFrameOfOrigin.Position
	local Direction = (Target.Position - Origin).Unit * MaxDist

	local Result = workspace:Raycast(Origin, Direction, RayParams or DefaultParams)
	if Result then	
		local Hit = Result.Instance
		if Hit == Origin or Hit:IsDescendantOf(Viewer.Parent) then
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
	local Descript = Players:GetHumanoidDescriptionFromUserId(UserID)
	
	Humanoid:ApplyDescription(Descript)
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

-- Mathematics / Physics

--[[
Sum Function
* Calculates the sum of every number in a table

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
* Calculates the "average" for a table of numbers (Useful for calculating grades)

@param Table - The array of numbers
]]
function Lib.Mean(Table: { number }): number
	return Lib.Sum(Table)/#Table
end

--[[
IsOdd Function
* Gives you a boolean if a number is odd or even.

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
* Gives you a boolean if a number Divides with another number

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
* Checks if a number is a prime number

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
* Calculates the Factorial of a number

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
GetSpeed Function
* Calculates the speed based on time and distance

ProTip: Time is in seconds and Distance is in meters, therefore the speed is in m/s

@param Time - The time elapsed
@param Distance - The distance that took in the time.
]]
function Lib.GetSpeed(Time: number, Distance: number): number
	return Distance / Time
end

--[[
GetDistance Function
* Calculates the distance based on speed and time

ProTip: Speed is in m/s, therefore the distance is in meters

@param Time - The time elapsed
@param Speed - The speed the object was in
]]
function Lib.GetDistance(Time: number, Speed: number): number
	return Speed * Time
end

--[[
GetTime Function
* Calculates the time elapsed based on speed and distance

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
* Turns ROBLOX Studs into Metres

@param Studs - The amount of studs to turn into metres
]]
function Lib.StudsToMetres(Studs: number)
	return Studs * StudConverter
end

--[[
MetresToStuds Function
* Turns Metres into ROBLOX Studs

@param Metres - The amount of metres to turn into studs
]]
function Lib.MetresToStuds(Metres: number)
	return Metres / StudConverter
end

--[[
FootToMetres Function
* Turns Foot into metres

@param Foot - The amount of Foot to turn into Metres
]]
function Lib.FootToMetres(Foot: number)
	return Foot / FootConverter
end

--[[
MetresToFoot Function
* Turns Metres into foot

@param Metres - The amount of Metres to turn into Foot
]]
function Lib.MetresToFoot(Metres: number)
	return Metres * FootConverter
end

--[[
InchesToMetres Function
* Turns Inches into metres

@param Inches - The amount of Inches to turn into Metres
]]
function Lib.InchesToMetres(Inches: number)
	return Inches / InchesConverter
end

--[[
MetresToInches Function
* Turns Metres into Inches

@param Metres - The amount of Metres to turn into Inches
]]
function Lib.MetresToInches(Metres: number)
	return Metres * InchesConverter
end

--[[
HeightInMetres Function
* Turns Height (Foot and Inches) into Metres

@param Foot - First Number in your height
@param Inches - Second Number in your height
]]
function Lib.HeightInMetres(Foot: number, Inches: number)
	return Lib.FootToMetres(Foot)+Lib.InchesToMetres(Inches)
end

--// RETURN

if Lib.CheckForVersions then task.spawn(CheckVersion) end

return Lib
