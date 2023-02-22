--=======================================================================================================
-- BetterContracts SCRIPT
--
-- Purpose:		Enhance ingame contracts menu.
-- Author:		Royal-Modding / Mmtrx
-- Changelog:
--  v1.0.0.0	19.10.2020	initial by Royal-Modding
--	v1.1.0.0	12.04.2021	release candidate RC-2
--  v1.1.1.0	24.04.2021  (Mmtrx) gui enhancements: addtl details, sort buttons
--  v1.1.1.4    07.07.2021  (Mmtrx) add user-defined missionVehicles.xml, allow missions with no vehicles
--  v1.2.0.0    18.01.2022  (Mmtrx) adapt for FS22
--  v1.2.2.0    30.03.2022  recognize conflict FS22_Contracts_Plus, 
--                          details for transport missions
--  v1.2.3.0    04.04.2022  filter contracts per jobtype
--  v1.2.4.0    26.08.2022  allow for other (future) mission types, 
-- 							fix distorted menu page for different screen aspect ratios,
-- 							show fruit type to harvest in contracts list 
--  v1.2.4.1 	05.09.2022	indicate leased equipment for active missions
--							allow clear/new contracts button only for master user
--  v1.2.4.3 	10.10.2022	recognize FS22_LimeMission
--  v1.2.6.0 	30.11.2022	UI for all settings
--  v1.2.6.2 	16.12.2022	don't act onFarmlandStateChanged() before mission started. Smaller menu icon 
--  v1.2.7.0 	29.01.2023	visual tags for mission fields and vehicles. 
--							show leased vehicles for active contracts 
--  v1.2.7.2 	12.02.2023	don't show negative togos
--  v1.2.7.3	20.02.2023	double progress bar active contracts. Fix PnH BGA/ Maize+ 
--=======================================================================================================

--- Adds a new page to the in game menu.
function BetterContracts:fixInGameMenuPage(frame, pageName, iconFile, uvs, sizeFile, 
	position, predicateFunc)
	local inGameMenu = g_gui.screenControllers[InGameMenu]

	-- remove all to avoid warnings
	for k, v in pairs({pageName}) do
		inGameMenu.controlIDs[v] = nil
	end
	inGameMenu:registerControls({pageName})
	inGameMenu[pageName] = frame
	inGameMenu.pagingElement:addElement(inGameMenu[pageName])
	inGameMenu:exposeControlsAsFields(pageName)

	if position == nil then 	-- should insert before contractsPage
		for i = 1, #inGameMenu.pagingElement.elements do
			local child = inGameMenu.pagingElement.elements[i]
			if child == inGameMenu.pageContracts then
				position = i
				break
			end
		end
	end
	for i = 1, #inGameMenu.pagingElement.elements do
		local child = inGameMenu.pagingElement.elements[i]
		if child == inGameMenu[pageName] then
			table.remove(inGameMenu.pagingElement.elements, i)
			table.insert(inGameMenu.pagingElement.elements, position, child)
			break
		end
	end
	for i = 1, #inGameMenu.pagingElement.pages do
		local child = inGameMenu.pagingElement.pages[i]
		if child.element == inGameMenu[pageName] then
			table.remove(inGameMenu.pagingElement.pages, i)
			table.insert(inGameMenu.pagingElement.pages, position, child)
			break
		end
	end

	inGameMenu.pagingElement:updateAbsolutePosition()
	inGameMenu.pagingElement:updatePageMapping()
	
	inGameMenu:registerPage(inGameMenu[pageName], position, predicateFunc)
	local iconFileName = Utils.getFilename(iconFile, self.directory)
	inGameMenu:addPageTab(inGameMenu[pageName],iconFileName,GuiUtils.getUVs(uvs, sizeFile))
	inGameMenu[pageName]:applyScreenAlignment()
	inGameMenu[pageName]:updateAbsolutePosition()

	for i = 1, #inGameMenu.pageFrames do
		local child = inGameMenu.pageFrames[i]
		if child == inGameMenu[pageName] then
			table.remove(inGameMenu.pageFrames, i)
			table.insert(inGameMenu.pageFrames, position, child)
			break
		end
	end
	inGameMenu:rebuildTabList()
