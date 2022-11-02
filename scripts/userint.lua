--=======================================================================================================
-- BetterContracts SCRIPT
--
-- Purpose:		Enhance ingame contracts menu.
-- Author:		Royal-Modding / Mmtrx
-- Changelog:
--  v1.0.0.0	19.10.2020	initial by Royal-Modding
--	v1.1.0.0	12.04.2021	release candidate RC-2
--  v1.1.1.0	22.04.2021  (Mmtrx) gui enhancements: addtl details, sort buttons
--  v1.1.1.4    07.07.2021  (Mmtrx) add user-defined missionVehicles.xml, allow missions with no vehicles
--  v1.2.0.0    18.01.2022  (Mmtrx) adapt for FS22
--  v1.2.4.3 	10.10.2022	recognize FS22_LimeMission
--  v1.2.5.0 	31.10.2022	fewer mission vehicle warnings
--=======================================================================================================

-------------------- mission analysis functions ---------------------------------------------------
warnText = {
	"**[%s] - contract '%s field %s' has no vehicles",
	"**[%s] - could not get store item for '%s'",
	"**[%s]:getFromVehicle() - could not get workingWidth for '%s'",
	"**[%s]:getFromVehicle() could not find appropriate vehicle in mission %s on field %s",
	"[%s]:addMission(): problem with vehicles for contract '%s field %s'."
}
warnings = { {},{},{},{},{}, }
function BetterContracts:getDimensions(field, verbose)
	local numd = getNumOfChildren(field.fieldDimensions)
	local dim, x0, x1, x2, z0, z1, z2, widthX, widthZ, heightX, heightZ, widthLength, heightLength, area
	local xmin, xmax, zmin, zmax
	local dimensions = {
		minX = 999999,
		maxX = -999999,
		minZ = 999999,
		maxZ = -999999
	}
	for i = 1, numd do
		dim = getChildAt(field.fieldDimensions, i - 1)
		x1, _, z1 = getWorldTranslation(dim)
		x0, _, z0 = getWorldTranslation(getChildAt(dim, 0))
		x2, _, z2 = getWorldTranslation(getChildAt(dim, 1))

		xmin, xmax = math.min(x0, x1, x2), math.max(x0, x1, x2)
		zmin, zmax = math.min(z0, z1, z2), math.max(z0, z1, z2)
		if xmin < dimensions.minX then
			dimensions.minX = xmin
		end
		if xmax > dimensions.maxX then
			dimensions.maxX = xmax
		end
		if zmin < dimensions.minZ then
			dimensions.minZ = zmin
		end
		if zmax > dimensions.maxZ then
			dimensions.maxZ = zmax
		end

		_, _, widthX, widthZ, heightX, heightZ = MathUtil.getXZWidthAndHeight(x0, z0, x1, z1, x2, z2)
		widthLength = MathUtil.vector2Length(widthX, widthZ)
		heightLength = MathUtil.vector2Length(heightX, heightZ)
		_, area, _ = MathUtil.crossProduct(widthX, 0, widthZ, heightX, 0, heightZ)
		if verbose then
			print(string.format("(%.1f, %.1f) (%.1f, %.1f) (%.1f, %.1f) width: %.2f, height: %.2f, area: %.2f", x0, z0, x1, z1, x2, z2, widthLength, heightLength, math.abs(area)))
		end
	end
	dimensions.width = dimensions.maxX - dimensions.minX
	dimensions.height = dimensions.maxZ - dimensions.minZ
	return dimensions
end
function BetterContracts:isHarvester(vcat)
	-- check if vcat store category fits harvest missions
	local x, _ = string.find(self.catHarvest, string.upper(vcat))
	return x ~= nil
end
function BetterContracts:isMower(vcat)
	-- check if vcat store category fits grass missions
	local x, _ = string.find("MOWERS MOWERVEHICLES", string.upper(vcat))
	return x ~= nil
end
function BetterContracts:isSpreader(vcat)
	-- check if vcat store category fits fertilize/spray/seed missions
	local x, _ = string.find(self.catSpread, string.lower(vcat))
	return x ~= nil
end
function BetterContracts:isSimple(vcat)
	-- check if vcat store category fits simple missions
	local x, _ = string.find(self.catSimple, string.upper(vcat))
	return x ~= nil
end
function BetterContracts:isFruitPlanter(ft)
	-- check if ft is in fruittype categoy PLANTER
	local list = g_fruitTypeManager.categoryToFruitTypes[g_fruitTypeManager.categories.PLANTER]
	return TableUtility.contains(list, ft)
