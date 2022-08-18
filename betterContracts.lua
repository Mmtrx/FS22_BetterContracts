--=======================================================================================================
-- BetterContracts SCRIPT
--
-- Purpose:     Enhance ingame contracts menu.
-- Author:      Royal-Modding / Mmtrx
-- Changelog:
--  v1.0.0.0    19.10.2020  initial by Royal-Modding
--  v1.1.0.0    12.04.2021  (Mmtrx) release candidate RC-2
--  v1.1.0.3    24.04.2021  gui enhancements: addtl details, sort buttons
--  v1.1.0.4    07.07.2021  add user-defined missionVehicles.xml, allow missions with no vehicles
--  v1.2.0.0    18.01.2022  adapt for FS22
--  v1.2.0.0.rc 22.01.2022  release candidate. Gui optics in blue
--  v1.2.0.1.rc 30.01.2022  enabled MP
--  v1.2.1.0    09.02.2022  support for FS22_SupplyTransportContracts by GtX
--  v1.2.2.0    30.03.2022  recognize conflict FS22_Contracts_Plus, adjust harvest keep formulas to FS22 1.3.1
--                          details for transport missions
--  v1.2.3.0    04.04.2022  filter contracts per jobtype
--   		    04.05.2022  moved restartGame() to DebugCommands. MaxMissions 80
--  v1.2.3.1    26.07.2022  add NPCHarvest to fix harvest contracts
--  v1.2.4.0    26.08.2022  allow for other (future) mission types, 
-- 							fix distorted menu page for different screen aspect ratios,
-- 							show fruit type to harvest in contracts list 
--=======================================================================================================
InitRoyalUtility(Utils.getFilename("lib/utility/", g_currentModDirectory))
InitRoyalMod(Utils.getFilename("lib/rmod/", g_currentModDirectory))
SC = {
	FERTILIZER = 1, -- prices index
	LIQUIDFERT = 2,
	HERBICIDE = 3,
	SEEDS = 4,
	-- my mission cats:
	HARVEST = 1,
	SPREAD = 2,
	SIMPLE = 3,
	BALING = 4,
	TRANSP = 5,
	SUPPLY = 6,
	OTHER = 7,
	-- Gui controls:
	CONTROLS = {
		npcbox = "npcbox",
		sortbox = "sortbox",
		layout = "layout",
		filltype = "filltype",
		widhei = "widhei",
		ppmin = "ppmin",
		line3 = "line3",
		line4a = "line4a",
		line4b = "line4b",
		line5 = "line5",
		line6 = "line6",
		field = "field",
		dimen = "dimen",
		etime = "etime",
		valu4a = "valu4a",
		valu4b = "valu4b",
		price = "price",
		valu6 = "valu6",
		valu7 = "valu7",
		sort = "sort",
		sortcat = "sortcat",
		sortprof = "sortprof",
		sortpmin = "sortpmin",
		helpsort = "helpsort"
	}
}
---@class BetterContracts : RoyalMod
BetterContracts = RoyalMod.new(false, false)     --params bool debug, bool sync

function debugPrint(text, ...)
	if BetterContracts.debug then
		Logging.info(text,...)
	end
