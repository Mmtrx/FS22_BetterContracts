--- Royal Utility

---@author Royal Modding
---@version 2.1.1.0
---@date 09/11/2020

--- Utilities class
---@class Utility
Utility = Utility or {}

---@param target table
---@param name string
---@param newFunc function
function Utility.overwrittenFunction(target, name, newFunc)
    if target == nil then
        print("Error: " .. "overwrittenFunction 'target' cannot be nil")
        printCallstack()
    end
    if newFunc == nil then
        print("Error: " .. "overwrittenFunction 'newFunc' cannot be nil")
        printCallstack()
    end
    target[name] = Utils.overwrittenFunction(target[name], newFunc)
end

---@param target table
---@param name string
---@param newFunc function
function Utility.overwrittenStaticFunction(target, name, newFunc)
    if target == nil then
        print("Error: " .. "overwrittenStaticFunction 'target' cannot be nil")
        printCallstack()
    end
    if newFunc == nil then
        print("Error: " .. "overwrittenStaticFunction 'newFunc' cannot be nil")
        printCallstack()
    end
    local oldFunc = target[name]
    target[name] = function(...)
        return newFunc(oldFunc, ...)
    end
end

---@param target table
---@param name string
---@param newFunc function
function Utility.appendedFunction(target, name, newFunc)
    if target == nil then
        print("Error: " .. "appendedFunction 'target' cannot be nil")
        printCallstack()
    end
    if newFunc == nil then
        print("Error: " .. "appendedFunction 'newFunc' cannot be nil")
        printCallstack()
    end
    target[name] = Utils.appendedFunction(target[name], newFunc)
end

---@param target table
---@param name string
---@param newFunc function
function Utility.prependedFunction(target, name, newFunc)
    if target == nil then
        print("Error: " .. "prependedFunction 'target' cannot be nil")
        printCallstack()
    end
    if newFunc == nil then
        print("Error: " .. "prependedFunction 'newFunc' cannot be nil")
        printCallstack()
    end
    target[name] = Utils.prependedFunction(target[name], newFunc)
end

---@overload fun(fieldPartition: FieldPartition) : number, number, number, number, number, number
--- Converts from point-vertex-vertex to point-point-point (pvv to ppp)
---@param startX number | FieldPartition
---@param startZ number
---@param widthX number
---@param widthZ number
---@param heightX number
---@param heightZ number
---@return number
---@return number
---@return number
---@return number
---@return number
---@return number
function Utility.getPPP(startX, startZ, widthX, widthZ, heightX, heightZ)
    if type(startX) == "table" then
        return startX.x0, startX.z0, startX.widthX + startX.x0, startX.widthZ + startX.z0, startX.heightX + startX.x0, startX.heightZ + startX.z0
    else
        return startX, startZ, widthX + startX, widthZ + startZ, heightX + startX, heightZ + startZ
    end
end

--- Converts from  point-point-point to  point-vertex-vertex (ppp to pvv)
---@param startWorldX number
---@param startWorldZ number
---@param widthWorldX number
---@param widthWorldZ number
---@param heightWorldX number
---@param heightWorldZ number
---@return number
---@return number
---@return number
---@return number
---@return number
---@return number
function Utility.getPVV(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)
    return startWorldX, startWorldZ, widthWorldX - startWorldX, widthWorldZ - startWorldZ, heightWorldX - startWorldX, heightWorldZ - startWorldZ
end

--- Clamp between the given maximum and minimum
---@param minValue number
---@param value number
---@param maxValue number
---@return number
function Utility.clamp(minValue, value, maxValue)
    minValue = minValue or 0
    maxValue = maxValue or 1
    value = value or 0
    return math.max(minValue, math.min(maxValue, value))
end

--- Get random number sign (1 or -1)
---@return integer
function Utility.randomSign()
    if math.random(2) > 1 then
        return -1
    else
        return 1
    end
end