end
function loadIcons(self)
	-- body
	local iconFile = Utils.getFilename("gui/ui_2.dds", self.directory)
	local missionUVs = {
		plow = 		{ 64,  0, 64, 64},
		harvest = 	{128,  0, 64, 64},
		sow = 		{192,  0, 64, 64},
		hay = 		{  0, 64, 64, 64},
		silage = 	{ 64, 64, 64, 64},
		fertilize = {128, 64, 64, 64},
		weed = 		{192, 64, 64, 64},
	}
	self.missionIcons = {}
	local icon 
	for type, uvs in pairs(missionUVs) do 
		icon = Overlay.new(iconFile,0,0, getNormalizedScreenValues(30, 30))
		icon:setUVs(GuiUtils.getUVs(uvs, {256,256}))
		self.missionIcons[type] = icon 
	end
end
function loadGuiFile(self, fname, parent, initial)
	-- load gui from file, attach to parent, call initial func
	if fileExists(fname) then
		xmlFile = loadXMLFile("Temp", fname)
		local fbox = self.frCon.farmerBox
		-- load our "npcbox" as child of farmerBox:
		g_gui:loadGuiRec(xmlFile, "GUI", parent, self.frCon)
		initial(parent)
		delete(xmlFile)
	else
		Logging.error("[GuiLoader %s]  Required file '%s' could not be found!", self.name, fname)
		return false
	end
	return true
end
function BetterContracts:loadGUI(guiPath)
	-- load my gui profiles
	local fname = guiPath .. "guiProfiles.xml"
	if fileExists(fname) then
		g_gui:loadProfiles(fname)
	else
		Logging.error("[GuiLoader %s]  Required file '%s' could not be found!", self.name, fname)
		return false
	end
	-- load our "npcbox" as child of farmerBox:
	local canLoad = loadGuiFile(self, guiPath.."SCGui.xml", self.frCon.farmerBox, function(parent)
		local npcbox = parent:getDescendantById("npcbox")
		npcbox:applyScreenAlignment()
		npcbox:updateAbsolutePosition()
		parent:getDescendantById("layout"):invalidateLayout(true) -- adjust sort buttons
	end)
	-- load filter buttons
	if canLoad then 
		canLoad = loadGuiFile(self, guiPath.."filterGui.xml", self.frCon.contractsContainer, function(parent)
			layout = parent:getDescendantById("filterlayout")
			layout:applyScreenAlignment()
			layout:updateAbsolutePosition()
			layout:invalidateLayout(true) -- adjust filter buttons
			local hidden = parent:getDescendantById("hidden")
			hidden:applyScreenAlignment()
			hidden:updateAbsolutePosition()
		end)
	end
	-- load progress bars
	if canLoad then 
		canLoad = loadGuiFile(self, guiPath.."progressGui.xml", self.frCon.contractBox, function(parent)
			for _,id in ipairs({"box1","box2"}) do
				layout = parent:getDescendantById(id)
				layout:applyScreenAlignment()
				layout:updateAbsolutePosition()
				layout:invalidateLayout(true) -- adjust text fields
			end
		end)
	end
	if not canLoad then return false end 
	
	-- load "BCsettingsPage.lua"
	if g_gui ~= nil and g_gui.guis.BCSettingsFrame == nil then
		local luaPath = guiPath .. "BCsettingsPage.lua"
		if fileExists(luaPath) then
			source(luaPath)
		else
			Logging.error("[GuiLoader %s]  Required file '%s' could not be found!", self.name, luaPath)
			return false
		end
	end
	-- load "settingsPage.xml"
	fname = guiPath .. "settingsPage.xml"
	if fileExists(fname) then
		self.settingsPage = BCSettingsPage:new()
		if g_gui:loadGui(fname, "BCSettingsFrame", self.settingsPage, true) == nil then
			Logging.error("[GuiLoader %s]  Error loading SettingsPage", self.name)
			return false
		end
	else
		Logging.error("[GuiLoader %s]  Required file '%s' could not be found!", self.name, fname)
		return false
	end
	return true
