--- Royal Utility

---@author Royal Modding
---@version 2.1.1.0
---@date 05/01/2021

---@class GameplayUtility
GameplayUtility = GameplayUtility or {}

--- Get value of a trunk (splitshape)
---@param id integer
---@param splitType table
---@return number, number, number, number
function GameplayUtility.getTrunkValue(id, splitType)
    if splitType == nil then
        splitType = g_splitTypeManager:getSplitTypeByIndex(getSplitType(id))
    end

    if splitType == nil or splitType.pricePerLiter <= 0 then
        return 0
    end

    local volume = getVolume(id)
    local qualityScale = 1
    local lengthScale = 1
    local defoliageScale = 1
    local sizeX, sizeY, sizeZ, numConvexes, numAttachments = getSplitShapeStats(id)

    if sizeX ~= nil and volume > 0 then
        local bvVolume = sizeX * sizeY * sizeZ
        local volumeRatio = bvVolume / volume
        local volumeQuality = 1 - math.sqrt(MathUtil.clamp((volumeRatio - 3) / 7, 0, 1)) * 0.95 --  ratio <= 3: 100%, ratio >= 10: 5%
        local convexityQuality = 1 - MathUtil.clamp((numConvexes - 2) / (6 - 2), 0, 1) * 0.95
        -- 0-2: 100%:, >= 6: 5%

        local maxSize = math.max(sizeX, math.max(sizeY, sizeZ))
        -- 1m: 60%, 6-11m: 120%, 19m: 60%
        if maxSize < 11 then
            lengthScale = 0.6 + math.min(math.max((maxSize - 1) / 5, 0), 1) * 0.6
        else
            lengthScale = 1.2 - math.min(math.max((maxSize - 11) / 8, 0), 1) * 0.6
        end

        local minQuality = math.min(convexityQuality, volumeQuality)
        local maxQuality = math.max(convexityQuality, volumeQuality)
        qualityScale = minQuality + (maxQuality - minQuality) * 0.3 -- use 70% of min quality

        defoliageScale = 1 - math.min(numAttachments / 15, 1) * 0.8 -- #attachments 0: 100%, >=15: 20%
    end

    -- Only take 33% into account of the quality criteria on easy difficulty
    qualityScale = MathUtil.lerp(1, qualityScale, g_currentMission.missionInfo.economicDifficulty / 3)

    defoliageScale = MathUtil.lerp(1, defoliageScale, g_currentMission.missionInfo.economicDifficulty / 3)

    local sellPriceMultiplier = g_currentMission.missionInfo.sellPriceMultiplier

    return volume * 1000 * splitType.pricePerLiter * qualityScale * defoliageScale * lengthScale * sellPriceMultiplier, qualityScale, defoliageScale, lengthScale
end

--- Get the farm color
---@param farmId number
---@return number[]
function GameplayUtility.getFarmColor(farmId)
    local farm = g_farmManager:getFarmById(farmId)
    if farm ~= nil then
        local color = Farm.COLORS[farm.color]
        if color ~= nil then
            return color
        end
    end
    return {1, 1, 1, 1}
end

--- Get the farm name
---@param farmId number
---@return string
function GameplayUtility.getFarmName(farmId)
    local farm = g_farmManager:getFarmById(farmId)
    if farm ~= nil then
        return farm.name
    end
    return nil
end
