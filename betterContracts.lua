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
--  v1.2.4.1 	05.09.2022	indicate leased equipment for active missions
--							allow clear/new contracts button only for master user
-- 							lazyNPC / maxActive contracts now configurable
--  v1.2.4.2 	19.09.2022	[ModHub] recognize FS22_DynamicMissionVehicles
--  v1.2.4.3 	10.10.2022	recognize FS22_LimeMission, RollerMission. Add lazyNPC switch for weed
-- 							delete config.xml file template from mod directory
--  v1.2.4.4 	16.10.2022	fix FS22_LimeMission details, filter buttons. Add timeLeft to MP sync
--  			21.10.2022	fix mtype.LIME, FS22_IBCtankfix mod compat
--  v1.2.5.0 	31.10.2022	hard mode: active miss time out at midnght. Penalty for missn cancel
--							discount mode: get discounted field price, based on # of missions
--							mission vehicle warnings: only if no vehicles or debug="true"
--  v1.2.6.0 	30.11.2022	UI for all settings
--=======================================================================================================
SC = {
	FERTILIZER = 1, -- prices index
	LIQUIDFERT = 2,
	HERBICIDE = 3,
	SEEDS = 4,
	LIME = 5,
	-- my mission cats:
	HARVEST = 1,
	SPREAD = 2,
	SIMPLE = 3,
	BALING = 4,
	TRANSP = 5,
	SUPPLY = 6,
    OTHER = 7,
    -- refresh MP:
    ADMIN = 1,
    FARMMANAGER = 2,
    PLAYER = 3,
    -- hardMode expire:
    DAY = 1,
    MONTH = 2,

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
function debugPrint(text, ...)
	if BetterContracts.config and BetterContracts.config.debug then
		Logging.info(text,...)
	end
end
source(Utils.getFilename("RoyalMod.lua", g_currentModDirectory.."scripts/")) 	-- RoyalMod support functions
source(Utils.getFilename("Utility.lua", g_currentModDirectory.."scripts/")) 	-- RoyalMod utility functions
---@class BetterContracts : RoyalMod
BetterContracts = RoyalMod.new(false, true)     --params bool debug, bool sync

function catMissionTypes(self)
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
		mission.type to BC category: harvest, spread, simple, mow, transp, supply
		self.typeToCat = {4, 3, 3, 2, 1, 3, 2, 2, 5, 6} 
	]]
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
    addMapping("supplyTransport", SC.SUPPLY) 	-- mod by GtX
    addMapping("deadwood", SC.OTHER) 			-- Platinum DLC mission by Giants
    addMapping("treeTransport", SC.OTHER) 		-- Platinum DLC mission by Giants
    addMapping("destructibleRocks", SC.OTHER) 	-- Platinum DLC mission by Giants
    addMapping("roll", SC.SIMPLE) 				-- roller mission by tn4799
    addMapping("lime", SC.SPREAD) 				-- lime mission by Mmtrx
	for _, missionType in pairs(g_missionManager.missionTypes) do
		if self.typeToCat[missionType.typeId] == nil then
			addMapping(missionType.name, SC.OTHER) -- default category for not registered mission types
		end
	end
	-- check mission types
	for i = #self.typeToCat+1, g_missionManager.nextMissionTypeId -1 do
		Logging.warning("[%s] ignoring new mission type %s (id %s)", self.name, 
				g_missionManager.missionTypes[i].name, i)
	end
end
function checkOtherMods(self)
	local mods = {	
		FS22_RefreshContracts = "needsRefreshContractsConflictsPrevention",
		FS22_Contracts_Plus = "preventContractsPlus",
		FS22_SupplyTransportContracts = "supplyTransport",
		FS22_DynamicMissionVehicles = "dynamicVehicles",
		FS22_TransportMissions = "transportMission",
		FS22_LimeMission = "limeMission",
		}
	for mod, switch in pairs(mods) do
		if g_modIsLoaded[mod] then
			self[switch] = true
		end
	end
