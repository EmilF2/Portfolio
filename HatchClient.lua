local replicatedStorage = game:GetService("ReplicatedStorage")
local runService = game:GetService("RunService")
local tweenService = game:GetService("TweenService")
local uis = game:GetService("UserInputService")
local mps = game:GetService("MarketplaceService")

local player = game.Players.LocalPlayer
local camera = workspace.Camera

local Pets = replicatedStorage:FindFirstChild("Pets")
local Eggs = workspace:WaitForChild("Eggs")
local Module3D = require(replicatedStorage:WaitForChild("Module3D"))
local tripleHatchID = 78819276
local gamepassFH = 78912757

local stopAutoHatching = script.Parent.Parent.StopAutoHatching

local MaxDisplayDistance = 15
local canHatch = false
local isHatching = false
local hatchOneConnection = nil
local cantOpenBillboard = false
local cooldown = false
local eggHatchSpeed = 3
local isAutoHatching = false

wait(.5)

if mps:UserOwnsGamePassAsync(player.UserId, gamepassFH) then
	eggHatchSpeed = 1.5
end

local function animateBillboard(billboard, openOrClose)
	if openOrClose == true then
		tweenService:Create(billboard,TweenInfo.new(.1),{Size = UDim2.new(5,0,7,0)}):Play()
	else
		tweenService:Create(billboard,TweenInfo.new(.1),{Size = UDim2.new(0,0,0,0)}):Play()
		wait(.2)
		billboard.Enabled = false
	end
	wait(.5)
end

local function ToggleScreenGuis(bool)
	for i, v in pairs(script.Parent.Parent.Parent:GetChildren()) do
		if v.Name ~= "Egg" then
			v.Enabled = bool
		end
	end
end

local function disableAllBillboards()
	cantOpenBillboard = true
	for i, v in pairs(script.Parent.Parent.EggBillboards:GetChildren()) do
		if v:IsA("BillboardGui") then
			animateBillboard(v, false)
		end
	end
end

local function enableAllBillboards()
	cantOpenBillboard = false
	for i, v in pairs(script.Parent.Parent.EggBillboards:GetChildren()) do
		if v:IsA("BillboardGui") then
			animateBillboard(v, true)
		end
	end
end

