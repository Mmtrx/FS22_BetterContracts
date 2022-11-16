--=======================================================================================================
-- BetterContracts SCRIPT
--
-- Purpose:     Enhance ingame contracts menu.
-- Functions:   options for lazyNPC, hardMode, fieldDiscount
-- Author:      Royal-Modding / Mmtrx
-- Changelog:
--  v1.2.5.0 	31.10.2022	hard mode: active miss time out at midnght. Penalty for missn cancel
--=======================================================================================================

--------------------- lazyNPC --------------------------------------------------------------------------- 
function NPCHarvest(self, superf, field, allowUpdates)
	if not allowUpdates or BetterContracts.fieldToMission[field.fieldId] == nil then 
		superf(self, field, allowUpdates)
		return
	end
	-- there is a mission offered for this field, and 
	local npc 		= BetterContracts.npcType
	local prob 		= BetterContracts.npcProb
	local limeMiss 	= BetterContracts.limeMission
	local fruitDesc, harvestReadyState, maxHarvestState, area, total, withered
	local x, z = FieldUtil.getMeasurementPositionOfField(field)
	if field.fruitType ~= nil then
		-- not an empty field
		fruitDesc = g_fruitTypeManager:getFruitTypeByIndex(field.fruitType)

		local witheredState = fruitDesc.witheredState
		if witheredState ~= nil then
			area, total = FieldUtil.getFruitArea(x - 1, z - 1, x + 1, z - 1, x - 1, z + 1, FieldUtil.FILTER_EMPTY, FieldUtil.FILTER_EMPTY, field.fruitType, witheredState, witheredState, 0, 0, 0, false)
			withered = area > 0.5 * total 
		end
		if npc.harvest then
			-- don't let NPCs harvest
			harvestReadyState = fruitDesc.maxHarvestingGrowthState
			if fruitDesc.maxPreparingGrowthState > -1 then
				harvestReadyState = fruitDesc.maxPreparingGrowthState
			end
			maxHarvestState = FieldUtil.getMaxHarvestState(field, field.fruitType)
			if maxHarvestState == harvestReadyState then return end
		end
		if npc.weed and not withered then 
			-- leave field with weeds for weeding/ spraying
			local maxWeedState = FieldUtil.getMaxWeedState(field)
			if maxWeedState >= 3 and math.random() < prob.weed then return 
			end
		end
		if npc.plowCultivate then
			-- leave a cut field for plow/ grubber/ lime mission
			area, total = FieldUtil.getFruitArea(x - 1, z - 1, x + 1, z - 1, x - 1, z + 1, FieldUtil.FILTER_EMPTY, FieldUtil.FILTER_EMPTY, field.fruitType, fruitDesc.cutState, fruitDesc.cutState, 0, 0, 0, false)
			if area > 0.5 * total and 
				g_currentMission.snowSystem.height < SnowSystem.MIN_LAYER_HEIGHT then
				local limeFactor = FieldUtil.getLimeFactor(field)
				if limeMiss and limeFactor == 0 and math.random() < prob.lime then return
				elseif math.random() < prob.plowCultivate then return 
				end 
			end
		end
		if npc.fertilize and not withered then 
			local sprayFactor = FieldUtil.getSprayFactor(field)
			if sprayFactor < 1 and math.random() < prob.fertilize then return
			end
		end
	elseif npc.sow then
		-- leave empty (plowed/grubbered) field for sow/ lime mission
		local limeFactor = FieldUtil.getLimeFactor(field)
		if limeMiss and limeFactor == 0 and math.random() < prob.lime then return
		elseif self:getFruitIndexForField(field) ~= nil and 
			math.random() < prob.sow then return 
		end
	end
	superf(self, field, allowUpdates)
end

--------------------- hard mode ------------------------------------------------------------------------- 
function updateTallyText(parent)
	debugPrint("*** updating tallyBox ***")
	local function findId(e)
		return e.sourceText and 
		e.sourceText == g_i18n:getText("fieldJob_tally_stealing")
	end
	local element = parent:getFirstDescendant(findId)
	if element then 
		element:setText(g_i18n:getText("bc_penalty"))
	end
end
function harvestCalcStealing(self,superf)
	-- body
	local penal = HarvestMission:superClass().calculateStealingCost(self)
	local steal = superf(self)
	debugPrint("BC: harvest steal/ penalty is %.1f / %.1f", steal, penal)
	return steal + penal