end
function registerXML(self)
	self.baseXmlKey = "BetterContracts"
	self.xmlSchema = XMLSchema.new(self.baseXmlKey)
	self.xmlSchema:register(XMLValueType.BOOL, self.baseXmlKey.."#debug")
	self.xmlSchema:register(XMLValueType.BOOL, self.baseXmlKey.."#lazyNPC")
	self.xmlSchema:register(XMLValueType.BOOL, self.baseXmlKey.."#discount")
	self.xmlSchema:register(XMLValueType.BOOL, self.baseXmlKey.."#hard")

	self.xmlSchema:register(XMLValueType.INT, self.baseXmlKey.."#maxActive")
	self.xmlSchema:register(XMLValueType.INT, self.baseXmlKey.."#refreshMP")
	self.xmlSchema:register(XMLValueType.FLOAT, self.baseXmlKey.."#reward")
	self.xmlSchema:register(XMLValueType.FLOAT, self.baseXmlKey.."#lease")

	local key = self.baseXmlKey..".lazyNPC"
	self.xmlSchema:register(XMLValueType.BOOL, key.."#harvest")
	self.xmlSchema:register(XMLValueType.BOOL, key.."#plowCultivate")
	self.xmlSchema:register(XMLValueType.BOOL, key.."#sow")
	self.xmlSchema:register(XMLValueType.BOOL, key.."#weed")
	self.xmlSchema:register(XMLValueType.BOOL, key.."#fertilize")

	local key = self.baseXmlKey..".discount"
	self.xmlSchema:register(XMLValueType.FLOAT, key.."#perJob")
	self.xmlSchema:register(XMLValueType.INT,   key.."#maxJobs")

	local key = self.baseXmlKey..".hard"
	self.xmlSchema:register(XMLValueType.FLOAT, key.."#penalty")
	self.xmlSchema:register(XMLValueType.INT,   key.."#leaseJobs")
	self.xmlSchema:register(XMLValueType.INT,   key.."#expire")
end
function readconfig(self)
	if g_currentMission.missionInfo.savegameDirectory == nil then return end
	-- check for config file in current savegame dir
	self.savegameDir = g_currentMission.missionInfo.savegameDirectory .."/"
	self.configFile = self.savegameDir .. self.name..'.xml'
	local xmlFile = XMLFile.loadIfExists("BCconf", self.configFile, self.xmlSchema)
	if xmlFile then
		-- read config parms:
		local key = self.baseXmlKey

		self.config.debug =		xmlFile:getValue(key.."#debug", false)			
		self.config.maxActive = xmlFile:getValue(key.."#maxActive", 3)
		self.config.multReward= xmlFile:getValue(key.."#reward", 1.)
		self.config.multLease = xmlFile:getValue(key.."#lease", 1.)
		self.config.refreshMP =	xmlFile:getValue(key.."#refreshMP", 2)		
		self.config.lazyNPC = 	xmlFile:getValue(key.."#lazyNPC", false)
		self.config.hardMode = 	xmlFile:getValue(key.."#hard", false)
		self.config.discountMode = xmlFile:getValue(key.."#discount", false)
		if self.config.lazyNPC then
			key = self.baseXmlKey..".lazyNPC"
			self.config.npcHarvest = 	xmlFile:getValue(key.."#harvest", false)			
			self.config.npcPlowCultivate =xmlFile:getValue(key.."#plowCultivate", false)		
			self.config.npcSow = 		xmlFile:getValue(key.."#sow", false)		
			self.config.npcFertilize = 	xmlFile:getValue(key.."#fertilize", false)
			self.config.npcWeed = 		xmlFile:getValue(key.."#weed", false)
		end
		if self.config.discountMode then
			key = self.baseXmlKey..".discount"
			self.config.discPerJob = MathUtil.round(xmlFile:getValue(key.."#perJob", 0.05),2)			
			self.config.discMaxJobs =	xmlFile:getValue(key.."#maxJobs", 5)		
		end
		if self.config.hardMode then
			key = self.baseXmlKey..".hard"
			self.config.hardPenalty = MathUtil.round(xmlFile:getValue(key.."#penalty", 0.1),2)			
			self.config.hardLease =		xmlFile:getValue(key.."#leaseJobs", 2)		
			self.config.hardExpire =	xmlFile:getValue(key.."#expire", SC.MONTH)		
		end
		xmlFile:delete()
		for _,setting in ipairs(self.settings) do		
			setting:setValue(self.config[setting.name])
		end
	else
		debugPrint("[%s] config file %s not found, using default settings",self.name,self.configFile)
	end
