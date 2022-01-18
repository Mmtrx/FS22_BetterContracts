---@diagnostic disable: lowercase-global
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
--=======================================================================================================

-------------------- development helper functions ---------------------------------------------------
function BetterContracts:restartGame(savegameId)
	if not g_server then return end
	local gameId = savegameId or "1"
	if tonumber(gameId) and tonumber(gameId) < 11 then
		restartApplication(true, " -cheats -autoStartSavegameId "..gameId)
	end
end
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
	if #self.baling > 0 then
		print(sep .. "Baling Miss" .. sep)
		for i, c in ipairs(self.baling) do
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
			print(string.format("%2s %10s %10s %10.2f %10d %10s %54s %10s", i, c.miss.type.name, c.miss.field.fieldId, 
				c.miss.field.fieldArea, rew, MathUtil.round(c.worktime/60), 
				 g_i18n:formatNumber(rew, 0), g_i18n:formatNumber(rew / c.worktime * 60)))
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
 1    harvest         67       0.23        376          3     Weizen       2088        752        506        756        224
 2    harvest         73       1.84      3.036         15       Raps      12355       4454       1020      7.582        495
 3    harvest         34       1.10      1.809         20     Weizen       8251       2975        506      3.315        163
 4    harvest         54       1.84      3.043         17      Hafer      10046       3622        818      6.007        356
 5    harvest         65       0.23        376          3      Hafer       1337        482        818        770        228
 6    harvest         62       0.66      1.086          9       Raps       4844       1746       1020      2.869        316
---------------------------------------------Baling Miss---------------------------------------------
 1   mow_bale         14       0.22      6.288          8     Silage       5922       1578        288      6.744        881
 2   mow_bale         15       0.25      6.408          8     Silage       5922       1578        288      6.864        896
 3   mow_bale         16       0.25      6.408          8     Silage       5922       1578        288      6.864        896
 4   mow_bale         71       6.04     26.043         64        Heu     266035      70930         90     32.468        511
---------------------------------------------Spread Miss---------------------------------------------
Nr       Type      Field         ha     reward   duration   Filltype      usage      price       cost      Total  perMinute
 1      spray         53       1.76      2.588    00:05 h   Herbizid        655       1200       -786      1.802        359
                                                  00:03 h liquidFert        760       1200       -912      1.281
 2  fertilize          3       0.30        523    00:01 h FlÃ¼ssigdÃ        131       1600       -211        311        225
                                                  00:01 h liquidFert        150       1600       -240        203
                                                  00:01 h    vehicle        131       1600       -211        232
 3      spray         74       1.48      2.187    00:04 h   Herbizid        516       1200       -619      1.567        389
                                                  00:03 h liquidFert        554       1200       -665      1.188
 4      spray         60       1.06      1.561    00:03 h   Herbizid        446       1200       -535      1.025        298
                                                  00:03 h liquidFert        446       1200       -535        787
 5      spray          8       1.84      2.715    00:05 h   Herbizid        643       1200       -771      1.943        387
                                                  00:04 h liquidFert        729       1200       -875      1.425
 6      spray         72       2.02      2.983    00:05 h FlÃ¼ssigdÃ       1022       1200      -1226      1.756        311
                                                  00:05 h liquidFert       1022       1200      -1226      1.301
 7  fertilize         61       0.66      1.140    00:01 h MineraldÃ¼        197       1920       -378        761        547
                                                  00:02 h liquidFert        266       1600       -426        541
                                                  00:01 h    vehicle        335       1600       -536        431
 8  fertilize         11       2.44      4.220    00:05 h FlÃ¼ssigdÃ        830       1600      -1328      2.892        501
                                                  00:07 h liquidFert        934       1600      -1494      2.087
                                                  00:05 h    vehicle        830       1600      -1328      2.253
 9  fertilize         77       1.29      2.239    00:02 h MineraldÃ¼        393       1920       -754      1.485        569
                                                  00:04 h liquidFert        530       1600       -849      1.051
                                                  00:04 h    vehicle        479       1600       -767      1.133
10  fertilize         38       4.40      7.612    00:08 h MineraldÃ¼       1421       1920      -2730      4.882        543
                                                  00:14 h liquidFert       1919       1600      -3071      3.389
                                                  00:36 h    vehicle       1774       1600      -2838      3.622
11      spray         80       0.25        374    00:01 h   Herbizid        121       1200       -146        227        219
                                                  00:01 h liquidFert        167       1200       -200        116
12      spray         41       1.96      2.889    00:05 h   Herbizid        745       1200       -894      1.995        347
                                                  00:04 h liquidFert        839       1200      -1006      1.442
13      spray         63       0.67        987    00:02 h   Herbizid        267       1200       -320        666        308
                                                  00:02 h liquidFert        267       1200       -320        516