end
function onFrameOpen(superself, superFunc, ...)
	local self = BetterContracts
	local inGameMenu = self.gameMenu
	if self.needsRefreshContractsConflictsPrevention then
		-- this will prevent execution of FS22_RefreshContracts code (because they check for that field to be nil)
		inGameMenu.refreshContractsElement_Button = 1
	end
	if self.preventContractsPlus then
		-- this will prevent execution of FS22_Contracts_Plus code (because they check for those fields to be nil)
		inGameMenu.newContractsButton = 1
		inGameMenu.clearContractsButton = 1
	end
	superFunc(superself, ...)
	inGameMenu.refreshContractsElement_Button = nil
	inGameMenu.newContractsButton = nil 
	inGameMenu.clearContractsButton = nil 
	FocusManager:unsetFocus(self.frCon.contractsList)  -- to allow focus movement

	local parent = inGameMenu.menuButton[1].parent
	-- add new buttons
	if inGameMenu.newButton == nil then
		inGameMenu.newButton = inGameMenu.menuButton[1]:clone(parent)
		inGameMenu.newButton.onClickCallback = onClickNewContractsCallback
		inGameMenu.newButton:setText(g_i18n:getText("bc_new_contracts"))
		inGameMenu.newButton:setInputAction("MENU_EXTRA_1")
	end
	if inGameMenu.clearButton == nil then
		inGameMenu.clearButton = inGameMenu.menuButton[1]:clone(parent)
		inGameMenu.clearButton.onClickCallback = onClickClearContractsCallback
		inGameMenu.clearButton:setText(g_i18n:getText("bc_clear_contracts"))
		inGameMenu.clearButton:setInputAction("MENU_EXTRA_2")
	end
	if inGameMenu.detailsButton == nil then
		local button = inGameMenu.menuButton[1]:clone(parent)
		button.onClickCallback = detailsButtonCallback
		inGameMenu.detailsButton = button
		local text = g_i18n:getText("bc_detailsOn")
		if self.isOn then
			text = g_i18n:getText("bc_detailsOff")
		end
		button:setText(text)
		button:setInputAction("MENU_EXTRA_3")
	end
	-- register action, so that our button is also activated by keystroke
	local _, eventId = g_currentMission.inputManager:registerActionEvent("MENU_EXTRA_3", inGameMenu, onClickMenuExtra3, false, true, false, true)
	self.eventExtra3 = eventId

	-- if we were sorted on last frame close, focus the corresponding sort button
	if self.isOn and self.sort > 0 then
		self:radioButton(self.sort)
	end
end
function onFrameClose()
	local inGameMenu = g_currentMission.inGameMenu
	for _, button in ipairs(
		{
			inGameMenu.newButton,
			inGameMenu.clearButton,
			inGameMenu.detailsButton
		}
	) do
		if button ~= nil then
			button:unlinkElement()
			button:delete()
		end
	end
	if BetterContracts.eventExtra3 ~= nil then
		g_inputBinding:removeActionEvent(BetterContracts.eventExtra3)
	end
	inGameMenu.newButton = nil
	inGameMenu.clearButton = nil
	inGameMenu.detailsButton = nil
end

function onClickMenuExtra1(inGameMenu, superFunc, ...)
	if superFunc ~= nil then
		superFunc(inGameMenu, ...)
	end
	if inGameMenu.newButton ~= nil then
		inGameMenu.newButton.onClickCallback(inGameMenu)
	end
end
function onClickMenuExtra2(inGameMenu, superFunc, ...)
	if superFunc ~= nil then
		superFunc(inGameMenu, ...)
	end
	if inGameMenu.clearButton ~= nil then
		inGameMenu.clearButton.onClickCallback(inGameMenu)
	end
end
function onClickMenuExtra3(inGameMenu)
	---Due to how the input system works in fs22, the input is not only handled
	-- with a click callback but also via these events
	if inGameMenu.detailsButton ~= nil then
		inGameMenu.detailsButton.onClickCallback(inGameMenu)
		inGameMenu:playSample(GuiSoundPlayer.SOUND_SAMPLES.CLICK)
	end
end

function onClickNewContractsCallback(inGameMenu)
	BetterContractsNewEvent.sendEvent()
end
function onClickClearContractsCallback(inGameMenu)
	BetterContractsClearEvent.sendEvent()