end
function loadPrices(self)
	local prices = {}
	-- store prices per 1000 l
	local items = {
		{"data/objects/bigbagpallet/fertilizer/bigbagpallet_fertilizer.xml", 1, 1920},
		{"data/objects/pallets/liquidtank/fertilizertank.xml", 0.5, 1600},
		{"data/objects/pallets/liquidtank/herbicidetank.xml", 0.5, 1200},
		{"data/objects/bigbagpallet/seeds/bigbagpallet_seeds.xml", 1, 900},
		{"data/objects/bigbagpallet/lime/bigbagpallet_lime.xml", 0.5, 225}
	}
	for _, item in ipairs(items) do
		local storeItem = g_storeManager.xmlFilenameToItem[item[1]]
		local price = item[3]
		if storeItem ~= nil then 
			price = storeItem.price * item[2]
		end
		table.insert(prices, price)
	end
	return prices
end
function setupMissionFilter(self)
	-- setup fieldjob types:
	local buttonText = {
		mow_bale	= g_i18n:getText("fieldJob_jobType_baling"),
		cultivate 	= g_i18n:getText("fieldJob_jobType_cultivating"),
		fertilize 	= g_i18n:getText("fieldJob_jobType_fertilizing"),
		harvest 	= g_i18n:getText("fieldJob_jobType_harvesting" ),
		plow   		= g_i18n:getText("fieldJob_jobType_plowing"),
		sow     	= g_i18n:getText("fieldJob_jobType_sowing"),
		spray   	= g_i18n:getText("fieldJob_jobType_spraying"),
		weed    	= g_i18n:getText("fieldJob_jobType_weeding"),
		-- lime is g_missionManager.missionTypes[2] !
	}
	self.fieldjobs = {}
	self.otherTypes = {}
	self.filterState = {}
	for _, type in ipairs(g_missionManager.missionTypes) do
		-- initial state: show all types
		self.filterState[type.name] = true
		local name = buttonText[type.name]
		if name ~= nil then 
			table.insert(self.fieldjobs, {type.typeId, type.name, name})
		else
			table.insert(self.otherTypes,{type.typeId, type.name})
		end
	end
	table.sort(self.fieldjobs, function(a,b)
				return a[3] < b[3]
				end)
	-- this is for all other mission types:
	table.insert(self.fieldjobs, 
				{nil,"other", g_i18n:getText("bc_other")})

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
end
function initGui(self)
	if not self:loadGUI(self.directory .. "gui/") then
		Logging.warning("'%s.Gui' failed to load! Supporting files are missing.", self.name)
	else
		debugPrint("-------- gui loaded -----------")
	end
	self:fixInGameMenuPage(self.settingsPage, "pageBCSettings", "gui/ui_2.dds",
			{0, 0, 128, 128}, {256,256}, nil, function () 
				if g_currentMission.missionDynamicInfo.isMultiplayer then
					return g_currentMission.isMasterUser 
				end
				return true
				end)

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
	profit:setPosition(-110/1920 *g_aspectScaleX, -12/1080 *g_aspectScaleY) 	-- 
	profit.textBold = false
	profit:setVisible(false)

	-- add field "owner" to InGameMenuMapFrame farmland view:
	local box = self.frMap.farmlandValueBox
	local labelFarmland = box:getFirstDescendant(
		function(e) return e.sourceText and 
		e.sourceText == utf8ToUpper(g_i18n:getText("ui_farmlandScreen"))..":"
		end )
	local label = labelFarmland:clone(box)
	label:setText(g_i18n:getText("bc_owner"))
	label:setVisible(false)

	local ownerText = self.frMap.farmlandIdText:clone(box)
	ownerText.textUpperCase = false
	ownerText:setVisible(false)

	self.my.ownerLabel = label 
	self.my.ownerText = ownerText
	self.frMap.farmlandValueBox:setSize(unpack(GuiUtils.getNormalizedValues(
			"1000px", {g_referenceScreenWidth,g_referenceScreenHeight})))

	-- set controls for npcbox, sortbox and their elements:
	for _, name in pairs(SC.CONTROLS) do
		self.my[name] = self.frCon.farmerBox:getDescendantById(name)
	end
	-- set callbacks for our 3 sort buttons
	for _, name in ipairs({"sortcat", "sortprof", "sortpmin"}) do
		self.my[name].onClickCallback = onClickSortButton
		self.my[name].onHighlightCallback = onHighSortButton
		self.my[name].onHighlightRemoveCallback = onRemoveSortButton
		self.my[name].onFocusCallback = onHighSortButton
		self.my[name].onLeaveCallback = onRemoveSortButton
	end
	setupMissionFilter(self)

	self.my.filterlayout:setVisible(true)
	self.my.hidden:setVisible(false)
	self.my.npcbox:setVisible(false)
	self.my.sortbox:setVisible(false)
