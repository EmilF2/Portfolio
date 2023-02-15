local PetHandler = {}
local AllCoinsPetMultiplier
local AllGemsPetMultiplier
--// Services
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

--// Variables
local DataFolder = ServerStorage.Data
local ServerPets = Workspace:WaitForChild("Pets"):WaitForChild("ServerPets")
local GameClient = ReplicatedStorage:WaitForChild("GameClient")
local LoadPetsEvent = GameClient.Events.RemoteEvent.LoadPets
local CreatePetEvent = GameClient.Events.RemoteEvent.CreatePet
local HandlePetEvent = GameClient.Events.RemoteFunction.HandlePet
local UpdateAllPetLevelsEvent = GameClient.Events.RemoteEvent.UpdateAllPetLevels
local UpdatePetLevelEvent = GameClient.Events.RemoteEvent.UpdatePetLevel
local GetPetsTableEvent = GameClient.Events.RemoteFunction.GetPetsTable

--// Modules
local DataController = require(DataFolder.DataController)
local PetStats = require(GameClient.Modules.Utilities.PetStats)
local AutoDeleteServerModule = require(script.Parent.EggServerHandler.AutoDeleteServer)

function PetHandler:ReturnPetData(name, id, equip, evolution, lvl)
	return {
		PetName = tostring(name) or "Dog";
		PetID = id or 1;
		PetIsEquip = equip or false;
		Locked = false;
		PetLevel = (tonumber(lvl) or 1);
		XP = 0;
		PetEvolution = (evolution ~= nil and tostring(evolution) or "Normal");
	}
end
function PetHandler:FindPetStatsInData(Data, id)
	local pets = Data.OwnedItems.Pets
	for _, v in pairs(pets) do
		if type(v) == "table" then
			local petId = v.PetID
			if petId == id then
				return v
			end
		end
	end
end

function PetHandler:CheckIfPetCanEquip(Data)
	local MaxPetsEquipped = Data.PetControl.MaxPetsEquipped
	local AmountOfPetsEquipped = (function()
		local pets = Data.OwnedItems.Pets
		local amount = 0
		for _, v in pairs(pets) do
			if type(v) == "table" then
				if v.PetIsEquip == true then
					amount = amount + 1
				end
			end
		end
		return amount
	end)()
	if (tonumber(AmountOfPetsEquipped) + 1) > tonumber(MaxPetsEquipped) then
		return false
	end
	return true
end

function MakePetFolder(plr, petName, petID, evolution, level)
	local petFol = Instance.new("Folder") petFol.Name = petID

	local petNameVal = Instance.new("StringValue")
	petNameVal.Name = "PetName" petNameVal.Value = tostring(petName)
	petNameVal.Parent = petFol
	
	local petIDVal = Instance.new("StringValue")
	petIDVal.Name = "PetID" petIDVal.Value = petID
	petIDVal.Parent = petFol
	
	evolution = evolution ~= nil and tostring(evolution) or "Normal"
	local evolutionFol = Instance.new("StringValue")
	evolutionFol.Name = "Evolution" evolutionFol.Value = tostring(evolution)
	evolutionFol.Parent = petFol
	
	level = level ~= nil and tonumber(level) or 1
	local levelFol = Instance.new("NumberValue")
	levelFol.Name = "Level" levelFol.Value = tonumber(level)
	levelFol.Parent = petFol
	
	local PetFolder = ServerPets:FindFirstChild(plr.Name)
	petFol.Parent = PetFolder
	return petFol
end

function PetHandler:AddPet(plr, data)
	if plr and data ~= nil then
		local Data = DataController:GetAllData(plr)
		
		local plrIDNumber = Data.PetControl.CurrentPetID
		if plrIDNumber == nil or tonumber(plrIDNumber) == 0 or type(tonumber(plrIDNumber)) ~= "number" then
			plrIDNumber = 1
		end
		local petName = data.PetName
		local petEvolution = data.Evolution or "Normal"
		local petID = plr.UserId .."-".. tostring(plrIDNumber)
		local petLevel = data.Level or 1
		local noShowClient = data.NoShowClient or false
		
		local petData
		if self:CheckIfPetCanEquip(Data) == true then
			petData = self:ReturnPetData(petName, petID, true, petEvolution, petLevel)
			local level = petData.PetLevel or 1
			MakePetFolder(plr, petName, petID, petEvolution, level)
		else
			petData = self:ReturnPetData(petName, petID, false, petEvolution, petLevel)
		end
		
		local pets = Data.OwnedItems.Pets
		table.insert(pets, petData)
		local newID = tonumber(plrIDNumber) + 1
		Data.PetControl.CurrentPetID = newID
		DataController:SavePlayerData(plr)
		
		CreatePetEvent:FireClient(plr, petData, noShowClient)
		
		return true
	end
