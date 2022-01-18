---${title}

---@author ${author}
---@version r_version_r
---@date @date 25/02/2021

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

---@param connection any
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
