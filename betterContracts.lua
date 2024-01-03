--=======================================================================================================
-- BetterContracts SCRIPT
--
-- Purpose:     Enhance ingame contracts menu.
-- Author:      Royal-Modding / Mmtrx
-- Copyright:	Mmtrx
-- License:		GNU GPL v3.0
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
--  v1.2.6.1 	05.12.2022	initGui(): utf8ToUpper(). Addtnl l10n translations from github
--  v1.2.6.2 	16.12.2022	don't act onFarmlandStateChanged() before mission started. Smaller menu icon
--  v1.2.6.3 	02.01.2023	onClickBuyFarmland, missionVehicles (userdefined) fixed
--  v1.2.6.4 	17.01.2023	fix issue #88: onClickBuyFarmland() if discountMode off
--  v1.2.6.5 	18.01.2023	add setting "toDeliver": harvest contract success factor.
--							Improve reward multiplier getReward()
--							handle zombie (pallet, bigbag) vehicles when dismissing contracts
--  v1.2.7.0 	29.01.2023	visual tags for mission fields and vehicles.
--							show leased vehicles for active contracts
--  v1.2.7.1 	10.02.2023	fix mission visual tags for MP: renderIcon().
--  v1.2.7.2	15.02.2023	Add settings to adjust contract generation
-- 							Icon for roller missions. Don't show negative togos
--  v1.2.7.3	20.02.2023	double progress bar active contracts. Fix PnH BGA/ Maize+
--  v1.2.7.4	22.02.2023	increase range for "toDeliver". Add setting "toDeliverBale"
--  v1.2.7.5	26.02.2023	display other farms active contracts (MP only).
--							Read userDefined missions from "BCuserDefined.xml" in modSettings dir
--  v1.2.7.6	21.03.2023	format rewd values > 100.000 (issue #113)
--							Read userDefined from modSettings/FS22_BetterContracts/<mapName>/ (issue #115)
--  v1.2.7.7	29.03.2023	add "off" values to hardMode settings. Allow forage wagon on grass missions (#118)
--							"userDefined.xml" compat with FS22_DynamicMissionVehicles
--  v1.2.7.8	12.04.2023	getfilltypePrice() catch unknown fillType. Allow mission bales in storage.
--							let player instant-ferment wrapped bales
--  v1.2.7.9	21.04.2023	Allow 240er PackedBales as mission bales, i.e. insta ferment.
--							Add 240er bales to Kuhn sw4014 wrapper
--  v1.2.8.0	03.08.2023	Sort per NPC and contract value. Allow Göweil mission bales.
--							Allow mowers/ swathers on harvest missions. Tweak plow reward (#137)
--  v1.2.8.1	17.08.2023	save NPC farmland owners to farmland.xml (#153).
--  v1.2.8.2	22.09.2023	support chaff mission. Insta-ferment only in debug mode (#158)
--  v1.2.8.3	10.10.2023	force plow after root crop harvest (#123). Insta-ferment separate setting (#158)
--  v1.2.8.5	10.10.2023	add settings ferment, forcePlow to readconfig(), onPostSaveSavegame()
--  v1.2.8.6	12.10.2023	add bcPrintVehicles console command. Fix farmlandManagerSaveToXMLFile() (#169)
--	v1.2.8.7 	02.12.2023	npc should not work before noon of first day in month (#187)
--							new setting "hardLimit": limit jobs per farm and month (#168)
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
	OFF = 0,
	DAY = 1,
	MONTH = 2,
	-- Gui farmerBox controls:
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
		"sortrev",
		"sortnpc",
		sortprof = "sortprof",
		sortpmin = "sortpmin",
		helpsort = "helpsort",
		container = "container",
		mTable = "mTable",
		mToggle = "mToggle",
	},
	-- Gui contractBox controls:
	CONTBOX = {
		"box1", "box2", "prog1", "prog2",
		"progressBarBg", "progressBar1", "progressBar2"
	}
}
function debugPrint(text, ...)
	if BetterContracts.config and BetterContracts.config.debug then
		Logging.info(text, ...)
	end
end

source(Utils.getFilename("RoyalMod.lua", g_currentModDirectory .. "scripts/")) -- RoyalMod support functions
source(Utils.getFilename("Utility.lua", g_currentModDirectory .. "scripts/"))  -- RoyalMod utility functions
---@class BetterContracts : RoyalMod
BetterContracts = RoyalMod.new(false, true)                                    --params bool debug, bool sync

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
	self.jobText = {}
	local function addMapping(name, title, category)
		local missionType = g_missionManager:getMissionType(name)
		if missionType ~= nil then
			self.typeToCat[missionType.typeId] = category
			self.jobText[name] = g_i18n:getText(title)
		end
	end
	addMapping("mow_bale", "fieldJob_jobType_baling", SC.BALING)
	addMapping("plow", "fieldJob_jobType_plowing", SC.SIMPLE)
	addMapping("cultivate", "fieldJob_jobType_cultivating", SC.SIMPLE)
	addMapping("sow", "fieldJob_jobType_sowing", SC.SPREAD)
	addMapping("harvest", "fieldJob_jobType_harvesting", SC.HARVEST)
	addMapping("weed", "fieldJob_jobType_weeding", SC.SIMPLE)
	addMapping("spray", "fieldJob_jobType_spraying", SC.SPREAD)
	addMapping("fertilize", "fieldJob_jobType_fertilizing", SC.SPREAD)
	addMapping("transport", "helpLine_Misc_Transport", SC.TRANSP)
	addMapping("supplyTransport", "ai_jobTitleDeliver", SC.SUPPLY)          -- mod by GtX
	addMapping("deadwood", "deadwoodMission_title", SC.OTHER)               -- Platinum DLC mission by Giants
	addMapping("treeTransport", "treeTransportMission_title", SC.OTHER)     -- Platinum DLC mission by Giants
	addMapping("destructibleRocks", "destructibleRockMission_title", SC.OTHER) -- Platinum DLC mission by Giants
	addMapping("roll", "helpLine_ImproveYield_Rolling", SC.SIMPLE)          -- roller mission by tn4799
	addMapping("lime", "helpLine_ImproveYield_Liming", SC.SPREAD)           -- lime mission by Mmtrx
	addMapping("chaff", "bc_jobType_chaff", SC.HARVEST)                     -- chaff mission by Mmtrx
	for _, missionType in pairs(g_missionManager.missionTypes) do
		if self.typeToCat[missionType.typeId] == nil then
			addMapping(missionType.name, SC.OTHER) -- default category for not registered mission types
		end
	end
	-- check mission types
	for i = #self.typeToCat + 1, g_missionManager.nextMissionTypeId - 1 do
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
		FS22_MaizePlus = "maizePlus",
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
	self.xmlSchema:register(XMLValueType.BOOL, self.baseXmlKey .. "#debug")
	self.xmlSchema:register(XMLValueType.BOOL, self.baseXmlKey .. "#ferment")
	self.xmlSchema:register(XMLValueType.BOOL, self.baseXmlKey .. "#forcePlow")
	self.xmlSchema:register(XMLValueType.BOOL, self.baseXmlKey .. "#lazyNPC")
	self.xmlSchema:register(XMLValueType.BOOL, self.baseXmlKey .. "#discount")
	self.xmlSchema:register(XMLValueType.BOOL, self.baseXmlKey .. "#hard")

	self.xmlSchema:register(XMLValueType.INT, self.baseXmlKey .. "#maxActive")
	self.xmlSchema:register(XMLValueType.INT, self.baseXmlKey .. "#refreshMP")
	self.xmlSchema:register(XMLValueType.FLOAT, self.baseXmlKey .. "#reward")
	self.xmlSchema:register(XMLValueType.FLOAT, self.baseXmlKey .. "#lease")
	self.xmlSchema:register(XMLValueType.FLOAT, self.baseXmlKey .. "#deliver")

	local key = self.baseXmlKey .. ".rewards"
	self.xmlSchema:register(XMLValueType.FLOAT, key .. "#mow_bale")
	self.xmlSchema:register(XMLValueType.FLOAT, key .. "#plow")
	self.xmlSchema:register(XMLValueType.FLOAT, key .. "#cultivate")
	self.xmlSchema:register(XMLValueType.FLOAT, key .. "#sow")
	self.xmlSchema:register(XMLValueType.FLOAT, key .. "#harvest")
	self.xmlSchema:register(XMLValueType.FLOAT, key .. "#weed")
	self.xmlSchema:register(XMLValueType.FLOAT, key .. "#spray")
	self.xmlSchema:register(XMLValueType.FLOAT, key .. "#fertilize")
	self.xmlSchema:register(XMLValueType.FLOAT, key .. "#others")

	local key = self.baseXmlKey .. ".lazyNPC"
	self.xmlSchema:register(XMLValueType.BOOL, key .. "#harvest")
	self.xmlSchema:register(XMLValueType.BOOL, key .. "#plowCultivate")
	self.xmlSchema:register(XMLValueType.BOOL, key .. "#sow")
	self.xmlSchema:register(XMLValueType.BOOL, key .. "#weed")
	self.xmlSchema:register(XMLValueType.BOOL, key .. "#fertilize")

	local key = self.baseXmlKey .. ".discount"
	self.xmlSchema:register(XMLValueType.FLOAT, key .. "#perJob")
	self.xmlSchema:register(XMLValueType.INT, key .. "#maxJobs")

	local key = self.baseXmlKey .. ".hard"
	self.xmlSchema:register(XMLValueType.FLOAT, key .. "#penalty")
	self.xmlSchema:register(XMLValueType.INT, key .. "#leaseJobs")
	self.xmlSchema:register(XMLValueType.INT, key .. "#expire")
	self.xmlSchema:register(XMLValueType.INT, key .. "#hardLimit")

	local key = self.baseXmlKey .. ".generation"
	self.xmlSchema:register(XMLValueType.INT, key .. "#interval")
	self.xmlSchema:register(XMLValueType.FLOAT, key .. "#percentage")
end

function readconfig(self)
	if g_currentMission.missionInfo.savegameDirectory == nil then return end
	-- check for config file in current savegame dir
	self.savegameDir = g_currentMission.missionInfo.savegameDirectory .. "/"
	self.configFile = self.savegameDir .. self.name .. '.xml'
	local xmlFile = XMLFile.loadIfExists("BCconf", self.configFile, self.xmlSchema)
	if xmlFile then
		-- read config parms:
		local key = self.baseXmlKey

		self.config.debug = xmlFile:getValue(key .. "#debug", false)
		self.config.ferment = xmlFile:getValue(key .. "#ferment", false)
		self.config.forcePlow = xmlFile:getValue(key .. "#forcePlow", false)
		self.config.maxActive = xmlFile:getValue(key .. "#maxActive", 3)
		self.config.multLease = xmlFile:getValue(key .. "#lease", 1.)
		self.config.toDeliver = xmlFile:getValue(key .. "#deliver", 0.94)
		self.config.toDeliverBale = xmlFile:getValue(key .. "#deliver", 0.90)
		self.config.refreshMP = xmlFile:getValue(key .. "#refreshMP", 2)
		self.config.lazyNPC = xmlFile:getValue(key .. "#lazyNPC", false)
		self.config.hardMode = xmlFile:getValue(key .. "#hard", false)
		self.config.discountMode = xmlFile:getValue(key .. "#discount", false)

		-- Rewards per job type
		key = self.baseXmlKey .. ".rewards"
		self.config.multRewardMowBale = xmlFile:getValue(key .. "#mow_bale", 1.)
		self.config.multRewardPlow = xmlFile:getValue(key .. "#plow", 1.)
		self.config.multRewardCultivate = xmlFile:getValue(key .. "#cultivate", 1.)
		self.config.multRewardSow = xmlFile:getValue(key .. "#sow", 1.)
		self.config.multRewardHarvest = xmlFile:getValue(key .. "#harvest", 1.)
		self.config.multRewardWeed = xmlFile:getValue(key .. "#weed", 1.)
		self.config.multRewardSpray = xmlFile:getValue(key .. "#spray", 1.)
		self.config.multRewardFertilize = xmlFile:getValue(key .. "#fertilize", 1.)
		self.config.multRewardOthers = xmlFile:getValue(key .. "#others", 1.)

		if self.config.lazyNPC then
			key = self.baseXmlKey .. ".lazyNPC"
			self.config.npcHarvest = xmlFile:getValue(key .. "#harvest", false)
			self.config.npcPlowCultivate = xmlFile:getValue(key .. "#plowCultivate", false)
			self.config.npcSow = xmlFile:getValue(key .. "#sow", false)
			self.config.npcFertilize = xmlFile:getValue(key .. "#fertilize", false)
			self.config.npcWeed = xmlFile:getValue(key .. "#weed", false)
		end
		if self.config.discountMode then
			key = self.baseXmlKey .. ".discount"
			self.config.discPerJob = MathUtil.round(xmlFile:getValue(key .. "#perJob", 0.05), 2)
			self.config.discMaxJobs = xmlFile:getValue(key .. "#maxJobs", 5)
		end
		if self.config.hardMode then
			key = self.baseXmlKey .. ".hard"
			self.config.hardPenalty = MathUtil.round(xmlFile:getValue(key .. "#penalty", 0.1), 2)
			self.config.hardLease = xmlFile:getValue(key .. "#leaseJobs", 2)
			self.config.hardExpire = xmlFile:getValue(key .. "#expire", SC.MONTH)
			self.config.hardLimit = xmlFile:getValue(key .. "#hardLimit", -1)
		end
		key = self.baseXmlKey .. ".generation"
		self.config.generationInterval = xmlFile:getValue(key .. "#interval", 1)
		self.config.missionGenPercentage = xmlFile:getValue(key .. "#percentage", 0.2)
		xmlFile:delete()
		for _, setting in ipairs(self.settings) do
			setting:setValue(self.config[setting.name])
		end
	else
		debugPrint("[%s] config file %s not found, using default settings", self.name, self.configFile)
	end
end

function loadPrices(self)
	local prices = {}
	-- store prices per 1000 l
	local items = {
		{ "data/objects/bigbagpallet/fertilizer/bigbagpallet_fertilizer.xml", 1,   1920 },
		{ "data/objects/pallets/liquidtank/fertilizertank.xml",               0.5, 1600 },
		{ "data/objects/pallets/liquidtank/herbicidetank.xml",                0.5, 1200 },
		{ "data/objects/bigbagpallet/seeds/bigbagpallet_seeds.xml",           1,   900 },
		{ "data/objects/bigbagpallet/lime/bigbagpallet_lime.xml",             0.5, 225 }
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
	self.buttonNames = {}
	self.otherTypes = {}
	self.filterState = {}
	for _, type in ipairs(g_missionManager.missionTypes) do
		-- initial state: show all types
		self.filterState[type.name] = true
		-- setup button names
		local name = self.jobText[type.name]
		if string.find("mow_balecultivatefertilizeharvestplowsowsprayweed", type.name) then
			table.insert(self.buttonNames, { type.typeId, type.name, name })
		else
			table.insert(self.otherTypes, { type.typeId, type.name, name })
		end
	end
	table.sort(self.buttonNames, function(a, b)
		return a[3] < b[3]
	end)
	-- this is for all other mission types:
	table.insert(self.buttonNames,
		{ nil, "other", g_i18n:getText("bc_other") })

	-- set controls for filterbox:
	self.my.filterlayout = self.frCon.contractsContainer:getDescendantById("filterlayout")
	self.my.hidden = self.frCon.contractsContainer:getDescendantById("hidden")
	for i, name in ipairs({ "fb1", "fb2", "fb3",
		"fb4", "fb5", "fb6", "fb7", "fb8", "fb9" }) do
		self.my[name] = self.frCon.contractsContainer:getDescendantById(name)
		local button = self.my[name]
		button.onClickCallback = onClickFilterButton
		button.pressed = true
		-- set button text
		button.elements[1]:setText(self.buttonNames[i][3])
	end
end

function initGui(self)
	if not self:loadGUI(self.directory .. "gui/") then
		Logging.warning("'%s.Gui' failed to load! Supporting files are missing.", self.name)
	else
		debugPrint("-------- gui loaded -----------")
	end
	self:fixInGameMenuPage(self.settingsPage, "pageBCSettings", "gui/ui_2.dds",
		{ 0, 0, 64, 64 }, { 256, 256 }, nil, function()
			if g_currentMission.missionDynamicInfo.isMultiplayer then
				return g_currentMission.isMasterUser
			end
			return true
		end)
	loadIcons(self)
	------------------- setup my display elements -------------------------------------
	-- move farmer picture to right
	local fbox = self.frCon.farmerBox
	for _, v in ipairs(fbox:getDescendants()) do
		if v.id ~= nil and
			v.id:sub(1, 6) == "farmer" then
			v:move(115 / 1920, 0)
		end
	end
	-- add field "profit" to all listItems
	local rewd = self.frCon.contractsList.cellDatabase.autoCell1:getDescendantByName("reward")
	local profit = rewd:clone(self.frCon.contractsList.cellDatabase.autoCell1)
	profit.name = "profit"
	profit:setPosition(-144 / 1920 * g_aspectScaleX, -12 / 1080 * g_aspectScaleY) --
	profit.textBold = false
	profit:setVisible(false)

	-- add field "owner" to InGameMenuMapFrame farmland view:
	local box = self.frMap.farmlandValueBox
	local labelFarmland = box:getFirstDescendant(
		function(e)
			return e.sourceText and
				e.sourceText == utf8ToUpper(g_i18n:getText("ui_farmlandScreen")) .. ":"
		end)
	local label = labelFarmland:clone(box)
	label:setText(g_i18n:getText("bc_owner"))
	label:setVisible(false)

	local ownerText = self.frMap.farmlandIdText:clone(box)
	ownerText.textUpperCase = false
	ownerText:setVisible(false)

	self.my.ownerLabel = label
	self.my.ownerText = ownerText
	self.frMap.farmlandValueBox:setSize(unpack(GuiUtils.getNormalizedValues(
		"1000px", { g_referenceScreenWidth, g_referenceScreenHeight })))

	-- set controls for npcbox, sortbox and their elements:
	for _, name in pairs(SC.CONTROLS) do
		self.my[name] = self.frCon.detailsBox:getDescendantById(name)
	end
	-- set controls for contractBox:
	for _, name in pairs(SC.CONTBOX) do
		self.my[name] = self.frCon.contractBox:getDescendantById(name)
	end
	-- set callbacks for our 3 sort buttons
	for _, name in ipairs({ "sortcat", "sortrev", "sortnpc", "sortprof", "sortpmin" }) do
		self.my[name].onClickCallback = onClickSortButton
		self.my[name].onHighlightCallback = onHighSortButton
		self.my[name].onHighlightRemoveCallback = onRemoveSortButton
		self.my[name].onFocusCallback = onHighSortButton
		self.my[name].onLeaveCallback = onRemoveSortButton
	end
	setupMissionFilter(self)

	-- init other farms mission table
	self.my.mTable:initialize()
	self.my.container:setVisible(false)
	self.mapTableOn = false -- visibility of other farms mission table
	self.my.mToggle.onClickCallback = onClickToggle
	self.my.mToggle:setVisible(self.isMultiplayer)

	self.my.filterlayout:setVisible(true)
	self.my.hidden:setVisible(false)
	self.my.npcbox:setVisible(false)
	self.my.sortbox:setVisible(false)
end

function BetterContracts:initialize()
	debugPrint("[%s] initialize(): %s", self.name, self.initialized)
	if self.initialized ~= nil then return end -- run only once
	self.initialized = false
	self.config = {
		debug = false,        -- debug mode
		ferment = false,      -- allow insta-fermenting wrapped bales by player
		forcePlow = false,    -- force plow after root crop harvest
		maxActive = 3,        -- max active contracts
		multLease = 1.,       -- general lease cost multiplier
		toDeliver = 0.94,     -- HarvestMission.SUCCESS_FACTOR
		toDeliverBale = 0.90, -- BaleMission.SUCCESS_FACTOR
		generationInterval = 1, -- MissionManager.MISSION_GENERATION_INTERVAL
		missionGenPercentage = 0.2, -- percent of missions to be generated (default: 20%)
		refreshMP = SC.ADMIN, -- necessary permission to refresh contract list (MP)
		lazyNPC = false,      -- adjust NPC field work activity
		hardMode = false,     -- penalty for canceled missions
		discountMode = false, -- get field price discount for successfull missions
		npcHarvest = false,
		npcPlowCultivate = false,
		npcSow = false,
		npcFertilize = false,
		npcWeed = false,
		discPerJob = 0.05,
		discMaxJobs = 5,
		hardPenalty = 0.1, -- % of total reward for missin cancel
		hardLease = 2,   -- # of jobs to allow borrowing equipment
		hardExpire = SC.MONTH, -- or "day"
		hardLimit = -1,  -- max jobs to accept per farm and month
		multRewardMowBale = 1.,
		multRewardPlow = 1.,
		multRewardCultivate = 1.,
		multRewardSow = 1.,
		multRewardHarvest = 1.,
		multRewardWeed = 1.,
		multRewardSpray = 1.,
		multRewardFertilize = 1.,
		multRewardOthers = 1.,
	}
	self.NPCAllowWork = false         -- npc should not work before noon of last 2 days in month
	self.settingsByName = {}          -- will hold setting objects, init by BCsetting.init()
	self.settings = BCsetting.init(self) -- settings list
	self.missionVecs = {}             -- holds names of active mission vehicles

	g_missionManager.missionMapNumChannels = 6
	self.missionUpdTimeout = 15000
	self.missionUpdTimer = 0 -- will also update on frame open of contracts page
	self.turnTime = 5.0   -- estimated seconds per turn at end of each lane
	self.events = {}
	--  Amazon ZA-TS3200,   Hardi Mega, TerraC6F, Lemken Az9,  mission,grain potat Titan18
	--  default:spreader,   sprayer,    sower,    planter,     empty,  harv, harv, plow, mow,lime
	self.SPEEDLIMS = { 15, 12, 15, 15, 0, 10, 10, 12, 20, 18 }
	self.WORKWIDTH = { 42, 24, 6, 6, 0, 9, 3.3, 4.9, 9, 18 }
	self.harvest = {}     -- harvest missions       	1
	self.spread = {}      -- sow, spray, fertilize, lime 2
	self.simple = {}      -- plow, cultivate, weed   	3
	self.mow_bale = {}    -- mow/ bale             	4
	self.transp = {}      -- transport   				5
	self.supply = {}      -- supplyTransport mod 		6
	self.other = {}       -- deadwood, treeTrans			7
	self.IdToCont = {}    -- to find a contract from its mission id
	self.fieldToMission = {} -- to find a contract from its field number
	self.catHarvest =
	"BEETHARVESTING BEETVEHICLES CORNHEADERS COTTONVEHICLES CUTTERS POTATOHARVESTING POTATOVEHICLES SUGARCANEHARVESTING SUGARCANEVEHICLES"
	self.catSpread = "fertilizerspreaders seeders planters sprayers sprayervehicles slurrytanks manurespreaders"
	self.catSimple = "CULTIVATORS DISCHARROWS PLOWS POWERHARROWS SUBSOILERS WEEDERS ROLLERS"
	self.isOn = false
	self.numCont = 0                            -- # of contracts in our tables
	self.numHidden = 0                          -- # of hidden (filtered) contracts
	self.my = {}                                -- will hold my gui element adresses
	self.sort = 0                               -- sorted status: 1 cat, 2 prof, 3 permin
	self.lastSort = 0                           -- last sorted status
	self.buttons = {
		{ "sortcat",  g_i18n:getText("SC_sortCat") }, -- {button id, help text}
		{ "sortrev",  g_i18n:getText("SC_sortRev") },
		{ "sortnpc",  g_i18n:getText("SC_sortNpc") },
		{ "sortprof", g_i18n:getText("SC_sortProf") },
		{ "sortpmin", g_i18n:getText("SC_sortpMin") }
	}
	self.npcProb = {
		harvest = 1.0,
		plowCultivate = 0.5,
		sow = 0.5,
		fertilize = 0.9,
		weed = 0.9,
		lime = 0.9
	}
	catMissionTypes(self) -- init self.typeToCat[]
	checkOtherMods(self)
	registerXML(self)  -- register xml: self.xmlSchema

	-- to show our ingame menu settings page when admin logs in:
	Utility.appendedFunction(InGameMenuMultiplayerUsersFrame, "onAdminLoginSuccess", adminMP)

	-- to allow forage wagon on bale missions:
	Utility.overwrittenFunction(BaleMission, "new", baleMissionNew)
	-- to allow MOWER / SWATHER on harvest missions:
	Utility.overwrittenFunction(HarvestMission, "new", harvestMissionNew)

	-- to allow MOWER / SWATHER on harvest missions:
	Utility.prependedFunction(HarvestMission, "completeField", harvestCompleteField)

	-- to set missionBale for packed 240cm bales:
	Utility.overwrittenFunction(Bale, "loadBaleAttributesFromXML", loadBaleAttributes)

	-- allow stationary baler to produce mission bales:
	local pType = g_vehicleTypeManager:getTypeByName("pdlc_goeweilPack.balerStationary")
	if pType ~= nil then
		SpecializationUtil.registerOverwrittenFunction(pType, "createBale", self.createBale)
	end

	-- to count and save/load # of jobs per farm per NPC
	Utility.appendedFunction(AbstractFieldMission, "finish", finish)
	Utility.appendedFunction(FarmStats, "saveToXMLFile", saveToXML)
	Utility.appendedFunction(FarmStats, "loadFromXMLFile", loadFromXML)
	Utility.appendedFunction(Farm, "writeStream", farmWrite)
	Utility.appendedFunction(Farm, "readStream", farmRead)
	Utility.overwrittenFunction(FarmlandManager, "saveToXMLFile", farmlandManagerSaveToXMLFile)

	-- to adjust contracts reward / vehicle lease values:
	Utility.overwrittenFunction(AbstractFieldMission, "getReward", getReward)
	Utility.overwrittenFunction(AbstractFieldMission, "calculateVehicleUseCost", calcLeaseCost)

	-- adjust NPC activity for missions:
	Utility.overwrittenFunction(FieldManager, "updateNPCField", NPCHarvest)

	-- hard mode:
	Utility.overwrittenFunction(HarvestMission, "calculateStealingCost", harvestCalcStealing)
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
	Utility.overwrittenFunction(AbstractFieldMission, "loadNextVehicleCallback", loadNextVehicle)
	Utility.prependedFunction(AbstractFieldMission, "removeAccess", removeAccess)
	Utility.appendedFunction(AbstractFieldMission, "onVehicleReset", onVehicleReset)

	for name, typeDef in pairs(g_vehicleTypeManager.types) do
		-- rename mission vehicle:
		if typeDef ~= nil and not TableUtility.contains({ "horse", "pallet", "locomotive" }, name) then
			SpecializationUtil.registerOverwrittenFunction(typeDef, "getName", vehicleGetName)
		end
	end
	Utility.appendedFunction(MissionManager, "loadFromXMLFile", missionManagerLoadFromXMLFile)
	Utility.appendedFunction(InGameMenuMapUtil, "showContextBox", showContextBox)

	-- tag mission fields in map:
	Utility.appendedFunction(FieldHotspot, "render", renderIcon)

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
	BetterContracts:updateGenerationInterval()
end

function BetterContracts:onSetMissionInfo(missionInfo, missionDynamicInfo)
	PlowMission.REWARD_PER_HA = 2800 -- tweak plow reward (#137)

	-- setup new / clear buttons for contracts page:
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
		local txt = string.format("%s read config: maxActive %d", self.name, self.config.maxActive)
		if self.config.lazyNPC then txt = txt .. ", lazyNPC" end
		if self.config.hardMode then txt = txt .. ", hardMode" end
		if self.config.discountMode then txt = txt .. ", discountMode" end
		debugPrint(txt)
	end
	addConsoleCommand("bcPrint", "Print detail stats for all available missions.", "consoleCommandPrint", self)
	addConsoleCommand("bcMissions", "Print stats for other clients active missions.", "bcMissions", self)
	addConsoleCommand("bcPrintVehicles", "Print all available vehicle groups for mission types.", "printMissionVehicles",
		self)
	if self.config.debug then
		addConsoleCommand("bcFieldGenerateMission", "Force generating a new mission for given field",
			"consoleGenerateFieldMission", g_missionManager)
		addConsoleCommand("gsMissionLoadAllVehicles", "Loading and unloading all field mission vehicles",
			"consoleLoadAllFieldMissionVehicles", g_missionManager)
		addConsoleCommand("gsMissionHarvestField", "Harvest a field and print the liters", "consoleHarvestField",
			g_missionManager)
		addConsoleCommand("gsMissionTestHarvests", "Run an expansive tests for harvest missions", "consoleHarvestTests",
			g_missionManager)
	end
	-- init Harvest SUCCESS_FACTORs (std is harv = .93, bale = .9)
	HarvestMission.SUCCESS_FACTOR = self.config.toDeliver
	BaleMission.FILL_SUCCESS_FACTOR = self.config.toDeliverBale

	BetterContracts:updateGenerationSettings()

	-- initialize constants depending on game manager instances
	self.isMultiplayer = g_currentMission.missionDynamicInfo.isMultiplayer
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
	self.frMap.buttonBuyFarmland.onClickCallback = onClickBuyFarmland

	initGui(self) -- setup my gui additions
	self.initialized = true
end

function BetterContracts:updateGenerationInterval()
	-- init Mission generation rate (std is 1 hour)
	MissionManager.MISSION_GENERATION_INTERVAL = self.config.generationInterval * 3600000
end

function BetterContracts:updateGenerationSettings()
	BetterContracts:updateGenerationInterval()

	-- adjust max missions
	local fieldsAmount = table.size(g_fieldManager.fields)
	local adjustedFieldsAmount = math.max(fieldsAmount, 45)
	MissionManager.MAX_MISSIONS = math.min(80, math.ceil(adjustedFieldsAmount * 0.60))                 -- max missions = 60% of fields amount (minimum 45 fields) max 120
	MissionManager.MAX_MISSIONS_PER_GENERATION = math.min(MissionManager.MAX_MISSIONS * self.config.missionGenPercentage,
		30)                                                                                            -- max missions per generation = max mission / 5 but not more then 30
	MissionManager.MAX_TRIES_PER_GENERATION = math.ceil(MissionManager.MAX_MISSIONS_PER_GENERATION * 1.5) -- max tries per generation 50% more then max missions per generation
	debugPrint("[%s] Fields amount %s (%s)", self.name, fieldsAmount, adjustedFieldsAmount)
	debugPrint("[%s] MAX_MISSIONS set to %s", self.name, MissionManager.MAX_MISSIONS)
	debugPrint("[%s] MAX_TRANSPORT_MISSIONS set to %s", self.name, MissionManager.MAX_TRANSPORT_MISSIONS)
	debugPrint("[%s] MAX_MISSIONS_PER_GENERATION set to %s", self.name, MissionManager.MAX_MISSIONS_PER_GENERATION)
	debugPrint("[%s] MAX_TRIES_PER_GENERATION set to %s", self.name, MissionManager.MAX_TRIES_PER_GENERATION)
end

function BetterContracts:onPostSaveSavegame(saveDir, savegameIndex)
	-- save our settings
	debugPrint("** saving settings to %s (%d)", saveDir, savegameIndex)
	self.configFile = saveDir .. "/" .. self.name .. '.xml'
	local xmlFile = XMLFile.create("BCconf", self.configFile, self.baseXmlKey, self.xmlSchema)
	if xmlFile == nil then return end

	local conf = self.config
	local key = self.baseXmlKey
	xmlFile:setBool(key .. "#debug", conf.debug)
	xmlFile:setBool(key .. "#ferment", conf.ferment)
	xmlFile:setBool(key .. "#forcePlow", conf.forcePlow)
	xmlFile:setInt(key .. "#maxActive", conf.maxActive)
	xmlFile:setFloat(key .. "#lease", conf.multLease)
	xmlFile:setFloat(key .. "#deliver", conf.toDeliver)
	xmlFile:setFloat(key .. "#deliverBale", conf.toDeliverBale)
	xmlFile:setInt(key .. "#refreshMP", conf.refreshMP)
	xmlFile:setBool(key .. "#lazyNPC", conf.lazyNPC)
	xmlFile:setBool(key .. "#discount", conf.discountMode)
	xmlFile:setBool(key .. "#hard", conf.hardMode)

	-- Rewards per job type
	key = self.baseXmlKey .. ".rewards"
	xmlFile:setFloat(key .. "#mow_bale", conf.multRewardMowBale)
	xmlFile:setFloat(key .. "#plow", conf.multRewardPlow)
	xmlFile:setFloat(key .. "#cultivate", conf.multRewardCultivate)
	xmlFile:setFloat(key .. "#sow", conf.multRewardSow)
	xmlFile:setFloat(key .. "#harvest", conf.multRewardHarvest)
	xmlFile:setFloat(key .. "#weed", conf.multRewardWeed)
	xmlFile:setFloat(key .. "#spray", conf.multRewardSpray)
	xmlFile:setFloat(key .. "#fertilize", conf.multRewardFertilize)
	xmlFile:setFloat(key .. "#others", conf.multRewardOthers)

	if conf.lazyNPC then
		key = self.baseXmlKey .. ".lazyNPC"
		xmlFile:setBool(key .. "#harvest", conf.npcHarvest)
		xmlFile:setBool(key .. "#plowCultivate", conf.npcPlowCultivate)
		xmlFile:setBool(key .. "#sow", conf.npcSow)
		xmlFile:setBool(key .. "#weed", conf.npcWeed)
		xmlFile:setBool(key .. "#fertilize", conf.npcFertilize)
	end
	if conf.discountMode then
		key = self.baseXmlKey .. ".discount"
		xmlFile:setFloat(key .. "#perJob", conf.discPerJob)
		xmlFile:setInt(key .. "#maxJobs", conf.discMaxJobs)
	end
	if conf.hardMode then
		key = self.baseXmlKey .. ".hard"
		xmlFile:setFloat(key .. "#penalty", conf.hardPenalty)
		xmlFile:setInt(key .. "#leaseJobs", conf.hardLease)
		xmlFile:setInt(key .. "#expire", conf.hardExpire)
		xmlFile:setInt(key .. "#hardLimit", conf.hardLimit)
	end
	key = self.baseXmlKey .. ".generation"
	xmlFile:setInt(key .. "#interval", conf.generationInterval)
	xmlFile:setFloat(key .. "#percentage", conf.missionGenPercentage)
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
	if self.initialized == false then
		return
	end

	if self.transportMission and g_server == nil then
		updateTransportTimes(dt)
	end

	self.missionUpdTimer = self.missionUpdTimer + dt
	if self.missionUpdTimer >= self.missionUpdTimeout then
		if self.isOn then
			self:refresh()
		end -- only needed when GUI shown
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
	--debugPrint("[%s] refresh() at %s sec, found %d contracts", self.name,
	--	g_i18n:formatNumber(g_currentMission.time/1000)  ,#list)
	self.numCont = 0
	for _, m in ipairs(list) do
		res = self:addMission(m)
		if res[1] and res[1] > 0 then
			self.IdToCont[m.id] = res
			self.numCont = self.numCont + 1
		end
	end
	self.missionUpdTimer = 0 -- don't call us again too soon
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
	-- check for Maize+ (or other unknown) filltype
	local fillType = m.fillType
	if m.sellPoint.fillTypePrices[fillType] ~= nil then
		return m.sellPoint:getEffectiveFillTypePrice(fillType)
	end
	if m.sellPoint.fillTypePrices[FillType.SILAGE] then
		return m.sellPoint:getEffectiveFillTypePrice(FillType.SILAGE)
	end
	Logging.warning("[%s]:addMission(): SellPoint %s has no price for fillType %s.",
		self.name, m.sellPoint:getName(), self.ft[m.fillType].title)
	return 0
end

function BetterContracts:calcProfit(m, successFactor)
	-- calculate brutto income as reward + value of kept harvest
	local keep = math.floor(m.expectedLiters * (1 - successFactor))
	local price = self:getFilltypePrice(m)
	return keep, price, m:getReward() + keep * price
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
		if vfound and wwidth > 0 then
			_, dura = self:estWorktime(wid, hei, wwidth, speed)
		elseif not vfound or cat ~= SC.SPREAD then
			-- use default width and speed values :
			if self.debug then
				self:warning(5, m.type.name, m.field.fieldId)
			end
			-- cat/index: 1/6, 1/7, 3/8, 4/9 = grain harvest, potato harv, plow, mow
			local ix = 6
			if cat == SC.HARVEST then
				local variant = m:getVehicleVariant()
				if not TableUtility.contains({ "MAIZE", "GRAIN" }, variant) then
					ix = 7 -- earth fruit harvest
				end
			else
				ix = cat + 5
			end
			_, dura = self:estWorktime(wid, hei, self.WORKWIDTH[ix], self.SPEEDLIMS[ix])
		end
		if (cat == SC.HARVEST or cat == SC.BALING) and m.expectedLiters == nil then
			Logging.warning("[%s]:addMission(): contract '%s %s on field %s' has no expectedLiters.",
				self.name, m.type.name, self.ft[m.fillType].title, m.field.fieldId)
			m.expectedLiters = 0
			return { 0, cont }
		end
	end
	if cat == SC.HARVEST then
		local keep, price, profit = self:calcProfit(m, HarvestMission.SUCCESS_FACTOR)
		cont = {
			miss = m,
			width = wid,
			height = hei,
			worktime = dura,
			ftype = self.ft[m.fillType].title,
			deliver = math.ceil(m.expectedLiters - keep), --must be delivered
			keep = keep,                         --can be sold on your own
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
		local keep, price, profit = self:calcProfit(m, BaleMission.FILL_SUCCESS_FACTOR)
		cont = {
			miss = m,
			width = wid,
			height = hei,
			worktime = dura * 3, -- dura is just the mow time, adjust for windrowing/ baling
			ftype = self.ft[m.fillType].title,
			deliver = math.ceil(m.expectedLiters - keep),
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
			profit = rew - m.contractLiters * m.pricePerLitre,
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
	return { cat, cont }
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
	for _, m in ipairs(g_missionManager.missions) do
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

function hasFarmReachedMissionLimit(self, superf, farmId)
	-- overwritten from MissionManager
	local maxActive = BetterContracts.config.maxActive
	if maxActive == 0 then return false end

	MissionManager.ACTIVE_CONTRACT_LIMIT = maxActive
	return superf(self, farmId)
end

function abstractMissionNew(isServer, superf, isClient, customMt)
	local self = superf(isServer, isClient, customMt)
	self.mission = g_currentMission
	-- Fix for error in AbstractMission 'self.mission' still missing in Version 1.9
	return self
end

function adminMP(self)
	-- appended to InGameMenuMultiplayerUsersFrame:onAdminLoginSuccess()
	BetterContracts.gameMenu:updatePages()
end

function baleMissionNew(isServer, superf, isClient, customMt)
	-- allow forage wagons to collect grass/ hay, for baling/wrapping at stationary baler
	local self = superf(isServer, isClient, customMt)
	self.workAreaTypes[WorkAreaType.FORAGEWAGON] = true
	self.workAreaTypes[WorkAreaType.CUTTER] = true
	return self
end

function harvestMissionNew(isServer, superf, isClient, customMt)
	-- allow mower/ swather to harvest swaths
	local self = superf(isServer, isClient, customMt)
	self.workAreaTypes[WorkAreaType.MOWER] = true
	self.workAreaTypes[WorkAreaType.FORAGEWAGON] = true
	return self
end