end

function PetHandler:TradePet(PlayerWhoHadPetName, PlayerWhoGetsPetName, petName, petId)
	if petName ~= nil and petId ~= nil then
		local plr1 = Players:FindFirstChild(tostring(PlayerWhoHadPetName))
		local plr2 = Players:FindFirstChild(tostring(PlayerWhoGetsPetName))
		if plr1 ~= nil and plr2 ~= nil then
			local Data = DataController:GetAllData(plr1)
			local petData = self:FindPetStatsInData(Data, petId)
			if petData == nil then
				warn("No Pet data for pet with ID:", tostring(petId))
				return
			end
			local evolution, lvl = petData.PetEvolution, petData.PetLevel
			local deleted = self:DeletePet(plr1, Data, petId, petName, false, false)
			if deleted == true then
				if plr2 ~= nil then
					local addedPet = self:AddPet(plr2, {
						PetName = tostring(petName), 
						Evolution = (tostring(evolution) or "Normal"), 
						Level = (tonumber(lvl) or 1),
					})
					if addedPet == true then
						return true
					end
				end
			end
		end
	end
	return false
end

local function checkNoOtherSpecialPet(plr, specialPetName)
	local Data = DataController:GetAllData(plr)
	local pets = Data.OwnedItems.Pets
	for _, v in pairs(pets) do
		if type(v) == "table" then	
			if v.PetName ~= nil then
				local petName = v.PetName
				if tostring(petName) == tostring(specialPetName) then
					return true
				end
			end
		end
	end
	return false
end

function PetHandler:AddDevPet(plr)
	if plr.UserId == 4219054594 then
		local petName = "Cam"
		if checkNoOtherSpecialPet(plr, tostring(petName)) == false then
			for i = 1, 4 do
				spawn(function()
					self:AddPet(plr, {PetName = tostring(petName)})
				end)
			end
			DataController:SavePlayerData(plr)
		end
	end
end

local function GetPetEquip(Player, Data)
	local PetEquip = 4
	 -- check pass
	if Player.Stats:FindFirstChild("+2PetsEquipped").Value == 1 then
		PetEquip = tonumber(PetEquip) + 2
	end
	
	if tonumber(PetEquip) < 4 or tonumber(PetEquip) == nil then PetEquip = 4 end
	return tonumber(PetEquip)
end

local function GetPetStorage(Player, Data)
	local PetStorage = 100
	
	 -- check pass
	if Player.Stats:FindFirstChild("+100PetStorage").Value == 1 then
		PetStorage = tonumber(PetStorage) + 100
	end
	
	if tonumber(PetStorage) < 100 or tonumber(PetStorage) == nil then PetStorage = 100 end
	return tonumber(PetStorage)
end

function SetPetControlStats(plr, load)
	local Data = DataController:GetAllData(plr)
	
	local PetEquip = GetPetEquip(plr, Data)
	DataController:SetStatForPlayer(plr, "MaxPetsEquipped", tonumber(PetEquip))
	
	local PetStorage = GetPetStorage(plr, Data)
	DataController:SetStatForPlayer(plr, "MaxPetsInventory", tonumber(PetStorage))
	
	if load == true then wait()
		UpdatePetLevelEvent:FireClient(plr, true)
	end
end

function PetHandler:LoadPetsEquipped(plr)
	local Data = DataController:GetAllData(plr)
	
	delay(3, function()
		SetPetControlStats(plr, true)
	end)
	
	--// Set Auto Delete Settings False
	spawn(function()
		AutoDeleteServerModule:MakePlayerTable(plr)
	end)
	
	--// Load Pets
	local pets = Data.OwnedItems.Pets
	for _, v in pairs(pets) do
		if type(v) == "table" then
			if v.PetIsEquip == true then
				local petName, petID = v.PetName, v.PetID
				local petEvolution = v.PetEvolution or "Normal"
				local level = v.PetLevel or 1
				MakePetFolder(plr, petName, petID, petEvolution, level)
			end
		end
	end
	LoadPetsEvent:FireClient(plr, pets)
