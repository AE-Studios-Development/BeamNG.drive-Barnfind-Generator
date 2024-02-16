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
	-- == detailed vehicle wear and condition coming soon :tm:
	
	-- gather info about the part wear
	if Eng then
		wearInfo["Engine"] = {
			["Crankshaft"] = Eng.damageDynamicFrictionCoef,
			["Spark_Plugs"] = Eng.damageIdleAVReadErrorRangeCoef,
			["Fuel_Pump"] = Eng.fastIgnitionErrorChance,
			["Idle_Controller"] = Eng.slowIgnitionErrorChance,
			["Head_Gasket"] = Thr.headGasketBlown,
			["Piston_Rings"] = Thr.pistonRingsDamaged,
			["Connecting_Rods"] = Thr.connectingRodBearingsDamaged ,
			["Exhaust_Pipe"] = nil
		}
		
		local _,reqInfo = Thr.getPartConditionRadiator()
		wearInfo["Radiator"] = {
			["Coolant_Level"] = reqInfo.coolantMass,
			["Leaking"] = reqInfo.radiatorDamage
		}
		
		wearInfo["Oil Pan"] = Thr.debugData.engineThermalData.oilLeakRateOilpan
		
		if Tur.isExisting then
			local _,reqInfo = Tur.getPartCondition()
			wearInfo["Turbocharger"] = {
				["Turbine"] = reqInfo.damageFrictionCoef,
				["Compressor"] = reqInfo.damageExhaustPowerCoef
			}
		end
		
		if Spc.isExisting then
			local _,reqInfo = Spc.getPartCondition()
			wearInfo["Supercharger"] = reqInfo.damagePressureCoef
		end
	end
	
	for a,b in pairs(eSt) do
		if b.type == "fuelTank" then
			wearInfo["Fuel_Tank"] = {
				["Fuel_Level"] = b.remainingRatio,
				["Leaking"] = b.currentLeakRate
			}
		end
	end
	
	if Clt then
		wearInfo["Clutch"] = {
			["Springs"] = Clt.clutchPermanentlyDamaged ,
			["Disc"] = Clt.damageLockTorqueCoef ,
			["Pressure_Plate"] = Clt.damageClutchFreePlayCoef
		}
	end
	
	if Grb then
		if Grb.type == "manualGearbox" then
			wearInfo["Gearbox"] = nil
		elseif Grb.type == "automaticGearbox" then
			wearInfo["Gearbox"] = Grb.damageGearRatioChangeRateCoef
		elseif Grb.type == "dctGearbox" then
			wearInfo["Gearbox"] = Grb.damageLockTorqueCoef
		end
	end
	
	wearInfo["Body"] = {
		["Paint"] = nil,
		["Panels"] = nil
	}
	
	wearInfo["Chassis"] = {
		["Suspension"] = nil,
		["Brakes"] = nil,
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