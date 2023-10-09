--=======================================================================================================
-- BetterContracts SCRIPT
--
-- Purpose:		Enhance ingame contracts menu.
-- Author:		Mmtrx
-- Changelog:
--  v1.2.6.0 	30.11.2022	UI for all settings
--  v1.2.6.5 	18.01.2023	add setting "toDeliver": harvest contract success factor
--  v1.2.7.4	22.02.2023	increase range for "toDeliver". Add setting "toDeliverBale"
--  v1.2.7.7	29.03.2023	add "off" values to hardMode settings
--  v1.2.7.9	03.05.2023	more values discPerJob, discMaxJobs
--  v1.2.8.3	10.10.2023	force plow after root crop harvest. Insta-ferment separate setting (#158)
--=======================================================================================================
local function lazyNPCDisabled()
	return not BetterContracts.config.lazyNPC
end
local function hardDisabled()
	return not BetterContracts.config.hardMode
end
local function discountDisabled()
	return not BetterContracts.config.discountMode
end
BCSettingsBySubtitle = {
	{
	title = "bc_baseSettings",
	elements = {
		{name = "multReward", 
		values = {.8,.9,1,1.1,1.2,1.3,1.4},
		texts = {"-20 %","-10 %","standard","+10 %","+20 %","+30 %","+40 %"},
		default = 3,
		title = "bc_rewardMultiplier",
		tooltip = "bc_rewardMultiplier_tooltip",
		actionFunc = function(self,ix) 
			BetterContracts:refresh() -- to recalc contract rewards
			end,
		noTranslate = true
			},
		{name = "multLease", 
		min = .8, max = 1.5, increment = .1,
		values = {.8,.9,1,1.1,1.2,1.3,1.4,1.5},
		texts = {"-20 %","-10 %","standard","+10 %","+20 %","+30 %","+40 %","+50 %"},
		default = 3,
		title = "bc_leaseMultiplier",
		tooltip = "bc_leaseMultiplier_tooltip",
		noTranslate = true
			},
		{name = "maxActive", 
		values = {0,1,2, 3, 4, 5, 6, 7, 8, 9, 10},
		texts = {"unlimited", "1", "2", "3", "4", "5", "6", "7", "8", "9", "10"},
		default = 1,
		title = "bc_maxActive",
		tooltip = "bc_maxActive_tooltip",
		noTranslate = true
			},
		{name = "toDeliver", 
		min = .7, max = .941, increment = .03, unit = true,
		default = 9,
		title = "bc_toDeliver",
		tooltip = "bc_toDeliver_tooltip",
		actionFunc = function(self,ix) 
			HarvestMission.SUCCESS_FACTOR = self.values[ix]
			BetterContracts:refresh() -- to recalc deliver/keep for harvest contr
			end,
		noTranslate = true
			},
		{name = "toDeliverBale", 
		min = .7, max = .91, increment = .04, unit = true,
		default = 6,
		title = "bc_toDeliverBale",
		tooltip = "bc_toDeliver_tooltip",
		actionFunc = function(self,ix) 
			BaleMission.FILL_SUCCESS_FACTOR = self.values[ix]
			BetterContracts:refresh() -- to recalc deliver/keep for baling contr
			end,
		noTranslate = true
			},
		{name = "refreshMP", 
		values = {SC.ADMIN, SC.FARMMANAGER, SC.PLAYER},
		texts = {"ui_admin","ui_farmManager","ui_players"},
		default = 1,
		title = "bc_refreshMP",
		tooltip = "bc_refreshMP_tooltip",
		isDisabledFunc = function() 
			return not g_currentMission.missionDynamicInfo.isMultiplayer end,
			},
		{name = "ferment",
		values = {false, true},
		texts = {"ui_off", "ui_on"},
		default = 1,
		title = "bc_ferment",
		tooltip = "bc_ferment_tooltip",
			},
		{name = "forcePlow",
		values = {false, true},
		texts = {"ui_off", "ui_on"},
		default = 1,
		title = "bc_forcePlow",
		tooltip = "bc_forcePlow_tooltip",
			},
		{name = "debug",
		values = {false, true},
		texts = {"ui_off", "ui_on"},
		default = 1,
		title = "bc_debug",
		tooltip = "bc_debug_tooltip",
			},
		},
	},
	{
	title = "bc_lazyNPC",
	elements = {
		{name = "lazyNPC",
		values = {false, true},
		texts = {"ui_no", "ui_yes"},
		default = 1,
		title = "bc_mainSwitch",
		tooltip = "bc_lazyNPC_tooltip",
		},
		{name = "npcHarvest",
		values = {false, true},
		texts = {"ui_off", "bc_active"},
		default = 1,
		title = "fieldJob_jobType_harvesting",
		tooltip = "bc_lazyNPCHarvest_tooltip",
		isDisabledFunc = lazyNPCDisabled,
		},
		{name = "npcSow",
		values = {false, true},
		texts = {"ui_off", "bc_active"},
		default = 1,
		title = "fieldJob_jobType_sowing",
		tooltip = "bc_lazyNPCSow_tooltip",
		isDisabledFunc = lazyNPCDisabled,
		},
		{name = "npcPlowCultivate",
		values = {false, true},
		texts = {"ui_off", "bc_active"},
		default = 1,
		title = "bc_lazyNPCPlow",
		tooltip = "bc_lazyNPCPlow_tooltip",
		isDisabledFunc = lazyNPCDisabled,
		},
		{name = "npcFertilize",
		values = {false, true},
		texts = {"ui_off", "bc_active"},
		default = 1,
		title = "fieldJob_jobType_fertilizing",
		isDisabledFunc = lazyNPCDisabled,
		tooltip = "bc_lazyNPCFertilize_tooltip",
		},
		{name = "npcWeed",
		values = {false, true},
		texts = {"ui_off", "bc_active"},
		default = 1,
		title = "fieldJob_jobType_weeding",
		tooltip = "bc_lazyNPCWeed_tooltip",
		isDisabledFunc = lazyNPCDisabled,
			}
		},
	},
	{
	title = "bc_hardMode",
	elements = {
		{name = "hardMode",
		values = {false, true},
		texts = {"ui_no", "ui_yes"},
		default = 1,
		title = "bc_mainSwitch",
		tooltip = "bc_hardMode_tooltip",
			},
		{name = "hardPenalty",
		min = .0, max = .7, increment = .1, unit = true,
		default = 2,
		title = "bc_hardPenalty",
		tooltip = "bc_hardPenalty_tooltip",
		isDisabledFunc = hardDisabled,
		noTranslate = true
			},
		{name = "hardLease",
		min = 0, max = 7, increment = 1, 
		default = 2,
		title = "bc_hardLease",
		tooltip = "bc_hardLease_tooltip",
		isDisabledFunc = hardDisabled,
		noTranslate = true
			},
		{name = "hardExpire",
		values = {SC.OFF, SC.DAY, SC.MONTH},
		texts = {"ui_off", "ui_day", "ui_month"},
		default = 3,
		title = "bc_hardExpire",
		tooltip = "bc_hardExpire_tooltip",
		isDisabledFunc = hardDisabled,
			},
		},
	},
	{
	title = "bc_discountMode",
	elements = {
		{name = "discountMode",
		values = {false, true},
		texts = {"ui_no", "ui_yes"},
		default = 1,
		title = "bc_mainSwitch",
		tooltip = "bc_discountMode_tooltip",
			},
		{name = "discPerJob",
		min = .01, max = .14, increment = .01, unit = true,
		--values = {.05,.08,.11,.14},
		--texts = {"5 %","8 %","11 %","14 %", },
		default = 1,
		title = "bc_discPerJob",
		tooltip = "bc_discPerJob_tooltip",
		isDisabledFunc = discountDisabled,
		noTranslate = true
			},
		{name = "discMaxJobs",
		min = 1, max = 20, increment = 1,
		--values = {1,2,3,4,5,6,7},
		--texts = {"1", "2", "3", "4", "5", "6", "7",},
		default = 5,
		title = "bc_discMaxJobs",
		tooltip = "bc_discMaxJobs_tooltip",
		isDisabledFunc = discountDisabled,
		noTranslate = true
			},
		},
	},
	{
	title = "bc_missionGeneration",
	elements = {
		{name = "generationInterval",
		min = 1, max = 24, increment = 1,
		default = 1,
		title = "bc_generationInterval",
		tooltip = "bc_generationInterval_tooltip",
		actionFunc = function(self,ix)
			BetterContracts:updateGenerationSettings() -- recalculate generation settings
			end,
		noTranslate = true
			},
		{name = "missionGenPercentage",
		values = {0.01, 0.02, 0.04, 0.05, 0.1, 0.2},
		texts = {"1%", "2%", "4%", "5%", "10%", "20%"},
		default = 0.2,
		title = "bc_missionGenPercentage",
		tooltip = "bc_missionGenPercentage_tooltip",
		actionFunc = function(self,ix)
			BetterContracts:updateGenerationSettings() -- recalculate generation settings
			end,
		noTranslate = true
			},
		},
	},
}
-- settings class
BCsetting = {}
local BCsetting_mt = Class(BCsetting, AIParameter)

function BCsetting.new(data, customMt)
	local self = AIParameter.new(customMt or BCsetting_mt)
	self.type = AIParameterType.SELECTOR
	self.name = data.name
	self.data = data
	if data.values ~=nil and next(data.values) ~=nil then
		self.values = table.copy(data.values)
		self.texts = table.copy(data.texts)
	elseif data.min ~= nil and data.max ~=nil then
		self.data.values = {}
		self.data.texts = {}
		BCsetting.generateValues(self, self.data.values, self.data.texts, data.min, data.max, data.increment, data.unit)
		self.values = table.copy(self.data.values)
		if self.data.texts ~= nil then
			self.texts = table.copy(self.data.texts)
		end
	end
	self.title = data.title
	self.tooltip = data.tooltip

	-- index of the current value/text
	self.default = data.default
	self.current = data.default or 1 
	-- index of the previous value/text
	self.previous = 1
	self.isDisabledFunc = data.isDisabledFunc
	self.actionFunc = data.actionFunc
	self.guiElement = nil
	return self
end
function BCsetting.init(bc)
	-- initialize setting objects from constants
	local settings = {}
	for _, subtitle in ipairs(BCSettingsBySubtitle) do 
		for _, data in ipairs(subtitle.elements) do
			local setting = BCsetting.new(data)
			setting:setValue(bc.config[setting.name])
			table.insert(settings, setting)
			bc.settingsByName[setting.name] = setting -- needed for SettingsEvent:readStream()
		end
	end
	return settings
end
function BCsetting:generateValues(values, texts, min, max, inc, percent)
	inc = inc or 1
	for i=min, max, inc do 
		table.insert(values, i)
		local value = MathUtil.round(i, 2)
		local text = percent and string.format("%d %%",value*100) or tostring(value)
		table.insert(texts, text)
	end
end
function BCsetting:setValue(value)
	-- set the settings current corresponding to input value. Return false, if value nil or not found
	local function func(...) return false end 
	if value ~= nil then
		if type(value) == "number" then 
			func = function(a, b)
				local epsilon = self.data.incremental or 0.01
				if a == nil or b == nil then return false end
				return a > b - epsilon/2 and a <= b + epsilon/2 
			end
		else
			func = function(a, b) return a == b end
		end
	else
		Logging.warning("[BetterContracts] %s:setValue() called with nil value",self.name)
		return false
	end
	-- find the value requested, set current correspondingly
	for i = 1, #self.values do
		if func(self.values[i], value) then
			self.previous = self.current
			self.current = i
			return true
		end
	end
	return false
end
function BCsetting:setIx(ix)
	-- set it to values[ix]
	local conf = BetterContracts.config
	if self.current ~= ix then 
		self.previous = self.current
		self.current = ix 
		conf[self.name] = self.values[ix]
		if self.actionFunc ~= nil then 
			self:actionFunc(ix)
		end
		debugPrint("** %s set to %s **", self.name,self.values[ix])
	end
end
function BCsetting:setGuiElement(element)
	local labels = {}
	for i = 1, #self.texts do
		if self.data.noTranslate == true then
			labels[i] = self.texts[i]
		else
			labels[i] = g_i18n:getText(self.texts[i])
		end
	end
	element:setTexts(labels)

	-- init value from BetterContracts.config:
	self:setValue(BetterContracts.config[self.name])

	element:setState(self.current)
	self.guiElement = element
	element.bc_setting = self

	local isDisabledFunc = self.isDisabledFunc
	if isDisabledFunc then 
		element:setDisabled(isDisabledFunc())
	end
end
function BCsetting:writeStream(streamId, connection)
	streamWriteInt32(streamId, self.current)
end
function BCsetting:readStream(streamId, connection)
	local ix = streamReadInt32(streamId)
	self:setIx(ix)
end
