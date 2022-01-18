--- Royal Utility

---@author Royal Modding
---@version 2.1.1.0
---@date 17/02/2017

---@class FadeEffect
FadeEffect = {}

FadeEffect.STATES = {}
FadeEffect.STATES.FADEIN = 1
FadeEffect.STATES.STAY = 2
FadeEffect.STATES.FADEOUT = 3
FadeEffect.STATES.IDLE = 4

FadeEffect.ALIGNS = {}
FadeEffect.ALIGNS.LEFT = 0
FadeEffect.ALIGNS.TOP = 0
FadeEffect.ALIGNS.CENTER = 1
FadeEffect.ALIGNS.RIGHT = 2
FadeEffect.ALIGNS.BOTTOM = 2

---@class FadeEffectSettings
FadeEffect.defaultSettings = {
    color = {
        r = 1,
        g = 1,
        b = 1
    },
    position = {
        x = 0.5,
        y = 0.5
    },
    align = {
        x = FadeEffect.ALIGNS.CENTER,
        y = FadeEffect.ALIGNS.CENTER
    },
    bold = true,
    size = 0.025,
    text = "Fade Effect",
    shadow = false,
    shadowPosition = {
        x = 0,
        y = 0
    },
    initialAlpha = 0,
    statesTime = {1, 1, 1},
    statesAlpha = {1, 1, 0},
    loop = false
}

---@param settings FadeEffectSettings
---@return FadeEffect
function FadeEffect:new(settings)
    if FadeEffect_mt == nil then
        FadeEffect_mt = Class(FadeEffect)
    end

    ---@type FadeEffect
    local fe = setmetatable({}, FadeEffect_mt)

    ---@type FadeEffectSettings
    fe.settings = {}

    for k, v in pairs(self.defaultSettings) do
        fe.settings[k] = v
    end

    for k, v in pairs(settings) do
        fe.settings[k] = v
    end

    fe:play(fe.settings.text)
    fe.state = FadeEffect.STATES.IDLE

    return fe
end

function FadeEffect:alignText()
    self.settings.position.alignedX = self.settings.position.x
    self.settings.position.alignedY = self.settings.position.y
    if self.settings.align.x == FadeEffect.ALIGNS.CENTER then
        self.settings.position.alignedX = self.settings.position.x - (getTextWidth(self.settings.size, self.settings.text) / 2)
    end
    if self.settings.align.x == FadeEffect.ALIGNS.RIGHT then
        self.settings.position.alignedX = self.settings.position.x - getTextWidth(self.settings.size, self.settings.text)
    end
    if self.settings.align.y == FadeEffect.ALIGNS.CENTER then
        self.settings.position.alignedY = self.settings.position.y - (getTextHeight(self.settings.size, self.settings.text) / 2)
    end
    if self.settings.align.y == FadeEffect.ALIGNS.TOP then
        self.settings.position.alignedY = self.settings.position.y - getTextHeight(self.settings.size, self.settings.text)
    end
end

---@param text string
function FadeEffect:setText(text)
    self.settings.text = text
    self:alignText()
end

---@param text string
function FadeEffect:play(text)
    if text ~= nil then
        self.settings.text = text
        self:alignText()
    end
    self.alpha = self.settings.initialAlpha
    self.initialAlpha = self.settings.initialAlpha
    self.state = FadeEffect.STATES.FADEIN
    self.tmpStateTime = 0
end

function FadeEffect:stop()
    self.state = FadeEffect.STATES.IDLE
end

function FadeEffect:draw()
    if self.state ~= FadeEffect.STATES.IDLE then
        setTextBold(self.settings.bold)
        if self.settings.shadow then
            setTextColor(0, 0, 0, self.alpha)
            renderText(self.settings.position.alignedX + self.settings.shadowPosition.x, self.settings.position.alignedY - self.settings.shadowPosition.y, self.settings.size, self.settings.text)
        end
        setTextColor(self.settings.color.r, self.settings.color.g, self.settings.color.b, self.alpha)
        renderText(self.settings.position.alignedX, self.settings.position.alignedY, self.settings.size, self.settings.text)
        setTextBold(false)
        setTextColor(1, 1, 1, 1)
    end
end

---@param dt number
function FadeEffect:update(dt)
    if self.state ~= FadeEffect.STATES.IDLE then
        local stateTime = self.settings.statesTime[self.state] * 1000
        if (self.tmpStateTime + dt) >= stateTime then
            self.tmpStateTime = (self.tmpStateTime + dt - stateTime)
            self.alpha = self.settings.statesAlpha[self.state]
            self.initialAlpha = self.alpha
            self.state = self.state + 1
            if self.settings.loop and self.state == FadeEffect.STATES.IDLE then
                self.state = 1
            end
        else
            self.tmpStateTime = self.tmpStateTime + dt
        end
        if self.initialAlpha == self.settings.statesAlpha[self.state] then
            self.alpha = self.settings.statesAlpha[self.state]
        else
            self.alpha = math.abs(self.initialAlpha - (1 / stateTime) * self.tmpStateTime)
        end
    end
end