end

function PetHandler:GetPetsForPlayer(plr, PlayerName)
	if PlayerName ~= nil then
		local Player = Players:FindFirstChild(tostring(PlayerName))
		if Player ~= nil then
			local Data = DataController:GetAllData(Player)
			local pets = Data.OwnedItems.Pets
			return pets
		end
	end
end

function PetHandler:GetPetStats(name)
	if PetStats[tostring(name)] == nil then
		warn("No Pet Stats for pet with name of", tostring(name))
		return PetStats.Dog
	end
	return PetStats[tostring(name)]
end

function PetHandler:DeletePet(plr, Data, petID, petName, petLocked, multiDelete)
	if petLocked == true then
		return "NoDelete" 
	end
	local stats = self:GetPetStats(petName)
	if stats.Deletable == false then
		return "NoDelete"
	end
	local pets = Data.OwnedItems.Pets
	local tableI = (function()
		for i, v in pairs(pets) do
			if type(v) == "table" then
				local petId = v.PetID
				if petId == petID then
					return i
				end
			end
		end
	end)()
	if tableI ~= nil then
		table.remove(pets, tableI)
		if multiDelete == true then else
			DataController:SavePlayerData(plr)
		end
		
		local PetFolder = ServerPets:FindFirstChild(plr.Name)
		if PetFolder ~= nil then
			if PetFolder:FindFirstChild(petID) ~= nil then
				local modelToDestroy = PetFolder:FindFirstChild(petID)
				modelToDestroy:Destroy()
			end
		end
		
		return true
	end
end

local function getNewEvolutionFromOld(oldEvolution)
	if oldEvolution == "Normal" then
		return "Gold"
	elseif oldEvolution == "Gold" then
		return "Shiny"
	end
	warn("No Old Evolution Provided! Old Evolution:", tostring(oldEvolution))
	return "Gold"
end

--// Unequip All Pets
function PetHandler:UnequipAllPets(plr)
	local PetFolder = ServerPets:FindFirstChild(plr.Name)
	if PetFolder ~= nil then
		local Data = DataController:GetAllData(plr)
		local pets = Data.OwnedItems.Pets
		for _, v in pairs(pets) do
			if type(v) == "table" then
				if v.PetIsEquip == true and PetFolder:FindFirstChild(v.PetID) ~= nil then
					local modelToDestroy = PetFolder:FindFirstChild(v.PetID)
					modelToDestroy:Destroy()
					
					v.PetIsEquip = false
				end
			end
		end
		DataController:SavePlayerData(plr)
		return true
	end
	return false
end

--// Stat Variables
local Craft_Multipliers = {
	Normal = 1;
	Gold = 2;
	Shiny = 3;
}

--// Get Individual Pet Multiplier
function GetPetMultiplier(Stats, PetLevel, PetEvolution)
	local coinMul, gemsMul = Stats.CoinMultiplier, Stats.GemsMultiplier
	
	local mul = Craft_Multipliers[tostring(PetEvolution)]
	if mul == nil then
		warn("No Craft Multiplier For ".. tostring(PetEvolution).." Evolution!")
		mul = 1
	end
	
	local petLevelMul = (tonumber(PetLevel) * 0.1) + 1
	if tonumber(petLevelMul) < 1 then petLevelMul = 1 end
	
	coinMul = coinMul * tonumber(petLevelMul) * tonumber(mul)
	gemsMul = gemsMul * tonumber(petLevelMul) * tonumber(mul)
	
	if tonumber(coinMul) < 1 then coinMul = 1 end
	if tonumber(gemsMul) < 1 then gemsMul = 1 end
	
	return coinMul, gemsMul
end