end
function BetterContracts:initialize()
	debugPrint("[%s] initialize(): %s", self.name,self.initialized)
	if self.initialized ~= nil then return end -- run only once
	-- check for debug switch in modSettings/
	self.modSettings= getUserProfileAppPath().."modSettings/"
	if not self.debug and      
		fileExists(self.modSettings.."BetterContracts.debug") then
		self.debug = true 
	end
	g_missionManager.missionMapNumChannels = 6
	self.missionUpdTimeout = 15000
	self.missionUpdTimer = 0 -- will also update on frame open of contracts page
	self.turnTime = 5.0 -- estimated seconds per turn at end of each lane
	self.events = {}
	self.initialized = false
	--  Amazon ZA-TS3200,   Hardi Mega, Pöttr TerraC6F, Lemken Azur 9,  mission, Lemken Titan18
	--  default:spreader,   sprayer,    sower,          planter,        empty, harvest,   plow,  mow
	self.SPEEDLIMS = {15,   12,         15,             15,             0,      10,         12,   20} 
	self.WORKWIDTH = {42,   24,          6,              6,             0,       9,         4.9,   9} 
	--[[  contract types:
		1 mow_bale
		2 plow
		3 cultivate
		4 sow
		5 harvest
		6 weed
		7 spray
		8 fertilize
		9 transport
		10 supplyTransport (Mod)
	]]
	-- mission.type to BC category: harvest, spread, simple, mow, transp, supply
	-- self.typeToCat = {4, 3, 3, 2, 1, 3, 2, 2, 5, 6} 
	self.typeToCat = {}
	local function addMapping(name, category)
		local missionType = g_missionManager:getMissionType(name)
		if missionType ~= nil then
			self.typeToCat[missionType.typeId] = category
		end
	end
	addMapping("mow_bale", SC.BALING)
	addMapping("plow", SC.SIMPLE)
	addMapping("cultivate", SC.SIMPLE)
	addMapping("sow", SC.SPREAD)
	addMapping("harvest", SC.HARVEST)
	addMapping("weed", SC.SIMPLE)
	addMapping("spray", SC.SPREAD)
	addMapping("fertilize", SC.SPREAD)
	addMapping("transport", SC.TRANSP)
	addMapping("supplyTransport", SC.SUPPLY)
	addMapping("deadwood", SC.OTHER)
	addMapping("treeTransport", SC.OTHER)
	self.harvest = {} -- harvest missions       	1
	self.spread = {} -- sow, spray, fertilize   	2
	self.simple = {} -- plow, cultivate, weed   	3
	self.mow_bale = {} -- mow/ bale             	4
	self.transp = {} -- transport   				5
	self.supply = {} -- supplyTransport mod 		6
	self.other = {} -- deadwood, treeTrans			7
	self.IdToCont = {} -- to find a contract from its mission id
	self.fieldToMission = {} -- to find a contract from its field number
	self.catHarvest = "BEETHARVESTING BEETVEHICLES CORNHEADERS COTTONVEHICLES CUTTERS POTATOHARVESTING POTATOVEHICLES SUGARCANEHARVESTING SUGARCANEVEHICLES"
	self.catSpread = "fertilizerspreaders seeders planters sprayers sprayervehicles slurrytanks manurespreaders"
	self.catSimple = "CULTIVATORS DISCHARROWS PLOWS POWERHARROWS SUBSOILERS WEEDERS"
	self.isOn = false
	self.numCont = 0 	-- # of contracts in our tables
	self.numHidden = 0 	-- # of hidden (filtered) contracts 
	self.my = {} 		-- will hold my gui element adresses
	self.sort = 0 		-- sorted status: 1 cat, 2 prof, 3 permin
	self.lastSort = 0 	-- last sorted status
	self.buttons = {
		{"sortcat", g_i18n:getText("SC_sortCat")}, -- {button id, help text}
		{"sortprof", g_i18n:getText("SC_sortProf")},
		{"sortpmin", g_i18n:getText("SC_sortpMin")}
	}
	local mods = {"FS22_RefreshContracts","FS22_Contracts_Plus"}
	if g_modIsLoaded["FS22_RefreshContracts"] then
		self.needsRefreshContractsConflictsPrevention = true
	end
	if g_modIsLoaded["FS22_Contracts_Plus"] then
		self.preventContractsPlus = true
	end
	if g_modIsLoaded["FS22_SupplyTransportContracts"] then
		self.supplyTransport = true
	end
	-- to load own mission vehicles:
	Utility.overwrittenFunction(MissionManager, "loadMissionVehicles", BetterContracts.loadMissionVehicles)
	-- fix AbstractMission: 
	Utility.overwrittenFunction(AbstractMission, "new", abstractMissionNew)

	-- fix Harvest NPC Mission: 
	Utility.overwrittenFunction(FieldManager, "updateNPCField", NPCHarvest)

	-- get addtnl mission values from server:
	Utility.appendedFunction(HarvestMission, "writeStream", BetterContracts.writeStream)
	Utility.appendedFunction(HarvestMission, "readStream", BetterContracts.readStream)
	Utility.appendedFunction(BaleMission, "writeStream", BetterContracts.writeStream)
	Utility.appendedFunction(BaleMission, "readStream", BetterContracts.readStream)
	Utility.appendedFunction(AbstractMission, "writeUpdateStream", BetterContracts.writeUpdateStream)
	Utility.appendedFunction(AbstractMission, "readUpdateStream", BetterContracts.readUpdateStream)
	-- functions for ingame menu contracts frame:
	InGameMenuContractsFrame.onFrameOpen = Utils.overwrittenFunction(InGameMenuContractsFrame.onFrameOpen, onFrameOpen)
	InGameMenuContractsFrame.onFrameClose = Utils.appendedFunction(InGameMenuContractsFrame.onFrameClose, onFrameClose)
	InGameMenuContractsFrame.updateFarmersBox = Utils.appendedFunction(InGameMenuContractsFrame.updateFarmersBox, updateFarmersBox)
	InGameMenuContractsFrame.populateCellForItemInSection = Utils.appendedFunction(InGameMenuContractsFrame.populateCellForItemInSection, populateCell)
	InGameMenuContractsFrame.updateList = Utils.overwrittenFunction(InGameMenuContractsFrame.updateList, updateList)
	InGameMenuContractsFrame.sortList = Utils.overwrittenFunction(InGameMenuContractsFrame.sortList, sortList)
	-- to allow multiple missions:
	MissionManager.hasFarmReachedMissionLimit =
		Utils.overwrittenFunction(nil,
			function() return false end
			)
	if self.debug then
		addConsoleCommand("printBetterContracts", "Print detail stats for all available missions.", "consoleCommandPrint", self)
		addConsoleCommand("gsFieldGenerateMission", "Force generating a new mission for given field", "consoleGenerateFieldMission", g_missionManager)
		addConsoleCommand("gsMissionLoadAllVehicles", "Loading and unloading all field mission vehicles", "consoleLoadAllFieldMissionVehicles", g_missionManager)
		addConsoleCommand("gsMissionHarvestField", "Harvest a field and print the liters", "consoleHarvestField", g_missionManager)
		addConsoleCommand("gsMissionTestHarvests", "Run an expansive tests for harvest missions", "consoleHarvestTests", g_missionManager)
	end
