---${title}

---@author ${author}
---@version r_version_r
---@date @date 19/10/2020

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