--- Pick one random between the **batches** and return a random integer in it's interval
---@param batches RandomInterval[]
---@return integer
function Utility.randomFromBatches(batches)
    local batch = batches[math.random(1, #batches)]
    return math.random(batch.min, batch.max)
end

--- Normalize value by given maximum and minimum
---@param minValue number
---@param value number
---@param maxValue number
---@return number
function Utility.normalize(minValue, value, maxValue)
    minValue = minValue or 0
    maxValue = maxValue or 1
    value = value or 0.5
    return (value - minValue) / (maxValue - minValue)
end

--- Get elapsed seconds between given date and FS19 release date
---@param year? integer
---@param month? integer
---@param day? integer
---@param hour? integer
---@param minute? integer
---@param second? integer
---@return integer
function Utility.getTimestampAt(year, month, day, hour, minute, second)
    year = year or 0
    month = month or 0
    day = day or 0
    hour = hour or 0
    minute = minute or 0
    second = second or 0
    return getDateDiffSeconds(year, month, day, hour, minute, second, 2018, 11, 20, 0, 0, 0)
end

--- Get elapsed seconds since FS19 release date
---@return integer
function Utility.getTimestamp()
    local date = getDate("%Y-%m-%d_%H-%M-%S")
    local year, month, day, hour, minute, second = date:match("(%d%d%d%d)-(%d%d)-(%d%d)_(%d%d)-(%d%d)-(%d%d)")
    return Utility.getTimestampAt(tonumber(year), tonumber(month), tonumber(day), tonumber(hour), tonumber(minute), tonumber(second))
end

--- Table utilities class ---------------------------------------------------------
---@class TableUtility
TableUtility = TableUtility or {}

--- Clone a table
---@param t table
---@return table
function TableUtility.clone(t)
    local copy = {}
    for k, v in pairs(t) do
        if type(v) == "table" then
            v = TableUtility.clone(v)
        end
        copy[k] = v
    end
    return copy
end

--- Overwrite a table
---@param t table
---@param newTable table
---@return table
function TableUtility.overwrite(t, newTable)
    t = t or {}
    for k, v in pairs(newTable) do
        if type(v) == "table" then
            TableUtility.overwrite(t[k], v)
        else
            t[k] = v
        end
    end
end

--- Get if a the element exists
---@param t table
---@param value any
---@return boolean
function TableUtility.contains(t, value)
    for _, v in pairs(t) do
        if v == value then
            return true
        end
    end
    return false
end

--- Get if a matching element exists
---@param t table
---@param func function | "function(e) return true end"
---@return boolean
function TableUtility.f_contains(t, func)
    for _, v in pairs(t) do
        if func(v) then
            return true
        end
    end
    return false
end

--- Get the index of element
---@param t table
---@param value any
---@return integer|nil
function TableUtility.indexOf(t, value)
    for k, v in pairs(t) do
        if v == value then
            return k
        end
    end
    return nil
end

--- Get the index of matching element
---@param t table
---@param func function | "function(e) return true end"
---@return integer|nil
function TableUtility.f_indexOf(t, func)
    for k, v in pairs(t) do
        if func(v) then
            return k
        end
    end
    return nil
end

--- Get the matching element
---@param t table
---@param func function | "function(e) return true end"
---@return any|nil
function TableUtility.f_find(t, func)
    for _, v in pairs(t) do
        if func(v) then
            return v
        end
    end
    return nil
end

--- Get a new table with matching elements
---@param t table
---@param func function | "function(e) return true end"
---@return table
function TableUtility.f_filter(t, func)
    local new = {}
    for _, v in pairs(t) do
        if func(v) then
            table.insert(new, v)
        end
    end
    return new
end

--- Remove matching element
---@param t table
---@param value any
---@return boolean
function TableUtility.removeValue(t, value)
    for k, v in pairs(t) do
        if v == value then
            table.remove(t, k)
            return true
        end
    end
    return false
end

--- Remove matching elements
---@param t table
---@param func function | "function(e) return true end"
function TableUtility.f_remove(t, func)
    for k, v in pairs(t) do
        if func(v) then
            table.remove(t, k)
        end
    end
end

--- Count occurrences
---@param t table
---@return integer
function TableUtility.count(t)
    local c = 0
    if t ~= nil then
        for _ in pairs(t) do
            c = c + 1
        end
    end
    return c
end

--- Count occurrences
---@param t table
---@param func function | "function(e) return true end"
---@return integer
function TableUtility.f_count(t, func)
    local c = 0
    if t ~= nil then
        for _, v in pairs(t) do
            if func(v) then
                c = c + 1
            end
        end
    end
    return c
end

--- Concat and return nil if the sring is empty
---@param t table
---@param sep string
---@param i integer
---@param j integer
---@return string|nil
function TableUtility.concatNil(t, sep, i, j)
    local res = table.concat(t, sep, i, j)
    if res == "" then
        res = nil
    end
    return res
end

---@param table1 table
---@param table2 table
---@return boolean
function TableUtility.equals(table1, table2)
    if table1 == table2 then
        return true
    end

    local table1Type = type(table1)

    local table2Type = type(table2)

    if table1Type ~= table2Type then
        return false
    end

    if table1Type ~= "table" then
        return false
    end

    local keySet = {}

    for key1, value1 in pairs(table1) do
        local value2 = table2[key1]
        if value2 == nil or TableUtility.equals(value1, value2) == false then
            return false
        end
        keySet[key1] = true
    end

    for key2, _ in pairs(table2) do
        if not keySet[key2] then
            return false
        end
    end

    return true
end