end

function BetterContracts:initialize()
	debugPrint("[%s] initialize(): %s", self.name,self.initialized)
	if self.initialized ~= nil then return end -- run only once
	self.initialized = false
	self.config = {
		debug = false, 			-- debug mode
		maxActive = 3, 			-- max active contracts
		multReward = 1., 		-- general reward multiplier
		multLease = 1.,			-- general lease cost multiplier
		refreshMP = SC.ADMIN, 	-- necessary permission to refresh contract list (MP)
		lazyNPC = false, 		-- adjust NPC field work activity
		hardMode = false, 		-- penalty for canceled missions
		discountMode = false, 	-- get field price discount for successfull missions
		npcHarvest = false,
		npcPlowCultivate = false,
		npcSow = false,	
		npcFertilize = false,
		npcWeed = false,
		discPerJob = 0.05,
		discMaxJobs = 5,
		hardPenalty = 0.1, 		-- % of total reward for missin cancel
		hardLease =	2, 			-- # of jobs to allow borrowing equipment
		hardExpire = SC.MONTH, 	-- or "day"
	}
	self.settingsByName = {}				-- will hold setting objects, init by BCsetting.init()
	self.settings = BCsetting.init(self) 	-- settings list

	g_missionManager.missionMapNumChannels = 6
	self.missionUpdTimeout = 15000
	self.missionUpdTimer = 0 -- will also update on frame open of contracts page
	self.turnTime = 5.0 -- estimated seconds per turn at end of each lane
	self.events = {}
	--  Amazon ZA-TS3200,   Hardi Mega, TerraC6F, Lemken Az9,  mission,grain potat Titan18       
	--  default:spreader,   sprayer,    sower,    planter,     empty,  harv, harv, plow, mow,lime
	self.SPEEDLIMS = {15,   12,         15,        15,         0,      10,   10,   12,   20, 18}
	self.WORKWIDTH = {42,   24,          6,         6,         0,       9,   3.3,  4.9,   9, 18} 
	self.harvest = {} -- harvest missions       	1
	self.spread = {} -- sow, spray, fertilize, lime 2
	self.simple = {} -- plow, cultivate, weed   	3
	self.mow_bale = {} -- mow/ bale             	4
	self.transp = {} -- transport   				5
	self.supply = {} -- supplyTransport mod 		6
    self.other = {} -- deadwood, treeTrans			7
	self.IdToCont = {} -- to find a contract from its mission id
	self.fieldToMission = {} -- to find a contract from its field number
	self.catHarvest = "BEETHARVESTING BEETVEHICLES CORNHEADERS COTTONVEHICLES CUTTERS POTATOHARVESTING POTATOVEHICLES SUGARCANEHARVESTING SUGARCANEVEHICLES"
	self.catSpread = "fertilizerspreaders seeders planters sprayers sprayervehicles slurrytanks manurespreaders"
	self.catSimple = "CULTIVATORS DISCHARROWS PLOWS POWERHARROWS SUBSOILERS WEEDERS ROLLERS"
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
	self.npcProb = {
		harvest = 1.0,
		plowCultivate = 0.5,
		sow = 0.5,
		fertilize = 0.9,
		weed = 0.9,
		lime = 0.9
	}
	catMissionTypes(self) 		-- init self.typeToCat[]
	checkOtherMods(self)
	registerXML(self) 			-- register xml: self.xmlSchema

	-- to show our ingame menu settings page when admin logs in:
	Utility.appendedFunction(InGameMenuMultiplayerUsersFrame,"onAdminLoginSuccess",adminMP)

	-- to count and save/load # of jobs per farm per NPC
	Utility.appendedFunction(AbstractFieldMission,"finish",finish)
	Utility.appendedFunction(FarmStats,"saveToXMLFile",saveToXML)
	Utility.appendedFunction(FarmStats,"loadFromXMLFile",loadFromXML)
	Utility.appendedFunction(Farm,"writeStream",farmWrite)
	Utility.appendedFunction(Farm,"readStream",farmRead)

	-- to adjust contracts reward / vehicle lease values:
	Utility.overwrittenFunction(AbstractFieldMission,"calculateReward",calcReward)
	Utility.overwrittenFunction(AbstractFieldMission,"calculateVehicleUseCost",calcLeaseCost)

	-- adjust NPC activity for missions: 
	Utility.overwrittenFunction(FieldManager, "updateNPCField", NPCHarvest)

	-- hard mode:
	Utility.overwrittenFunction(HarvestMission,"calculateStealingCost",harvestCalcStealing)
	Utility.overwrittenFunction(InGameMenuContractsFrame, "onButtonCancel", onButtonCancel)
	Utility.appendedFunction(InGameMenuContractsFrame, "updateDetailContents", updateDetails)
	Utility.appendedFunction(AbstractMission, "dismiss", dismiss)
	g_messageCenter:subscribe(MessageType.DAY_CHANGED, self.onDayChanged, self)
	g_messageCenter:subscribe(MessageType.HOUR_CHANGED, self.onHourChanged, self)
	g_messageCenter:subscribe(MessageType.PERIOD_CHANGED, self.onPeriodChanged, self)

	-- discount mode:
	-- to display discount if farmland selected / on buy dialog
	Utility.appendedFunction(InGameMenuMapFrame, "onClickMap", onClickFarmland)
	Utility.overwrittenFunction(InGameMenuMapFrame, "onClickBuyFarmland", onClickBuyFarmland)
	-- to handle disct price on farmland buy
	g_farmlandManager:addStateChangeListener(self)

	-- to load own mission vehicles:
	Utility.overwrittenFunction(MissionManager, "loadMissionVehicles", BetterContracts.loadMissionVehicles)
	-- flexible mission limit: 
	Utility.overwrittenFunction(MissionManager, "hasFarmReachedMissionLimit", hasFarmReachedMissionLimit)
	-- fix AbstractMission: 
	Utility.overwrittenFunction(AbstractMission, "new", abstractMissionNew)

	-- get addtnl mission values from server:
	Utility.appendedFunction(HarvestMission, "writeStream", BetterContracts.writeStream)
	Utility.appendedFunction(HarvestMission, "readStream", BetterContracts.readStream)
	Utility.appendedFunction(BaleMission, "writeStream", BetterContracts.writeStream)
	Utility.appendedFunction(BaleMission, "readStream", BetterContracts.readStream)
	Utility.appendedFunction(TransportMission, "writeStream", BetterContracts.writeTransport)
	Utility.appendedFunction(TransportMission, "readStream", BetterContracts.readTransport)
	Utility.appendedFunction(AbstractMission, "writeUpdateStream", BetterContracts.writeUpdateStream)
	Utility.appendedFunction(AbstractMission, "readUpdateStream", BetterContracts.readUpdateStream)

	-- functions for ingame menu contracts frame:
	Utility.overwrittenFunction(InGameMenuContractsFrame, "onFrameOpen", onFrameOpen)
	Utility.appendedFunction(InGameMenuContractsFrame, "onFrameClose", onFrameClose)
	Utility.appendedFunction(InGameMenuContractsFrame, "updateFarmersBox", updateFarmersBox)
	Utility.appendedFunction(InGameMenuContractsFrame, "populateCellForItemInSection", populateCell)
	Utility.overwrittenFunction(InGameMenuContractsFrame, "updateList", updateList)
	Utility.overwrittenFunction(InGameMenuContractsFrame, "sortList", sortList)
	Utility.overwrittenFunction(InGameMenuContractsFrame, "startContract", startContract)
	Utility.appendedFunction(InGameMenu, "updateButtonsPanel", updateButtonsPanel)