14  fertilize         55       0.98      1.702    00:03 h MineraldÃ¼        464       1920       -892        810        254
                                                  00:04 h liquidFert        627       1600      -1003        441
                                                  00:02 h    vehicle        783       1600      -1254        190
15      spray         66       0.23        336    00:01 h   Herbizid        125       1200       -150        185        175
                                                  00:01 h liquidFert        125       1200       -150        134
16      spray         82       0.24        359    00:00 h FlÃ¼ssigdÃ        104       1200       -124        234        376
                                                  00:00 h liquidFert        104       1200       -124        180
17  fertilize         50       1.52      2.627    00:02 h MineraldÃ¼        429       1920       -824      1.803        639
                                                  00:04 h liquidFert        579       1600       -927      1.302
                                                  00:01 h    vehicle        555       1600       -889      1.340
18  fertilize          5       0.29        506    00:00 h MineraldÃ¼        100       1920       -193        312        416
                                                  00:01 h liquidFert        136       1600       -218        211
                                                  00:00 h    vehicle        143       1600       -229        200
19      spray         75       1.28      1.886    00:03 h   Herbizid        397       1200       -477      1.409        456
                                                  00:03 h liquidFert        397       1200       -477      1.121
20      spray         47       0.71      1.050    00:02 h   Herbizid        260       1200       -313        737        348
                                                  00:02 h liquidFert        358       1200       -430        459
21      spray         69       4.45      6.565    00:16 h   Herbizid       2215       1200      -2658      3.906        236
                                                  00:12 h liquidFert       2330       1200      -2797      2.766
22  fertilize         58       3.22      5.580    00:05 h MineraldÃ¼        902       1920      -1732      3.847        672
                                                  00:09 h liquidFert       1218       1600      -1949      2.786
                                                  00:04 h    vehicle       1477       1600      -2364      2.371
23  fertilize          6       0.49        850    00:03 h FlÃ¼ssigdÃ        163       1600       -261        588        178
                                                  00:01 h liquidFert        211       1600       -337        384
                                                  00:03 h    vehicle        163       1600       -261        460
24  fertilize          2       0.36        625    00:01 h MineraldÃ¼        137       1920       -264        361        344
                                                  00:01 h liquidFert        186       1600       -297        233
                                                  00:00 h    vehicle        240       1600       -384        146
25  fertilize         68       8.02     13.884    00:12 h MineraldÃ¼       1991       1920      -3822     10.061        819
                                                  00:19 h liquidFert       2688       1600      -4300      7.483
                                                  00:07 h    vehicle       2720       1600      -4353      7.430
26      spray         79       0.25        374    00:01 h   Herbizid        121       1200       -146        227        219
                                                  00:01 h liquidFert        121       1200       -146        170
27      spray         42       1.92      2.832    00:03 h FlÃ¼ssigdÃ        714       1200       -857      1.974        540
                                                  00:03 h liquidFert        714       1200       -857      1.542
28      spray         36       1.15      1.699    00:03 h   Herbizid        431       1200       -518      1.181        345
                                                  00:03 h liquidFert        431       1200       -518        921
29  fertilize         27       0.75      1.293    00:02 h MineraldÃ¼        325       1920       -624        669        291
                                                  00:03 h liquidFert        439       1600       -702        395
                                                  00:01 h    vehicle        510       1600       -816        281
30  fertilize         33       3.15      5.452    00:19 h FlÃ¼ssigdÃ        934       1600      -1494      3.957        206
                                                  00:08 h liquidFert       1156       1600      -1849      2.778
                                                  00:19 h    vehicle        934       1600      -1494      3.133
31  fertilize         39       4.42      7.657    00:28 h FlÃ¼ssigdÃ       1400       1600      -2241      5.416        192
                                                  00:12 h liquidFert       1622       1600      -2595      3.903
                                                  00:28 h    vehicle       1400       1600      -2241      4.257
---------------------------------------------Simple Miss---------------------------------------------
 1       plow          1       0.54       1244    00:33 h                                                  1.244         37
 2       plow         43       0.89       2062    00:26 h                                                  2.062         77
 3       plow         56       2.78       6411    00:45 h                                                  6.411        142
 4  cultivate          7       0.93       1525    00:14 h                                                  1.525        106
 5  cultivate         12       1.00       1653    00:13 h                                                  1.653        121
 6       plow         78       0.49       1130    00:11 h                                                  1.130         99
 7       plow         51       1.24       2863    00:27 h                                                  2.863        104
 8       plow         10       5.70      13172    01:10 h                                                 13.172        185
 9       plow         23       0.68       1570    00:16 h                                                  1.570         95
10  cultivate         21       0.23        372    00:02 h                                                    372        138
11  cultivate         29       1.03       1696    00:20 h                                                  1.696         82
12       plow         76       0.87       2011    00:39 h                                                  2.011         50
13  cultivate         32       6.61      10904    00:29 h                                                 10.904        368
14  cultivate         40       1.21       1997    00:17 h                                                  1.997        113
]]
