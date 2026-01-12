local OLEDAFK_Frame = CreateFrame("Frame")
local OLEDAFK_Active = false
local OLEDAFK_FADE_TIME = 2.0
local AFK_StartTime = 0

-- 1. Configuration & Settings Initialization
local function InitializeSettings()
    if not OLEDAFK_Settings then 
        OLEDAFK_Settings = { 
            speed = 0.01,
            dimIntensity = 0.95 
        } 
    end
    if not OLEDAFK_Stats then 
        OLEDAFK_Stats = { totalTime = 0 } 
    end
end

-- 2. UI Overlay
local OLEDAFK_Overlay = CreateFrame("Frame", "OLEDAFK_DimOverlay", UIParent)
OLEDAFK_Overlay:SetFrameStrata("TOOLTIP")
OLEDAFK_Overlay:SetAllPoints(UIParent)
OLEDAFK_Overlay.texture = OLEDAFK_Overlay:CreateTexture(nil, "BACKGROUND")
OLEDAFK_Overlay.texture:SetColorTexture(0, 0, 0, 1)
OLEDAFK_Overlay.texture:SetAllPoints()
OLEDAFK_Overlay:SetAlpha(0)
OLEDAFK_Overlay:Hide()

local function FormatTime(seconds)
    local h = math.floor(seconds / 3600)
    local m = math.floor((seconds % 3600) / 60)
    local s = math.floor(seconds % 60)
    if h > 0 then return string.format("%dh %dm %ds", h, m, s)
    elseif m > 0 then return string.format("%dm %ds", m, s)
    else return string.format("%ds", s) end
end

-- 3. Core Functions
local function StartAFKMode()
    if OLEDAFK_Active then return end
    OLEDAFK_Active = true
    AFK_StartTime = GetTime()
    MoveViewRightStart(OLEDAFK_Settings.speed)
    OLEDAFK_Overlay:Show()
    UIFrameFadeIn(OLEDAFK_Overlay, OLEDAFK_FADE_TIME, 0, OLEDAFK_Settings.dimIntensity)
end

local function StopAFKMode()
    if not OLEDAFK_Active then return end
    OLEDAFK_Active = false
    
    local duration = GetTime() - AFK_StartTime
    OLEDAFK_Stats.totalTime = OLEDAFK_Stats.totalTime + duration
    
    local playerName = UnitName("player")
    local _, classFile = UnitClass("player")
    local classColor = C_ClassColor.GetClassColor(classFile):GenerateHexColor()
    
    MoveViewRightStop()
    UIFrameFadeOut(OLEDAFK_Overlay, OLEDAFK_FADE_TIME, OLEDAFK_Settings.dimIntensity, 0)
    C_Timer.After(OLEDAFK_FADE_TIME, function() 
        if not OLEDAFK_Active then OLEDAFK_Overlay:Hide() end 
    end)
    
    print("|cff00ff00OLEDAFKScreen: Welcome back, |r|c" .. classColor .. playerName .. "|r|cff00ff00! You were AFK for " .. FormatTime(duration) .. ".|r")
end

-- 4. THE UI MENU
local optionsPanel = CreateFrame("Frame", "OLEDAFK_OptionsPanel", UIParent)
optionsPanel.name = "OLED AFK Screen"

