-- === GE

-- psa: this code's organization sucks as much as beamNG's lua documentation does. will improve later.

local M = {}

local function spawnBarnfind(genConfig)
	log('I', 'barnfindGenerator', 'Generating barnfind...')
	local success,err = pcall(function()
		-- setup configs and other variables
		local conf_maxYear = genConfig.MaxYear or -1
		local conf_showInfo = genConfig.ShowInfo or true
		local conf_condition = genConfig.Condition or math.random()
		local conf_mileage = genConfig.Mileage or math.random(0,500000000)
		local conf_maxDistance = genConfig.MaxDist or 10000000000
		local conf_minDistance = genConfig.MinDist or 100000 -- doesnt work due to a coding mistake in the beamng parking script
		local conf_showDistance = genConfig.ShowDist or true
		local conf_showStateReport = genConfig.ShowState or true
		
		local allCars = core_vehicles.getVehicleList().vehicles 
		local carModel 
		local carConfig 
		local paintColor 
		local paintName
		local carInfo = {}
		
		-- get combined car population of all vehicles
		local maxPop = 0 
		for a,b in pairs(allCars) do 
			if (conf_maxYear == -1 or (b.model.Years and b.model.Years.min <= conf_maxYear)) and (b.model.Type == "Car" or b.model.Type == "Truck") then 
				for c,d in pairs(b.configs) do 
					if d.Population and not (d.Type and string.find(d.Type,"Prop")) then 
						maxPop = maxPop + d.Population 
					end 
				end 
			end 
		end 
		
		-- roll a random car to select depending on how populated it is
		local rngPop = math.random(1, maxPop) 
		local carFound = false 
		local attempts = 0
		
		while carFound == false do
			for a,b in pairs(allCars) do 
				if (conf_maxYear == -1 or (b.model.Years and b.model.Years.min <= conf_maxYear)) and (b.model.Type == "Car" or b.model.Type == "Truck") then 
					for c,d in pairs(b.configs) do 
						
						-- make sure it fits the max year config, that it has a population value and it isn't a simplified traffic car
						if d.Population and not (d.Type and string.find(d.Type,"Prop")) then 
							rngPop = rngPop - d.Population 
							if rngPop <= 0 then 
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
								Population = d.Population,
								Value = d.Value or "N/A",
								Mileage = tostring(math.floor(conf_mileage / 1000)).." km",
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
		local parkingSpots = gameplay_parking.findParkingSpots(be:getPlayerVehicle(0):getPosition(), conf_minDistance, conf_maxDistance) 
		local parkingSpotNames = tableKeys(parkingSpots) 

		local parkingSpotName = parkingSpotNames[math.random(tableSize(parkingSpotNames))] 
		local park = parkingSpots[parkingSpotName]
		
		if park == nil then
			error("No parking location could be found. Either your Max distance Config is too low or this map doesn't have parking support.")
		end
		
		local approxDistance = math.floor(math.sqrt(park.squaredDistance))
		if conf_showDistance then
			carInfo['Distance'] = tostring(approxDistance).." m"
		end
		
		-- spawn the vehicle at the selected parking spot & setup the rest
		local car = core_vehicles.spawnNewVehicle(carModel, {config = carConfig, paint = paintColor}) 
		be:enterNextVehicle(0, 1) 
		
		gameplay_parking.moveToParkingSpot(car:getId(), park.ps, true)
		car:queueLuaCommand("extensions.barnfindGenerator.setupBarnfind("..tostring(conf_mileage)..","..tostring(conf_condition)..","..tostring(conf_showStateReport)..")") 
		
		-- show the vehicle info on the console
		if conf_showInfo then
			for a,b in pairs(carInfo) do
				log('O', 'barnfindGenerator', tostring(a)..": "..tostring(b))
			end
		end
	end)
	
	-- protected call result
	if success then
		log('I', '', 'Execution Complete!')
	else
		log('E', '', 'Execution Failed: '..err)
	end
end

M.spawnBarnfind = spawnBarnfind

return M