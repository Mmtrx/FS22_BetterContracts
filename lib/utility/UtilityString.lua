--- Royal Utility

---@author Royal Modding
---@version 1.8.1.0
---@date 05/01/2021

--- String utilities class
---@class StringUtility
StringUtility = StringUtility or {}

--- Chars available for randomizing
---@type string[]
StringUtility.randomCharset = {
    "0",
    "1",
    "2",
    "3",
    "4",
    "5",
    "6",
    "7",
    "8",
    "9",
    "A",
    "B",
    "C",
    "D",
    "E",
    "F",
    "G",
    "H",
    "I",
    "J",
    "K",
    "L",
    "M",
    "N",
    "O",
    "P",
    "Q",
    "R",
    "S",
    "T",
    "U",
    "V",
    "W",
    "X",
    "Y",
    "Z",
    "a",
    "b",
    "c",
    "d",
    "e",
    "f",
    "g",
    "h",
    "i",
    "j",
    "k",
    "l",
    "m",
    "n",
    "o",
    "p",
    "q",
    "r",
    "s",
    "t",
    "u",
    "v",
    "w",
    "x",
    "y",
    "z"
}

--- Get random string
---@param length number
---@return string
function StringUtility.random(length)
    length = length or 1
    if length <= 0 then
        return ""
    end
    return StringUtility.random(length - 1) .. StringUtility.randomCharset[math.random(1, #StringUtility.randomCharset)]
end

--- Split a string
---@param s string
---@param sep string
---@return string[]
function StringUtility.split(s, sep)
    sep = sep or ":"
    local fields = {}
    local pattern = string.format("([^%s]+)", sep)
    s:gsub(
        pattern,
        function(c)
            fields[#fields + 1] = c
        end
    )
    return fields
end

--- Get translated text
---@param key string text key prefixed with "$l10n_"
---@return string text translated text
function StringUtility.parseI18NText(key)
    if key == nil then
        return ""
    end
    return g_i18n:convertText(key)
end