local function CreateOptions()
    local title = optionsPanel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 16, -16)
    title:SetText("OLED AFK Screen Settings")

    -- Author Tag in Menu
    local authorText = optionsPanel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    authorText:SetPoint("TOPLEFT", 18, -35)
    authorText:SetText("Created by |cffffff00ArNz8o8|r")

    -- SLIDER 1: Speed
    local speedSlider = CreateFrame("Slider", "OLEDAFK_SpeedSlider", optionsPanel, "OptionsSliderTemplate")
    speedSlider:SetPoint("TOPLEFT", 30, -85)
    speedSlider:SetMinMaxValues(0.001, 0.1)
    speedSlider:SetValueStep(0.001)
    speedSlider:SetObeyStepOnDrag(true)
    speedSlider:SetWidth(220)
    _G[speedSlider:GetName() .. 'Low']:SetText('Slow')
    _G[speedSlider:GetName() .. 'High']:SetText('Fast')
    
    speedSlider:SetScript("OnValueChanged", function(self, value)
        OLEDAFK_Settings.speed = value
        _G[self:GetName() .. 'Text']:SetText(string.format("Rotation Speed: %.3f", value))
    end)

    -- SLIDER 2: Dim Intensity
    local dimSlider = CreateFrame("Slider", "OLEDAFK_DimSlider", optionsPanel, "OptionsSliderTemplate")
    dimSlider:SetPoint("TOPLEFT", 30, -145)
    dimSlider:SetMinMaxValues(0.1, 1.0)
    dimSlider:SetValueStep(0.05)
    dimSlider:SetObeyStepOnDrag(true)
    dimSlider:SetWidth(220)
    _G[dimSlider:GetName() .. 'Low']:SetText('Light')
    _G[dimSlider:GetName() .. 'High']:SetText('Pure Black')

    dimSlider:SetScript("OnValueChanged", function(self, value)
        OLEDAFK_Settings.dimIntensity = value
        _G[self:GetName() .. 'Text']:SetText(string.format("Screen Dimming: %d%%", value * 100))
        if not OLEDAFK_Active then
            OLEDAFK_Overlay:Show()
            OLEDAFK_Overlay:SetAlpha(value)
            if self.timer then self.timer:Cancel() end
            self.timer = C_Timer.NewTimer(1, function() 
                if not OLEDAFK_Active then OLEDAFK_Overlay:Hide() end 
            end)
        end
    end)

    -- Reset to Default Button
    local resetButton = CreateFrame("Button", nil, optionsPanel, "UIPanelButtonTemplate")
    resetButton:SetPoint("TOPLEFT", 30, -190)
    resetButton:SetSize(120, 25)
    resetButton:SetText("Reset to Default")
    resetButton:SetScript("OnClick", function()
        OLEDAFK_Settings.speed = 0.01
        OLEDAFK_Settings.dimIntensity = 0.95
        speedSlider:SetValue(0.01)
        dimSlider:SetValue(0.95)
        print("|cff00ff00OLEDAFKScreen: Settings reset to default values.|r")
    end)

    -- Statistics
    local statsTitle = optionsPanel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    statsTitle:SetPoint("TOPLEFT", 16, -235)
    statsTitle:SetText("Statistics")

    local statsText = optionsPanel:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    statsText:SetPoint("TOPLEFT", 16, -255)
    
    optionsPanel:SetScript("OnShow", function()
        statsText:SetText("Total Protected Time: " .. FormatTime(OLEDAFK_Stats.totalTime))
        speedSlider:SetValue(OLEDAFK_Settings.speed)
        dimSlider:SetValue(OLEDAFK_Settings.dimIntensity)
        _G[speedSlider:GetName() .. 'Text']:SetText(string.format("Rotation Speed: %.3f", OLEDAFK_Settings.speed))
        _G[dimSlider:GetName() .. 'Text']:SetText(string.format("Screen Dimming: %d%%", OLEDAFK_Settings.dimIntensity * 100))
    end)

    local category = Settings.RegisterCanvasLayoutCategory(optionsPanel, optionsPanel.name)
    Settings.RegisterAddOnCategory(category)
end

-- 5. Event Handling
OLEDAFK_Frame:RegisterEvent("PLAYER_FLAGS_CHANGED")
OLEDAFK_Frame:RegisterEvent("PLAYER_REGEN_DISABLED")
OLEDAFK_Frame:RegisterEvent("ADDON_LOADED")

OLEDAFK_Frame:SetScript("OnEvent", function(self, event, arg1)
    if event == "ADDON_LOADED" and arg1 == "OLEDAFKScreen" then
        InitializeSettings()
        CreateOptions()
        -- Updated Login Message with Author
        print("|cff00ff00OLEDAFKScreen by |r|cffffff00ArNz8o8|r|cff00ff00 loaded. Type |r|cffffff00/oled|r|cff00ff00 for settings.|r")
    elseif event == "PLAYER_REGEN_DISABLED" then
        StopAFKMode()
    elseif event == "PLAYER_FLAGS_CHANGED" and arg1 == "player" then
        if UnitIsAFK("player") then StartAFKMode() else StopAFKMode() end
    end
end)

-- 6. Slash Command
SLASH_OLEDAFK1 = "/oled"
SlashCmdList["OLEDAFK"] = function()
    Settings.OpenToCategory(optionsPanel.name)
end
