--- Royal Utility

---@author Royal Modding
---@version 2.1.1.0
---@date 11/01/2021

--- Interpolators utilities class
---@class InterpolatorUtility
InterpolatorUtility = InterpolatorUtility or {}

function InterpolatorUtility.exponential11Interpolator1(first, second, alpha)
    alpha = 1 - alpha
    alpha = alpha ^ 2
    return (first[1] + alpha * (second[1] - first[1]))
end

function InterpolatorUtility.exponential11InvertedInterpolator1(first, second, alpha)
    alpha = alpha ^ 2
    return (second[1] + alpha * (first[1] - second[1]))
end

function InterpolatorUtility.exponential12Interpolator1(first, second, alpha)
    alpha = 1 - alpha
    alpha = alpha ^ 3
    return (first[1] + alpha * (second[1] - first[1]))
end

function InterpolatorUtility.exponential12InvertedInterpolator1(first, second, alpha)
    alpha = alpha ^ 3
    return (second[1] + alpha * (first[1] - second[1]))
end

function InterpolatorUtility.exponential13Interpolator1(first, second, alpha)
    alpha = 1 - alpha
    alpha = alpha ^ 4
    return (first[1] + alpha * (second[1] - first[1]))
end

function InterpolatorUtility.exponential13InvertedInterpolator1(first, second, alpha)
    alpha = alpha ^ 4
    return (second[1] + alpha * (first[1] - second[1]))
end

function InterpolatorUtility.exponential14Interpolator1(first, second, alpha)
    alpha = 1 - alpha
    alpha = alpha ^ 8
    return (first[1] + alpha * (second[1] - first[1]))
end

function InterpolatorUtility.exponential14InvertedInterpolator1(first, second, alpha)
    alpha = alpha ^ 8
    return (second[1] + alpha * (first[1] - second[1]))
end

function InterpolatorUtility.exponential21Interpolator1(first, second, alpha)
    alpha = 1 - alpha
    alpha = (2 ^ alpha) - 1
    return (first[1] + alpha * (second[1] - first[1]))
end

function InterpolatorUtility.exponential21InvertedInterpolator1(first, second, alpha)
    alpha = (2 ^ alpha) - 1
    return (second[1] + alpha * (first[1] - second[1]))
end

function InterpolatorUtility.exponential22Interpolator1(first, second, alpha)
    alpha = 1 - alpha
    alpha = ((3 ^ alpha) - 1) / 2
    return (first[1] + alpha * (second[1] - first[1]))
end

function InterpolatorUtility.exponential22InvertedInterpolator1(first, second, alpha)
    alpha = ((3 ^ alpha) - 1) / 2
    return (second[1] + alpha * (first[1] - second[1]))
end

function InterpolatorUtility.exponential23Interpolator1(first, second, alpha)
    alpha = 1 - alpha
    alpha = ((4 ^ alpha) - 1) / 3
    return (first[1] + alpha * (second[1] - first[1]))
end

function InterpolatorUtility.exponential23InvertedInterpolator1(first, second, alpha)
    alpha = ((4 ^ alpha) - 1) / 3
    return (second[1] + alpha * (first[1] - second[1]))
end

function InterpolatorUtility.exponential24Interpolator1(first, second, alpha)
    alpha = 1 - alpha
    alpha = ((8 ^ alpha) - 1) / 7
    return (first[1] + alpha * (second[1] - first[1]))
end

function InterpolatorUtility.exponential24InvertedInterpolator1(first, second, alpha)
    alpha = ((8 ^ alpha) - 1) / 7
    return (second[1] + alpha * (first[1] - second[1]))
end

function InterpolatorUtility.catmullRomInterpolator1(first, second, beforeFirst, afterSecond, alpha)
    alpha = 1 - alpha
    local alpha2 = alpha * alpha
    local alpha3 = alpha2 * alpha

    if beforeFirst == nil then
        beforeFirst = {2 * first[1] - second[1]}
    end

    if afterSecond == nil then
        afterSecond = {2 * second[1] - first[1]}
    end

    return 0.5 * ((2 * first[1]) + (-beforeFirst[1] + second[1]) * alpha + (2 * beforeFirst[1] - 5 * first[1] + 4 * second[1] - afterSecond[1]) * alpha2 + (-beforeFirst[1] + 3 * first[1] - 3 * second[1] + afterSecond[1]) * alpha3)
end