end

function BetterContracts:onMissionInitialize(baseDirectory, missionCollaborators)
	MissionManager.MISSION_GENERATION_INTERVAL = 3600000 -- every 1 game hour
end

function BetterContracts:onSetMissionInfo(missionInfo, missionDynamicInfo)
	Utility.overwrittenFunction(g_currentMission.inGameMenu, "onClickMenuExtra1", onClickMenuExtra1)
	Utility.overwrittenFunction(g_currentMission.inGameMenu, "onClickMenuExtra2", onClickMenuExtra2)
end

function BetterContracts:onStartMission()
	-- check mission vehicles
	BetterContracts:validateMissionVehicles()
end

function BetterContracts:onPostLoadMap(mapNode, mapFile)
	-- handle our config and optional settings
	if g_server ~= nil then
		readconfig(self)
		local txt = string.format("%s read config: maxActive %d",self.name, self.config.maxActive)
		if self.config.lazyNPC then txt = txt..", lazyNPC" end
		if self.config.hardMode then txt = txt..", hardMode" end
		if self.config.discountMode then txt = txt..", discountMode" end
		debugPrint(txt)
	end
	if self.config.debug then
		addConsoleCommand("bcprint", "Print detail stats for all available missions.", "consoleCommandPrint", self)
		addConsoleCommand("bcFieldGenerateMission", "Force generating a new mission for given field", "consoleGenerateFieldMission", g_missionManager)
		addConsoleCommand("gsMissionLoadAllVehicles", "Loading and unloading all field mission vehicles", "consoleLoadAllFieldMissionVehicles", g_missionManager)
		addConsoleCommand("gsMissionHarvestField", "Harvest a field and print the liters", "consoleHarvestField", g_missionManager)
		addConsoleCommand("gsMissionTestHarvests", "Run an expansive tests for harvest missions", "consoleHarvestTests", g_missionManager)
	end
	-- adjust max missions
	local fieldsAmount = table.size(g_fieldManager.fields)
	local adjustedFieldsAmount = math.max(fieldsAmount, 45)
	MissionManager.MAX_MISSIONS = math.min(80, math.ceil(adjustedFieldsAmount * 0.60)) -- max missions = 60% of fields amount (minimum 45 fields) max 120
	MissionManager.MAX_MISSIONS_PER_GENERATION = math.min(MissionManager.MAX_MISSIONS / 5, 30) -- max missions per generation = max mission / 5 but not more then 30
	MissionManager.MAX_TRIES_PER_GENERATION = math.ceil(MissionManager.MAX_MISSIONS_PER_GENERATION * 1.5) -- max tries per generation 50% more then max missions per generation
	debugPrint("[%s] Fields amount %s (%s)", self.name, fieldsAmount, adjustedFieldsAmount)
	debugPrint("[%s] MAX_MISSIONS set to %s", self.name, MissionManager.MAX_MISSIONS)
	debugPrint("[%s] MAX_TRANSPORT_MISSIONS set to %s", self.name, MissionManager.MAX_TRANSPORT_MISSIONS)
	debugPrint("[%s] MAX_MISSIONS_PER_GENERATION set to %s", self.name, MissionManager.MAX_MISSIONS_PER_GENERATION)
	debugPrint("[%s] MAX_TRIES_PER_GENERATION set to %s", self.name, MissionManager.MAX_TRIES_PER_GENERATION)

	-- initialize constants depending on game manager instances
	self.ft = g_fillTypeManager.fillTypes
	self.prices = loadPrices()
	self.sprUse = {
		g_sprayTypeManager.sprayTypes[SprayType.FERTILIZER].litersPerSecond,
		g_sprayTypeManager.sprayTypes[SprayType.LIQUIDFERTILIZER].litersPerSecond,
		g_sprayTypeManager.sprayTypes[SprayType.HERBICIDE].litersPerSecond,
		0, -- seeds are measured per sqm, not per second
		g_sprayTypeManager.sprayTypes[SprayType.LIME].litersPerSecond
	}
	self.mtype = {
		FERTILIZE = g_missionManager:getMissionType("fertilize").typeId,
		SOW = g_missionManager:getMissionType("sow").typeId,
		SPRAY = g_missionManager:getMissionType("spray").typeId,
	}
	if self.limeMission then 
		self.mtype.LIME = g_missionManager:getMissionType("lime").typeId
	end
	self.gameMenu = g_currentMission.inGameMenu
	self.frCon = self.gameMenu.pageContracts
	self.frMap = self.gameMenu.pageMapOverview
	self.frMap.ingameMap.onClickMapCallback = self.frMap.onClickMap

	initGui(self) 			-- setup my gui additions
	self.initialized = true
