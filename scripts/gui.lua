---@diagnostic disable: lowercase-global
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
--=======================================================================================================

-------------------- Gui enhance functions ---------------------------------------------------
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

function updateList(frCon)
	-- if a new mission was created, update our tables, so that we can show the details
	-- No:(if deleted or taken by another player, postpone refresh to next 15sec update tick)
	local self = BetterContracts
	if #g_missionManager:getMissionsList(g_currentMission:getFarmId()) ~= self.numCont then
		self:refresh()
	end
end
function populateCell(frCon, list, sect, index, cell)
	local profit = cell:getAttribute("profit")
	local self = BetterContracts
	if not self.isOn then
		profit:setVisible(false)
		return
	end
	local id = frCon.sectionContracts[sect].contracts[index].mission.id
	if self.IdToCont[id] == nil or self.IdToCont[id][2] == nil then
		debugPrint("populateCell(): empty IdToCont for id %s. sect/index: %s/%s",
			id, sect,index)
	end
	local prof = self.IdToCont[id] and self.IdToCont[id][2] and self.IdToCont[id][2].profit or 0
	local cat = self.IdToCont[id] and self.IdToCont[id][1] or 0
	local showProf = false
	if cat==SC.HARVEST or cat==SC.SPREAD or cat==SC.BALING then 
	-- only for harvest, spread, mow contracts
		local reward = cell:getAttribute("reward")
		local rewtext = reward:getText()
		reward:setText(g_i18n:formatMoney(prof, 0, true, true))
		profit:setText(rewtext)
		showProf = true
	end
	profit:setVisible(showProf)
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
	if not self.isOn then
		return
	end
 
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
		print("**Error BetterContracts:updateFarmersBox() - no contract found for mission id " .. tostring(m.id))
		return
	end
	local cat = con[1]
	local c = con[2]
	self.my.npcbox:setVisible(true)

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
			local secLeft =  m.timeLeft / 1000 
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
		local price = m.sellPoint:getEffectiveFillTypePrice(m.fillType)
		self.my.filltype:setText(c.ftype)

		if active then
			self.my.line3:setText(g_i18n:getText("SC_worked"))
			self.my.etime:setText(string.format("%.1f%%", m.fieldPercentageDone * 100))

			local depo = 1000 		-- just as protection
			if m.depositedLiters then depo = m.depositedLiters end

			local delivered, togo = MathUtil.round(depo / 100) * 100,
									MathUtil.round((c.deliver - depo) / 100) * 100
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
