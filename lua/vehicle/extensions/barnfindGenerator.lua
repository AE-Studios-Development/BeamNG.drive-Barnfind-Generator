-- === VEHICLE

local M = {}

-- memory variables
local randomSeed
local Miles
local Condition
local WearVar
local Override 
local BalanceWear

-- cleanup functions
local function setupWear(override)
	return override or clamp(Condition * ((1 - WearVar) + math.random() * (WearVar * 2)),0,1)
end

local function containsString(strVal,tabVal)
	for a,b in pairs(tabVal) do
		if string.find(strVal,b) then
			return true
		end
	end
	return false
end

-- main function
local function setupBarnfind(seed, miles, condition, wearVar, showState, override, balanceWear, firstTime)
	local success,err = pcall(function()
		-- main setup
		randomSeed = seed
		Miles = miles
		Condition = condition
		WearVar = wearVar
		Override = override
		BalanceWear = balanceWear
		
		local genCondition = tonumber(condition)
		local totalMileage = tonumber(miles)
		local wearInfo = {}
		
		math.randomseed(randomSeed)
		
		local Eng = powertrain.getDevice("mainEngine") 
		local Grb = powertrain.getDevice("gearbox") 
		local Clt = powertrain.getDevice("clutch") 
		local Thr = Eng and Eng.thermals or nil
		local eSt = energyStorage.getStorages()
		local Tur = Eng and Eng.turbocharger or nil
		local Spc = Eng and Eng.supercharger or nil
		local fEm = powertrain.getDevice("frontMotor") 
		local rEm = powertrain.getDevice("rearMotor") 
		
		-- natural mileage setup
		local wear_Paint = setupWear(override.paint)
		local wear_Panels = setupWear(override.panels)
		
		local wear_Brakes = setupWear(override.brakes)
		local wear_Suspension = setupWear(override.suspension)
		local wear_Tires = setupWear(override.tires)
		
		local wear_Radiator = setupWear(override.radiator)
		local wear_CoolantLevel = setupWear(override.coolant)
		local wear_Oilpan = setupWear(override.oilpan)
		local wear_Thermals = setupWear(override.thermals)
		local wear_FuelLevel = setupWear(override.fuellevel)
		local wear_FuelTank = setupWear(override.fueltank)
		
		local wear_Exhaust = setupWear(override.exhaust)
		local wear_Crankshaft = setupWear(override.crankshaft)
		local wear_Sparkplugs = setupWear(override.sparkplugs)
		local wear_FuelPump = setupWear(override.fuelpump)
		local wear_IdleController = setupWear(override.idle)
		
		local wear_ElectricMotor = setupWear(override.motors)
		local wear_Battery = setupWear(override.battery)
		
		local wear_Supercharger = setupWear(override.supercharger)
		local wear_TurboTurbine = setupWear(override.turboturbine)
		local wear_TurboCompressor = setupWear(override.turbocompressor)
		
		local wear_ClutchPressurePlate = setupWear(override.clutchplate)
		local wear_ClutchDisc = setupWear(override.clutchdisc)
		local wear_ClutchSprings = setupWear(override.clutchsprings)
		local wear_Gearbox = setupWear(override.gearbox)
		
		-- balance the parts condition if requested
		local finalWear_Suspension = balanceWear and clamp(50 ^(2.2 * (1 - wear_Suspension) - 2.25) - .001, 0, .8) or 1 - wear_Suspension
 		local finalWear_Crankshaft = balanceWear and math.max(.98 + 50^(2 * (1 - wear_Crankshaft) - 1), 1) or 1 + (1 - wear_Crankshaft) * 33
		local finalWear_FuelPump = balanceWear and clamp(100 ^((1 - wear_FuelPump) - 1) - .01, 0, 1) or 1 - wear_FuelPump
		local finalWear_SparkPlugs = balanceWear and clamp(100 ^((1 - wear_Sparkplugs) - 1) - .01, 0, 1) or 1 - wear_Sparkplugs
		local finalWear_Turbine = balanceWear and 1 + 20^(4 * (1 - wear_TurboTurbine) - .5) - .001 or 1 + (1 - wear_TurboTurbine) * 100
		local finalWear_Panels = balanceWear and 500 ^(-wear_Panels) -.011 or 1 - wear_Panels
		local finalWear_ManualGearbox = balanceWear and 250 ^(wear_Gearbox - 1) - .01 or 1 - wear_Gearbox
		
		-- natural condition setup
		local _,reqInfo = Thr.getPartConditionRadiator() -- this is placed before initConditions to prevent a bug
		
		local exhaustBeams = {}
		local suspensionBeams = {}
		local panelBeams = {}
		for a,b in pairs(v.data.beams) do -- this is here for performance
			if b.isExhaust and b.breakGroup ~= nil and containsString(b.breakGroup,{"exhaust","muffler"}) then
				table.insert(exhaustBeams,b)
			elseif containsString(b.partOrigin,{"coilover","leaf","spring","strut","shock"}) then
				table.insert(suspensionBeams,b.cid)
			elseif b.breakGroup ~= nil and type(b.breakGroup) ~= "table" and not containsString(b.breakGroup,{"wheel","fueltank","transmissionmount","driveshaft","enginemount"}) then
				table.insert(panelBeams,b)
			end
		end
			
		if firstTime then
			partCondition.initConditions(nil, totalMileage, genCondition, wear_Paint)
		end
		
		-- apply chassis and body part wear
		-- PANELS
		local beamNum = #panelBeams
		local dam = 0
		while dam < finalWear_Panels do 
			local rng = math.random(1,#panelBeams) 
			local selB = panelBeams[rng] 
			obj:breakBeam(selB.cid)
			beamstate.triggerDeformGroup(selB.breakGroup)
			table.remove(panelBeams,rng) 
			dam = dam + (1 / beamNum) 
		end 
		
		-- TIRES
		local flatTires = math.floor((1 - wear_Tires) * #v.data.wheels)
		for i = 1,flatTires do
			beamstate.deflateRandomTire()
		end
		
		-- BRAKES
		wheels.scaleBrakeTorque(wear_Brakes)
		
		-- SUSPENSIONS
		local beamNum = #suspensionBeams 
		local dam = 0 
		while dam < finalWear_Suspension do 
			local rng = math.random(1,#suspensionBeams) 
			local selB = suspensionBeams[rng] 
			obj:breakBeam(selB) 
			table.remove(suspensionBeams,rng) 
			dam = dam + (1 / beamNum) 
		end 
		
		-- gather part wear info
		wearInfo["Body"] = {
			["Paint"] = tostring(math.floor(wear_Paint * 100)).." %",
			["Panels"] = tostring(math.floor(wear_Panels * 100)).." %"
		}
		
		wearInfo["Chassis"] = {
			["Suspension"] = tostring(math.floor(wear_Suspension * 100)).." %",
			["Brakes"] = tostring(math.floor(wear_Brakes * 100)).." %",
			["Tires"] = tostring(math.floor(wear_Tires * 100)).." %"
		}
		
		-- apply mechanical and powertrain part wear
		if Eng then
			-- ENGINE
			Eng.damageDynamicFrictionCoef = finalWear_Crankshaft
			Eng.damageIdleAVReadErrorRangeCoef = math.max(15 - (wear_IdleController * 15), 1)
			Eng.fastIgnitionErrorChance = finalWear_FuelPump
			Eng.slowIgnitionErrorChance = finalWear_SparkPlugs

			Eng.wearIdleAVReadErrorRangeCoef = linearScale(totalMileage, 50000000, 1000000000, 1, 5) -- nerf the idle controller wear from mileage

			-- gather main engine wear info
			wearInfo["Engine"] = {
				["Crankshaft"] = tostring(math.max(math.floor(103 - (Eng.damageDynamicFrictionCoef * Eng.wearDynamicFrictionCoef * 3)), 0)).." %",
				["Idle_Controller"] = tostring(math.max(math.floor(102.5 - (Eng.damageIdleAVReadErrorRangeCoef * Eng.wearIdleAVReadErrorRangeCoef * 2.5)), 0)).." %",
				["Fuel_Pump"] = tostring(math.floor(100 - (Eng.fastIgnitionErrorChance * 100))).." %",
				["Spark_Plugs"] = tostring(math.floor(100 - (Eng.slowIgnitionErrorChance * 100))).." %",
			}
			
			if Thr then
				-- EXHAUST
				local beamNum = #exhaustBeams
				local dam = 0 
				while dam < -.4 + (1 - wear_Exhaust) do
					local rng = math.random(1,#exhaustBeams) 
					local selB = exhaustBeams[rng]
					obj:breakBeam(selB.cid)
					beamstate.triggerDeformGroup(selB.breakGroup)
					table.remove(exhaustBeams,rng)
					dam = dam + (1 / beamNum)  
				end
				
				-- HEAD GASKET + PISTON RINGS + CONNECTING RODS
				local parts = {false, false, false}
				local dam = 0
				for i = 1,3 do
					if (1 / (2 ^ i) > wear_Thermals) then
						dam = dam + 1
					else
						break
					end
				end
				
				for i = 1,dam do
					while true do
						local selPart = math.random(1,#parts)
						if parts[selPart] == false then
							parts[selPart] = true
							break
						end
					end
				end
				Thr.setPartConditionThermals(0,{headGasketBlown = override.headgasket or parts[1], pistonRingsDamaged = override.pistonrings or parts[2], connectingRodBearingsDamaged = override.connectingrods or parts[3]}) 
				
				-- gather engine thermal wear info
				wearInfo["Engine"]["Head_Gasket"] = Thr.headGasketBlown and "Bad" or "Good"
				wearInfo["Engine"]["Piston_Rings"] = Thr.pistonRingsDamaged and "Bad" or "Good"
				wearInfo["Engine"]["Connecting_Rods"] = Thr.connectingRodBearingsDamaged and "Bad" or "Good"
				wearInfo["Engine"]["Exhaust_Pipe"] = tostring(math.floor(wear_Exhaust * 100)).." %"
			
				-- RADIATOR
				if Thr.coolantTemperature then
					Thr.setPartConditionRadiator(0,{coolantMass = reqInfo.coolantMass * wear_CoolantLevel, radiatorDamage = wear_Radiator > .3 and 0 or math.max(.3 - wear_Radiator,0)})
					local _,reqInfo2 = Thr.getPartConditionRadiator()
					wearInfo["Radiator"] = {
						["Leaking"] = reqInfo2.radiatorDamage == 0 and "Good" or "Bad",
						["Coolant"] = tostring(math.floor(wear_CoolantLevel * 100)).." %"
					}
				end
				
				-- OILPAN
				if wear_Oilpan < .3 then
					Thr.applyDeformGroupDamageOilpan(.04 - (wear_Oilpan * .1))
				end
				wearInfo["Oil_Pan"] = wear_Oilpan < .3 and "Bad" or "Good"
			end
			
			-- TURBO CHARGER
			if Tur.isExisting then
				Tur.setPartCondition(totalMileage, {damageFrictionCoef = finalWear_Turbine, damageExhaustPowerCoef = wear_TurboCompressor})
				local _,reqInfo = Tur.getPartCondition()
				wearInfo["Turbocharger"] = {
					["Turbine"] = tostring(clamp(math.floor(101 - (reqInfo.damageFrictionCoef * linearScale(totalMileage, 30000000, 1000000000, 1, 2))),0,100)).." %",
					["Compressor"] = tostring(math.floor(reqInfo.damageExhaustPowerCoef * 100)).." %" 
				}
			end
			
			-- SUPER CHARGER
			if Spc.isExisting then
				Spc.setPartCondition(totalMileage, {damagePressureCoef = wear_Supercharger})
				local _,reqInfo = Spc.getPartCondition()
				wearInfo["Supercharger"] = tostring(math.floor(linearScale(totalMileage, 30000000, 1000000000, 1, 0.5) * reqInfo.damagePressureCoef * 100)).." %" 
			end
			
		-- ELECTRIC MOTORS
		else
			if fEm then
				fEm.scaleOutputTorque(fEm, wear_ElectricMotors)
				wearInfo["Electric Motors"] = tostring(math.floor(wear_ElectricMotors * 100)).." %" 
			end
			if rEm then
				rEm.scaleOutputTorque(rEm, wear_ElectricMotors)
				wearInfo["Electric Motors"] = tostring(math.floor(wear_ElectricMotors * 100)).." %" 
			end
		end
		
		for a,b in pairs(eSt) do
			-- FUEL TANK
			if b.type == "fuelTank" then
				b.setPartCondition(b, totalMileage, wear_FuelLevel)
				b.currentLeakRate = wear_FuelTank > .25 and 0 or math.max(.25 - wear_Radiator,0)
				wearInfo["Fuel_Tank"] = {
					["Fuel_Level"] = tostring(math.floor(b.remainingRatio * 100)).." %",
					["Leaking"] = b.currentLeakRate == 0 and "Good" or "Bad"
				}
			
			-- BATTERY
			elseif b.type == "electricBattery" then
				b.setRemainingRatio(b, wear_Battery)
				wearInfo["Battery"] = tostring(math.floor(wear_Battery * 100)).." %" 
			end
		end
		
		-- CLUTCH
		if Clt then
			Clt.clutchPermanentlyDamaged = wear_ClutchSprings < .25
			Clt.damageClutchFreePlayCoef = math.max(15 - (wear_ClutchPressurePlate * 15), 1)
			Clt.damageLockTorqueCoef = math.min(1.15 - (1 - wear_ClutchDisc),1)

			Clt.wearClutchFreePlayCoef = linearScale(totalMileage, 30000000, 1000000000, 1, 5) -- nerf the clutch pressure plate wear from mileage

			wearInfo["Clutch"] = {
				["Springs"] = Clt.clutchPermanentlyDamaged and "Bad" or "Good",
				["Disc"] = tostring(math.floor(Clt.damageLockTorqueCoef * Clt.wearLockTorqueCoef * 100)).." %",
				["Pressure_Plate"] = tostring(math.max(math.floor(102.5 - (Clt.damageClutchFreePlayCoef * Clt.wearClutchFreePlayCoef * 2.5)), 0)).." %"
			}
		end
		
		-- GEARBOX
		if Grb then
			if Grb.type == "manualGearbox" then
				local dam = math.floor(finalWear_ManualGearbox * #Grb.gearRatios)
				for i = 1,dam do
					local selGear = 0 
					while selGear == 0 do 
						selGear = math.random(1,#Grb.gearRatios)-2 
						Grb.gearRatios[selGear] = 0 
					end 
				end
				wearInfo["Gearbox"] = tostring(math.floor(wear_Gearbox * 100)).." %"
			elseif Grb.type == "automaticGearbox" then
				Grb.wearGearRatioChangeRateCoef = linearScale(totalMileage, 100000000, 500000000, 1, 0.7)
				Grb.damageGearRatioChangeRateCoef = wear_Gearbox
				wearInfo["Gearbox"] = tostring(math.floor(Grb.damageGearRatioChangeRateCoef * Grb.wearGearRatioChangeRateCoef * 100)).." %"
			elseif Grb.type == "dctGearbox" then
				Grb.damageLockTorqueCoef = wear_Gearbox
				wearInfo["Gearbox"] = tostring(math.floor(Grb.damageLockTorqueCoef * Grb.wearLockTorqueCoef * 100)).." %"
			end
		end
		
		-- nerf friction wear
		for a,b in pairs(powertrain.getDevices()) do 
			if a ~= "turbocharger" then 
				for c,d in pairs(b) do 
					if c == "wearFrictionCoef" or c == "damageFrictionCoef" then 
						b[c] = math.max(1 + ((d - 1) * .25),1) 
					end 
				end 
			end 
		end 

		-- display vehicle state if requested
		if showState then
			log('I', 'Barnfind_Info', 'Vehicle Part Wear:')
			dump(wearInfo)
		end
	end)
	if not success then
		log('E', 'Barnfind_Error', 'A vehicle error has occured: '..err)
	end
end

-- reset function
local function resetBarnfind()
	if randomSeed then
		setupBarnfind(randomSeed, Miles, Condition, WearVar, false, Override, BalanceWear, false)
		log('I', 'Barnfind_State', 'Vehicle state has been successfully reset.')
	else
		log('E', 'Barnfind_Error', "Error while resetting: This vehicle isn't a barnfind.")
	end
end

M.setupBarnfind = setupBarnfind
M.resetBarnfind = resetBarnfind

return M
