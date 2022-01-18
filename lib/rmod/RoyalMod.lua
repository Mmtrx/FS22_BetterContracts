--- Royal Mod

---@author Royal Modding
---@version 1.5.0.0
---@date 03/12/2020
-- Changelog:
--  v1.0.0.0    03.12.2020  initial by Royal-Modding
--  v1.1.0.0    30.12.2021: (Mmtrx) commented out vehicleTypeManagerFinalizeTypes, different in FS22

---@class RoyalMod
---@field onWriteStream fun(self: RoyalMod, streamId: integer)
---@field onReadStream fun(self: RoyalMod, streamId: integer)
---@field onUpdateTick fun(self: RoyalMod, dt: number)
---@field onWriteUpdateStream fun(self: RoyalMod, streamId: integer, connection: Connection, dirtyMask: integer)
---@field onReadUpdateStream fun(self: RoyalMod, streamId: integer, timestamp: number, connection: Connection)
---@field onLoadMap fun(self: RoyalMod, mapNode: integer, mapFile: string)
---@field onDeleteMap fun(self: RoyalMod)
---@field onDraw fun(self: RoyalMod)
---@field onUpdate fun(self: RoyalMod, dt: number)
---@field onMouseEvent fun(self: RoyalMod, posX: number, posY: number, isDown: boolean, isUp: boolean, button: integer)
---@field onKeyEvent fun(self: RoyalMod, unicode: integer, sym: integer, modifier: integer, isDown: boolean)
---@field initialize fun(self: RoyalMod)
---@field onValidateVehicleTypes fun(self: RoyalMod, vtm: VehicleTypeManager, addSpecialization: fun(specName: string), addSpecializationBySpecialization: fun(specName: string, requiredSpecName: string), addSpecializationByVehicleType: fun(specName: string, requiredVehicleTypeName: string), addSpecializationByFunction: fun(specName: string, func: function))
---@field onMissionInitialize fun(self: RoyalMod, baseDirectory: string, missionCollaborators: MissionCollaborators)
---@field onSetMissionInfo fun(self: RoyalMod, missionInfo: MissionInfo, missionDynamicInfo: table)
---@field onLoad fun(self: RoyalMod)
---@field onPreLoadMap fun(self: RoyalMod, mapFile: string)
---@field onCreateStartPoint fun(self: RoyalMod, startPointNode: integer)
---@field onPostLoadMap fun(self: RoyalMod, mapNode: integer, mapFile: string)
---@field onLoadSavegame fun(self: RoyalMod, savegameDirectory: string, savegameIndex: integer)
---@field onPreLoadVehicles fun(self: RoyalMod, xmlFile: integer, resetVehicles: boolean)
---@field onPreLoadItems fun(self: RoyalMod, xmlFile: integer)
---@field onPreLoadOnCreateLoadedObjects fun(self: RoyalMod, xmlFile: integer)
---@field onLoadFinished fun(self: RoyalMod)
---@field onStartMission fun(self: RoyalMod)
---@field onMissionStarted fun(self: RoyalMod)
---@field onPreDeleteMap fun(self: RoyalMod)
---@field onPreSaveSavegame fun(self: RoyalMod, savegameDirectory: string, savegameIndex: integer)
---@field onPostSaveSavegame fun(self: RoyalMod, savegameDirectory: string, savegameIndex: integer)
---@field onLoadHelpLine fun(self: RoyalMod): string
--@field directory string mod directory
--@field userProfileDirectory string user profile directory
--@field name string mod name
--@field mod table g_modManager mod object
--@field version string mod version
--@field author string mod author
--@field modEnv table mod scripting environment
--@field gameEnv table game scripting environment
--@field super table mod super class
--@field debug boolean mod debug state
RoyalMod = {}