--// Equip Best Pets
function PetHandler:EquipBestPets(plr)
	if plr ~= nil then
		local Data = DataController:GetAllData(plr)
		local pets = Data.OwnedItems.Pets
		local Table = {}
		for _, v in pairs(pets) do
			if type(v) == "table" then
				local petId, petName, evolution, PetLevel = v.PetID, v.PetName, v.PetEvolution, v.PetLevel
				if petId ~= nil and petName ~= nil and evolution ~= nil and PetLevel ~= nil then
					local stats = self:GetPetStats(petName)
					local coinMul, gemsMul = GetPetMultiplier(stats, PetLevel, evolution)
					local total = (tonumber(coinMul) or 0) + (tonumber(gemsMul) or 0)
					table.insert(Table, {
						PetID = petId;
						Score = tonumber(total);
					})
				end
			end
		end
		wait() table.sort(Table, function(a, b)
			return a.Score > b.Score
		end)
		
		for _, v in pairs(Table) do
			if type(v) == "table" then
				local petID, petName = v.PetID, v.PetName
				local petData = self:FindPetStatsInData(Data, petID)
				if petData ~= nil then
					if self:CheckIfPetCanEquip(Data) == true then
						self:HandlePet(plr, "Equip", {PetName = petData.PetName, PetId = petData.PetID})
					else
						break
					end
				else
					warn("No Pet data for pet with ID:", tostring(petID))
				end
			end
		end
	end
end

