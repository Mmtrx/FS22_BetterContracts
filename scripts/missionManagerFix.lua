---${title}

---@author ${author}
---@version r_version_r
---@date 25/02/2021

function MissionManager:update(dt)
    if g_currentMission:getIsServer() then
        self.generationTimer = self.generationTimer - g_currentMission.missionInfo.timeScale * dt
        self:updateMissions(dt)
        if self.generationTimer <= 0 then
            if #self.missions < MissionManager.MAX_MISSIONS then
                self:generateMissions(dt)
            end
            self.generationTimer = MissionManager.MISSION_GENERATION_INTERVAL
        end
    end
end
