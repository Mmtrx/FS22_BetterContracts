--=======================================================================================================
-- BetterContracts EVENTS
--
-- Purpose:     Enhance ingame contracts menu.
-- Functions:   options for lazyNPC, hardMode, fieldDiscount
-- Author:      Royal-Modding / Mmtrx
-- Changelog:
--  v1.2.5.0    31.10.2022  hard mode: active miss time out at midnght. Penalty for missn cancel
--  v1.2.6.0 	30.11.2022	UI for all settings
--=======================================================================================================

--------------------- ClearEvent ------------------------------------------------------------------------ 
BetterContractsClearEvent = {}
BetterContractsClearEvent_mt = Class(BetterContractsClearEvent, Event)
InitEventClass(BetterContractsClearEvent, "BetterContractsClearEvent")

function BetterContractsClearEvent.emptyNew()
	local o = Event.new(BetterContractsClearEvent_mt)
	o.className = "BetterContractsClearEvent"
	return o
end
function BetterContractsClearEvent.new()
	local o = BetterContractsClearEvent.emptyNew()
	return o
end
function BetterContractsClearEvent:writeStream(_, _)
end
function BetterContractsClearEvent:readStream(_, connection)
	self:run(connection)
end
function BetterContractsClearEvent:run(connection)
	if g_server ~= nil and connection:getIsServer() == false then
		-- if the event is coming from a client, server have only to broadcast
		BetterContractsClearEvent.sendEvent()
	else
		-- if the event is coming from the server, both clients and server have to delete old contracts
		-- remove only inactive (status == 0) missions

		---@type table<any, AbstractMission>
		local missionsToDelete = {}

		for i, mission in ipairs(g_missionManager.missions) do
			if mission.status == AbstractMission.STATUS_STOPPED then
				missionsToDelete[i] = mission
			end
		end

		for _, mission in pairs(missionsToDelete) do
			mission:delete()
		end

		if g_currentMission.inGameMenu.isOpen and g_currentMission.inGameMenu.pageContracts.visible then
			g_currentMission.inGameMenu.pageContracts:setButtonsForState()
		end
	end
end
function BetterContractsClearEvent.sendEvent()
	local event = BetterContractsClearEvent.new()
	if g_server ~= nil then
		-- server have to broadcast to all clients and himself
		g_server:broadcastEvent(event, true)
	else
		-- clients have to send to server
		g_client:getServerConnection():sendEvent(event)
	end
end

--------------------- NewEvent ------------------------------------------------------------------------- 
BetterContractsNewEvent = {}
BetterContractsNewEvent_mt = Class(BetterContractsNewEvent, Event)
InitEventClass(BetterContractsNewEvent, "BetterContractsNewEvent")

function BetterContractsNewEvent.emptyNew()
	local o = Event.new(BetterContractsNewEvent_mt)
	o.className = "BetterContractsNewEvent"
	return o
end
function BetterContractsNewEvent.new()
	local o = BetterContractsNewEvent.emptyNew()
	return o
end
function BetterContractsNewEvent:writeStream(_, _)
end
function BetterContractsNewEvent:readStream(_, connection)
	self:run(connection)
end
function BetterContractsNewEvent:run(_)
	if g_server ~= nil then
		g_missionManager:generateMissions()
		-- reset generation timer
		g_missionManager.generationTimer = MissionManager.MISSION_GENERATION_INTERVAL
	end
end
function BetterContractsNewEvent.sendEvent()
	g_client:getServerConnection():sendEvent(BetterContractsNewEvent.new())
end

--------------------- SettingsEvent -------------------------------------------------------------------- 
SettingsEvent = {}
SettingsEvent_mt = Class(SettingsEvent, Event)
InitEventClass(SettingsEvent, "SettingsEvent")

function SettingsEvent.emptyNew()
    return Event.new(SettingsEvent_mt)
end
function SettingsEvent.new(setting)
    local o = SettingsEvent.emptyNew()
    o.setting = setting
    return o
end
function SettingsEvent:writeStream(streamId, connection)
    streamWriteString(streamId,self.setting.name)
    self.setting:writeStream(streamId, connection)
end
function SettingsEvent:readStream(streamId, connection)
    local name = streamReadString(streamId)
    local setting = BetterContracts.settingsByName[name]
    setting:readStream(streamId, connection)
    self:run(connection, setting)
end
function SettingsEvent:run(connection, setting)
    --- If we received this from a client, forward to other clients
    if not connection:getIsServer() then
        -- ignore self (connection)
        g_server:broadcastEvent(SettingsEvent.new(setting), nil, connection, nil)
    end
end
function SettingsEvent.sendEvent(setting)
    if g_server ~= nil then
        -- send to all clients
        g_server:broadcastEvent(SettingsEvent.new(setting))
    else -- send to Server
        g_client:getServerConnection():sendEvent(SettingsEvent.new(setting))
    end
end