function PetHandler:HandlePet(plr, which, data)
	if plr and which ~= nil and data ~= nil then
		local Data = DataController:GetAllData(plr)
		if which == "MultiDelete" then
			if #data < 1 then else
				local returnDeleted = {}
				for _, v in pairs(data) do
					local petName, petId = v.PetName, v.PetId
					local petData = self:FindPetStatsInData(Data, petId)
					if petData ~= nil then
						local petLocked = petData.Locked or false
						local deleted = self:DeletePet(plr, Data, petId, petName, petLocked, true)
						if deleted == "NoDelete" then else
							table.insert(returnDeleted, {PetId = petId})
						end
					else
						warn("No Pet data for pet with ID:", tostring(petId))
					end
				end
				DataController:SavePlayerData(plr)
				return returnDeleted
			end
		elseif which == "UnequipAll" then
			return self:UnequipAllPets(plr)
		elseif which == "EquipBest" then
			self:UnequipAllPets(plr) wait(.1)
			self:EquipBestPets(plr)
			return true
		elseif which == "LockAll" or which == "UnLockAll" then
			local var = which == "LockAll" and true or false
			local pets = Data.OwnedItems.Pets
			for _, v in pairs(pets) do
				if type(v) == "table" then
					local petLocked = v.Locked
					if petLocked ~= nil then
						v.Locked = var
					end
				end
			end
			DataController:SavePlayerData(plr)
			return true
		elseif which == "GetPetDeleteAllText" then
			local Table, Text = {}, "FIRST"
			local pets = Data.OwnedItems.Pets
			for _, v in pairs(pets) do
				if type(v) == "table" then
					local petName, petId, petLocked = v.PetName, v.PetID, v.Locked
					if petName ~= nil and petId ~= nil and petLocked ~= nil then
						local stats = self:GetPetStats(petName)
						if stats.Deletable == false then else
							if petLocked == true then else
								local petData = self:FindPetStatsInData(Data, petId)
								if petData ~= nil then
									local petEvolution = petData.PetEvolution or "Normal"
									local newPetName = ""
									if petEvolution == "Normal" then
										newPetName = tostring(petName)
									else
										newPetName = tostring(petEvolution).." ".. tostring(petName)
									end
									if Table[tostring(newPetName)] == nil then
										Table[tostring(newPetName)] = {tostring(newPetName), 1}
									else
										local currentAmount = Table[tostring(newPetName)][2]
										Table[tostring(newPetName)] = {tostring(newPetName), (currentAmount + 1)}
									end
								end
							end
						end
					end
				end
			end
			for _, v in pairs(Table) do
				local petName, amount = v[1], v[2]
				if petName ~= nil and amount ~= nil then
					if Text == "FIRST" then
						local str = tostring(petName).." (x".. tostring(amount) ..")"
						Text = tostring(str)
					else
						local str = ", ".. tostring(petName).." (x".. tostring(amount) ..")"
						Text = Text.. tostring(str)
					end
				end
			end
			if Text ~= nil and tostring(Text) ~= "" and string.len(tostring(Text)) > 0 then
				if tostring(Text) == "FIRST" then
					return "No Pets To Delete"
				end
				return tostring(Text)
			end
			return "[ FAILED TO GET DELTE ALL PETS ]"
		elseif which == "DeleteAllPetsUnlocked" then
			if #data < 1 then else
				local returnDeleted = {}
				for _, v in pairs(data) do
					if type(v) == "table" then
						local petName, petId, petLocked = v.PetName, v.PetID, v.Locked
						if petName ~= nil and petId ~= nil and petLocked ~= nil then
							local stats = self:GetPetStats(petName)
							if stats.Deletable == false then else
								if petLocked == true then else
									local deleted = self:DeletePet(plr, Data, petId, petName, petLocked, true)
									if deleted == "NoDelete" then else
										table.insert(returnDeleted, {PetId = petId})
									end
								end
							end
						end
					end
				end
				DataController:SavePlayerData(plr)
				return returnDeleted
			end
		elseif which == "CraftPet" then
			if #data[2] < 1 then else
				local returnDeleted , totalDeleted, PetName, oldEvolution = {}, 0, data[1], data[2]
				for _, v in pairs(data[3]) do
					if type(v) == "table" then
						local petName, petId = v.PetName, v.PetID
						if petName ~= nil and petId ~= nil then
							local deleted = self:DeletePet(plr, Data, petId, petName, false, true)
							if deleted == "NoDelete" then else
								table.insert(returnDeleted, {PetId = petId})
								totalDeleted = totalDeleted + 1
							end
						end
					end
				end
				if totalDeleted >= 10 then
					DataController:SavePlayerData(plr)
					local nextEvolution = getNewEvolutionFromOld(tostring(oldEvolution))
					self:AddPet(plr, {PetName = tostring(PetName), Evolution = tostring(nextEvolution); NoShowClient = true;})
					return returnDeleted
				else
					warn("Did Not Meet 10 Deleted Pets! Did Not Make New Pet!")
				end
			end
		elseif which == "UpdatePetLevels" then
			local PetFolder = ServerPets:FindFirstChild(plr.Name)
			if PetFolder ~= nil then
				for _, v in pairs(PetFolder:GetChildren()) do
					if v:IsA("Folder") and v:FindFirstChild("PetID") and v:FindFirstChild("Level") then
						local petId = v.PetID.Value
						local petData = self:FindPetStatsInData(Data, petId)
						if petData ~= nil then
							local level = petData.PetLevel
							if level == nil then
								warn("No Pet Level For pet with ID:", tostring(petId))
								level = 1
							end
							v.Level.Value = (tonumber(level) or 1)
						else
							warn("No Pet data for pet with ID:", tostring(petId))
						end
					end
				end
				UpdateAllPetLevelsEvent:FireClient(plr)
			end
		else
			local petData = self:FindPetStatsInData(Data, data.PetId)
			if petData == nil then
				warn("No Pet data for pet with ID:", tostring(data.PetId))
				return
			end
			if which == "Equip" then
				if self:CheckIfPetCanEquip(Data) == true then
					if petData.PetIsEquip == false and ServerPets:FindFirstChild(data.PetId) == nil then
						petData.PetIsEquip = true
						DataController:SavePlayerData(plr)
						
						local petName, petID = data.PetName, data.PetId
						local petEvolution = petData.PetEvolution or "Normal"
						local level = petData.PetLevel or 1
						local folder = MakePetFolder(plr, petName, petID, petEvolution, level)
						
						return true
					end
				end
			elseif which == "Unequip" then
				local PetFolder = ServerPets:FindFirstChild(plr.Name)
				if PetFolder ~= nil then
					if petData.PetIsEquip == true and PetFolder:FindFirstChild(data.PetId) ~= nil then
						local modelToDestroy = PetFolder:FindFirstChild(data.PetId)
						modelToDestroy:Destroy()
						
						petData.PetIsEquip = false
						DataController:SavePlayerData(plr)
						
						return true
					end
				end
			elseif which == "Delete" then
				local petLocked = petData.Locked or false
				return self:DeletePet(plr, Data, data.PetId, data.PetName, petLocked, false)
			elseif which == "Lock" then
				if petData.Locked == nil then
					petData.Locked = true
					DataController:SavePlayerData(plr)
					return true
				else
					if petData.Locked == false then
						petData.Locked = true
						DataController:SavePlayerData(plr)
						return true
					end
				end
			elseif which == "Unlock" then
				if petData.Locked == nil then
					petData.Locked = false
					DataController:SavePlayerData(plr)
					return true
				else
					if petData.Locked == true then
						petData.Locked = false
						DataController:SavePlayerData(plr)
						return true
					end
				end
			end
		end
	end
end

function PetHandler:Int()
	HandlePetEvent.OnServerInvoke = function(...)
		return self:HandlePet(...)
	end
	GetPetsTableEvent.OnServerInvoke = function(...)
		return self:GetPetsForPlayer(...)
	end
end

return PetHandler