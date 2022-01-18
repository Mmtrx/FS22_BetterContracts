--- Royal Utility

---@author Royal Modding
---@version 2.1.1.0
---@date 05/01/2021

--- Table utilities class
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

--- Get if an element with the given value exists
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

--- Map a table to a new table
---@param t table source table
---@param func function | "function(e) return { f1 = e.f1, f2 = e.f2 } end" mapping function
---@return table mapped mapped table
function TableUtility.map(t, func)
    local mapped = {}
    for k, v in pairs(t) do
        mapped[k] = func(v)
    end
    return mapped
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