end
function detailsButtonCallback(inGameMenu)
	local self = BetterContracts
	local frCon = self.frCon

	-- it's a toggle button - change my "on" state
	self.isOn = not self.isOn
	self.my.npcbox:setVisible(self.isOn)
	self.my.sortbox:setVisible(self.isOn)

	if self.isOn then
		inGameMenu.detailsButton:setText(g_i18n:getText("bc_detailsOff"))
		-- if we were sorted on last "off" click, then one of our sort buttons might still have focus
		if self.lastSort > 0 then
			FocusManager:setFocus(frCon.contractsList, "top") -- remove focus from our sort buttton
		end
	else
		inGameMenu.detailsButton:setText(g_i18n:getText("bc_detailsOn"))
		-- "off" always resets sorting to default
		if self.sort > 0 then
			self:radioButton(0) -- reset all sort buttons
		end
		self.my.helpsort:setText("")
	end
	frCon:updateList() -- restore standard sort order
	-- refresh farmerBox
	local s, i = frCon.contractsList:getSelectedPath()
	frCon:updateDetailContents(s, i)
end

function makeCon(m)
	local missionInfo = m:getData()
	return {
		mission = m,
		active = m.status == AbstractMission.STATUS_RUNNING,
		finished = m.status == AbstractMission.STATUS_FINISHED,
		possible = m.status == AbstractMission.STATUS_STOPPED,
		jobType = missionInfo.jobType
	}
end
function updateList(frCon,superFunc)
	-- complete overwrite, to handle filterbutton settings 
	-- called from messageCenter on mission change events (start,dismiss,finish),
	--  mission generated / deleted
	local self = BetterContracts
	local list = g_missionManager:getMissionsList(g_currentMission:getFarmId())
	local numCont = #list 
	local hasMissions = numCont ~= 0
	if  numCont ~= self.numCont then
		-- update our own mission type tables, so that we can show the details
		self:refresh()
	end
	frCon.contractsListBox:setVisible(hasMissions)
	frCon.detailsBox:setVisible(hasMissions)
	frCon.noContractsBox:setVisible(not hasMissions)

	frCon.contracts = {}
	self.numHidden = 0 
	for _, m in ipairs(list) do
		local nofilter = m.status == AbstractMission.STATUS_RUNNING or 
						m.status == AbstractMission.STATUS_FINISHED
		if nofilter or self.filterState[m.type.name] then 
			table.insert(frCon.contracts, makeCon(m))
		else
			self.numHidden = self.numHidden +1
		end
	end
	frCon:sortList()
	frCon.contractsList:reloadData()
	self.my.hidden:setText(string.format(g_i18n:getText("bc_hidden"),self.numHidden))
	self.my.hidden:setVisible(self.numHidden > 0)
end
function filterList(typeId, show)
	-- called when a filterbutton was clicked. Gui contractsFrame is up, i.e.
	--  contracts list is already there. Needs some adjustments only 
	local self = BetterContracts
	local frCon = self.frCon
	local type = g_missionManager:getMissionTypeById(typeId)
	local nofilter 
	debugPrint("  *filterList - show %s: %s", type.name, show)
	if show then
		-- re-insert filtered contracts:
		for _, m in ipairs(g_missionManager:getMissionsList(g_currentMission:getFarmId())) do
			nofilter = m.status == AbstractMission.STATUS_RUNNING or 
						m.status == AbstractMission.STATUS_FINISHED
			if not nofilter and m.type == type then 
				table.insert(frCon.contracts, makeCon(m))
				self.numHidden = self.numHidden -1
			end
		end
	else
	-- remove filtered-off contracts:
		local remove = {}
		for _, c in ipairs(frCon.contracts) do
			nofilter = c.active or c.finished  
			if not nofilter and c.mission.type.typeId == typeId then 
				table.insert(remove, c)
			end
		end
		for _, c in ipairs(remove) do 
			table.removeElement(frCon.contracts, c)
		end
		self.numHidden = self.numHidden + #remove
	end
	frCon:sortList()
	frCon.contractsList:reloadData()
	self.my.hidden:setText(string.format(g_i18n:getText("bc_hidden"),self.numHidden))
	self.my.hidden:setVisible(self.numHidden > 0)
