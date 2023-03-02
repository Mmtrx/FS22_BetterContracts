--=======================================================================================================
-- BetterContracts SCRIPT
--
-- Purpose:		Enhance ingame contracts menu.
-- Author:		Royal-Modding / Mmtrx
-- Changelog:
--  v1.0.0.0	19.10.2020	initial by Royal-Modding
--	v1.1.0.0	12.04.2021	release candidate RC-2
--  v1.1.0.3    24.04.2021  (Mmtrx) gui enhancements: addtl details, sort buttons
--  v1.1.0.4    07.07.2021  (Mmtrx) add user-defined missionVehicles.xml, allow missions with no vehicles
--  v1.2.0.0    18.01.2022  (Mmtrx) adapt for FS22
--   		    13.04.2022  moved restartGame() to DebugCommands
--  v1.2.7.5	26.02.2023	display other farms active contracts (MP only)
--=======================================================================================================

-------------------- v1.2.7.5 functions for mTable --------------------------------------------------
function BetterContracts:bcMissions()
	-- print all active missions (only in debug mode)
	print(string.format("%10s %10s %5s %10s %5s", "Farm","Contract","Field","Fruit","Compl"))
	local data = self:getMData()
	for _,row in ipairs(data) do
		print(string.format("%10s %10s %5s %10s %5s", 
			row.c1, row.c2, row.c3, row.c4, row.c5))
	end
end
function BetterContracts:getMData(notMy)
	-- return data rows for other farms mission table
	-- {c1="MyFarm",c2="Düngen",c3=14,c4="Gerste", c5="22%"}
	local fmissions, data = {}, {}
	local myId = g_currentMission.player.farmId or 0
	for _, farm in ipairs(g_farmManager:getFarms()) do
		if not (notMy and farm.farmId == myId) then
			fmissions = table.ifilter(g_missionManager:getMissionsList(farm.farmId), function(m)
				return m.status == AbstractMission.STATUS_RUNNING or 
					m.status == AbstractMission.STATUS_FINISHED
				end)
			for _, m in ipairs(fmissions) do
				local jobName = self.jobText[m.type.name]
				if jobName==nil then jobName = g_i18n:getText("bc_other") end
				local progress = string.format("%d%%", MathUtil.round(m:getCompletion()*100))
				local fruitName = "n/a" 
				local fieldId = "n/a"
				if m.field then fieldId = m.field.fieldId end
				if table.hasElement({"harvest","mow_bale","supplyTransport"}, m.type.name) then 
					fruitName = self.ft[m.fillType].title
				elseif m.field and m.field.fruitType then 
					local ft = g_fruitTypeManager:getFillTypeIndexByFruitTypeIndex(m.field.fruitType)
					fruitName = self.ft[ft].title
				end 
				local row = {
					c1 = farm.name,
					c2 = jobName,
					c3 = fieldId,
					c4 = fruitName,
					c5 = progress,
				}
				table.insert(data, row)
			end
		end
	end
	return data
end
function testData(self)
	return {
		{c1="MyFarm",c2="Düngen",c4="Gerste",	 c3=14,	c5=22},
		{c1="MyFarm",c2="Ernten",c4="Weizen",	 c3=18,	c5=11},
		{c1="Hof-2", c2="Düngen",c4="Bohnen",	 c3=5, 	c5=100},
		{c1="Hof 3", c2="Düngen",c4="Kartoffeln",c3=37,	c5=80},
		{c1="Hof 3", c2="Kalken",c4="n/a",		 c3=114,c5=0},
		{c1="Hof-2", c2="Düngen",c4="Bohnen",	 c3=5, 	c5=100},
		{c1="Hof 3", c2="Düngen",c4="Kartoffeln",c3=37,	c5=80},
		{c1="Hof 3", c2="Kalken",c4="n/a",		 c3=114,c5=0},
	}
end
function updateMTable(self)
	-- update missions table
	local bt = self.my.mTable
	bt:clearData()
	local mData = self:getMData(true)
	for i=1, #mData do
		self:buildRow(bt, bt.columnNames, mData[i])
	end
	bt:updateView(true)
end
function BetterContracts:buildRow(bt, cols, values)
	-- adds a row to table bt, inits col cells to values 
	-- bt.columnnames = {"c1","c2","c3","c4","c5"}
	-- local id = string.combine(values.c1:split(" "),"") -- id only optional for new row
	local row = TableElement.DataRow.new(nil, cols )
	bt:addRow(row) 		-- this makes bt.data[bt.numActiveRows] = row
	local ixRow = bt.numActiveRows
	for c, value in pairs(values) do 
		bt:setCellText(ixRow, cols[c], tostring(value))
	end