end

function BetterContracts:onMissionInitialize(baseDirectory, missionCollaborators)
	MissionManager.AI_PRICE_MULTIPLIER = 1.5
	MissionManager.MISSION_GENERATION_INTERVAL = 3600000 -- every 1 game hour
end

function BetterContracts:onSetMissionInfo(missionInfo, missionDynamicInfo)
	Utility.overwrittenFunction(g_currentMission.inGameMenu, "onClickMenuExtra1", onClickMenuExtra1)
	Utility.overwrittenFunction(g_currentMission.inGameMenu, "onClickMenuExtra2", onClickMenuExtra2)
end

function BetterContracts:onPostLoadMap(mapNode, mapFile)
	-- adjust max missions
	local fieldsAmount = TableUtility.count(g_fieldManager.fields)
	local adjustedFieldsAmount = math.max(fieldsAmount, 45)
	MissionManager.MAX_MISSIONS = math.min(80, math.ceil(adjustedFieldsAmount * 0.60)) -- max missions = 60% of fields amount (minimum 45 fields) max 120
	--MissionManager.MAX_TRANSPORT_MISSIONS = math.max(math.ceil(MissionManager.MAX_MISSIONS / 15), 2) -- max transport missions is 1/15 of maximum missions but not less then 2
	--MissionManager.MAX_MISSIONS = MissionManager.MAX_MISSIONS + MissionManager.MAX_TRANSPORT_MISSIONS -- add max transport missions to max missions
	MissionManager.MAX_MISSIONS_PER_GENERATION = math.min(MissionManager.MAX_MISSIONS / 5, 30) -- max missions per generation = max mission / 5 but not more then 30
	MissionManager.MAX_TRIES_PER_GENERATION = math.ceil(MissionManager.MAX_MISSIONS_PER_GENERATION * 1.5) -- max tries per generation 50% more then max missions per generation
	debugPrint("[%s] Fields amount %s (%s)", self.name, fieldsAmount, adjustedFieldsAmount)
	debugPrint("[%s] MAX_MISSIONS set to %s", self.name, MissionManager.MAX_MISSIONS)
	debugPrint("[%s] MAX_TRANSPORT_MISSIONS set to %s", self.name, MissionManager.MAX_TRANSPORT_MISSIONS)
	debugPrint("[%s] MAX_MISSIONS_PER_GENERATION set to %s", self.name, MissionManager.MAX_MISSIONS_PER_GENERATION)
	debugPrint("[%s] MAX_TRIES_PER_GENERATION set to %s", self.name, MissionManager.MAX_TRIES_PER_GENERATION)

	-- initialize constants depending on game manager instances
	self.ft = g_fillTypeManager.fillTypes
	self.prices = {
		-- storeprices per 1000 l
		g_storeManager.xmlFilenameToItem["data/objects/bigbagpallet/fertilizer/bigbagpallet_fertilizer.xml"].price,
		g_storeManager.xmlFilenameToItem["data/objects/pallets/liquidtank/fertilizertank.xml"].price / 2,
		g_storeManager.xmlFilenameToItem["data/objects/pallets/liquidtank/herbicidetank.xml"].price / 2,
		g_storeManager.xmlFilenameToItem["data/objects/bigbagpallet/seeds/bigbagpallet_seeds.xml"].price
	}
	self.sprUse = {
		g_sprayTypeManager.sprayTypes[SprayType.FERTILIZER].litersPerSecond,
		g_sprayTypeManager.sprayTypes[SprayType.LIQUIDFERTILIZER].litersPerSecond,
		g_sprayTypeManager.sprayTypes[SprayType.HERBICIDE].litersPerSecond
	}
	self.mtype = {
		FERTILIZE = g_missionManager:getMissionType("fertilize").typeId,
		SOW = g_missionManager:getMissionType("sow").typeId,
		SPRAY = g_missionManager:getMissionType("spray").typeId
	}
	self.gameMenu = g_currentMission.inGameMenu
	self.frCon = self.gameMenu.pageContracts

	-- check mission types
	for i = #self.typeToCat+1, g_missionManager.nextMissionTypeId -1 do
		Logging.warning("[%s] ignoring new mission type %s (id %s)", self.name, 
				g_missionManager.missionTypes[i].name, i)
	end
	-- load my gui xmls
	if not self:loadGUI(true, self.directory .. "gui/") then
		Logging.warning("'%s.Gui' failed to load! Supporting files are missing.", self.name)
	else
		debugPrint("-------- gui loaded -----------")
	end

	------------------- setup my display elements -------------------------------------
	-- move farmer picture to right
	local fbox = self.frCon.farmerBox
	for _,v in ipairs(fbox:getDescendants()) do
		if v.id ~= nil and 
			v.id:sub(1,6) == "farmer" then 
			v:move(115/1920, 0) 
		end
	end
	-- add field "profit" to all listItems
	local rewd = self.frCon.contractsList.cellDatabase.autoCell1:getDescendantByName("reward")
	local profit = rewd:clone(self.frCon.contractsList.cellDatabase.autoCell1)
	profit.name = "profit"
	profit:setPosition(-110/1920, -12/1080 *g_aspectScaleY) 	-- 
	--profit:setTextColor(1, 1, 1, 1)
	profit.textBold = false
	profit:setVisible(false)
	-- set controls for npcbox, sortbox and their elements:
	for _, name in pairs(SC.CONTROLS) do
		self.my[name] = self.frCon.farmerBox:getDescendantById(name)
	end

	-- setup fieldjob types:
	local fjobs = {
		mow_bale	= g_i18n:getText("fieldJob_jobType_baling"),
		cultivate 	= g_i18n:getText("fieldJob_jobType_cultivating"),
		fertilize 	= g_i18n:getText("fieldJob_jobType_fertilizing"),
		harvest 	= g_i18n:getText("fieldJob_jobType_harvesting" ),
		plow   		= g_i18n:getText("fieldJob_jobType_plowing"),
		sow     	= g_i18n:getText("fieldJob_jobType_sowing"),
		spray   	= g_i18n:getText("fieldJob_jobType_spraying"),
		weed    	= g_i18n:getText("fieldJob_jobType_weeding"),
	}
	self.fieldjobs = {}
	for i = 1, 8 do 
		local type = g_missionManager.missionTypes[i] 
		table.insert(self.fieldjobs, {type.typeId, type.name, fjobs[type.name]})
	end
	table.sort(self.fieldjobs, function(a,b)
				return a[3] < b[3]
				end)
	self.fieldjobs[9] = {9,"transport", g_i18n:getText("bc_other")}
	-- initial state: show all types
	self.filterState = {
		mow_bale	= true,
		cultivate 	= true,
		fertilize 	= true,
		harvest 	= true,
		plow   		= true,
		sow     	= true,
		spray   	= true,
		weed    	= true,
		transport 	= true,
		supplyTransport = true
	}
	-- set controls for filterbox:
	self.my.filterlayout = self.frCon.contractsContainer:getDescendantById("filterlayout")
	self.my.hidden = self.frCon.contractsContainer:getDescendantById("hidden")
	for i, name in ipairs({"fb1","fb2","fb3",
		"fb4","fb5","fb6","fb7","fb8","fb9"}) do
		self.my[name] = self.frCon.contractsContainer:getDescendantById(name)
		local button = self.my[name]
		button.onClickCallback = onClickFilterButton
		button.pressed = true 
		-- set button text
		button.elements[1]:setText(self.fieldjobs[i][3])
	end
	-- set callbacks for our 3 sort buttons
	for _, name in ipairs({"sortcat", "sortprof", "sortpmin"}) do
		self.my[name].onClickCallback = onClickSortButton
		self.my[name].onHighlightCallback = onHighSortButton
		self.my[name].onHighlightRemoveCallback = onRemoveSortButton
		self.my[name].onFocusCallback = onHighSortButton
		self.my[name].onLeaveCallback = onRemoveSortButton
	end

	self.my.filterlayout:setVisible(true)
	self.my.hidden:setVisible(false)
	self.my.npcbox:setVisible(false)
	self.my.sortbox:setVisible(false)
	self.initialized = true