end
function populateCell(frCon, list, sect, index, cell)
	local profit = cell:getAttribute("profit")
	local self = BetterContracts
	if not self.isOn then
		profit:setVisible(false)
		return
	end
	local m = frCon.sectionContracts[sect].contracts[index].mission
	local id = m.id
	local cont
	if self.IdToCont[id] == nil or self.IdToCont[id][2] == nil then
		debugPrint("populateCell(): empty IdToCont for id %s. sect/index: %s/%s",
			id, sect,index)
	else
		cont = self.IdToCont[id][2]
	end
	local prof = self.IdToCont[id] and self.IdToCont[id][2] and self.IdToCont[id][2].profit or 0
	local cat = self.IdToCont[id] and self.IdToCont[id][1] or 0
	local showProf = false
	if cat==SC.HARVEST or cat==SC.SPREAD or cat==SC.BALING then 
	-- only for harvest, spread, mow contracts
		-- update total profit
		if cat == SC.HARVEST then 
			_,_, prof = self:calcProfit(m, HarvestMission.SUCCESS_FACTOR)
		elseif cat == SC.BALING then 
			_,_, prof = self:calcProfit(m, BaleMission.FILL_SUCCESS_FACTOR)
		end
		--todo: update profit spread mission
		
		local reward = cell:getAttribute("reward")
		local rewtext = reward:getText()
		reward:setText(g_i18n:formatMoney(prof, 0, true, true))
		profit:setText(rewtext)
		showProf = true
		if cat == SC.HARVEST and cont ~= nil then 
			-- overwrite "contract" with fruittype to harvest
			local fruit = cell:getAttribute("contract")
			fruit:setText(g_i18n:getText("bc_harvest").. cont.ftype)
		end
	end
	profit:setVisible(showProf)
	-- indicate leased equipment for active missions
	if cont and cont.miss.status == AbstractMission.STATUS_RUNNING then
		local indicator = cell:getAttribute("indicatorActive")
		local txt = ""
		if cont.miss.spawnedVehicles then
			txt = g_i18n:getText("bc_leased")
		end
		indicator:setText(g_i18n:getText("fieldJob_active")..txt)
		indicator:setVisible(true)
	end
end
function sortList(frCon, superfunc)
	-- sort frCon.contracts according to sort button clicked
	local self = BetterContracts
	if not self.isOn or self.sort < 2 then
		superfunc(frCon)
		return
	end
	local sorts = function(a, b)
		local av, bv = 1000000.0 * (a.active and 1 or 0) + 500000.0 * (a.finished and 1 or 0), 1000000.0 * (b.active and 1 or 0) + 500000.0 * (b.finished and 1 or 0)
		local am, bm = a.mission, b.mission

		if self.sort == 3 then -- sort profit per Minute
			-- if permin == 0 for both am, bm, then sort on profit
			av = av +  50.0 * self.IdToCont[am.id][2].permin + 0.0001 * self.IdToCont[am.id][2].profit
			bv = bv +  50.0 * self.IdToCont[bm.id][2].permin + 0.0001 * self.IdToCont[bm.id][2].profit
		elseif self.sort == 2 then -- sort profit
			av = av + self.IdToCont[am.id][2].profit
			bv = bv + self.IdToCont[bm.id][2].profit
		--[[
		elseif self.sort == 1 then -- sort mission category / field #
			av = av - 10000 * self.IdToCont[am.id][1] - 100 * am.type.typeId
			if am.field ~= nil then
				av = av - am.field.fieldId
			end
			bv = bv - 10000 * self.IdToCont[bm.id][1] - 100 * bm.type.typeId
			if bm.field ~= nil then
				bv = bv - bm.field.fieldId
			end
		]]	
		else -- should not happen
			av, bv = am.generationTime, bm.generationTime
		end
		return av > bv
	end
	table.sort(frCon.contracts, sorts)

	-- distribute contracts to sections
	frCon.sectionContracts = {
		{ 	title = g_i18n:getText("fieldJob_active"),
			contracts = {}
		},
		{	title = g_i18n:getText("fieldJob_finished"),
			contracts = {}
		},
		{	title = g_i18n:getText("SC_sortpMin"):upper(),
			contracts = {}
		}
	}
	if self.sort == 2 then 
		frCon.sectionContracts[3].title = g_i18n:getText("SC_sortProf"):upper()
	end
	local lastType = nil
	for _, contract in ipairs(frCon.contracts) do
		if contract.active then
			table.insert(frCon.sectionContracts[1].contracts, contract)
		elseif contract.finished then
			table.insert(frCon.sectionContracts[2].contracts, contract)
		else
			table.insert(frCon.sectionContracts[3].contracts, contract)
		end
	end
	if #frCon.sectionContracts[2].contracts == 0 then
		table.remove(frCon.sectionContracts, 2)
	end
	if #frCon.sectionContracts[1].contracts == 0 then
		table.remove(frCon.sectionContracts, 1)
	end
