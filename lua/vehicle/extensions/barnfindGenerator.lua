-- === VEHICLE

local M = {}

local randomSeed
local Miles
local Condition
local WearVar
local Override 
local BalanceWear

local function setupBarnfind(seed, miles, condition, wearVar, showState, override, balanceWear, firstTime)
	local success,err = pcall(function()
		-- variable setup
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
		
		-- natural mileage setup
		local wear_Paint = override.paint or clamp(genCondition * ((1 - wearVar) + math.random() * (wearVar * 2)),0,1)
		local wear_Panels = override.panels or clamp(genCondition * ((1 - wearVar) + math.random() * (wearVar * 2)),0,1)
		
		local wear_Brakes = override.brakes or clamp(genCondition * ((1 - wearVar) + math.random() * (wearVar * 2)),0,1)
		local wear_Suspension = override.suspension or clamp(genCondition * ((1 - wearVar) + math.random() * (wearVar * 2)),0,1)
		local wear_Tires = override.tires or clamp(genCondition * ((1 - wearVar) + math.random() * (wearVar * 2)),0,1)
		
		local wear_Radiator = override.radiator or clamp(genCondition * ((1 - wearVar) + math.random() * (wearVar * 2)),0,1)
		local wear_Oilpan = override.oilpan or clamp(genCondition * ((1 - wearVar) + math.random() * (wearVar * 2)),0,1)
		local wear_Thermals = override.thermals or clamp(genCondition * ((1 - wearVar) + math.random() * (wearVar * 2)),0,1)
		local wear_FuelTank = override.fueltank or clamp(genCondition * ((1 - wearVar) + math.random() * (wearVar * 2)),0,1)
		
		local wear_Exhaust = override.exhaust or clamp(genCondition * ((1 - wearVar) + math.random() * (wearVar * 2)),0,1)
		local wear_Crankshaft = override.crankshaft or clamp(genCondition * ((1 - wearVar) + math.random() * (wearVar * 2)),0,1)
		local wear_Sparkplugs = override.sparkplugs or clamp(genCondition * ((1 - wearVar) + math.random() * (wearVar * 2)),0,1)
		local wear_FuelPump = override.fuelpump or clamp(genCondition * ((1 - wearVar) + math.random() * (wearVar * 2)),0,1)
		local wear_IdleController = override.idle or clamp(genCondition * ((1 - wearVar) + math.random() * (wearVar * 2)),0,1)
		
		local wear_Supercharger = override.supercharger or clamp(genCondition * ((1 - wearVar) + math.random() * (wearVar * 2)),0,1)
		local wear_TurboTurbine = override.turboturbine or clamp(genCondition * ((1 - wearVar) + math.random() * (wearVar * 2)),0,1)
		local wear_TurboCompressor = override.turbocompressor or clamp(genCondition * ((1 - wearVar) + math.random() * (wearVar * 2)),0,1)
		
		local wear_ClutchPressurePlate = override.clutchplate or clamp(genCondition * ((1 - wearVar) + math.random() * (wearVar * 2)),0,1)
		local wear_ClutchDisc = override.clutchdisc or clamp(genCondition * ((1 - wearVar) + math.random() * (wearVar * 2)),0,1)
		local wear_ClutchSprings = override.clutchsprings or clamp(genCondition * ((1 - wearVar) + math.random() * (wearVar * 2)),0,1)
		local wear_Gearbox = override.gearbox or clamp(genCondition * ((1 - wearVar) + math.random() * (wearVar * 2)),0,1)
		
		-- balance the parts condition if requested
		local finalWear_Suspension = balanceWear and clamp(50 ^(2.2 * (1 - wear_Suspension) - 2.25) - .001, 0, .8) or 1 - wear_Suspension
 		local finalWear_Crankshaft = balanceWear and math.max(.98 + 50^(2 * (1 - wear_Crankshaft) - 1), 1) or 1 + (1 - wear_Crankshaft) * 50
		local finalWear_FuelPump = balanceWear and clamp(100 ^((1 - wear_FuelPump) - 1) - .01, 0, 1) or 1 - wear_FuelPump
		local finalWear_SparkPlugs = balanceWear and clamp(100 ^((1 - wear_Sparkplugs) - 1) - .01, 0, 1) or 1 - wear_Sparkplugs
		local finalWear_Turbine = balanceWear and 1 + 10^(7 * (1 - wear_TurboTurbine) - 4) or 1 + (1 - wear_TurboTurbine) * 100

		-- natural condition setup
		local _,reqInfo = Thr.getPartConditionRadiator() -- this is placed before initConditions to prevent a bug
		
		if firstTime then
			partCondition.initConditions(nil, totalMileage, genCondition, wear_Paint)
		end
		
		-- apply chassis and body part wear
		-- PANELS
		-- wip
		
		-- TIRES
		local flatTires = math.floor((1 - wear_Tires) * #v.data.wheels)
		for i = 1,flatTires do
			beamstate.deflateRandomTire()
		end
		
		-- BRAKES
		wheels.scaleBrakeTorque(wear_Brakes)
		
		-- SUSPENSIONS
		local p = {} 
		for a,b in pairs(v.data.beams) do  
			for c,d in pairs({"leaf","coilover","strut","shock","spring"}) do 
				if string.find(b["partOrigin"],d) then 
					table.insert(p,b.cid)
				end 
			end 
		end 

		local beamNum = #p 
		local dam = 0 
		while dam < finalWear_Suspension do 
			local rng = math.random(1,#p) 
			local selB = p[rng] 
			obj:breakBeam(selB) 
			table.remove(p,rng) 
			dam = dam + (1 / beamNum) 
		end 
		
		-- gather part wear info
		wearInfo["Body"] = {
			["Paint"] = tostring(math.floor(wear_Paint * 100)).." %",
			["Panels"] = nil
		}
		
		wearInfo["Chassis"] = {
			["Suspension"] = tostring(math.floor(wear_Suspension * 100)).." %",
			["Brakes"] = tostring(math.floor(wear_Brakes * 100)).." %",
			["Tires"] = tostring(math.floor(wear_Tires * 100)).." %"
		}
		
		-- apply mechanical and powertrain part wear
		if Eng then
			-- EXHAUST
			if wear_Exhaust < .6 then
				local dam = 0 
				local maxDam = math.ceil(6 - (wear_Exhaust * 10))
				for a,b in pairs(v.data.beams) do 
					if b.isExhaust then 
						obj:breakBeam(b.cid) 
						dam = dam + 1 
						if dam > maxDam then 
							break 
						end 
					end 
				end
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
			Thr.setPartConditionThermals(0,{headGasketBlown = parts[1], pistonRingsDamaged = parts[2], connectingRodBearingsDamaged = parts[3]}) 
			
			-- ENGINE
			Eng.damageDynamicFrictionCoef = finalWear_Crankshaft
			Eng.damageIdleAVReadErrorRangeCoef = math.max(30 - (wear_IdleController * 30), 1)
			Eng.fastIgnitionErrorChance = finalWear_FuelPump
			Eng.slowIgnitionErrorChance = finalWear_SparkPlugs

			Eng.wearIdleAVReadErrorRangeCoef = linearScale(totalMileage, 30000000, 1000000000, 1, 5) -- nerf the idle controller wear from mileage

			-- gather main engine wear info
			wearInfo["Engine"] = {
				["Crankshaft"] = tostring(math.max(math.floor(103 - (Eng.damageDynamicFrictionCoef * Eng.wearDynamicFrictionCoef * 3)), 0)).." %",
				["Idle_Controller"] = tostring(math.max(math.floor(102 - (Eng.damageIdleAVReadErrorRangeCoef * Eng.wearIdleAVReadErrorRangeCoef * 2)), 0)).." %",
				["Fuel_Pump"] = tostring(math.floor(100 - (Eng.fastIgnitionErrorChance * 100))).." %",
				["Spark_Plugs"] = tostring(math.floor(100 - (Eng.slowIgnitionErrorChance * 100))).." %",
				["Head_Gasket"] = Thr.headGasketBlown and "Bad" or "Good",
				["Piston_Rings"] = Thr.pistonRingsDamaged and "Bad" or "Good",
				["Connecting_Rods"] = Thr.connectingRodBearingsDamaged and "Bad" or "Good",
				["Exhaust_Pipe"] = tostring(math.floor(wear_Exhaust * 100)).." %"
			}
			
			-- RADIATOR
			Thr.setPartConditionRadiator(0,{coolantMass = reqInfo.coolantMass * wear_Radiator, radiatorDamage = wear_Radiator > .4 and 0 or .2})
			local _,reqInfo2 = Thr.getPartConditionRadiator()
			wearInfo["Radiator"] = {
				["Leaking"] = reqInfo2.radiatorDamage == 0 and "Good" or "Bad",
				["Coolant"] = tostring(math.floor(wear_Radiator * 100)).." %"
			}
			
			-- OILPAN
			if wear_Oilpan < .3 then
				Thr.applyDeformGroupDamageOilpan(.04 - (wear_Oilpan * .1))
			end
			wearInfo["Oil_Pan"] = wear_Oilpan < .3 and "Bad" or "Good"
			
			-- TURBO CHARGER
			if Tur.isExisting then
				Tur.setPartCondition(totalMileage, {damageFrictionCoef = finalWear_Turbine, damageExhaustPowerCoef = wear_TurboCompressor})
				local _,reqInfo = Tur.getPartCondition()
				wearInfo["Turbocharger"] = {
					["Turbine"] = tostring(math.floor(101 - (reqInfo.damageFrictionCoef * linearScale(mileage, 30000000, 1000000000, 1, 2)))).." %",
					["Compressor"] = tostring(math.floor(reqInfo.damageExhaustPowerCoef * 100)).." %" 
				}
			end
			
			-- SUPER CHARGER
			if Spc.isExisting then
				Spc.setPartCondition(totalMileage, {damagePressureCoef = wear_Supercharger})
				local _,reqInfo = Spc.getPartCondition()
				wearInfo["Supercharger"] = tostring(math.floor(linearScale(totalMileage, 30000000, 1000000000, 1, 0.5) * reqInfo.damagePressureCoef * 100)).." %" 
			end
		end
		
		-- FUEL TANK
		for a,b in pairs(eSt) do
			if b.type == "fuelTank" then
				b.setPartCondition(b, totalMileage, wear_FuelTank)
				wearInfo["Fuel_Tank"] = {
					["Fuel_Level"] = tostring(math.floor(b.remainingRatio * 100)).." %",
					["Leaking"] = b.currentLeakRate == 0 and "Good" or "Bad"
				}
			end
		end
		
		-- CLUTCH
		if Clt then
			Clt.clutchPermanentlyDamaged = wear_ClutchSprings < .25
			Clt.damageClutchFreePlayCoef = math.max(30 - (wear_ClutchPressurePlate * 30), 1)
			Clt.damageLockTorqueCoef = Clt.damageLockTorqueCoef

			Clt.wearClutchFreePlayCoef = linearScale(totalMileage, 25000000, 1000000000, 1, 5) -- nerf the clutch pressure plate wear from mileage

			wearInfo["Clutch"] = {
				["Springs"] = Clt.clutchPermanentlyDamaged and "Bad" or "Good",
				["Disc"] = tostring(math.floor(Clt.damageLockTorqueCoef * Clt.wearLockTorqueCoef * 100)).." %",
				["Pressure_Plate"] = tostring(math.max(math.floor(102 - (Clt.damageClutchFreePlayCoef * Clt.wearClutchFreePlayCoef * 2)), 0)).." %"
			}
		end
		
		-- GEARBOX
		if Grb then
			if Grb.type == "manualGearbox" then
				local dam = math.floor((1 - (wear_Gearbox * 1.5)) * #Grb.gearRatios)
				for i = 1,dam do
					local selGear = 0 
					while selGear == 0 do 
						selGear = math.random(1,#Grb.gearRatios)-2 
						Grb.gearRatios[selGear] = 0 
					end 
				end
				wearInfo["Gearbox"] = tostring(math.floor(wear_Gearbox * 100)).." %"
			elseif Grb.type == "automaticGearbox" then
				Grb.wearGearRatioChangeRateCoef = linearScale(totalMileage, 100000000, 500000000, 1, 0.5)
				Grb.damageGearRatioChangeRateCoef = wear_Gearbox
				wearInfo["Gearbox"] = tostring(math.floor(Grb.damageGearRatioChangeRateCoef * Grb.wearGearRatioChangeRateCoef * 100)).." %"
			elseif Grb.type == "dctGearbox" then
				Grb.damageLockTorqueCoef = wear_Gearbox
				wearInfo["Gearbox"] = tostring(math.floor(Grb.damageLockTorqueCoef * Grb.wearLockTorqueCoef * 100)).." %"
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