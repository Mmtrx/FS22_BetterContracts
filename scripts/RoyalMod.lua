--- Royal Mod

---@author Royal Modding
---@version 1.5.0.0
---@date 03/12/2020
-- Changelog:
--  v1.0.0.0    03.12.2020  initial by Royal-Modding
--  v1.1.0.0    30.12.2021: (Mmtrx) commented out vehicleTypeManagerFinalizeTypes, different in FS22
--  v1.1.0.1    27.02.2022: (Mmtrx) delete vehicleTypeManagerFinalizeTypes, different in FS22
--							remove mod.gameEnv, no longer reachable in FS22
--							change addOnCreateLoadedObjects -> OnCreateObjectSystem:add() for mpSync
--							delete Mission00.loadOnCreateLoadedObjects, no more in FS22
--							add BaseMission.onFinishedLoading 
--				13.04.2022	add check on g_vehicleTypeManager when calling mod.initialize 
--				15.05.2022	call mod.onLoad with "mission" param
--				20.06.2022	check on TypeManager.typeName when calling mod.initialize 

--------- possible functions that mod can specify: ------------------------------------
--[[
 -- for MP syncing:
 ---@field onWriteStream fun(self: RoyalMod, streamId: integer)
 ---@field onReadStream fun(self: RoyalMod, streamId: integer)
 ---@field onUpdateTick fun(self: RoyalMod, dt: number)
 ---@field onWriteUpdateStream fun(self: RoyalMod, streamId: integer, connection: Connection, dirtyMask: integer)
 ---@field onReadUpdateStream fun(self: RoyalMod, streamId: integer, timestamp: number, connection: Connection)
 
 -- standard listeners:
 ---@field onLoadMap fun(self: RoyalMod, mapNode: integer, mapFile: string)
 ---@field onDeleteMap fun(self: RoyalMod)
 ---@field onDraw fun(self: RoyalMod)
 ---@field onUpdate fun(self: RoyalMod, dt: number)
 ---@field onMouseEvent fun(self: RoyalMod, posX: number, posY: number, isDown: boolean, isUp: boolean, button: integer)
 ---@field onKeyEvent fun(self: RoyalMod, unicode: integer, sym: integer, modifier: integer, isDown: boolean)
 
 -- additional Royal Mod entry points:
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
 ---@field onLoadFinished fun(self: RoyalMod)
 ---@field onStartMission fun(self: RoyalMod)
 ---@field onMissionStarted fun(self: RoyalMod)
 ---@field onPreDeleteMap fun(self: RoyalMod)
 ---@field onPreSaveSavegame fun(self: RoyalMod, savegameDirectory: string, savegameIndex: integer)
 ---@field onPostSaveSavegame fun(self: RoyalMod, savegameDirectory: string, savegameIndex: integer)
 ---@field onLoadHelpLine fun(self: RoyalMod): string
 
 
 --------- predefined fields of the mod: ------------------------------------
 --@field directory string mod directory
 --@field userProfileDirectory string user profile directory
 --@field name string mod name
 --@field mod table g_modManager mod object
 --@field version string mod version
 --@field author string mod author
 --@field modEnv table mod scripting environment
 --@field super table mod super class
 --@field debug boolean mod debug state
]]
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
	mod.super = {}
	mod.debug = debug

	if mod.debug then
		g_showDevelopmentWarnings = true
		g_addTestCommands = true
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
	-- ------------- for MP sync handling ----------------------------------------
	if mpSync then
		mod.super.sync = Object.new(g_server ~= nil, g_client ~= nil, Class(nil, Object))

		---@param self Object
		---@param streamId integer
		mod.super.sync.writeStream = function(self, streamId)
			self:superClass().writeStream(self, streamId)
			if mod.onWriteStream ~= nil then
				local time = netGetTime()
				local offset = streamGetWriteOffset(streamId)
				xpcall(mod.onWriteStream, mod.super.errorHandle, mod, streamId)
				offset = streamGetWriteOffset(streamId) - offset
				debugPrint("[%s] Written %.0f bits (%.0f bytes) in %s ms", mod.name, offset, offset / 8, netGetTime() - time)
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
				debugPrint("[%s] Read %.0f bits (%.0f bytes) in %s ms", mod.name, offset, offset / 8, netGetTime() - time)
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

	mod.super.oldFunctions.TypeManagerValidateTypes = TypeManager.validateTypes
	TypeManager.validateTypes = function(self, ...)
		if mod.initialize ~= nil and self.typeName == "placeable" then
			---  validateTypes will be called twice:
			---   for vehicles and for placeables 
			--- g_currentMission is still nil here. All mods are loaded here
			xpcall(mod.initialize, mod.super.errorHandle, mod)
		end
		mod.super.oldFunctions.TypeManagerValidateTypes(self, ...)
	end

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
		mod.super.oldFunctions.Mission00setMissionInfo(self, missionInfo, missionDynamicInfo, ...)
		if mod.onSetMissionInfo ~= nil then
			--- g_currentMission is no more nil here
			xpcall(mod.onSetMissionInfo, mod.super.errorHandle, mod, missionInfo, missionDynamicInfo)
		end
	end

	mod.super.oldFunctions.Mission00load = Mission00.load
	---@param self Mission00
	Mission00.load = function(self, ...)
		if mod.onLoad ~= nil then
			xpcall(mod.onLoad, mod.super.errorHandle, mod, self)
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
	
	-- apparently called when careerStartPoint is created from map
	mod.super.oldFunctions.Mission00onCreateStartPoint = Mission00.onCreateStartPoint
	---@param self Mission00
	---@param startPointNode integer
	Mission00.onCreateStartPoint = function(self, startPointNode, ...)
		mod.super.oldFunctions.Mission00onCreateStartPoint(self, startPointNode, ...)
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
		if mod.super.sync ~= nil then
			--g_currentMission:addOnCreateLoadedObject(mod.super.sync)
			g_currentMission.onCreateObjectSystem:add(mod.super.sync)
			mod.super.sync:register(true)
		end
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

	-- not called on clients in MP games
	mod.super.onLoadFinished = function()
		if mod.onLoadFinished ~= nil then
			xpcall(mod.onLoadFinished, mod.super.errorHandle, mod)
		end
	end

	mod.super.oldFunctions.BaseMissionOnFinishedLoading = BaseMission.onFinishedLoading
	---@param self BaseMission
	BaseMission.onFinishedLoading = function(self, ...)
		mod.super.oldFunctions.BaseMissionOnFinishedLoading(self, ...)
		if mod.onFinishedLoading ~= nil then
			xpcall(mod.onFinishedLoading, mod.super.errorHandle, mod)
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
			-- before all vehicles, items and onCreateObjects are saved
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