end
function calcStealing(self,superf)
	-- calc penalty for canceled mission
	if not self.success and self.isServer then
		local penalty = 0 
		local difficulty = 0.7 + 0.3 * g_currentMission.missionInfo.economicDifficulty
		if self.reward then  
			penalty = self.reward * difficulty * SC.PENALTY 
			debugPrint("* calcStealing: diff %.1f, penalty %d",
				difficulty, penalty)
		end
		return penalty
	end
	return superf(self)
end
function updateDetails(self, section, index)
	-- hard Mode: vehicle lease cost also for canceled mission
	local contract = nil
	local sectionContracts = self.sectionContracts[section]
	if sectionContracts ~= nil then
		contract = sectionContracts.contracts[index]
	end
	if contract == nil then return end
	local mission = contract.mission
	local lease, penal = 0, 0
	if contract.finished and not mission.success then 
		if mission:hasLeasableVehicles() and mission.spawnedVehicles then
			lease = -mission.vehicleUseCost
		end
		if mission.stealingCost ~= nil then
			penal = -mission.stealingCost
		end
		local total = lease + penal 
		self.tallyBox:getDescendantByName("leaseCost"):setText(g_i18n:formatMoney(lease, 0, true, true))
		self.tallyBox:getDescendantByName("stealing"):setText(g_i18n:formatMoney(penal, 0, true, true))
		self.tallyBox:getDescendantByName("total"):setText(g_i18n:formatMoney(total, 0, true, true))
	end
end
function dismiss(self)
	-- deduct lease cost for a canceled mission
	if self.isServer and not self.success and self:hasLeasableVehicles()
		and self.spawnedVehicles then
		self.mission:addMoney(-self.vehicleUseCost,self.farmId, 
			MoneyType.MISSIONS, true, true)
	end
end
function BetterContracts:onDayChanged()
	-- hard mode: cancel any active missions
	for _, m in ipairs(g_missionManager:getActiveMissions()) do 
		g_missionManager:cancelMission(m)
	end
end
function BetterContracts:onHourChanged()
	-- hard mode: issue warning for active missions
	if g_currentMission.environment.currentHour ~= 23 then return end 

	local farmId = g_currentMission:getFarmId()
	local count = 0 
	for _, m in ipairs(g_missionManager:getActiveMissions()) do 
		if m.farmId == farmId then 
			count = count +1
		end
	end
	if count > 0 then
		g_currentMission:addIngameNotification(FSBaseMission.INGAME_NOTIFICATION_CRITICAL, string.format(g_i18n:getText("bc_warnTimeout"), count))
	end
end
function onButtonCancel(self)
	local contract = self:getSelectedContract()
	local m = contract.mission 
	local difficulty = 0.7 + 0.3 * g_currentMission.missionInfo.economicDifficulty
	local text = g_i18n:getText("fieldJob_endContract")
	local reward = m:getReward()
	if reward then  
		local penalty = reward * difficulty * SC.PENALTY 
		text = text.. g_i18n:getText("bc_warnCancel") ..
		 g_i18n:formatMoney(penalty, 0, true, true)
	end
	g_gui:showYesNoDialog({
		text = text,
		callback = self.onCancelDialog,
		target = self
	})
end

--------------------- discount mode --------------------------------------------------------------------- 
function finish(self, success )
	-- appended to AbstractFieldMission:finish(success)
	if g_currentMission:getIsServer() and success then
		local farm =  g_farmManager:getFarmById(self.farmId)
		local npcIndex = self.field.farmland.npcIndex
		local npc = g_npcManager:getNPCByIndex(npcIndex)
		if farm.stats.npcJobs == nil then 
			farm.stats.npcJobs = {}
		end
		local jobs = farm.stats.npcJobs
		if jobs[npcIndex] == nil then 
			jobs[npcIndex] = 1 
		else
			jobs[npcIndex] = math.min(jobs[npcIndex] +1, SC.MAXJOBS)
		end
		local disct = jobs[npcIndex] * 100*SC.DISCOUNT
		g_currentMission:addIngameNotification(FSBaseMission.INGAME_NOTIFICATION_OK, 
				string.format(g_i18n:getText("bc_discValue"), npc.title, disct))
		if jobs[npcIndex] == SC.MAXJOBS then 
			g_currentMission:addIngameNotification(FSBaseMission.INGAME_NOTIFICATION_OK, 
				string.format(g_i18n:getText("bc_maxJobs"), npc.title))
		end
	end
