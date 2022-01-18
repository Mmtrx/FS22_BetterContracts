--- Royal Mod

---@author Royal Modding
---@version 1.5.0.0
---@date 03/12/2020

--- Initialize RoyalMod
---@param rmodDirectory string
function InitRoyalMod(rmodDirectory)
    source(Utils.getFilename("RoyalMod.lua", rmodDirectory))
    printDebug("Royal Mod loaded successfully by " .. g_currentModName)
    return true
end