end

function BetterContracts:onUpdate(dt)
	local self = BetterContracts
	self.missionUpdTimer = self.missionUpdTimer + dt
	if self.missionUpdTimer >= self.missionUpdTimeout then
		if self.isOn then self:refresh() end  -- only needed when GUI shown
		self.missionUpdTimer = 0
	end
end

function BetterContracts:refresh()
	-- refresh our contract tables. Called by onFrameOpen/updateList, and every 15 sec by self:onUpdate
	self.harvest, self.spread, self.simple, self.mow_bale, self.transp, self.supply, self.other =
		 {}, {}, {}, {}, {}, {}, {}
	self.IdToCont, self.fieldToMission = {}, {}
	local list = g_missionManager:getMissionsList(g_currentMission:getFarmId())
	local res = {}
	debugPrint("[%s] refresh() at %s sec, found %d contracts", self.name, 
		g_i18n:formatNumber(g_currentMission.time/1000)  ,#list)
	self.numCont = 0
	for _, m in ipairs(list) do
		res = self:addMission(m)
		if res[1] and res[1] > 0 then
			self.IdToCont[m.id] = res 
			self.numCont = self.numCont +1
		end
	end
	self.missionUpdTimer = 0        -- don't call us again too soon
end
function BetterContracts:getFilltypePrice(m)
	-- get price for harvest/ mow-bale missions
	if m.sellPointId then
		m:tryToResolveSellPoint()
	end
	if not m.sellPoint then
		Logging.warning("[%s]:addMission(): contract '%s %s on field %s' has no sellPoint.", 
			self.name, m.type.name, self.ft[m.fillType].title, m.field.fieldId)
		return 0
	end
	return m.sellPoint:getEffectiveFillTypePrice(m.fillType)
end
function BetterContracts:addMission(m)
	-- add mission m to the corresponding BetterContracts list
	local cont = {}
	local dim, wid, hei, dura, wwidth, speed, vtype, vname, vfound
	local cat = self.typeToCat[m.type.typeId]
	local rew = m:getReward()
	if cat < SC.TRANSP then
		dim = self:getDimensions(m.field, false)
		wid, hei = dim.width, dim.height
		if wid > hei then
			wid, hei = hei, wid
		end
		self.fieldToMission[m.field.fieldId] = m
		vfound, wwidth, speed, vtype, vname = self:getFromVehicle(cat, m)

		-- estimate mission duration:
		if vfound and wwidth > 0  then
			_, dura = self:estWorktime(wid, hei, wwidth, speed)
		elseif not vfound or cat~=SC.SPREAD then
			Logging.warning("[%s]:addMission(): problem with vehicles for contract '%s field %s'.", 
				self.name, m.type.name, m.field.fieldId)
			local cat1 = cat == 1 and 1 or 0 
			-- use default width and speed values :
			-- cat/index: 1/6, 3/7, 4/8 = harvest, plow, mow
			_,dura = self:estWorktime(wid, hei, self.WORKWIDTH[4+cat+cat1], self.SPEEDLIMS[4+cat+cat1])
		end
		if (cat==SC.HARVEST or cat==SC.BALING) and m.expectedLiters == nil then
			Logging.warning("[%s]:addMission(): contract '%s %s on field %s' has no expectedLiters.", 
				self.name, m.type.name, self.ft[m.fillType].title, m.field.fieldId)
			m.expectedLiters = 0 
			return {0, cont}
		end 
	end
	if cat == SC.HARVEST then
		local keep = math.floor(m.expectedLiters *(1 - HarvestMission.SUCCESS_FACTOR))
		local price = self:getFilltypePrice(m)
		local profit = rew + keep * price
		cont = {
			miss = m,
			width = wid,
			height = hei,
			worktime = dura,
			ftype = self.ft[m.fillType].title,
			deliver = math.ceil(m.expectedLiters - keep), --must be delivered
			keep = keep, --can be sold on your own
			price = price * 1000,
			profit = profit,
			permin = profit / dura * 60,
			reward = rew
		}
		table.insert(self.harvest, cont)
	elseif cat == SC.SPREAD then
		cont = self:spreadMission(m, wid, hei, wwidth, speed)
		table.insert(self.spread, cont)
	elseif cat == SC.SIMPLE then
		cont = {
			miss = m,
			width = wid,
			height = hei,
			worktime = dura,
			profit = rew,
			permin = rew / dura * 60,
			reward = rew
		}
		table.insert(self.simple, cont)
	elseif cat == SC.BALING then
		local deliver = math.ceil(m.expectedLiters * BaleMission.FILL_SUCCESS_FACTOR)
		local keep = math.floor(m.expectedLiters - deliver) --can be sold on your own
		local price = self:getFilltypePrice(m)
		local profit = rew + keep * price
		cont = {
			miss = m,
			width = wid,
			height = hei,
			worktime = dura * 3, -- dura is just the mow time, adjust for windrowing/ baling
			ftype = self.ft[m.fillType].title,
			deliver = deliver,
			keep = keep, --can be sold on your own
			price = price * 1000,
			profit = profit,
			permin = profit / dura / 3 * 60,
			reward = rew
		}
		table.insert(self.mow_bale, cont)
	elseif cat == SC.SUPPLY then    
		cont = {
			miss = m,
			worktime = 0,
			ftype = self.ft[m.fillType].title,
			deliver = m.contractLiters,
			price = m.pricePerLitre * 1000,
			profit =  rew - m.contractLiters * m.pricePerLitre,
			permin = 0,
			reward = rew
		}
		table.insert(self.supply, cont)
	elseif cat == SC.TRANSP then
		cont = {
			miss = m,
			worktime = 0,
			ftype = getPalletType(m),
			deliver = m.numObjects,
			profit = rew,
			permin = 0,
			reward = rew
		}
		table.insert(self.transp, cont)
	elseif cat == SC.OTHER then
		cont = {
			miss = m,
			worktime = 0,
			profit = rew,
			permin = 0,
			reward = rew
		}
		table.insert(self.other, cont)
	else 	
		Logging.warning("[%s]: Unknown cat %s in addMission(m)", self.name, cat)
	end
	return {cat, cont}
end
function getPalletType(m)
	-- return type of pallet contents, from mission object
	for _, o in ipairs(m.missionConfig.objects) do 
		if m.objectFilename == o.filename then 
			return o.title
		end
	end
	return ""
end
function BetterContracts.writeStream(self, streamId, connection)
	streamWriteFloat32(streamId, self.expectedLiters)
	streamWriteFloat32(streamId, self.depositedLiters)
end
function BetterContracts.readStream(self, streamId, connection)
	self.expectedLiters = streamReadFloat32(streamId)
	self.depositedLiters = streamReadFloat32(streamId)
end
function BetterContracts.writeUpdateStream(self, streamId, connection, dirtyMask)
	local fieldPercent, depo = 0., 0.
	if self.fieldPercentageDone then fieldPercent = self.fieldPercentageDone end
	if self.depositedLiters then depo = self.depositedLiters end
	streamWriteFloat32(streamId, fieldPercent)
	streamWriteFloat32(streamId, depo)
end
function BetterContracts.readUpdateStream(self, streamId, timestamp, connection)
	self.fieldPercentageDone = streamReadFloat32(streamId)
	self.depositedLiters = streamReadFloat32(streamId)
end
function abstractMissionNew(isServer, superf, isClient, customMt )
	local self = superf(isServer, isClient, customMt)
	self.mission = g_currentMission 
	-- Fix for error in AbstractMission 'self.mission' still missing in Version 1.6
	return self
end
function NPCHarvest(self, superf, field, allowUpdates)
	if not allowUpdates then 
		superf(self, field, allowUpdates)
		return
	end
	local fruitDesc, harvestReadyState, maxHarvestState, area, total
	local x, z = FieldUtil.getMeasurementPositionOfField(field)
	if field.fruitType ~= nil then

		-- leave a withered field for plow/ grubber missions
		fruitDesc = g_fruitTypeManager:getFruitTypeByIndex(field.fruitType)
		local withered = fruitDesc.witheredState
		if withered ~= nil then
			area, total = FieldUtil.getFruitArea(x - 1, z - 1, x + 1, z - 1, x - 1, z + 1, FieldUtil.FILTER_EMPTY, FieldUtil.FILTER_EMPTY, field.fruitType, withered, withered, 0, 0, 0, false)
			if area > 0.5*total and math.random() < 0.5 then return end
		end

		-- don't let NPCs harvest
		harvestReadyState = fruitDesc.maxHarvestingGrowthState
		if fruitDesc.maxPreparingGrowthState > -1 then
			harvestReadyState = fruitDesc.maxPreparingGrowthState
		end
		maxHarvestState = FieldUtil.getMaxHarvestState(field, field.fruitType)
		if maxHarvestState == harvestReadyState then return end

		-- leave a cut field for plow/ grubber mission
		area, total = FieldUtil.getFruitArea(x - 1, z - 1, x + 1, z - 1, x - 1, z + 1, FieldUtil.FILTER_EMPTY, FieldUtil.FILTER_EMPTY, field.fruitType, fruitDesc.cutState, fruitDesc.cutState, 0, 0, 0, false)
		if area > 0.5 * total and g_currentMission.snowSystem.height < SnowSystem.MIN_LAYER_HEIGHT and math.random() < 0.3 then return end 
	else
		-- leave empty (plowed/grubbered) field for sow mission
		if self:getFruitIndexForField(field) ~= nil and math.random() < 0.5 then return end
	end
	superf(self, field, allowUpdates)
end