end

function BetterContracts:onPostSaveSavegame(saveDir, savegameIndex)
	-- save our settings
	debugPrint("** saving settings to %s (%d)", saveDir, savegameIndex)
	self.configFile = saveDir.."/".. self.name..'.xml'
	local xmlFile = XMLFile.create("BCconf", self.configFile, self.baseXmlKey, self.xmlSchema)
	if xmlFile == nil then return end 

	local conf = self.config
	local key = self.baseXmlKey 
	xmlFile:setBool ( key.."#debug", 	conf.debug)
	xmlFile:setInt  ( key.."#maxActive",conf.maxActive)
	xmlFile:setFloat( key.."#reward", 	conf.multReward)
	xmlFile:setFloat( key.."#lease", 	conf.multLease)
	xmlFile:setInt  ( key.."#refreshMP",conf.refreshMP)
	xmlFile:setBool ( key.."#lazyNPC", 	conf.lazyNPC)
	xmlFile:setBool ( key.."#discount", conf.discountMode)
	xmlFile:setBool ( key.."#hard", 	conf.hardMode)
	if conf.lazyNPC then
		key = self.baseXmlKey .. ".lazyNPC"
		xmlFile:setBool (key.."#harvest", 	conf.npcHarvest)
		xmlFile:setBool (key.."#plowCultivate",conf.npcPlowCultivate)
		xmlFile:setBool (key.."#sow", 		conf.npcSow)
		xmlFile:setBool (key.."#weed", 		conf.npcWeed)
		xmlFile:setBool (key.."#fertilize", conf.npcFertilize)
	end
	if conf.discountMode then
		key = self.baseXmlKey .. ".discount"
		xmlFile:setFloat(key.."#perJob", 	conf.discPerJob)
		xmlFile:setInt  (key.."#maxJobs",	conf.discMaxJobs)
	end
	if conf.hardMode then
		key = self.baseXmlKey .. ".hard"
		xmlFile:setFloat(key.."#penalty", 	conf.hardPenalty)
		xmlFile:setInt  (key.."#leaseJobs",	conf.hardLease)
		xmlFile:setInt  (key.."#expire",	conf.hardExpire)
	end
	xmlFile:save()
	xmlFile:delete()