end
function updateFarmersBox(frCon, field, npc)
	-- set the text values in our npcbox
	local self = BetterContracts
	if not self.isOn then return end

	-- find the current contract
	local section, ix = frCon.contractsList:getSelectedPath()
	local cont, m, con = nil, nil, nil
	local secCons = frCon.sectionContracts[section]
	if secCons ~= nil then
		cont = secCons.contracts[ix]
	end
	if cont ~= nil then 
		m = cont.mission 
	end
	if m ~= nil then 
		con = self.IdToCont[m.id]
	end
	if con == nil then
		Logging.error("**BetterContracts:updateFarmersBox() - no contract found for mission id " .. tostring(m.id))
		return
	end
	local cat = con[1]
	local c = con[2]
	self.my.npcbox:setVisible(true)

	-- show # of completed jobs
	if field ~= nil and npc ~= nil then 
		local farm =  g_farmManager:getFarmById(g_currentMission.player.farmId)
		if farm.stats.npcJobs == nil then 
			farm.stats.npcJobs = {}
		end
		local jobs = farm.stats.npcJobs
		if jobs[npc.index] == nil then 
			jobs[npc.index] = 0
		end 
		local txt = string.format(g_i18n:getText("bc_jobsCompleted"), jobs[npc.index])
		frCon.farmerText:setText(txt)
	end	

	-- handle non-field missions
	self.my.field:setText(g_i18n:getText("SC_fillType")) 	-- line 1
	self.my.filltype:setText(c.ftype)
	self.my.widhei:setText("") 			-- line 2
	self.my.dimen:setText("")
	self.my.line3:setText("") 			-- line 3
	self.my.etime:setText("")
	if cont.active then
		self.my.line4a:setText(g_i18n:getText("SC_delivered"))
		self.my.line4b:setText(g_i18n:getText("SC_togo"))
	else
		self.my.line4a:setText(g_i18n:getText("SC_deliver"))
		self.my.line4b:setText("")
		self.my.valu4b:setText("")
	end
	self.my.line6:setText(g_i18n:getText("SC_profitSupply"))
	self.my.valu6:setText(g_i18n:formatMoney(c.profit))
	self.my.ppmin:setText("")
	self.my.valu7:setText("")

	if cat == SC.TRANSP then 		-- it's a transport mission (maybe mod)
		if cont.active then
			self.my.valu4a:setText(string.format("%d Pal.", m.numFinished))
			self.my.valu4b:setText(string.format("%d Pal.",m.numObjects - m.numFinished))
		else
			self.my.valu4a:setText(string.format("%d Pal.",m.numObjects))
			self.my.ppmin:setText(g_i18n:getText("SC_timeleft"))
			local timeleft = m.timeLeft or 60000  -- just precaution
			local secLeft =  timeleft / 1000 
			local hh = math.floor(secLeft / 3600)
			local mm = (secLeft - 3600*hh) / 60
			local ss = (mm - math.floor(mm)) *60
			self.my.valu7:setText(string.format("%02d:%02d:%02d",hh,mm,ss))
		end
		self.my.line5:setText("")
		self.my.price:setText("")
		return
	elseif cat == SC.SUPPLY then -- a supplyTransp mission (mod)
		if cont.active then
			self.my.valu4a:setText(g_i18n:formatVolume(MathUtil.round(m.deliveredLiters,-2)))
			self.my.valu4b:setText(g_i18n:formatVolume(MathUtil.round(m.contractLiters-m.deliveredLiters,-2)))
		else
			self.my.valu4a:setText(g_i18n:formatVolume(MathUtil.round(m.contractLiters,-2)))
		end
		self.my.line5:setText(g_i18n:getText("SC_price")) 
		self.my.price:setText(g_i18n:formatMoney(c.price))
        return
    elseif cat == SC.OTHER then  -- platinum mission types
        self.my.field:setText("")
		self.my.line5:setText("")
		self.my.price:setText("")
        self.my.line4a:setText("")
        self.my.valu4a:setText("")
        self.my.line4b:setText("")
        self.my.valu4b:setText("")
		return
	end 

	-- handle field missions
	if field ~= nil then 
		local text = string.format(g_i18n:getText("SC_field"), field.fieldId, g_i18n:formatArea(field.fieldArea, 2))
		self.my.field:setText(text)
		self.my.widhei:setText(g_i18n:getText("SC_widhei"))
		self.my.ppmin:setText(g_i18n:getText("SC_profpmin"))
	end
	local etime = c.worktime
	if cat == SC.SPREAD then
		etime = c.worktime[c.bestj]
	end
	self.my.dimen:setText(string.format("%s / %s m", g_i18n:formatNumber(c.width), g_i18n:formatNumber(c.height)))
	self.my.line3:setText(g_i18n:getText("SC_worktim"))
	self.my.etime:setText(g_i18n:formatMinutes(etime / 60))
	self.my.valu7:setText(g_i18n:formatMoney(c.permin))
	self.my.line5:setText(g_i18n:getText("SC_price")) -- will be overwritten if active/ cat 4
	self.my.line5:setVisible(cat ~= SC.SIMPLE) -- price field only for harvest/ spread/ mow contracts

	if cat == SC.HARVEST or cat == SC.BALING then -- harvest / mow contract
		local active = cont.active
		local text, text4a, text4b
		--get current price
		local price = self:getFilltypePrice(m)
		self.my.filltype:setText(c.ftype)

		if active then
			self.my.line3:setText(g_i18n:getText("SC_worked"))
			self.my.etime:setText(string.format("%.1f%%", m.fieldPercentageDone * 100))

			local depo = 0 		-- just as protection
			if m.depositedLiters then depo = m.depositedLiters end

			local delivered = MathUtil.round(depo / 100) * 100
			-- don't show negative togos:
			local togo		= math.max(MathUtil.round((c.deliver - depo) / 100)*100, 0)
			text4a, text4b = g_i18n:getText("SC_delivered"), g_i18n:getText("SC_togo")
			local val4a, val4b = g_i18n:formatVolume(delivered), g_i18n:formatVolume(togo)
			if cat == SC.BALING then
				local bUnit = g_i18n:getText("unit_bale")
				bUnit = string.sub(bUnit, 1, 1):upper() .. string.sub(bUnit, 2)
				text4a = text4a .." (4k "..bUnit..")" 
				text4b = text4b .." (4k "..bUnit..")"
				val4a = string.format("%.0f (%d)",delivered, math.floor(delivered/4000))
				val4b = string.format("%.0f (%d)",togo, math.ceil(togo/4000))
			end
			self.my.line4a:setText(text4a)
			self.my.valu4a:setText(val4a)
			self.my.line4b:setText(text4b)
			self.my.valu4b:setText(val4b)
			-- save values for progress bars:
			self.fieldPercent = m.fieldPercentageDone
			self.deliverPercent = depo/c.deliver
		else
			text4a = g_i18n:formatVolume(MathUtil.round(c.deliver / 100) * 100)
			text4b = g_i18n:formatVolume(MathUtil.round(c.keep / 100) * 100)
			self.my.line4a:setText(g_i18n:getText("SC_deliver"))
			self.my.line4b:setText(g_i18n:getText("SC_keep"))
			self.my.valu4a:setText(text4a)
			self.my.valu4b:setText(text4b)
		end
		self.my.price:setText(g_i18n:formatMoney(price * 1000))
		self.my.line6:setText(g_i18n:getText("SC_profit"))
		self.my.valu6:setText(g_i18n:formatMoney(price * c.keep))
	elseif cat == SC.SPREAD then -- spread contract
		local j = c.bestj
		self.my.filltype:setText(c.ftype[j])
		self.my.line4a:setText("")
		self.my.valu4a:setText("")
		self.my.line4b:setText(g_i18n:getText("SC_usage"))
		self.my.valu4b:setText(g_i18n:formatVolume(c.usage[j], 0))
		self.my.price:setText(g_i18n:formatMoney(c.price[j], 0))
		self.my.line6:setText(g_i18n:getText("SC_cost"))
		self.my.valu6:setText(g_i18n:formatMoney(c.cost[j], 0))
	else -- simple contract
		self.my.filltype:setText("")
		self.my.line4a:setText("")
		self.my.valu4a:setText("")
		self.my.line4b:setText("")
		self.my.valu4b:setText("")
		self.my.price:setText("")
		self.my.line6:setText("")
		self.my.valu6:setText("")
	end
