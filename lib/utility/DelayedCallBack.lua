--- Royal Utility

---@author Royal Modding
---@version 2.1.1.0
---@date 08/03/17

---@class DelayedCallBack
DelayedCallBack = {}

---@param callback function
---@param callbackObject any
---@return DelayedCallBack
function DelayedCallBack:new(callback, callbackObject)
    if DelayedCallBack_mt == nil then
        DelayedCallBack_mt = Class(DelayedCallBack)
    end

    ---@type DelayedCallBack
    local dcb = setmetatable({}, DelayedCallBack_mt)
    dcb.callBack = callback
    dcb.callbackObject = callbackObject
    dcb.callbackCalled = true
    dcb.delay = 0
    dcb.timer = 0
    dcb.skipOneFrame = false
    return dcb
end

---@param dt number
function DelayedCallBack:update(dt)
    if not self.callbackCalled then
        if not self.skipOneFrame then
            self.timer = self.timer + dt
        end
        if self.timer >= self.delay then
            self:callCallBack()
        end
        if self.skipOneFrame then
            self.timer = self.timer + dt
        end
    end
end

---@param delay number
function DelayedCallBack:call(delay, ...)
    self.callbackCalled = false
    self.callbackParams = {...}
    if delay == nil or delay == 0 then
        self:callCallBack()
    else
        self.delay = delay
        self.timer = 0
    end
end

function DelayedCallBack:callCallBack()
    if self.callbackObject ~= nil then
        self.callBack(self.callbackObject, unpack(self.callbackParams))
    else
        self.callBack(unpack(self.callbackParams))
    end
    self.callbackCalled = true
end