end
function getDiscountPrice(farmland)
	local price = farmland.price
	local disct = ""
	local farm =  g_farmManager:getFarmById(g_currentMission.player.farmId)
	local jobs = farm.stats.npcJobs
	local count = jobs[farmland.npcIndex] or 0
	if count > 0 then
		price = price * (1 - count * SC.DISCOUNT) 		
		disct = string.format(" (- %d%%)", 100*count *SC.DISCOUNT)
	end
	return price, disct
end
function onClickFarmland(self, elem, X, Z)
	-- appended to InGameMenuMapFrame:onClickMap()
	if self.mode ~= InGameMenuMapFrame.MODE_FARMLANDS then return end 

	local farmland = self.selectedFarmland
	if farmland == nil or not farmland.showOnFarmlandsScreen
		or not self.canBuy
		then return 
	end
	local price, disct = getDiscountPrice(farmland)
	--self.farmlandValueText.textUpperCase = disct == ""
	self.farmlandValueText:setText(g_i18n:formatMoney(price, 0, true, true)..disct)
	self.farmlandValueBox:invalidateLayout()
end
function onClickBuyFarmland(self, superf)
	-- adjust price if player buys farmland
	if self.selectedFarmland == nil then return end

	local price, disct = getDiscountPrice(self.selectedFarmland)
	if price <= self.playerFarm:getBalance() then
		local text = string.format(self.l10n:getText(InGameMenuMapFrame.L10N_SYMBOL.DIALOG_BUY_FARMLAND), 
			self.l10n:formatMoney(price, 0, true, true)	.. disct)
		g_gui:showYesNoDialog({
			title = self.l10n:getText(InGameMenuMapFrame.L10N_SYMBOL.DIALOG_BUY_FARMLAND_TITLE),
			text = text,
			callback = BetterContracts.onYesNoBuyFarmland,
			target = BetterContracts,
			args = {self.selectedFarmland.id, g_currentMission:getFarmId(), price}
		})
	else
		g_gui:showInfoDialog({
			title = self.l10n:getText(InGameMenuMapFrame.L10N_SYMBOL.DIALOG_BUY_FARMLAND_TITLE),
			text = self.l10n:getText(InGameMenuMapFrame.L10N_SYMBOL.DIALOG_BUY_FARMLAND_NOT_ENOUGH_MONEY)
		})
	end
end
function BetterContracts:onYesNoBuyFarmland(yes, args)
	-- body
	if yes then 
		g_client:getServerConnection():sendEvent(FarmlandStateEvent.new(unpack(args)))
	end
end
function BetterContracts:onFarmlandStateChanged(landId, farmId)
	if g_server == nil or farmId == FarmlandManager.NO_OWNER_FARM_ID 
		then return end 

	-- reset npcJobs to 0 for npc seller of farmland
	local farm =  g_farmManager:getFarmById(farmId)
	local npcIndex = g_farmlandManager:getFarmlandById(landId).npcIndex
	if farm == nil or npcIndex == nil then return end 
	
	if farm.stats.npcJobs == nil then 
		farm.stats.npcJobs = {}
	end
	farm.stats.npcJobs[npcIndex] = 0 
end
function saveToXML(self, xmlFile, key)
	-- appended to FarmStats:saveToXMLFile()
	-- self is farm.stats
	local jobs = self.npcJobs
	if jobs ~= nil then
		xmlFile:setTable(key .. ".npcJobs.npc", jobs, 
			function (npcKey, npc, npcIndex)
			xmlFile:setInt(npcKey .. "#index", npcIndex)
			xmlFile:setInt(npcKey .. "#count", npc or 0)
		end)
	end
end
function loadFromXML(self, xmlFile, key)
	-- appended to FarmStats:loadFromXMLFile()
	-- self: farm.stats
	self.npcJobs = {}
	xmlFile:iterate(key .. ".npcJobs.npc", function (_, npcKey)
		local ix = xmlFile:getInt(npcKey.."#index")
		self.npcJobs[ix] = xmlFile:getInt(npcKey.."#count", 0)
	end)
end
