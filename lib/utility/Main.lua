--- Royal Utility

---@author Royal Modding
---@version 2.1.1.0
---@date 21/11/2020

--- Initialize RoyalUtility
---@param utilityDirectory string
function InitRoyalUtility(utilityDirectory)
    source(Utils.getFilename("Utility.lua", utilityDirectory))
    source(Utils.getFilename("Debug.lua", utilityDirectory))
    source(Utils.getFilename("Entity.lua", utilityDirectory))
    source(Utils.getFilename("Gameplay.lua", utilityDirectory))
    source(Utils.getFilename("String.lua", utilityDirectory))
    source(Utils.getFilename("Table.lua", utilityDirectory))
    source(Utils.getFilename("Interpolator.lua", utilityDirectory))
    source(Utils.getFilename("Array.lua", utilityDirectory))
    source(Utils.getFilename("FadeEffect.lua", utilityDirectory))
    source(Utils.getFilename("DelayedCallBack.lua", utilityDirectory))
    Logging.devInfo("Royal Utility loaded successfully by " .. g_currentModName)
    return true
end
