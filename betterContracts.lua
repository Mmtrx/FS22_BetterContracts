--=======================================================================================================
-- BetterContracts SCRIPT
--
-- Purpose:     Enhance ingame contracts menu.
-- Author:      Royal-Modding / Mmtrx
-- Changelog:
--  v1.0.0.0    19.10.2020  initial by Royal-Modding
--  v1.1.0.0    12.04.2021  release candidate RC-2
--  v1.1.0.3    24.04.2021  (Mmtrx) gui enhancements: addtl details, sort buttons
--  v1.1.0.4    07.07.2021  (Mmtrx) add user-defined missionVehicles.xml, allow missions with no vehicles
--  v1.2.0.0    18.01.2022  (Mmtrx) adapt for FS22
--  v1.2.0.0.rc 22.01.2022  (Mmtrx) release candidate. Gui optics in blue
--  v1.2.0.1.rc 30.01.2022  (Mmtrx) enabled MP
--=======================================================================================================
InitRoyalUtility(Utils.getFilename("lib/utility/", g_currentModDirectory))
InitRoyalMod(Utils.getFilename("lib/rmod/", g_currentModDirectory))
SC = {
    FERTILIZER = 1, -- prices index
    LIQUIDFERT = 2,
    HERBICIDE = 3,
    SEEDS = 4,
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
    self.modSettings= string.sub(g_modsDirectory,1,-3) .. "Settings/"
    -- check for debug switch in modSettings/
    if not self.debug and      
        fileExists(self.modSettings.."BetterContracts.debug") then
        self.debug = true 
    end
    debugPrint("[%s] initialize(): %s", self.name,self.initialized)
    if self.initialized ~= nil then return end -- run only once
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
        1 mow/ bale
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
    self.typeToCat = {4, 3, 3, 2, 1, 3, 2, 2, 5, 5} -- mission.type to self category: harvest, spread, simple, mow, transport
    self.harvest = {} -- harvest missions       1
    self.spread = {} -- sow, spray, fertilize   2
    self.simple = {} -- plow, cultivate, weed   3
    self.baling = {} -- mow/ bale               4
    self.transp = {} -- transport, supplyTrans  5
    self.IdToCont = {} -- to find a contract from its mission id
    self.fieldToMission = {} -- to find a contract from its field number
    self.catHarvest = "BEETHARVESTING BEETVEHICLES CORNHEADERS COTTONVEHICLES CUTTERS POTATOHARVESTING POTATOVEHICLES SUGARCANEHARVESTING SUGARCANEVEHICLES"
    self.catSpread = "fertilizerspreaders seeders planters sprayers sprayervehicles slurrytanks manurespreaders"
    self.catSimple = "CULTIVATORS DISCHARROWS PLOWS POWERHARROWS SUBSOILERS WEEDERS"
    self.isOn = false
    self.numCont = 0 -- # of contracts in our tables
    self.my = {} -- will hold my gui element adresses
    self.sort = 0 -- sorted status: 1 cat, 2 prof, 3 permin
    self.lastSort = 0 -- last sorted status
    self.buttons = {
        {"sortcat", g_i18n:getText("SC_sortCat")}, -- {button id, help text}
        {"sortprof", g_i18n:getText("SC_sortProf")},
        {"sortpmin", g_i18n:getText("SC_sortpMin")}
    }
    if g_modIsLoaded["FS22_RefreshContracts"] then
        self.needsRefreshContractsConflictsPrevention = true
    end
    if g_modIsLoaded["FS22_SupplyTransportContracts"] then
        self.supplyTransport = true
    end
    -- to load own mission vehicles:
    Utility.overwrittenFunction(MissionManager, "loadMissionVehicles", BetterContracts.loadMissionVehicles)
    -- get addtnl mission vales from server:
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
    InGameMenuContractsFrame.updateList = Utils.prependedFunction(InGameMenuContractsFrame.updateList, updateList)
    InGameMenuContractsFrame.sortList = Utils.overwrittenFunction(InGameMenuContractsFrame.sortList, sortList)
    -- to allow multiple missions:
    MissionManager.hasFarmReachedMissionLimit =
        Utils.overwrittenFunction(nil,
            function() return false end
            )
    if self.debug then
        g_showDevelopmentWarnings = true
        addConsoleCommand("printBetterContracts", "Print detail stats for all available missions.", "consoleCommandPrint", self)
        addConsoleCommand("restartGame", 'Restart my savegame [savegameId]', 'restartGame', self)
        addConsoleCommand("gsFieldGenerateMission", "Force generating a new mission for given field", "consoleGenerateFieldMission", g_missionManager)
        addConsoleCommand("gsMissionLoadAllVehicles", "Loading and unloading all field mission vehicles", "consoleLoadAllFieldMissionVehicles", g_missionManager)
        addConsoleCommand("gsMissionHarvestField", "Harvest a field and print the liters", "consoleHarvestField", g_missionManager)
        addConsoleCommand("gsMissionTestHarvests", "Run an expansive tests for harvest missions", "consoleHarvestTests", g_missionManager)
        addConsoleCommand("gsFieldSetFruit", "Sets a given fruit to field", "consoleCommandSetFieldFruit", g_fieldManager)
        addConsoleCommand("gsFieldSetFruitAll", "Sets a given fruit to all fields", "consoleCommandSetFieldFruitAll", g_fieldManager)
        addConsoleCommand("gsFieldSetGround", "Sets a given fruit to field", "consoleCommandSetFieldGround", g_fieldManager)
        addConsoleCommand("gsFieldSetGroundAll", "Sets a given fruit to allfield", "consoleCommandSetFieldGroundAll", g_fieldManager)
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
    MissionManager.MAX_MISSIONS = math.min(120, math.ceil(adjustedFieldsAmount * 0.60)) -- max missions = 60% of fields amount (minimum 45 fields) max 120
    MissionManager.MAX_TRANSPORT_MISSIONS = math.max(math.ceil(MissionManager.MAX_MISSIONS / 15), 2) -- max transport missions is 1/15 of maximum missions but not less then 2
    MissionManager.MAX_MISSIONS = MissionManager.MAX_MISSIONS + MissionManager.MAX_TRANSPORT_MISSIONS -- add max transport missions to max missions
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
    for i = #self.typeToCat, g_missionManager.nextMissionTypeId -1 do
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
    profit:setPosition(-110 / 1920, -12/1080)
    --profit:setTextColor(1, 1, 1, 1)
    profit.textBold = false
    profit:setVisible(false)
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
    -- set static texts
    self.my.widhei:setText(g_i18n:getText("SC_widhei"))
    self.my.ppmin:setText(g_i18n:getText("SC_profpmin"))

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

function BetterContracts:loadGUI(canLoad, guiPath)
    if canLoad then
        local fname
        -- load my gui profiles
        fname = guiPath .. "guiProfiles.xml"
        if fileExists(fname) then
            g_gui:loadProfiles(fname)
        else
            canLoad = false
        end
        -- load "SCGui.xml"
        fname = guiPath .. "SCGui.xml"
        if canLoad and fileExists(fname) then
            local xmlFile = loadXMLFile("Temp", fname)
            local fbox = self.frCon.farmerBox
            g_gui:loadGuiRec(xmlFile, "GUI", fbox, self.frCon)
            local layout = fbox:getDescendantById("layout")
            layout:invalidateLayout(true) -- adjust sort buttons
            fbox:applyScreenAlignment()
            fbox:updateAbsolutePosition()
            fbox:onGuiSetupFinished() -- connect the tooltip elements
            delete(xmlFile)
        else
            canLoad = false
            Logging.error("[GuiLoader %s]  Required file '%s' could not be found!", self.name, fname)
        end
    end
    return canLoad
end
function BetterContracts:refresh()
    -- refresh our contract tables. Called by onFrameOpen/updateList, and every 15 sec by self:onUpdate
    self.harvest, self.spread, self.simple, self.baling, self.transp = {}, {}, {}, {}, {}
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
    if cat < 5 then
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
        elseif not vfound or cat~=2 then
            Logging.warning("[%s]:addMission(): problem with vehicles for contract '%s field %s'.", 
                self.name, m.type.name, m.field.fieldId)
            local cat1 = cat == 1 and 1 or 0 
            -- use default width and speed values :
            -- cat/index: 1/6, 3/7, 4/8 = harvest, plow, mow
            _,dura = self:estWorktime(wid, hei, self.WORKWIDTH[4+cat+cat1], self.SPEEDLIMS[4+cat+cat1])
        end
        if (cat==1 or cat==4) and m.expectedLiters == nil then
            -- need to test mow-bale missions 
            Logging.warning("[%s]:addMission(): contract '%s %s on field %s' has no expectedLiters.", 
                self.name, m.type.name, self.ft[m.fillType].title, m.field.fieldId)
            m.expectedLiters = 0 
            return {0, cont}
        end 
    end
    if cat == 1 then
        local keep = math.floor(m.expectedLiters * 0.265)
        local price = self:getFilltypePrice(m)
        local profit = rew + keep * price
        cont = {
            miss = m,
            width = wid,
            height = hei,
            worktime = dura,
            ftype = self.ft[m.fillType].title,
            deliver = math.floor(m.expectedLiters * 0.735), --must be delivered
            keep = keep, --can be sold on your own
            price = price * 1000,
            profit = profit,
            permin = profit / dura * 60,
            reward = rew
        }
        table.insert(self.harvest, cont)
    elseif cat == 2 then
        cont = self:spreadMission(m, wid, hei, wwidth, speed)
        table.insert(self.spread, cont)
    elseif cat == 3 then
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
    elseif cat == 4 then
        local keep = math.floor(m.expectedLiters * 0.2105)
        local price = self:getFilltypePrice(m)
        local profit = rew + keep * price
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
        table.insert(self.baling, cont)
    else
        cont = {
            miss = m,
            ftype = self.ft[m.fillType].title or "",    -- set by supplyTransp mission
            deliver = m.contractLiters or "",           --          ""              --
            price = m.pricePerLitre * 1000 or "",       --          ""              --
            profit = rew,
            permin = 0,
            reward = rew
        }
        table.insert(self.transp, cont)
    end
    return {cat, cont}
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
