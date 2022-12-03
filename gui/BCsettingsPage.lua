--=======================================================================================================
-- BetterContracts SCRIPT
--
-- Purpose:		Enhance ingame contracts menu.
-- Author:		Mmtrx
-- Changelog:
--  v1.2.6.0 	30.11.2022	UI for all settings
--=======================================================================================================

BCSettingsPage = {
	CONTROLS = {
		"header",
		"subTitlePrefab",
		"multiTextOptionPrefab",
		"settingsContainer",
		"boxLayout"
	},
}
local BCSettingsPage_mt = Class(BCSettingsPage, TabbedMenuFrameElement)

function BCSettingsPage.new(target, custom_mt)
	local self = TabbedMenuFrameElement.new(target, custom_mt or BCSettingsPage_mt)
	self:registerControls(BCSettingsPage.CONTROLS)
	self.settings = BetterContracts.settings 
	self.settingsBySubtitle = BCSettingsBySubtitle
	return self
end
function generateGuiElements(settingsBySubTitle, parentGuiElement, genericSettingElement, genericSubTitleElement)
	for _, data in ipairs(settingsBySubTitle) do 
		local clonedSubTitleElement = genericSubTitleElement:clone(parentGuiElement)
		clonedSubTitleElement:setText(g_i18n:getText(data.title))
		FocusManager:loadElementFromCustomValues(clonedSubTitleElement)
		for _, setting in ipairs(data.elements) do 
			local cloned = genericSettingElement:clone(parentGuiElement)
			if cloned.labelElement and cloned.labelElement.setText then
				cloned:setLabel(g_i18n:getText(setting.title))
			end
			local toolTipElement = cloned.elements[6]
			if toolTipElement then
				toolTipElement:setText(g_i18n:getText(setting.tooltip))
			end
			FocusManager:loadElementFromCustomValues(cloned)
		end
	end
	parentGuiElement:invalidateLayout()
end
function linkGuiElementsAndSettings(settings, layout)
	local i = 1 	-- index for settings
	for ix, element in ipairs(layout.elements) do 
		if element:isa(MultiTextOptionElement) then 
			settings[i]:setGuiElement(element)
			i = i + 1
		end
	end
end
function BCSettingsPage:onGuiSetupFinished()
	BCSettingsPage:superClass().onGuiSetupFinished(self)
	
	self.subTitlePrefab:unlinkElement()
	FocusManager:removeElement(self.subTitlePrefab)
	self.multiTextOptionPrefab:unlinkElement()
	FocusManager:removeElement(self.multiTextOptionPrefab)

	self.header:setText(g_i18n:getText("bc_settingsPage_title"))	
	generateGuiElements(self.settingsBySubtitle,
		self.boxLayout,self.multiTextOptionPrefab, self.subTitlePrefab)
	self.boxLayout:invalidateLayout()
end
function BCSettingsPage:onFrameOpen()
	BCSettingsPage:superClass().onFrameOpen(self)

	linkGuiElementsAndSettings(self.settings, self.boxLayout)

	FocusManager:loadElementFromCustomValues(self.boxLayout)
	self.boxLayout:invalidateLayout()
	self:setSoundSuppressed(true)
	FocusManager:setFocus(self.boxLayout)
	self:setSoundSuppressed(false)
end
function BCSettingsPage:onFrameClose()
	BCSettingsPage:superClass().onFrameClose(self)
	--unlinkGuiElementsAndSettings(self.settings,self.boxLayout)
	self.boxLayout:invalidateLayout()
end
function BCSettingsPage:updateDisabled(layout)
	if g_gui:getIsGuiVisible() and g_currentMission.inGameMenu.currentPage == self then
		for _, element in ipairs(layout.elements) do 
			if element:isa(MultiTextOptionElement) then 
				local isDisabledFunc = element.bc_setting.isDisabledFunc
				if isDisabledFunc then 
					element:setDisabled(isDisabledFunc())
				end
			end
		end
	end
end
function BCSettingsPage:onClick(state, element)
	local setting = element.bc_setting
	if setting == nil then return end
	setting:setIx(state)
	if TableUtility.contains({"lazyNPC","discountMode","hardMode"}, setting.name) then  
		self:updateDisabled(element.parent)
	end
    SettingsEvent.sendEvent(setting)
end