end
function BetterContracts:onWriteStream(streamId)
	-- write settings to a client when it joins
	for _, setting in ipairs(self.settings) do 
		setting:writeStream(streamId)
	end
end
function BetterContracts:onReadStream(streamId)
	-- client reads our config settings when it joins
	for _, setting in ipairs(self.settings) do 
		setting:readStream(streamId)
	end
end
function BetterContracts:onUpdate(dt)
	if self.transportMission and g_server == nil then 
		updateTransportTimes(dt)
	end 
	self.missionUpdTimer = self.missionUpdTimer + dt
	if self.missionUpdTimer >= self.missionUpdTimeout then
		if self.isOn then 
		self:refresh() end  -- only needed when GUI shown
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
	local dim, wid, hei, dura, wwidth, speed, vfound
	local cat = self.typeToCat[m.type.typeId]
	local rew = m:getReward()
	if cat < SC.TRANSP then
		dim = self:getDimensions(m.field, false)
		wid, hei = dim.width, dim.height
		if wid > hei then
			wid, hei = hei, wid
		end
		self.fieldToMission[m.field.fieldId] = m
		vfound, wwidth, speed = self:getFromVehicle(cat, m)

		-- estimate mission duration:
		if vfound and wwidth > 0  then
			_, dura = self:estWorktime(wid, hei, wwidth, speed)
		elseif not vfound or cat~=SC.SPREAD then
			-- use default width and speed values :
			if self.debug then
				self:warning(5, m.type.name, m.field.fieldId)
			end
			-- cat/index: 1/6, 1/7, 3/8, 4/9 = grain harvest, potato harv, plow, mow
			local ix = 6 
			if cat == SC.HARVEST then 
				local variant = m:getVehicleVariant()
				if not TableUtility.contains({"MAIZE","GRAIN"}, variant) then 
					ix = 7 						-- earth fruit harvest
				end
			else 
				ix = cat +5
			end
			_,dura = self:estWorktime(wid, hei, self.WORKWIDTH[ix], self.SPEEDLIMS[ix])
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
function BetterContracts.writeTransport(self, streamId, connection)
	-- timeleft for transport mission
	streamWriteInt32(streamId, self.timeLeft or 0)