end
function updateButtonsPanel(menu, page)
	-- called by TabbedMenu.onPageChange(), after page:onFrameOpen()
	local inGameMenu = BetterContracts.gameMenu
	if page.id ~= "pageContracts" or inGameMenu.newButton == nil 
		or not g_currentMission.missionDynamicInfo.isMultiplayer then
		return end 
	-- disable buttons accorcing to setting refreshMP
	local refresh = BetterContracts.config.refreshMP
	local enable = g_currentMission.isMasterUser or refresh == SC.PLAYER  
		or refresh == SC.FARMMANAGER and g_currentMission:getHasPlayerPermission("farmManager")  

	inGameMenu.newButton:setDisabled(not enable)
	inGameMenu.clearButton:setDisabled(not enable)
end
function BetterContracts:radioButton(st)
	-- implement radiobutton behaviour: max. one sort button can be active
	self.lastSort = self.sort
	self.sort = st
	local prof = {
		active = {"SeeContactiveCat", "SeeContactiveProf", "SeeContactivepMin"},
		std = {"SeeContsortCat", "SeeContsortProf", "SeeContsortpMin"}
	}
	local bname
	if st == 0 then -- called from buttonCallback() when switching to off
		if self.lastSort > 0 then -- reset the active sort icon
			local a = self.lastSort
			bname = self.buttons[a][1]
			self.my[bname]:applyProfile(prof.std[a])
			FocusManager:unsetFocus(self.my[bname]) -- remove focus if we are sorted
			FocusManager:unsetHighlight(self.my[bname]) -- remove highlight
		end
		return
	end
	local a, b = math.fmod(st + 1, 3), math.fmod(st + 2, 3)
	if a == 0 then
		a = 3
	end
	if b == 0 then
		b = 3
	end
	self.my[self.buttons[st][1]]:applyProfile(prof.active[st]) -- set this Button Active
	self.my[self.buttons[a][1]]:applyProfile(prof.std[a]) -- reset the other 2
	self.my[self.buttons[b][1]]:applyProfile(prof.std[b])
