-- === VEHICLE

local M = {}

local function setupBarnfind(miles,condition,showState)
	-- variable setup
	local genCondition = tonumber(condition)
	local totalMileage = tonumber(miles)
	local wearInfo = {}
	
	local Eng = powertrain.getDevice("mainEngine") 
	local Grb = powertrain.getDevice("gearbox") 
	local Clt = powertrain.getDevice("clutch") 
	local Thr = Eng.thermals
	local eSt = energyStorage.getStorages()
	local Tur = Eng.turbocharger
	local Spc = Eng.supercharger
	
	-- natural mileage setup
	partCondition.initConditions(nil, totalMileage, genCondition, genCondition)
	
	-- other part wear setup
	wheels.scaleBrakeTorque(genCondition)
	
	-- == detailed vehicle wear and condition coming soon :tm:
	
	-- gather info about the part wear
	if Eng then
		wearInfo["Engine"] = {
			["Crankshaft"] = Eng.damageDynamicFrictionCoef * Eng.wearDynamicFrictionCoef,
			["Idle_Controller"] = tostring(math.max(math.floor(100 - (Eng.damageIdleAVReadErrorRangeCoef * Eng.wearIdleAVReadErrorRangeCoef * 2)), 0)).." %",
			["Fuel_Pump"] = tostring(math.floor(100 - (Eng.fastIgnitionErrorChance * 100))).." %",
			["Spark_Plugs"] = tostring(math.floor(100 - (Eng.slowIgnitionErrorChance * 100))).." %",
			["Head_Gasket"] = Thr.headGasketBlown and "Bad" or "Good",
			["Piston_Rings"] = Thr.pistonRingsDamaged and "Bad" or "Good",
			["Connecting_Rods"] = Thr.connectingRodBearingsDamaged and "Bad" or "Good",
			["Exhaust_Pipe"] = nil
		}
		
		local _,reqInfo = Thr.getPartConditionRadiator()
		wearInfo["Radiator"] = {
			["Coolant_Level"] = reqInfo.coolantMass,
			["Leaking"] = reqInfo.radiatorDamage == 0 and "Good" or "Bad"
		}
		
		wearInfo["Oil_Pan"] = Thr.debugData.engineThermalData.oilLeakRateOilpan == 0 and "Good" or "Bad"
		
		if Tur.isExisting then
			local _,reqInfo = Tur.getPartCondition()
			wearInfo["Turbocharger"] = {
				["Turbine"] = reqInfo.damageFrictionCoef,
				["Compressor"] = tostring(math.floor(reqInfo.damageExhaustPowerCoef * 100)).." %" 
			}
		end
		
		if Spc.isExisting then
			local _,reqInfo = Spc.getPartCondition()
			wearInfo["Supercharger"] = tostring(math.floor(reqInfo.damagePressureCoef * 100)).." %" 
		end
	end
	
	for a,b in pairs(eSt) do
		if b.type == "fuelTank" then
			wearInfo["Fuel_Tank"] = {
				["Fuel_Level"] = tostring(math.floor(b.remainingRatio * 100)).." %",
				["Leaking"] = b.currentLeakRate == 0 and "Good" or "Bad"
			}
		end
	end
	
	if Clt then
		wearInfo["Clutch"] = {
			["Springs"] = Clt.clutchPermanentlyDamaged and "Bad" or "Good",
			["Disc"] = tostring(math.floor(Clt.damageLockTorqueCoef * Clt.wearLockTorqueCoef * 100)).." %",
			["Pressure_Plate"] = tostring(math.max(math.floor(100 - (Clt.damageClutchFreePlayCoef * Clt.wearClutchFreePlayCoef * 2)), 0)).." %"
		}
	end
	
	if Grb then
		if Grb.type == "manualGearbox" then
			wearInfo["Gearbox"] = nil
		elseif Grb.type == "automaticGearbox" then
			wearInfo["Gearbox"] = tostring(math.floor(Grb.damageGearRatioChangeRateCoef * Grb.wearGearRatioChangeRateCoef * 100)).." %"
		elseif Grb.type == "dctGearbox" then
			wearInfo["Gearbox"] = tostring(math.floor(Grb.damageLockTorqueCoef * Grb.wearLockTorqueCoef * 100)).." %"
		end
	end
	
	wearInfo["Body"] = {
		["Paint"] = tostring(math.floor(genCondition * 100)).." %",
		["Panels"] = nil
	}
	
	wearInfo["Chassis"] = {
		["Suspension"] = nil,
		["Brakes"] = tostring(math.floor(genCondition * 100)).." %",
		["Tires"] = nil
	}
	
	-- display vehicle state if requested
	if showState then
		log('I', 'barnfindGenerator', 'Vehicle Part Wear:')
		dump(wearInfo)
	end
end

M.setupBarnfind = setupBarnfind

return M