end
------------------------------------------------------------------------------------------
function BetterContracts:consoleCommandPrint()
	-- print table of current missions
	local sep = string.rep("-", 45)
	local self = BetterContracts
	-- initialize contracts tables :
	self:refresh()
	local m
	-- harvest missions:
	print(sep .. "Harvest Mis" .. sep)
	print(string.format("%2s %10s %10s %10s %10s %10s %10s %10s %10s %10s %10s %10s", "Nr", "Type", "Field", "ha", "reward", "duration", "Filltype", "deliver", "keep", "price", "Total", "perMinute"))
	for i, c in ipairs(self.harvest) do
		m = c.miss
		print(
			string.format(
				"%2s %10s %10s %10.2f %10s %10s %10s %10d %10d %10d %10s %10s",
				i,
				m.type.name,
				m.field.fieldId,
				m.field.fieldArea,
				g_i18n:formatNumber(m:getReward(), 0),
				MathUtil.round(c.worktime / 60),
				c.ftype,
				c.deliver,
				c.keep,
				c.price,
				g_i18n:formatNumber(c.profit),
				g_i18n:formatNumber(c.permin)
			)
		)
	end
	-- mow/bale missions:
	if #self.mow_bale > 0 then
		print(sep .. "Baling Miss" .. sep)
		for i, c in ipairs(self.mow_bale) do
		m = c.miss
		print(
			string.format(
				"%2s %10s %10s %10.2f %10s %10s %10s %10d %10d %10d %10s %10s",
				i,
				m.type.name,
				m.field.fieldId,
				m.field.fieldArea,
				g_i18n:formatNumber(m:getReward(), 0),
				MathUtil.round(c.worktime / 60),
				c.ftype,
				c.deliver,
				c.keep,
				c.price,
				g_i18n:formatNumber(c.profit),
				g_i18n:formatNumber(c.permin)
			)
		)
		end
	end
	-- spread missions:
	print(sep .. "Spread Miss" .. sep)
	print(string.format("%2s %10s %10s %10s %10s %10s %10s %10s %10s %10s %10s %10s", "Nr", "Type", "Field", "ha", "reward", "duration", "Filltype", "usage", "price", "cost", "Total", "perMinute"))
	local pmin
	for i, c in ipairs(self.spread) do
		m = c.miss
		pmin = {"", "", ""}
		pmin[c.bestj] = g_i18n:formatNumber(c.profit / c.worktime[c.bestj] * 60)
		print(
			string.format(
				"\n%2s %10s %10s %10.2f %10s %10s %10.10s %10d %10s %10d %10s %10s",
				i,
				m.type.name,
				m.field.fieldId,
				m.field.fieldArea,
				g_i18n:formatNumber(c.reward),
				MathUtil.round(c.worktime[1] / 60,1),
				c.ftype[1],
				c.usage[1],
				c.price[1],
				c.cost[1],
				g_i18n:formatNumber(c.reward + c.cost[1]),
				pmin[1]
			)
		)
		if c.maxj > 1 then
			print(string.format("%57s %10.10s %10d %10s %10d %10s %10s", MathUtil.round(c.worktime[2] / 60,1), c.ftype[2], c.usage[2], c.price[2], c.cost[2], g_i18n:formatNumber(c.reward + c.cost[2]), pmin[2]))
		end
		if c.maxj == 3 then
			print(string.format("%57s %10.10s %10d %10s %10d %10s %10s", MathUtil.round(c.worktime[3] / 60,1), c.ftype[3], c.usage[3], c.price[3], c.cost[3], g_i18n:formatNumber(c.reward + c.cost[3]), pmin[3]))
		end
	end
	-- simple missions:
	if #self.simple > 0 then
		print(sep .. "Simple Miss" .. sep)
		for i, c in ipairs(self.simple) do
			local rew = c.miss:getReward()
			print(string.format("%2s %10s %10s %10.2f %10s %10s %54s %10s", i, c.miss.type.name, c.miss.field.fieldId, 
				c.miss.field.fieldArea, g_i18n:formatNumber(rew), MathUtil.round(c.worktime/60), 
				 g_i18n:formatNumber(rew, 0), g_i18n:formatNumber(rew / c.worktime * 60)))
		end
	end
	-- transport missions:
	if #self.transp > 0 then
		print(sep .. "Transp Miss" .. sep)
		for i, c in ipairs(self.transp) do
			local rew = c.miss:getReward()
			local ftype,deliv,price = "", "", 0
			if self.supplyTransport and c.miss:isa(SupplyTransportMission) then
				ftype,deliv,price = c.ftype, c.deliver, c.price
			end	
			print(string.format("%2s %10.10s %32s %10s %10.10s %10s %21d %10s", i, c.miss.type.name, g_i18n:formatNumber(rew), 
				"--", ftype, deliv, MathUtil.round(price), g_i18n:formatNumber(rew)))
		end
	end