---@param debug boolean defines if debug is enabled
---@param mpSync boolean defines if mp sync is enabled
---@return RoyalMod
function RoyalMod.new(debug, mpSync)
    ---@type RoyalMod
    local mod = {}
    mod.directory = g_currentModDirectory
    mod.userProfileDirectory = getUserProfileAppPath()
    mod.name = g_currentModName
    mod.modManagerMod = g_modManager:getModByName(mod.name)
    mod.version = mod.modManagerMod.version
    mod.author = mod.modManagerMod.author
    mod.modEnv = getfenv()
    mod.gameEnv = getfenv(0) -- is redirected to modEnv in FS22
    mod.super = {}
    mod.debug = debug

    if mod.debug then
        g_showDevelopmentWarnings = true
        g_addTestCommands = true
    --mod.gameEnv["g_isDevelopmentConsoleScriptModTesting"] = true
    end

    mod.super.oldFunctions = {}

    ---@param error string
    mod.super.errorHandle = function(error)
        Logging.error("RoyalMod caught error from %s (%s)", mod.name, mod.version)
        Logging.error(error)
    end

    mod.super.getSavegameDirectory = function()
        if g_currentMission ~= nil and g_currentMission.missionInfo ~= nil then
            if g_currentMission.missionInfo.savegameDirectory ~= nil then
                return string.format("%s/", g_currentMission.missionInfo.savegameDirectory)
            end

            if g_currentMission.missionInfo.savegameIndex ~= nil then
                return string.format("%ssavegame%d/", mod.userProfileDirectory, g_currentMission.missionInfo.savegameIndex)
            end
        end
        return mod.userProfileDirectory
    end

    if mpSync then
        mod.super.sync = Object:new(g_server ~= nil, g_client ~= nil, Class(nil, Object))

        ---@param self Object
        ---@param streamId integer
        mod.super.sync.writeStream = function(self, streamId)
            self:superClass().writeStream(self, streamId)
            if mod.onWriteStream ~= nil then
                local time = netGetTime()
                local offset = streamGetWriteOffset(streamId)
                xpcall(mod.onWriteStream, mod.super.errorHandle, mod, streamId)
                offset = streamGetWriteOffset(streamId) - offset
                Logging.devInfo("[%s] Written %.0f bits (%.0f bytes) in %s ms", mod.name, offset, offset / 8, netGetTime() - time)
            end
        end

        ---@param self Object
        ---@param streamId integer
        mod.super.sync.readStream = function(self, streamId)
            self:superClass().readStream(self, streamId)
            if mod.onReadStream ~= nil then
                local time = netGetTime()
                local offset = streamGetReadOffset(streamId)
                xpcall(mod.onReadStream, mod.super.errorHandle, mod, streamId)
                offset = streamGetReadOffset(streamId) - offset
                Logging.devInfo("[%s] Read %.0f bits (%.0f bytes) in %s ms", mod.name, offset, offset / 8, netGetTime() - time)
            end
        end

        ---@param self Object
        ---@param dt number
        mod.super.sync.updateTick = function(self, dt)
            self:superClass().updateTick(self, dt)
            if mod.onUpdateTick ~= nil then
                xpcall(mod.onUpdateTick, mod.super.errorHandle, mod, dt)
            end
        end

        ---@param self Object
        ---@param streamId integer
        ---@param connection Connection
        ---@param dirtyMask integer
        mod.super.sync.writeUpdateStream = function(self, streamId, connection, dirtyMask)
            self:superClass().writeUpdateStream(self, streamId, connection, dirtyMask)
            if mod.onWriteUpdateStream ~= nil then
                xpcall(mod.onWriteUpdateStream, mod.super.errorHandle, mod, streamId, connection, dirtyMask)
            end
        end

        ---@param self Object
        ---@param streamId integer
        ---@param timestamp number
        ---@param connection Connection
        mod.super.sync.readUpdateStream = function(self, streamId, timestamp, connection)
            self:superClass().readUpdateStream(self, streamId, timestamp, connection)
            if mod.onReadUpdateStream ~= nil then
                xpcall(mod.onReadUpdateStream, mod.super.errorHandle, mod, streamId, timestamp, connection)
            end
        end
    end

    ---@param _ table
    ---@param mapFile string
    mod.super.loadMap = function(_, mapFile)
        if mod.onLoadMap ~= nil then
            xpcall(mod.onLoadMap, mod.super.errorHandle, mod, mod.mapNode, mapFile)
        end
    end

    ---@param _ table
    mod.super.deleteMap = function(_)
        if mod.onDeleteMap ~= nil then
            xpcall(mod.onDeleteMap, mod.super.errorHandle, mod)
        end
    end

    ---@param _ table
    mod.super.draw = function(_)
        if mod.onDraw ~= nil then
            xpcall(mod.onDraw, mod.super.errorHandle, mod)
        end
    end

    ---@param _ table
    ---@param dt number
    mod.super.update = function(_, dt)
        if mod.onUpdate ~= nil then
            xpcall(mod.onUpdate, mod.super.errorHandle, mod, dt)
        end
    end

    ---@param _ table
    ---@param posX number
    ---@param posY number
    ---@param isDown boolean
    ---@param isUp boolean
    ---@param button integer
    mod.super.mouseEvent = function(_, posX, posY, isDown, isUp, button)
        if mod.onMouseEvent ~= nil then
            xpcall(mod.onMouseEvent, mod.super.errorHandle, mod, posX, posY, isDown, isUp, button)
        end
    end

    ---@param _ table
    ---@param unicode integer
    ---@param sym integer
    ---@param modifier integer
    ---@param isDown boolean
    mod.super.keyEvent = function(_, unicode, sym, modifier, isDown)
        if mod.onKeyEvent ~= nil then
            xpcall(mod.onKeyEvent, mod.super.errorHandle, mod, unicode, sym, modifier, isDown)
        end
    end

    --g_vehicleTypeManager = TypeManager.new("vehicle", "vehicleTypes", "dataS/vehicleTypes.xml", g_specializationManager)

    mod.super.oldFunctions.VehicleTypeManagerValidateTypes = TypeManager.validateTypes
    TypeManager.validateTypes = function(self, ...)
        ---@type table<string, string>
        local global = mod.gameEnv["g_i18n"].texts
        ---@type string
        for key, text in pairs(g_i18n.texts) do
            if global[key] == nil then
                global[key] = text
            end
        end
        if mod.initialize ~= nil then
            --- g_currentMission is still nil here
            --- All mods are loaded here
            xpcall(mod.initialize, mod.super.errorHandle, mod)
        end
        mod.super.oldFunctions.VehicleTypeManagerValidateTypes(self, ...)
    end

    --[[
    mod.super.oldFunctions.VehicleTypeManagerfinalizeTypes = g_vehicleTypeManager.finalizeTypes
    g_vehicleTypeManager.finalizeTypes = function(self, ...)
        local specs = {}
        local specsBySpec = {}
        local specsByType = {}
        local specsByFunc = {}

        local specAddAllowed = true

        if mod.onValidateVehicleTypes ~= nil then
            --- Add your specialization to vehicle types here
            xpcall(
                mod.onValidateVehicleTypes,
                mod.super.errorHandle,
                mod,
                self,
                ---@param specName string
                function(specName)
                    if not specAddAllowed then
                        Logging.devError("[%s] addSpecialization is no more allowed", mod.name)
                        return
                    end
                    table.insert(specs, {name = string.format("%s.%s", mod.name, specName), addedTo = {}})
                end,
                ---@param specName string
                ---@param requiredSpecName string
                function(specName, requiredSpecName)
                    if not specAddAllowed then
                        Logging.devError("[%s] addSpecializationBySpecialization is no more allowed", mod.name)
                        return
                    end
                    table.insert(specsBySpec, {name = string.format("%s.%s", mod.name, specName), requiredSpecName = requiredSpecName, addedTo = {}})
                end,
                ---@param specName string
                ---@param requiredVehicleTypeName string
                function(specName, requiredVehicleTypeName)
                    if not specAddAllowed then
                        Logging.devError("[%s] addSpecializationByVehicleType is no more allowed", mod.name)
                        return
                    end
                    table.insert(specsByType, {name = string.format("%s.%s", mod.name, specName), requiredVehicleTypeName = requiredVehicleTypeName, addedTo = {}})
                end,
                ---@param specName string
                ---@param func function
                function(specName, func)
                    if not specAddAllowed then
                        Logging.devError("[%s] addSpecializationByFunction is no more allowed", mod.name)
                        return
                    end
                    table.insert(specsByFunc, {name = string.format("%s.%s", mod.name, specName), func = func, addedTo = {}})
                end
            )
        end

        specAddAllowed = false

        -- remove invalid specs

        for i, spec in pairs(specs) do
            if g_specializationManager:getSpecializationByName(spec.name) == nil then
                Logging.devError("[%s] Can't find specialization %s", mod.name, spec.name)
                table.remove(specs, i)
            end
        end

        for i, spec in pairs(specsBySpec) do
            if g_specializationManager:getSpecializationByName(spec.name) == nil then
                Logging.devError("[%s] Can't find specialization %s", mod.name, spec.name)
                table.remove(specsBySpec, i)
            end
        end

        for i, spec in pairs(specsByType) do
            if g_specializationManager:getSpecializationByName(spec.name) == nil then
                Logging.devError("[%s] Can't find specialization %s", mod.name, spec.name)
                table.remove(specsByType, i)
            end
        end

        for i, spec in pairs(specsByFunc) do
            if g_specializationManager:getSpecializationByName(spec.name) == nil then
                Logging.devError("[%s] Can't find specialization %s", mod.name, spec.name)
                table.remove(specsByFunc, i)
            end
        end

        local vehicleTypesCount = 0

        for typeName, typeEntry in pairs(self:getVehicleTypes()) do
            vehicleTypesCount = vehicleTypesCount + 1

            -- add "global" specializations
            for _, spec in pairs(specs) do
                if typeEntry.specializationsByName[spec.name] == nil then
                    if g_specializationManager:getSpecializationObjectByName(spec.name).prerequisitesPresent(typeEntry.specializations) then
                        self:addSpecialization(typeName, spec.name)
                        table.insert(spec.addedTo, typeName)
                    else
                        Logging.devError("[%s] Not all prerequisites of specialization %s are fulfilled by %s", mod.name, spec.name, typeName)
                    end
                end
            end

            -- add specializations by function
            for _, spec in pairs(specsByFunc) do
                if spec.func(typeEntry) then
                    if typeEntry.specializationsByName[spec.name] == nil then
                        if g_specializationManager:getSpecializationObjectByName(spec.name).prerequisitesPresent(typeEntry.specializations) then
                            self:addSpecialization(typeName, spec.name)
                            table.insert(spec.addedTo, typeName)
                        else
                            Logging.devError("[%s] Not all prerequisites of specialization %s are fulfilled by %s", mod.name, spec.name, typeName)
                        end
                    end
                end
            end

            -- add specializations by required specialization
            for name, _ in pairs(typeEntry.specializationsByName) do
                for _, spec in pairs(specsBySpec) do
                    if name == spec.requiredSpecName then
                        if typeEntry.specializationsByName[spec.name] == nil then
                            if g_specializationManager:getSpecializationObjectByName(spec.name).prerequisitesPresent(typeEntry.specializations) then
                                self:addSpecialization(typeName, spec.name)
                                table.insert(spec.addedTo, typeName)
                            else
                                Logging.devError("[%s] Not all prerequisites of specialization %s are fulfilled by %s", mod.name, spec.name, typeName)
                            end
                        end
                    end
                end
            end

            -- add specializations by required vehicle type
            for _, spec in pairs(specsByType) do
                if typeName == spec.requiredVehicleTypeName then
                    if typeEntry.specializationsByName[spec.name] == nil then
                        if g_specializationManager:getSpecializationObjectByName(spec.name).prerequisitesPresent(typeEntry.specializations) then
                            self:addSpecialization(typeName, spec.name)
                            table.insert(spec.addedTo, typeName)
                        else
                            Logging.devError("[%s] Not all prerequisites of specialization %s are fulfilled by %s", mod.name, spec.name, typeName)
                        end
                    end
                end
            end
        end

        for _, spec in pairs(specs) do
            if #spec.addedTo <= 25 then
                Logging.devInfo("[%s] %s added to [%s]", mod.name, spec.name, table.concat(spec.addedTo, ", "))
            else
                Logging.devInfo("[%s] %s added to %s vehicle types out of %s", mod.name, spec.name, #spec.addedTo, vehicleTypesCount)
            end
        end

        for _, spec in pairs(specsBySpec) do
            if #spec.addedTo <= 25 then
                Logging.devInfo("[%s] %s added to [%s]", mod.name, spec.name, table.concat(spec.addedTo, ", "))
            else
                Logging.devInfo("[%s] %s added to %s vehicle types out of %s", mod.name, spec.name, #spec.addedTo, vehicleTypesCount)
            end
        end

        for _, spec in pairs(specsByType) do
            if #spec.addedTo <= 25 then
                Logging.devInfo("[%s] %s added to [%s]", mod.name, spec.name, table.concat(spec.addedTo, ", "))
            else
                Logging.devInfo("[%s] %s added to %s vehicle types out of %s", mod.name, spec.name, #spec.addedTo, vehicleTypesCount)
            end
        end

        for _, spec in pairs(specsByFunc) do
            if #spec.addedTo <= 25 then
                Logging.devInfo("[%s] %s added to [%s]", mod.name, spec.name, table.concat(spec.addedTo, ", "))
            else
                Logging.devInfo("[%s] %s added to %s vehicle types out of %s", mod.name, spec.name, #spec.addedTo, vehicleTypesCount)
            end
        end

        mod.super.oldFunctions.VehicleTypeManagerfinalizeTypes(self, ...)
    end
    ]]

    mod.super.oldFunctions.Mission00new = Mission00.new
    ---@param self Mission00
    ---@param baseDirectory string
    ---@param customMt? table
    ---@param missionCollaborators MissionCollaborators
    ---@return Mission00
    Mission00.new = function(self, baseDirectory, customMt, missionCollaborators, ...)
        if mod.onMissionInitialize ~= nil then
            --- g_currentMission is still nil here
            xpcall(mod.onMissionInitialize, mod.super.errorHandle, mod, baseDirectory, missionCollaborators)
        end
        return mod.super.oldFunctions.Mission00new(self, baseDirectory, customMt, missionCollaborators, ...)
    end

    mod.super.oldFunctions.Mission00setMissionInfo = Mission00.setMissionInfo
    ---@param self Mission00
    ---@param missionInfo FSCareerMissionInfo
    ---@param missionDynamicInfo table
    Mission00.setMissionInfo = function(self, missionInfo, missionDynamicInfo, ...)
        g_currentMission:addLoadFinishedListener(mod.super)
        g_currentMission:registerObjectToCallOnMissionStart(mod.super)
        if mod.onSetMissionInfo ~= nil then
            --- g_currentMission is no more nil here
            xpcall(mod.onSetMissionInfo, mod.super.errorHandle, mod, missionInfo, missionDynamicInfo)
        end
        mod.super.oldFunctions.Mission00setMissionInfo(self, missionInfo, missionDynamicInfo, ...)
    end

    mod.super.oldFunctions.Mission00load = Mission00.load
    ---@param self Mission00
    Mission00.load = function(self, ...)
        if mod.onLoad ~= nil then
            xpcall(mod.onLoad, mod.super.errorHandle, mod)
        end
        mod.super.oldFunctions.Mission00load(self, ...)
    end

    mod.super.oldFunctions.FSBaseMissionloadMap = FSBaseMission.loadMap
    ---@param self FSBaseMission
    ---@param mapFile string
    ---@param addPhysics boolean
    ---@param asyncCallbackFunction function
    ---@param asyncCallbackObject table
    ---@param asyncCallbackArguments table
    FSBaseMission.loadMap = function(self, mapFile, addPhysics, asyncCallbackFunction, asyncCallbackObject, asyncCallbackArguments, ...)
        if mod.onPreLoadMap ~= nil then
            xpcall(mod.onPreLoadMap, mod.super.errorHandle, mod, mapFile)
        end
        mod.super.oldFunctions.FSBaseMissionloadMap(self, mapFile, addPhysics, asyncCallbackFunction, asyncCallbackObject, asyncCallbackArguments, ...)
    end

    mod.super.oldFunctions.Mission00onCreateStartPoint = Mission00.onCreateStartPoint
    ---@param self Mission00
    ---@param startPointNode integer
    Mission00.onCreateStartPoint = function(self, startPointNode, ...)
        mod.super.oldFunctions.Mission00onCreateStartPoint(self, startPointNode, ...)
        if mod.super.sync ~= nil then
            g_currentMission:addOnCreateLoadedObject(mod.super.sync)
            mod.super.sync:register(true)
        end
        if mod.onCreateStartPoint ~= nil then
            xpcall(mod.onCreateStartPoint, mod.super.errorHandle, mod, startPointNode)
        end
    end

    mod.super.oldFunctions.BaseMissionloadMapFinished = BaseMission.loadMapFinished
    ---@param self BaseMission
    ---@param mapNode integer
    ---@param arguments table
    ---@param callAsyncCallback boolean
    BaseMission.loadMapFinished = function(self, mapNode, failedReason, arguments, callAsyncCallback, ...)
        mod.mapNode = mapNode
        local mapFile, _, _, _ = unpack(arguments)
        mod.super.oldFunctions.BaseMissionloadMapFinished(self, mapNode, failedReason, arguments, callAsyncCallback, ...)
        if mod.onPostLoadMap ~= nil then
            xpcall(mod.onPostLoadMap, mod.super.errorHandle, mod, mapNode, mapFile)
        end
    end

    mod.super.oldFunctions.Mission00loadMission00Finished = Mission00.loadMission00Finished
    ---@param self Mission00
    ---@param mapNode integer
    ---@param arguments table
    Mission00.loadMission00Finished = function(self, mapNode, arguments, ...)
        if mod.onLoadSavegame ~= nil then
            xpcall(mod.onLoadSavegame, mod.super.errorHandle, mod, mod.super.getSavegameDirectory(), g_currentMission.missionInfo.savegameIndex)
        end
        mod.super.oldFunctions.Mission00loadMission00Finished(self, mapNode, arguments, ...)
    end

    mod.super.oldFunctions.Mission00loadVehicles = Mission00.loadVehicles
    ---@param self Mission00
    ---@param xmlFile integer
    ---@param resetVehicles boolean
    Mission00.loadVehicles = function(self, xmlFile, resetVehicles, ...)
        if mod.onPreLoadVehicles ~= nil then
            xpcall(mod.onPreLoadVehicles, mod.super.errorHandle, mod, xmlFile, resetVehicles)
        end
        mod.super.oldFunctions.Mission00loadVehicles(self, xmlFile, resetVehicles, ...)
    end

    mod.super.oldFunctions.Mission00loadItems = Mission00.loadItems
    ---@param self Mission00
    ---@param xmlFile integer
    Mission00.loadItems = function(self, xmlFile, ...)
        if mod.onPreLoadItems ~= nil then
            xpcall(mod.onPreLoadItems, mod.super.errorHandle, mod, xmlFile)
        end
        mod.super.oldFunctions.Mission00loadItems(self, xmlFile, ...)
    end

    mod.super.oldFunctions.Mission00loadOnCreateLoadedObjects = Mission00.loadOnCreateLoadedObjects
    ---@param self Mission00
    ---@param xmlFile integer
    Mission00.loadOnCreateLoadedObjects = function(self, xmlFile, ...)
        if mod.onPreLoadOnCreateLoadedObjects ~= nil then
            xpcall(mod.onPreLoadOnCreateLoadedObjects, mod.super.errorHandle, mod, xmlFile)
        end
        mod.super.oldFunctions.Mission00loadOnCreateLoadedObjects(self, xmlFile, ...)
    end

    -- not called on clients in MP games
    mod.super.onLoadFinished = function()
        if mod.onLoadFinished ~= nil then
            xpcall(mod.onLoadFinished, mod.super.errorHandle, mod)
        end
    end

    mod.super.oldFunctions.Mission00onStartMission = Mission00.onStartMission
    ---@param self Mission00
    Mission00.onStartMission = function(self, ...)
        if mod.onStartMission ~= nil then
            xpcall(mod.onStartMission, mod.super.errorHandle, mod)
        end
        mod.super.oldFunctions.Mission00onStartMission(self, ...)
    end

    mod.super.onMissionStarted = function(...)
        if mod.onMissionStarted ~= nil then
            xpcall(mod.onMissionStarted, mod.super.errorHandle, mod)
        end
    end

    mod.super.oldFunctions.Mission00delete = Mission00.delete
    ---@param self Mission00
    Mission00.delete = function(self, ...)
        if mod.onPreDeleteMap ~= nil then
            xpcall(mod.onPreDeleteMap, mod.super.errorHandle, mod)
        end
        mod.super.oldFunctions.Mission00delete(self, ...)
    end

    mod.super.oldFunctions.FSBaseMissionsaveSavegame = FSBaseMission.saveSavegame
    ---@param self FSBaseMission
    FSBaseMission.saveSavegame = function(self, ...)
        if mod.onPreSaveSavegame ~= nil then
            -- before all vhicles, items and onCreateObjects are saved
            xpcall(mod.onPreSaveSavegame, mod.super.errorHandle, mod, mod.super.getSavegameDirectory(), g_currentMission.missionInfo.savegameIndex)
        end
        mod.super.oldFunctions.FSBaseMissionsaveSavegame(self, ...)
        if mod.onPostSaveSavegame ~= nil then
            -- after all vhicles, items and onCreateObjects are saved
            xpcall(mod.onPostSaveSavegame, mod.super.errorHandle, mod, mod.super.getSavegameDirectory(), g_currentMission.missionInfo.savegameIndex)
        end
    end

    mod.super.oldFunctions.HelpLineManagerloadMapData = HelpLineManager.loadMapData
    ---@param self HelpLineManager
    ---@param xmlFile integer
    ---@param missionInfo FSCareerMissionInfo
    ---@return boolean
    HelpLineManager.loadMapData = function(self, xmlFile, missionInfo)
        if mod.super.oldFunctions.HelpLineManagerloadMapData(self, xmlFile, missionInfo) then
            if mod.onLoadHelpLine ~= nil then
                local success, hlFilename = xpcall(mod.onLoadHelpLine, mod.super.errorHandle, mod)
                if success and hlFilename ~= nil and type(hlFilename) == "string" and hlFilename ~= "" then
                    self:loadFromXML(hlFilename)
                    for ci = 1, #self.categories do
                        local category = self.categories[ci]
                        for pi = 1, #category.pages do
                            local page = category.pages[pi]
                            for ii = 1, #page.items do
                                local item = page.items[ii]
                                if item.type == HelpLineManager.ITEM_TYPE.IMAGE then
                                    if item.value:sub(1, 10) == "$rmModDir/" then
                                        item.value = "$" .. mod.directory .. item.value:sub(11)
                                    end
                                end
                            end
                        end
                    end
                end
            end
            return true
        end
    end

    addModEventListener(mod.super)
    return mod
end