end
function BetterContracts:warning(id, p1, p2)
	-- display the same warning only once
	p2 = p2 or ""
	local count = warnings[id][p1..p2] or 0
	if count >= 1 then return end 
	Logging.warning(warnText[id],self.name,p1,p2)
	warnings[id][p1..p2] = count +1
end
function BetterContracts:getFromVehicle(cat, m)
	-- return workwidth, speedLimit for the appropriate mission vehicle:
	-- cat 1: harvest - get data from harvest mission vehicle (Todo: grass mission)
	-- cat 2: spread  - get spread / spray data from fertilize/ sow/ spray mission vehicle
	-- cat 3: simple  - get data from plow / cultivator/ weeder vehicle
	--print(string.format("-- getFrom Vehicle(cat, m) started: %d, %s",cat, m))
	local vehicles = {}
	local vec, con, vtype, wwidth, speed
	local spr = "n/a" -- sprayer name

	if m.vehiclesToLoad == nil then 
		self:warning(1, m.type.name, m.field.fieldId)
		return false 
	end
	if cat == SC.BALING then wwidth = 0 end -- init for search for biggest wwidth
	for _, v in ipairs(m.vehiclesToLoad) do	-- main loop over vehicles to load
		vec = g_storeManager.xmlFilenameToItem[string.lower(v.filename)]
		con = v.configurations
		if vec == nil then
			self:warning(2, v.filename)
			return false 
		end
		StoreItemUtil.loadSpecsFromXML(vec)
		vtype = vec.categoryName
		spr = string.sub(vec.xmlFilename, 15)

	--- if grass mission, scan for mower with largest workwidth
		if cat == SC.BALING then
			if self:isMower(vtype) and tonumber(vec.specs.workingWidth) > wwidth then
				wwidth = tonumber(vec.specs.workingWidth)
				speed = vec.specs.speedLimit
			end
		elseif cat == SC.SPREAD and vtype == "SLURRYTANKS" 
			and vec.functions[1] == g_i18n:getText("function_slurrySpreaderWithoutTool")
			then  -- skip this, it's a slurry barrel w/o spreader

		elseif cat == SC.HARVEST and vtype == "BEETVEHICLES" then  
			if vec.name == "Rexor 6300 Platinum" then 
				wwidth, speed = 2.8, 10.
				break 
			end
			-- else skip this, it's a beet harvester that needs a header

		elseif cat == SC.HARVEST and self:isHarvester(vtype) 
				or cat == SC.SPREAD and self:isSpreader(vtype) 
				or cat == SC.SIMPLE and self:isSimple(vtype) then
			speed = vec.specs.speedLimit
			wwidth = vec.specs.workingWidth
			if wwidth == nil then
				if vec.specs.workingWidthConfig ~= nil then 
					wwidth = Vehicle.getSpecValueWorkingWidthConfig(vec, nil, con, nil, true)
				end
				if wwidth == nil then
					if vec.name == "Ventor 4150" then wwidth = 3.3 end
				end
				if wwidth == nil then
					self:warning(3, spr)
					DebugUtil.printTableRecursively(vec," ",0,0)
				end
			end
			break
		end
	end
	-- if no spreader / sprayer in a spreadmission (e.g. a manure vehicle offered)
	-- or custom (harvest) vehicle --> use default speed, wwidth
	if wwidth == nil then
		speed, wwidth = 0, 0
		if cat ~= SC.SPREAD and self.debug then
			self:warning(4, m.id, m.field.fieldId)
		end
	end
	--debugPrint("%s %s - speed %.1f, width %.1f", vtype, spr,speed,wwidth)
	return true, tonumber(wwidth), tonumber(speed), string.lower(vtype), spr