end
--[[
(-111, 212) (-111, 277) (-235, 213)			width: 64.51, height: 123.44, area: 7962.54
(-262, 249) (-262, 212) (-233, 250)			width: 37.31, height: 28.69, area: 1069.87
(-234, 277) (-262, 249) (-216, 258)			width: 39.14, height: 26.43, area: 1033.83
(-258, 260) (-262, 249) (-251, 257)			width: 11.74, height: 6.90, area: 80.82
(-253, 264) (-258, 260) (-249, 261)			width:  6.02, height: 5.52, area: 32.33
(-234, 277) (-253, 264) (-231, 272)			width: 22.74, height: 6.03, area: 136.98
---------------------------------------------Harvest Mis---------------------------------------------
Nr       Type      Field         ha     reward   duration   Filltype    deliver       keep      price      Total  perMinute
 1    harvest         81       0.29        475          4      Hafer       1841        663        806      1.010        256
---------------------------------------------Spread Miss---------------------------------------------
Nr       Type      Field         ha     reward   duration   Filltype      usage      price       cost      Total  perMinute

 1  fertilize         43       0.89      1.545        1.7 MineraldÃ¼        339       1920       -651        893        537
                                                      3.7 FlÃ¼ssigdÃ        466       1600       -746        799           
                                                      1.4 FlÃ¼ssigdÃ        458       1600       -733        812           

 2      spray         52       0.88      1.303        3.3   Herbizid        417       1200       -500        803        242
                                                      3.3   Herbizid        417       1200       -500        803           

 3  fertilize         63       0.67      1.159        1.3 MineraldÃ¼        249       1920       -479        680           
                                                      2.2 FlÃ¼ssigdÃ        267       1600       -427        731           
                                                      2.7 FlÃ¼ssigdÃ        260       1600       -417        742        279

 4      spray         66       0.23        336        1.1   Herbizid        125       1200       -150        185        175
                                                      1.1   Herbizid        125       1200       -150        185           

 5  fertilize         49       0.42        719        1.3 MineraldÃ¼        247       1920       -475        244        194
                                                      2.7 FlÃ¼ssigdÃ        329       1600       -526        193           
                                                      1.1 FlÃ¼ssigdÃ        334       1600       -534        185           

 6  fertilize         22       1.03      1.788        1.5 MineraldÃ¼        300       1920       -576      1.212        813
                                                      3.2 FlÃ¼ssigdÃ        406       1600       -650      1.138           
                                                      3.6 FlÃ¼ssigdÃ        363       1600       -581      1.207           

 7      spray         21       0.23        332          1   Herbizid        121       1200       -145        187           
                                                      0.6   Herbizid         98       1200       -117        214        361

 8  fertilize         35       0.92      1.600        1.5 MineraldÃ¼        311       1920       -597      1.002           
                                                      2.7 FlÃ¼ssigdÃ        337       1600       -539      1.060        398
                                                      1.3 FlÃ¼ssigdÃ        420       1600       -672        927           

 9      spray         73       1.84      2.714        5.4   Herbizid        706       1200       -847      1.866        347
                                                      4.1   Herbizid        813       1200       -976      1.737           
---------------------------------------------Simple Miss---------------------------------------------
 1       plow         50       1.52      3.504         23                                                  3.504        151
---------------------------------------------Transp Miss---------------------------------------------
 1 supplyTran                           27.042         --      Hafer      24000                   805     27.042
 2 supplyTran                           56.333         --     Oliven      37000                  1088     56.333
 3 supplyTran                          560.391         --       Eier     214000                  1870    560.391
 4 supplyTran                        2.459.228         --   Kleidung     135000                 13012  2.459.228
]]