for i, v in pairs(Eggs:GetChildren()) do
	local eggPets = Pets:FindFirstChild(v.Name)

	if eggPets ~= nil then
		local billboardTemp = script.Template:Clone()
		local container = billboardTemp:WaitForChild("Container")
		local MainFrame = container:WaitForChild("MainFrame")
		local template = MainFrame:WaitForChild("Template")
		local Display = template:WaitForChild("Display")

		billboardTemp.Parent = script.Parent.Parent.EggBillboards
		billboardTemp.Name = v.Name
		billboardTemp.Adornee = v.EggMesh
		billboardTemp.Enabled = true
		

		local pets = {}

		for x, pet in pairs(eggPets:GetChildren()) do
			table.insert(pets,pet.Rarity.Value)
		end

		table.sort(pets)	

		for i = 1, math.floor(#pets/2) do
			local j = #pets - i + 1
			pets[i], pets[j] = pets[j], pets[i]
		end

		for _, rarity in pairs(pets) do

			for _, pet in pairs(eggPets:GetChildren()) do
				if pet.Rarity.Value == rarity then
					local rarity = pet.Rarity.Value


					local clonedTemp = template:Clone()

					clonedTemp.Name = pet.Name
					clonedTemp.Rarity.Text = tostring(pet.Rarity.Value).."%"
					clonedTemp.Visible = true
					clonedTemp.Parent = MainFrame

					local PetModel = Module3D:Attach3D(clonedTemp.Display,pet:Clone())
					PetModel:SetDepthMultiplier(1.2)
					PetModel.Camera.FieldOfView = 5
					PetModel.Visible = true

					runService.RenderStepped:Connect(function()
						PetModel:SetCFrame(CFrame.Angles(0,tick() % (math.pi * 2),0) * CFrame.Angles(math.rad(-10),0,0))
					end)
					
					break
				else
					continue
				end


			end
		end


		runService.RenderStepped:Connect(function()
			if player:DistanceFromCharacter(v.EggMesh.Position) < MaxDisplayDistance then
				if cantOpenBillboard == false then
					billboardTemp.Enabled = true
					animateBillboard(billboardTemp, true)
				end

			else
				if cantOpenBillboard == false then
					animateBillboard(billboardTemp, false)
				end
			end
		end)
	end
end

local function hatchOne(petName, egg)
	spawn(function() disableAllBillboards() end)
	ToggleScreenGuis(false)
	camera.CameraType = Enum.CameraType.Scriptable
	tweenService:Create(camera, TweenInfo.new(.5, Enum.EasingStyle.Sine, Enum.EasingDirection.Out, 0, false, 0), {CFrame = egg:FindFirstChild("CameraPart").CFrame}):Play()
	script.Parent.Parent.PetDisplay.PetNameDisplay.Text = petName
	local pet = Pets[egg.Name]:FindFirstChild(petName):Clone()
	isHatching = true
	local eggMesh = egg:FindFirstChild("Egg"):Clone()
	for i, v in pairs(eggMesh:GetChildren()) do
		if v:IsA("BasePart") then
			v.Anchored = true
			v.CanCollide = false
		end
	end
		hatchOneConnection = runService.RenderStepped:Connect(function()
		local cf = CFrame.new(0,0,-eggMesh.PrimaryPart.Size.Z * 2) * CFrame.Angles(0,0,math.sin(time() * 18)/2.3)
		eggMesh:SetPrimaryPartCFrame(camera.CFrame * cf)
	end)
	eggMesh.Parent = camera
	print("Hatching")
	wait(eggHatchSpeed)
	for i, v in pairs(eggMesh:GetChildren()) do
		if v:IsA("BasePart") then
			tweenService:Create(v, TweenInfo.new(.5),{Transparency = 1}):Play()
		end
	end
	wait(.5)
	hatchOneConnection:Disconnect()
	eggMesh:Destroy()
	script.Parent.Parent.PetDisplay.Visible = true
	local PetModel = Module3D:Attach3D(script.Parent.Parent.PetDisplay,pet:Clone())
	PetModel:SetDepthMultiplier(1.2)
	PetModel.Camera.FieldOfView = 5
	PetModel.Visible = true

	runService.RenderStepped:Connect(function()
		PetModel:SetCFrame(CFrame.Angles(0,tick() % (math.pi * 2),0) * CFrame.Angles(math.rad(-10),0,0))
	end)
	wait(eggHatchSpeed)
	tweenService:Create(script.Parent.Parent.PetDisplay:FindFirstChildOfClass("ViewportFrame"),TweenInfo.new(.5),{ImageTransparency = 1}):Play()
	wait(.5)
	for i, v in	pairs(script.Parent.Parent.PetDisplay:GetDescendants()) do
		if v:IsA("ViewportFrame") then
			v:Destroy()
		end
	end
	script.Parent.Parent.PetDisplay.Visible = false
	
	isHatching = false
	
	spawn(function() enableAllBillboards() end)
	ToggleScreenGuis(true)
	_G.newTemplate(petName)
	camera.CameraType = Enum.CameraType.Follow
	
end

local function tripleHatch(petName, petName2, petName3, egg)
	spawn(function() disableAllBillboards() end)
	ToggleScreenGuis(false)
	camera.CameraType = Enum.CameraType.Scriptable
	tweenService:Create(camera, TweenInfo.new(.5, Enum.EasingStyle.Sine, Enum.EasingDirection.Out, 0, false, 0), {CFrame = egg:FindFirstChild("CameraPart").CFrame}):Play()
	
	local pet = Pets[egg.Name]:FindFirstChild(petName):Clone()
	local pet2 = Pets[egg.Name]:FindFirstChild(petName2):Clone()
	local pet3 = Pets[egg.Name]:FindFirstChild(petName3):Clone()
	
	
	script.Parent.Parent.PetDisplay.PetNameDisplay.Text = petName
	script.Parent.Parent.PetDisplay2.PetNameDisplay.Text = petName2
	script.Parent.Parent.PetDisplay3.PetNameDisplay.Text = petName3
	
	isHatching = true
	local eggMesh = egg:FindFirstChild("Egg"):Clone()
	local eggMesh2 = egg:FindFirstChild("Egg"):Clone()
	local eggMesh3 = egg:FindFirstChild("Egg"):Clone()
	
	for i, v in pairs(eggMesh:GetChildren()) do
		if v:IsA("BasePart") then
			v.Anchored = true
			v.CanCollide = false
		end
	end
	for i, v in pairs(eggMesh2:GetChildren()) do
		if v:IsA("BasePart") then
			v.Anchored = true
			v.CanCollide = false
		end
	end
	for i, v in pairs(eggMesh3:GetChildren()) do
		if v:IsA("BasePart") then
			v.Anchored = true
			v.CanCollide = false
		end
	end
	hatchOneConnection = runService.RenderStepped:Connect(function()
	if mps:UserOwnsGamePassAsync(player.UserId, gamepassFH) then
		local cf = CFrame.new(0,0,-eggMesh.PrimaryPart.Size.Z * 2) * CFrame.Angles(0,0,math.sin(time() * 18)/2.3 * 2)
		local cf2 = CFrame.new(10,0,-eggMesh.PrimaryPart.Size.Z * 2) * CFrame.Angles(0,0,math.sin(time() * 18)/2.3 * 2)
		local cf3 = CFrame.new(-10,0,-eggMesh.PrimaryPart.Size.Z * 2) * CFrame.Angles(0,0,math.sin(time() * 18)/2.3 * 2)
		eggMesh:SetPrimaryPartCFrame(camera.CFrame * cf)
		eggMesh2:SetPrimaryPartCFrame(camera.CFrame * cf2)
		eggMesh3:SetPrimaryPartCFrame(camera.CFrame * cf3)
	else
		local cf = CFrame.new(0,0,-eggMesh.PrimaryPart.Size.Z * 2) * CFrame.Angles(0,0,math.sin(time() * 18)/2.3)
		local cf2 = CFrame.new(10,0,-eggMesh.PrimaryPart.Size.Z * 2) * CFrame.Angles(0,0,math.sin(time() * 18)/2.3)
		local cf3 = CFrame.new(-10,0,-eggMesh.PrimaryPart.Size.Z * 2) * CFrame.Angles(0,0,math.sin(time() * 18)/2.3)	
		eggMesh:SetPrimaryPartCFrame(camera.CFrame * cf)
		eggMesh2:SetPrimaryPartCFrame(camera.CFrame * cf2)
		eggMesh3:SetPrimaryPartCFrame(camera.CFrame * cf3)
	end
	end)
	eggMesh.Parent = camera
	eggMesh2.Parent = camera
	eggMesh3.Parent = camera
	
	print("Hatching")
	wait(eggHatchSpeed)
	for i, v in pairs(eggMesh:GetChildren()) do
		if v:IsA("BasePart") then
			tweenService:Create(v, TweenInfo.new(.5),{Transparency = 1}):Play()
		end
	end
	for i, v in pairs(eggMesh2:GetChildren()) do
		if v:IsA("BasePart") then
			tweenService:Create(v, TweenInfo.new(.5),{Transparency = 1}):Play()
		end
	end
	for i, v in pairs(eggMesh3:GetChildren()) do
		if v:IsA("BasePart") then
			tweenService:Create(v, TweenInfo.new(.5),{Transparency = 1}):Play()
		end
	end
	wait(.5)
	hatchOneConnection:Disconnect()
	eggMesh:Destroy()
	eggMesh2:Destroy()
	eggMesh3:Destroy()
	
	script.Parent.Parent.PetDisplay.Visible = true
	script.Parent.Parent.PetDisplay2.Visible = true
	script.Parent.Parent.PetDisplay3.Visible = true
	
	local PetModel = Module3D:Attach3D(script.Parent.Parent.PetDisplay,pet:Clone())
	PetModel:SetDepthMultiplier(1.2)
	PetModel.Camera.FieldOfView = 5
	PetModel.Visible = true
	
	local PetModel2 = Module3D:Attach3D(script.Parent.Parent.PetDisplay2,pet2:Clone())
	PetModel2:SetDepthMultiplier(1.2)
	PetModel2.Camera.FieldOfView = 5
	PetModel2.Visible = true
	
	local PetModel3 = Module3D:Attach3D(script.Parent.Parent.PetDisplay3,pet3:Clone())
	PetModel3:SetDepthMultiplier(1.2)
	PetModel3.Camera.FieldOfView = 5
	PetModel3.Visible = true

	runService.RenderStepped:Connect(function()
		PetModel:SetCFrame(CFrame.Angles(0,tick() % (math.pi * 2),0) * CFrame.Angles(math.rad(-10),0,0))
		PetModel2:SetCFrame(CFrame.Angles(0,tick() % (math.pi * 2),0) * CFrame.Angles(math.rad(-10),0,0))
		PetModel3:SetCFrame(CFrame.Angles(0,tick() % (math.pi * 2),0) * CFrame.Angles(math.rad(-10),0,0))
		
	end)
	wait(eggHatchSpeed)
	tweenService:Create(script.Parent.Parent.PetDisplay:FindFirstChildOfClass("ViewportFrame"),TweenInfo.new(.5),{ImageTransparency = 1}):Play()
	tweenService:Create(script.Parent.Parent.PetDisplay2:FindFirstChildOfClass("ViewportFrame"),TweenInfo.new(.5),{ImageTransparency = 1}):Play()
	tweenService:Create(script.Parent.Parent.PetDisplay3:FindFirstChildOfClass("ViewportFrame"),TweenInfo.new(.5),{ImageTransparency = 1}):Play()
	
	wait(.5)
	for i, v in	pairs(script.Parent.Parent.PetDisplay:GetDescendants()) do
		if v:IsA("ViewportFrame") then
			v:Destroy()
		end
	end
	for i, v in	pairs(script.Parent.Parent.PetDisplay2:GetDescendants()) do
		if v:IsA("ViewportFrame") then
			v:Destroy()
		end
	end
	for i, v in	pairs(script.Parent.Parent.PetDisplay3:GetDescendants()) do
		if v:IsA("ViewportFrame") then
			v:Destroy()
		end
	end
	script.Parent.Parent.PetDisplay.Visible = false
	script.Parent.Parent.PetDisplay2.Visible = false
	script.Parent.Parent.PetDisplay3.Visible = false

	isHatching = false
	
	spawn(function() enableAllBillboards() end)
	ToggleScreenGuis(true)
	_G.newTemplate(petName)
	_G.newTemplate(petName2)
	_G.newTemplate(petName3)	
	camera.CameraType = Enum.CameraType.Follow
	
end

uis.InputBegan:Connect(function(input)
	if input.KeyCode == Enum.KeyCode.E then
		if player.Character ~= nil and isHatching == false then
			local nearestEgg
			local plrPos = player.Character.HumanoidRootPart.Position

			for i,v in pairs(Eggs:GetChildren()) do
				if nearestEgg == nil then
					nearestEgg = v
				else
					if(plrPos - v.PrimaryPart.Position).Magnitude<(nearestEgg.PrimaryPart.Position - plrPos).Magnitude then
						nearestEgg = v
					end
				end
			end

			if player:DistanceFromCharacter(nearestEgg.EggMesh.Position) < MaxDisplayDistance then
				canHatch = true
			else
				canHatch = false
			end
		
			if canHatch == true then
				local result = replicatedStorage:WaitForChild("EggHatchingRemotes"):WaitForChild("HatchOneServer"):InvokeServer(nearestEgg)
				if result ~= "Cannot Hatch" then
					if not cooldown then
						cooldown = true
						hatchOne(result,nearestEgg)
						wait(.1)
						cooldown = false
					end
				else
					print("Cannot hatch")
				end
			end	
		end		
	end
	if input.KeyCode == Enum.KeyCode.R then
		if player.Character ~= nil and isHatching == false then
			local nearestEgg
			local plrPos = player.Character.HumanoidRootPart.Position

			for i,v in pairs(Eggs:GetChildren()) do
				if nearestEgg == nil then
					nearestEgg = v
				else
					if(plrPos - v.PrimaryPart.Position).Magnitude<(nearestEgg.PrimaryPart.Position - plrPos).Magnitude then
						nearestEgg = v
					end
				end
			end

			if player:DistanceFromCharacter(nearestEgg.EggMesh.Position) < MaxDisplayDistance then
				canHatch = true
			else
				canHatch = false
			end

			if canHatch == true then
				local result1, result2, result3 = replicatedStorage.EggHatchingRemotes.TripleHatchServer:InvokeServer(nearestEgg)
					
				if result1 ~= "The player does not own the gamepass" and result2 ~= nil and result3 ~= nil then
					if not cooldown then
						cooldown = true
						tripleHatch(result1,result2,result3,nearestEgg)
						wait(.1)
						cooldown = false
					end
				elseif result1 == "The player does not own the gamepass" then
					mps:PromptGamePassPurchase(player, tripleHatchID)
				end	
			end		
		end
	end
	
	if input.KeyCode == Enum.KeyCode.Q then
		if player.Character ~= nil and isHatching == false then
			local nearestEgg
			local plrPos = player.Character.HumanoidRootPart.Position

			for i,v in pairs(Eggs:GetChildren()) do
				if nearestEgg == nil then
					nearestEgg = v
				else
					if(plrPos - v.PrimaryPart.Position).Magnitude<(nearestEgg.PrimaryPart.Position - plrPos).Magnitude then
						nearestEgg = v
					end
				end
			end

			if player:DistanceFromCharacter(nearestEgg.EggMesh.Position) < MaxDisplayDistance then
				canHatch = true
			else
				canHatch = false
			end

			

			if canHatch == true then
				isAutoHatching = true
				while isAutoHatching == true do
					local result = replicatedStorage:WaitForChild("EggHatchingRemotes"):WaitForChild("AutoHatch"):InvokeServer(nearestEgg)
					if result ~= "Cannot Hatch" then
						if not cooldown then
							stopAutoHatching.Visible = true
							cooldown = true
							hatchOne(result,nearestEgg)
							wait(.1)
							cooldown = false
						end
					else
							print("Cannot hatch")
					end
					if isAutoHatching == false then
						break
					end
				end
			end
		end		
	end
end)

for i, v in pairs(script.Parent.Parent.EggBillboards:GetChildren()) do
	local Ebtn = v.Container.Buttons.E
	local Rbtn = v.Container.Buttons.R
	local Qbtn = v.Container.Buttons.Q
	
	Ebtn.MouseButton1Click:Connect(function()
		if player.Character ~= nil and isHatching == false then
			local nearestEgg
			local plrPos = player.Character.HumanoidRootPart.Position

			for i,v in pairs(Eggs:GetChildren()) do
				if nearestEgg == nil then
					nearestEgg = v
				else
					if(plrPos - v.PrimaryPart.Position).Magnitude<(nearestEgg.PrimaryPart.Position - plrPos).Magnitude then
						nearestEgg = v
					end
				end
			end

			if player:DistanceFromCharacter(nearestEgg.EggMesh.Position) < MaxDisplayDistance then
				canHatch = true
			else
				canHatch = false
			end
			
			if canHatch == true then
				local result = replicatedStorage:WaitForChild("EggHatchingRemotes"):WaitForChild("HatchOneServer"):InvokeServer(nearestEgg)
				if result ~= "Cannot Hatch" then
					if not cooldown then
						cooldown = true
						hatchOne(result,nearestEgg)
						wait(.1)
						cooldown = false
					end
				else
					print("Cannot hatch")
				end
			end	
		end		
	end)
	
	Rbtn.MouseButton1Click:Connect(function()	
		if player.Character ~= nil and isHatching == false then
			local nearestEgg
			local plrPos = player.Character.HumanoidRootPart.Position
			
			for i,v in pairs(Eggs:GetChildren()) do
				if nearestEgg == nil then
					nearestEgg = v
				else
					if(plrPos - v.PrimaryPart.Position).Magnitude<(nearestEgg.PrimaryPart.Position - plrPos).Magnitude then
						nearestEgg = v
					end
				end
			end
			
			if player:DistanceFromCharacter(nearestEgg.EggMesh.Position) < MaxDisplayDistance then
				canHatch = true
			else
				canHatch = false
			end

			if canHatch == true then
				local result1, result2, result3 = replicatedStorage.EggHatchingRemotes.TripleHatchServer:InvokeServer(nearestEgg)

				if result1 ~= "The player does not own the gamepass" and result2 ~= nil and result3 ~= nil then
					if not cooldown then
						cooldown = true
						tripleHatch(result1,result2,result3,nearestEgg)
						wait(.1)
						cooldown = false
					end
				elseif result1 == "The player does not own the gamepass" then
					mps:PromptGamePassPurchase(player, tripleHatchID)
				end	
		end	end	
	end)
	Qbtn.MouseButton1Click:Connect(function()
		if player.Character ~= nil and isHatching == false then
			local nearestEgg
			local plrPos = player.Character.HumanoidRootPart.Position

			for i,v in pairs(Eggs:GetChildren()) do
				if nearestEgg == nil then
					nearestEgg = v
				else
					if(plrPos - v.PrimaryPart.Position).Magnitude<(nearestEgg.PrimaryPart.Position - plrPos).Magnitude then
						nearestEgg = v
					end
				end
			end

			if player:DistanceFromCharacter(nearestEgg.EggMesh.Position) < MaxDisplayDistance then
				canHatch = true
			else
				canHatch = false
			end



			if canHatch == true then
				isAutoHatching = true
				while isAutoHatching == true do
					local result = replicatedStorage:WaitForChild("EggHatchingRemotes"):WaitForChild("AutoHatch"):InvokeServer(nearestEgg)
					if result ~= "Cannot Hatch" then
						if not cooldown then
							stopAutoHatching.Visible = true
							cooldown = true
							hatchOne(result,nearestEgg)
							wait(.1)
							cooldown = false
						end
					else
						print("Cannot hatch")
					end
					if isAutoHatching == false then
						break
					end
				end
			end
		end			
	end)
end




stopAutoHatching.MouseButton1Click:Connect(function()
	isAutoHatching = false
	stopAutoHatching.Visible = false
end)