end
function onClickFilterButton(frCon, button)
	local self = BetterContracts
	local index = tonumber(button.id:sub(-1))
	debugPrint("*** Filter button %s: oldState %s", button.id, button.pressed)
	button.pressed = not button.pressed 

	local prof = "myFilterDynamicTextInactive"
	if button.pressed then prof = "myFilterDynamicText" end
	button.elements[1]:applyProfile(prof)

	-- if button "Other" clicked:
	if index == 9 then -- also handle all other mission types:
		for _, other in ipairs(self.otherTypes) do 
			self.filterState[other[2]] = button.pressed
			filterList(other[1], button.pressed)
		end
	else
		local typeId = self.fieldjobs[index][1]
		local typeName = self.fieldjobs[index][2]
		self.filterState[typeName] = button.pressed
		filterList(typeId, button.pressed)
	end		
end
function onClickSortButton(frCon, button)
	local self, n = BetterContracts, 0
	for i, bu in ipairs(self.buttons) do
		if bu[1] == button.id then
			n = i
			break
		end
	end
	self:radioButton(n)
	frCon:updateList()
end
function onHighSortButton(frCon, button)
	-- show help text
	local self = BetterContracts
	--print(button.id.." -onHighlight / onFocusEnter, sort "..tostring(self.sort))
	local tx = ""
	for _, bu in ipairs(self.buttons) do
		if bu[1] == button.id then
			tx = bu[2]
			break
		end
	end
	self.my.helpsort:setText(tx)
end
function onRemoveSortButton(frCon, button)
	-- reset help text
	local self = BetterContracts
	--print(button.id.." -onHighlightRemove / onFocusLeave, sort "..tostring(self.sort))
	if self.sort == 0 then
		self.my.helpsort:setText("")
	else
		self.my.helpsort:setText(self.buttons[self.sort][2])
	end
end
-------------------------------------------- v1.2.7.0 -------------------------------
function showContextBox(contextBox, hotspot, description, imageFilename, uvs, farmId)
	-- to change color of vehicle text, if mission vehicle
	if contextBox == nil then return end 
	local text = contextBox:getDescendantByName("text")
	if description:sub(-1) == ")" then 
		text:applyProfile("missionVehicleText")
	else
		text:applyProfile("ingameMenuMapContextText")		
	end
end