end
function BetterContracts:spreadMission(m, wid, hei, vWorkwidth, vSpeed)
	-- analyze and estimate time/ usage for a fertilize / spray / sow mission
	local nlanes, workL, vtype, vname
	local fer, liq = self.ft[FillType.FERTILIZER].title, self.ft[FillType.LIQUIDFERTILIZER].title
	local u = {SPEEDLIMS = {}, WORKWIDTH = {}}
	local mtyp = m.type.typeId
	local workT, dura, usage, cost, price, ftext = {}, {}, {}, {}, {}, {}
	local maxj = 2 -- if mission vehicle found, use its specs as 3rd option
	local typ = 1 -- index to self.SPEEDLIMS / WORKWIDTH

	-- assume fertilize mission:
	ftext[1], ftext[2] = fer, liq
	for j = 1, 2 do
		usage[j], price[j] = self.sprUse[j], self.prices[j]
		u.SPEEDLIMS[j] = self.SPEEDLIMS[j]
		u.WORKWIDTH[j] = self.WORKWIDTH[j]
	end
	if mtyp == self.mtype.SOW then
		ftext[1] = self.ft[FillType.SEEDS].title
		price[1] = self.prices[SC.SEEDS]
		usage[1] = g_fruitTypeManager:getFruitTypeByIndex(m.fruitType).seedUsagePerSqm
		maxj = 1
		typ = 3
		price[2], usage[2], ftext[2] = price[1], usage[1], ftext[1]
	elseif mtyp == self.mtype.SPRAY then
		ftext[1] = self.ft[FillType.HERBICIDE].title
		price[1] = self.prices[SC.HERBICIDE]
		usage[1] = self.sprUse[SC.HERBICIDE]
		maxj = 1
		typ = 2 -- default sprayer (Hardi Mega1200)
		price[2], usage[2], ftext[2] = price[1], usage[1], ftext[1]
	elseif self.limeMission and mtyp == self.mtype.LIME then
		ftext[1] = self.ft[FillType.LIME].title
		price[1] = self.prices[SC.LIME]
		usage[1] = self.sprUse[SC.LIME]
		maxj = 1
		typ = 9 -- default lime sprayer (Bredal K165)
		price[2], usage[2], ftext[2] = price[1], usage[1], ftext[1]
	end
	-- set specs from mission vehicle
	if vWorkwidth ~= nil and vWorkwidth > 0 then
		maxj = maxj + 1
		u.WORKWIDTH[maxj], u.SPEEDLIMS[maxj] = vWorkwidth, vSpeed
	end
	u.SPEEDLIMS[1] = self.SPEEDLIMS[typ]
	u.WORKWIDTH[1] = self.WORKWIDTH[typ]
	--[[
	calculate worktime and usage (fertilizer, seeds, herbicide) cost for 2 or 3 diff vehicles:
	- fertilize mission
		1: default spreader, 2: default sprayer, 3: mission vehicle (if exists)
	- spray/ lime mission 
		1: default sprayer, 2: mission vehicle (if exists)
	- sow mission 
		1: default sower, 2: mission vehicle (if exists). 
		   dura may differ / usage independent from speed/workwidth
	]]
	for j = 1, maxj do
		workT[j], dura[j] = self:estWorktime(wid, hei, u.WORKWIDTH[j], u.SPEEDLIMS[j])
		if j == 3 then -- values from mission vehicle
			if vtype == "fertilizerspreaders" then
				usage[j], price[j] = self.sprUse[1], self.prices[1]
				 -- fertilizer
				ftext[3] = fer
			else
				usage[j], price[j] = self.sprUse[2], self.prices[2]
				 -- liquid fertilizer
				ftext[3] = liq
			end
		end
		if mtyp == self.mtype.SOW then
			-- literPerSqm * ha * 10.000
			usage[j] = usage[j] * m.field.fieldArea * 10000
		else
			-- literPerSec * sec
			usage[j] = usage[j] * u.WORKWIDTH[j] * u.SPEEDLIMS[j] * workT[j]
		end
		cost[j] = -usage[j] * price[j] / 1000
		--[[print(string.format("wid/hei %.1f/%.1f, nlanes %d, workL %.1f, workT %.1f",
			wid,hei,math.ceil(wid / u.WORKWIDTH[j]), math.ceil(wid / u.WORKWIDTH[j])*hei +wid,  
			workT[j]))
		]]
	end
	local jbest = 1
	for j = 1, maxj do
		if cost[j] > cost[jbest] then
			jbest = j
		end
	end
	local rew = m:getReward()
	return {
		miss = m,
		ftype = ftext,
		maxj = maxj,
		bestj = jbest,
		width = wid,
		height = hei,
		worktime = dura,
		usage = usage,
		price = price,
		cost = cost,
		profit = rew + cost[jbest],
		permin = (rew + cost[jbest]) / dura[jbest] * 60,
        reward = rew
	}
end
function BetterContracts:estWorktime(wid, hei, wwid, speed)
	-- estimate time to work a rectangle field (wid x hei) with a tool
	-- of working width wwid at given speed
	local nlanes = math.ceil(wid / wwid) -- how many passes
	local workL = nlanes * hei + wid -- length of working path
	local netT = workL / speed * 3.6 -- net working time in sec
	return netT, netT + nlanes * self.turnTime -- assume 5 sec per u-turn
end
