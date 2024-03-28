-- === GE

local M = {}

-- memory variables
local spawnSeed
local wearSeed
local lastConfig

-- cleanup functions
local function configBool(val,def)
	if type(val) == "boolean" then
		return val
	else
		return def
	end
end

-- main function
local function spawnBarnfind(genConfig) 
	log('I', 'Barnfind_State', 'Generating barnfind...')
	local success,err = pcall(function()
		-- remember configs and setup rng seed
		local globalSeed = os.time() + os.clock() * 1000
		spawnSeed = genConfig.Seed or globalSeed
		wearSeed = genConfig.WearSeed or globalSeed
		lastConfig = genConfig
		
		math.randomseed(spawnSeed)
		-- setup configs and other variables
		local conf_maxYear = genConfig.MaxYear or -1
		local conf_showInfo = configBool(genConfig.ShowInfo,true)
		local conf_condition = genConfig.Condition or math.random()
		local conf_mileage = genConfig.Mileage or math.random(0,650000)
		local conf_showDistance = configBool(genConfig.ShowDist,true)
		local conf_showStateReport = configBool(genConfig.ShowState,true)
		local conf_wearVariation = genConfig.WearVar or .35
		local conf_condOverride = genConfig.Override or {}
		local conf_balanceWear = configBool(genConfig.Balance,true)
		local conf_usePopulation = configBool(genConfig.UsePopulation,true)
		local conf_WearRandomSeed = genConfig.WearSeed or globalseed
		local conf_SpawnRandomSeed = genConfig.Seed or globalseed
		local conf_chancePark = genConfig.ParkChance or .15
		local conf_moddedVehicles = configBool(genConfig.ModCars,false)
		local conf_spawnAtCamera = configBool(genConfig.SpawnHere,false)
		
		local allCars = core_vehicles.getVehicleList().vehicles 
		local carModel, carConfig, paintColor, paintName
		local carInfo = {}
		
		-- get combined car population of all vehicles OR every configs
		local maxPop = 0 
		local possibleCars = {}
		for a,b in pairs(allCars) do 
			if (conf_maxYear == -1 or (b.model.Years and b.model.Years.min <= conf_maxYear)) and (b.model.Type == "Car" or b.model.Type == "Truck") then 
				for c,d in pairs(b.configs) do 
					if not (d.Type and string.find(d.Type,"Prop")) and (conf_moddedVehicles or d.Source == "BeamNG - Official") then 
						if conf_usePopulation then
							if d.Population then
								possibleCars[c] = {b,d}
								maxPop = maxPop + d.Population 
							end
						else
							possibleCars[c] = {b,d}
						end
					end 
				end 
			end 
		end 

		-- roll a random car to select depending on how populated it is
		local carName, carData
		if conf_usePopulation then
			local numLeft = math.random(1, maxPop)
			while not carData do
				for a,b in pairs(possibleCars) do
					numLeft = numLeft - b[2].Population
					if numLeft <= 0 then
						carName = a
						carData = b
						break
					end
				end
			end
		else
			local carRng = math.random(1, tableSize(possibleCars))  
			local carKeys = tableKeys(possibleCars)
			carName = carKeys[carRng]
			carData = possibleCars[carName]
		end
		
		local modelData = carData[1].model
		local variantData = carData[2]
								
		local years = variantData.Years or modelData.Years or nil
		-- randomize their paint with available factory colors
		local allPaints = modelData.paints 
		local paintRng = math.random(1, tableSize(allPaints))  
		
		local allPaintsKeys = tableKeys(allPaints)
		paintName = allPaintsKeys[paintRng]
		paintColor = allPaints[paintName]
								
		-- gather vehicle info
		carInfo = {Vehicle = (modelData.Brand or "").." "..modelData.Name,
		Variant = variantData.Configuration or "N/A",
		Year = (years and math.random(years.min,years.max) or "N/A"),
		Color = paintName or "N/A",
		Population = variantData.Population or "N/A",
		Value = variantData.Value and "$ "..tostring(variantData.Value) or "N/A",
		Mileage = tostring(math.floor(conf_mileage)).." km",
		Condition = tostring(math.floor(conf_condition * 100)).." %"}
		
		local park, road
		if not conf_spawnAtCamera then
			-- find a random parking spot to spawn the vehicle
			if math.random() < conf_chancePark then
				local allParks = gameplay_parking.getParkingSpots() -- this function makes sure parking sites are loaded before being returned
				local parkingSpots = gameplay_parking.findParkingSpots(nil, nil, 10000000000) 
				local parkingSpotNames = tableKeys(parkingSpots) 

				local parkingSpotName = parkingSpotNames[math.random(tableSize(parkingSpotNames))] 
				park = parkingSpots[parkingSpotName]
				
				if not park then
					log('W', 'Barnfind_Warning', "This map doesn't have any parking spots, spawning vehicle on a road instead...")
				end
			end
			
			if park then
				local approxDistance = math.floor(math.sqrt(park.squaredDistance))
				if conf_showDistance then
					carInfo['Distance'] = tostring(approxDistance).." m"
				end
			else
				-- if not, find a random road to spawn the vehicle instead
				local allNodes = map.getMap().nodes
				local pathNodes = tableSize(allNodes)
				
				if pathNodes > 0 then
					local selRoad = math.random(1,pathNodes)
					local allNodesKeys = tableKeys(allNodes)
					
					local roadName = allNodesKeys[selRoad]
					road = allNodes[roadName]
					
					local approxDistance = math.floor(math.sqrt(road.pos:squaredDistance(core_camera.getPosition())))
					if conf_showDistance then
						carInfo['Distance'] = tostring(approxDistance).." m"
					end
				else
					error("No available locations could be found to spawn the vehicle. You might need to use a different map.")
				end
			end
		end

		-- spawn the vehicle at the selected parking spot & setup the rest
		local car = core_vehicles.spawnNewVehicle(modelData.key, {config = carName, paint = paintColor}) 
		be:enterNextVehicle(0, 1) 
		
		if park then
			gameplay_parking.moveToParkingSpot(car:getId(), park.ps, true)
		else
			local vec = road and road.pos + vec3(0,0,.5) or core_camera.getPosition()
			local qua = road and quatFromEuler(0, 0, math.random() * 360) or quatFromEuler(0, 0, 0)
			car:setPosRot(vec.x, vec.y, vec.z, qua.x, qua.y, qua.z, qua.w)
			
			car:queueLuaCommand("electrics.setIgnitionLevel(0)")
		end
		
		spawn.safeTeleport(car, car:getPosition(), car:getRotation())
		
		-- send the vehicle and condition info to vehicle lua
		local stringTable = "{"
		local tabSize = tableSize(conf_condOverride)
		local ind = 1
		for a,b in pairs(conf_condOverride) do
			stringTable = stringTable..a.." = "..b
			ind = ind + 1
			if ind <= tabSize then
				stringTable = stringTable..", "
			end
		end
		
		local strWearSeed = tostring(wearSeed)
		local strConfMile = tostring(conf_mileage * 1000)
		local strConfCond = tostring(conf_condition)
		local strConfWearVar = tostring(conf_wearVariation)
		local strShowRep = tostring(conf_showStateReport)
		local strConfBal = tostring(conf_balanceWear)
		
		car:queueLuaCommand("local condOverride = "..stringTable.."} extensions.barnfindGenerator.setupBarnfind("..strWearSeed..","..strConfMile..","..strConfCond..","..strConfWearVar..","..strShowRep..",condOverride,"..strConfBal..", true)") 
		
		-- show the vehicle info on the console
		if conf_showInfo then
			for a,b in pairs(carInfo) do
				log('O', 'Barnfind_Info', tostring(a)..": "..tostring(b))
			end
		end
	end)
	
	-- protected call result
	if success then
		log('I', 'Barnfind_State', 'Execution Complete!')
	else
		log('E', 'Barnfind_Error', 'Execution Failed: '..err)
	end
end

local function respawnPrev()
	if lastConfig then
		lastConfig["Seed"] = spawnSeed
		lastConfig["WearSeed"] = wearSeed
		
		spawnBarnfind(lastConfig)
	else
		log('E', 'Barnfind_Error', 'There was no junk car generation made previously.')
	end
end

M.respawnPrev = respawnPrev
M.spawnBarnfind = spawnBarnfind

return M
