--- Royal Utility

---@author Royal Modding
---@version 1.8.1.0
---@date 26/02/2021

---@alias Array table<number, any> tables with numeric indexes only, always ordered and sequential

--- Array utilities class built with performances in mind (with 'array' we mean tables with numeric indexes only, always ordered and sequential)
---@class ArrayUtility
ArrayUtility = ArrayUtility or {}

--- Remove matching elements from an array
---@param array Array
---@param removeFunc fun(array: Array, index: number, moveAt: number): boolean | "function(array, index, moveAt) local element = array[index] return true end"
---@return Array
function ArrayUtility.remove(array, removeFunc)
    local moveAt, length = 1, #array
    for index = 1, length do
        if removeFunc(array, index, moveAt) then
            array[index] = nil
        else
            -- move kept element's value to moveAt's position, if it's not already there
            if (index ~= moveAt) then
                array[moveAt] = array[index]
                array[index] = nil
            end
            -- increment position of where we'll place the next kept value
            moveAt = moveAt + 1
        end
    end
    return array
end

--- Remove element at the given index from an array
---@param array Array
---@param index number
---@return Array
function ArrayUtility.removeAt(array, index)
    ArrayUtility.remove(
        array,
        function(_, i)
            return index == i
        end
    )
end