end
function BetterContracts.readTransport(self, streamId, connection)
	self.timeLeft = streamReadInt32(streamId)
end
function updateTransportTimes(dt)
	-- update timeLeft for transport missions on an MP client
	for _,m in ipairs(g_missionManager.missions) do
		if m.timeLeft ~= nil then 
			m.timeLeft = m.timeLeft - dt * g_currentMission:getEffectiveTimeScale()
		end
	end
end
function BetterContracts.writeUpdateStream(self, streamId, connection, dirtyMask)
	-- only called for active missions
	if self.status == AbstractMission.STATUS_RUNNING then
		streamWriteBool(streamId, self.spawnedVehicles or false)
		streamWriteFloat32(streamId, self.fieldPercentageDone or 0.)
		streamWriteFloat32(streamId, self.depositedLiters or 0.)
	end
end
function BetterContracts.readUpdateStream(self, streamId, timestamp, connection)
	if self.status == AbstractMission.STATUS_RUNNING then
		self.spawnedVehicles = streamReadBool(streamId)
		self.fieldPercentageDone = streamReadFloat32(streamId)
		self.depositedLiters = streamReadFloat32(streamId)
	end
end
function hasFarmReachedMissionLimit(self,superf,farmId)
	-- overwritten from MissionManager
	local maxActive = BetterContracts.config.maxActive
	if maxActive == 0 then return false end 

	MissionManager.ACTIVE_CONTRACT_LIMIT = maxActive
	return superf(self, farmId)
end
function abstractMissionNew(isServer, superf, isClient, customMt )
	local self = superf(isServer, isClient, customMt)
	self.mission = g_currentMission 
	-- Fix for error in AbstractMission 'self.mission' still missing in Version 1.6
	return self
end
function adminMP(self)
	-- appended to InGameMenuMultiplayerUsersFrame:onAdminLoginSuccess()
	BetterContracts.gameMenu:updatePages()
end