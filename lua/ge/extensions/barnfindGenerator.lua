-- === GE

-- psa: this code's organization sucks as much as beamNG's lua documentation does. will improve later.

local M = {}

local function configBool(val,def)
	if type(val) == "boolean" then
		return val
	else
		return def
	end
end

local function spawnBarnfind(genConfig)
	log('I', 'Barnfind_State', 'Generating barnfind...')
	local success,err = pcall(function()
		-- setup configs and other variables
		local conf_maxYear = genConfig.MaxYear or -1
		local conf_showInfo = configBool(genConfig.ShowInfo,true)
		local conf_condition = genConfig.Condition or math.random()
		local conf_mileage = genConfig.Mileage or math.random(0,500000)
		local conf_showDistance = configBool(genConfig.ShowDist,true)
		local conf_showStateReport = configBool(genConfig.ShowState,true)
		local conf_wearVariation = genConfig.WearVar or (.1 + math.random() * .35)
		local conf_condOverride = genConfig.Override or {}
		local conf_balanceWear = configBool(genConfig.Balance,true)
		local conf_usePopulation = configBool(genConfig.UsePopulation,true)
		local conf_randomSeed = genConfig.Seed or os.time()
		local conf_chancePark = genConfig.ParkChance or .2
		
		local allCars = core_vehicles.getVehicleList().vehicles 
		local carModel 
		local carConfig 
		local paintColor 
		local paintName
		local carInfo = {}
		
		-- get combined car population of all vehicles OR every configs
		local maxPop = 0 
		local possibleCars = {}
		for a,b in pairs(allCars) do 
			if (conf_maxYear == -1 or (b.model.Years and b.model.Years.min <= conf_maxYear)) and (b.model.Type == "Car" or b.model.Type == "Truck") then 
				for c,d in pairs(b.configs) do 
					if not (d.Type and string.find(d.Type,"Prop")) then 
						if conf_usePopulation then
							if d.Population then
								maxPop = maxPop + d.Population 
							end
						else
							table.insert(possibleCars,d)
						end
					end 
				end 
			end 
		end 

		-- roll a random car to select depending on how populated it is
		local rngPop = conf_usePopulation and math.random(1, maxPop) or possibleCars[math.random(1,#possibleCars)]
		local carFound = false 
		local attempts = 0
		
		while carFound == false do
			for a,b in pairs(allCars) do 
				if (conf_maxYear == -1 or (b.model.Years and b.model.Years.min <= conf_maxYear)) and (b.model.Type == "Car" or b.model.Type == "Truck") then 
					for c,d in pairs(b.configs) do 
						
						-- make sure it fits the max year config, that it has a population value (if requested) and it isn't a simplified traffic car
						if not (d.Type and string.find(d.Type,"Prop")) then 
							local chosenVehicle = false
							if conf_usePopulation then
								if d.Population then
									rngPop = rngPop - d.Population 
									chosenVehicle = (rngPop <= 0)
								end
							else
								chosenVehicle = (rngPop == d)
							end
							
							if chosenVehicle then
								carModel = b.model.key 
								carConfig = c 
								
								local years = d.Years or b.model.Years or nil
								-- randomize their paint with available factory colors
								local allPaints = b.model.paints 
								local paintRng = math.random(1, tableSize(allPaints)) 
								local paintCount = 0 
								
								for e,f in pairs(allPaints) do 
									paintCount = paintCount + 1 
									if paintCount == paintRng then 
										paintColor = f 
										paintName = e
										break 
									end 
								end 
								
								-- gather vehicle info
								carInfo = {Vehicle = (b.model.Brand or "").." "..b.model.Name,
								Variant = d.Configuration or "N/A",
								Year = (years and math.random(years.min,years.max) or "N/A"),
								Color = paintName or "N/A",
								Population = d.Population or "N/A",
								Value = d.Value and "$ "..tostring(d.Value) or "N/A",
								Mileage = tostring(math.floor(conf_mileage)).." km",
								Condition = tostring(math.floor(conf_condition * 100)).." %"}
									
								carFound = true 
								break
							end
						end 
						if carFound then break end 
					end 
				end 
				if carFound then break end 
			end
			
			if not carFound then
				attempts = attempts + 1
				if attempts > 20 then
					error("Could not select a vehicle. Your Max Year Config might be too low.")
				end
			end
		end 
		
		-- find a random parking spot to spawn the vehicle
		local park
		local road
		if math.random() < conf_chancePark then
			local allParks = gameplay_parking.getParkingSpots() -- this function makes sure parking sites are loaded before being returned
			local parkingSpots = gameplay_parking.findParkingSpots(be:getPlayerVehicle(0):getPosition(), 10000, 10000000000) 
			local parkingSpotNames = tableKeys(parkingSpots) 

			local parkingSpotName = parkingSpotNames[math.random(tableSize(parkingSpotNames))] 
			park = parkingSpots[parkingSpotName]
		end
		
		if park then
			local approxDistance = math.floor(math.sqrt(park.squaredDistance))
			if conf_showDistance then
				carInfo['Distance'] = tostring(approxDistance).." m"
			end
		else
			-- if not, find a random road to spawn the vehicle instead
			local pathNodes = tableSize(map.getMap().nodes)
			if pathNodes > 0 then
				local selRoad = math.random(1,pathNodes)
				local ind = 1
				for a,b in pairs(map.getMap().nodes) do
					if ind == selRoad then
						road = b
						local approxDistance = math.floor(math.sqrt(b.pos:squaredDistance(be:getPlayerVehicle(0):getPosition())))
						if conf_showDistance then
							carInfo['Distance'] = tostring(approxDistance).." m"
						end
						
						break
					end
					ind = ind + 1
				end
			else
				error("No available locations could be found to spawn the vehicle. You might need to use a different map.")
			end
		end

		-- spawn the vehicle at the selected parking spot & setup the rest
		local car = core_vehicles.spawnNewVehicle(carModel, {config = carConfig, paint = paintColor}) 
		be:enterNextVehicle(0, 1) 
		
		if park then
			gameplay_parking.moveToParkingSpot(car:getId(), park.ps, true)
		else
			car:setPosition(road.pos + vec3(0,0,.5))
			car:queueLuaCommand("electrics.setIgnitionLevel(0)")
		end
		
		spawn.safeTeleport(car, car:getPosition(), car:getRotation())
		
		local stringTable = "{"
		for i,v in pairs(conf_condOverride) do
			stringTable = stringTable..i.." = "..v..", "
		end
		stringTable = stringTable.."test = nil}"
		
		print(genConfig.ShowState)
		car:queueLuaCommand("local condOverride = "..stringTable.." extensions.barnfindGenerator.setupBarnfind("..tostring(conf_randomSeed)..","..tostring(conf_mileage * 500000)..","..tostring(conf_condition)..","..tostring(conf_wearVariation)..","..tostring(conf_showStateReport)..",condOverride,"..tostring(conf_balanceWear)..", true)") 
		
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

M.spawnBarnfind = spawnBarnfind

return M