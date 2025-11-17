-- OLEDAFK Screen: Reduce burn-in while AFK

local OLEDAFK_Frame = CreateFrame("Frame")
local OLEDAFK_Spinning = false
local OLEDAFK_UIHidden = false

-- Settings
local OLEDAFK_DimIntensity = 0.85      -- 0 = no dim, 1 = fully black
local OLEDAFK_FADE_TIME = 3.0          -- Fade-in/out duration for both UI and overlay

--------------------------------------------------
-- OLED DIM OVERLAY FRAME
--------------------------------------------------
local OLEDAFK_Overlay = CreateFrame("Frame", "OLEDAFK_DimOverlay", UIParent)
OLEDAFK_Overlay:SetFrameStrata("BACKGROUND")
OLEDAFK_Overlay:SetAllPoints(UIParent)
OLEDAFK_Overlay.texture = OLEDAFK_Overlay:CreateTexture(nil, "BACKGROUND")
OLEDAFK_Overlay.texture:SetColorTexture(0, 0, 0, 1)
OLEDAFK_Overlay.texture:SetAllPoints()
OLEDAFK_Overlay:SetAlpha(0)
OLEDAFK_Overlay:Hide()

--------------------------------------------------
-- CAMERA SPINNING
--------------------------------------------------
local function OLEDAFK_StartSpinning()
    if not OLEDAFK_Spinning then
        MoveViewRightStart(0.01)
        OLEDAFK_Spinning = true
    end
end

local function OLEDAFK_StopSpinning()
    if OLEDAFK_Spinning then
        MoveViewRightStop()
        OLEDAFK_Spinning = false
    end
end

--------------------------------------------------
-- FADE UI + OVERLAY
--------------------------------------------------
local function OLEDAFK_HideUI()
    if not OLEDAFK_UIHidden then
        -- Fade UI out
        UIFrameFadeOut(UIParent, OLEDAFK_FADE_TIME, 1, 0)
        C_Timer.After(OLEDAFK_FADE_TIME, function()
            UIParent:Hide()
        end)

        -- Keep overlay permanently visible during AFK
        OLEDAFK_Overlay:SetAlpha(0)
        OLEDAFK_Overlay:Show()
        UIFrameFadeIn(OLEDAFK_Overlay, OLEDAFK_FADE_TIME, 0, OLEDAFK_DimIntensity)

        OLEDAFK_UIHidden = true
        print("|cff00ff00OLEDAFK: Idle mode enabled (screen dimming active).|r")
    end
end

local function OLEDAFK_ShowUI()
    if OLEDAFK_UIHidden then
        -- Fade UI back in
        UIParent:Show()
        UIFrameFadeIn(UIParent, OLEDAFK_FADE_TIME, 0, 1)

        -- Fade overlay out and hide when AFK ends
        UIFrameFadeOut(OLEDAFK_Overlay, OLEDAFK_FADE_TIME, OLEDAFK_DimIntensity, 0)
        C_Timer.After(OLEDAFK_FADE_TIME, function()
            OLEDAFK_Overlay:Hide()
        end)

        OLEDAFK_UIHidden = false
        print("|cff00ff00OLEDAFK: Idle mode disabled (screen restored).|r")
    end
end

--------------------------------------------------
-- AFK CHECK
--------------------------------------------------
local function OLEDAFK_IsPlayerAFK()
    return UnitIsAFK("player")
end

--------------------------------------------------
-- EVENT HANDLING
--------------------------------------------------
OLEDAFK_Frame:SetScript("OnEvent", function(self, event, arg1)
    if event == "PLAYER_FLAGS_CHANGED" and arg1 == "player" then
        if OLEDAFK_IsPlayerAFK() then
            OLEDAFK_StartSpinning()
            OLEDAFK_HideUI()
        else
            OLEDAFK_StopSpinning()
            OLEDAFK_ShowUI()
        end
    elseif event == "PLAYER_ENTERING_WORLD" then
        if OLEDAFK_IsPlayerAFK() then
            OLEDAFK_StartSpinning()
            OLEDAFK_HideUI()
        else
            OLEDAFK_StopSpinning()
            OLEDAFK_ShowUI()
        end
    end
end)

-- Register events
OLEDAFK_Frame:RegisterEvent("PLAYER_FLAGS_CHANGED")
OLEDAFK_Frame:RegisterEvent("PLAYER_ENTERING_WORLD")

--------------------------------------------------
-- SLASH COMMANDS
--------------------------------------------------

SLASH_OLEDAFK1 = "/oled"
SlashCmdList["OLEDAFK"] = function(msg)

    msg = msg:lower()

    -- /oled start
    if msg == "start" then
        OLEDAFK_StartSpinning()
        OLEDAFK_HideUI()
        return

    -- /oled stop
    elseif msg == "stop" then
        OLEDAFK_StopSpinning()
        OLEDAFK_ShowUI()
        return

    -- /oled dim 40
    elseif msg:find("dim") then
        local value = tonumber(msg:match("dim%s+(%d+)"))
        if value then
            OLEDAFK_DimIntensity = math.min(1, math.max(0, value / 100))
            print("|cff00ff00OLEDAFK: Dim level set to "..value.."%|r")
        else
            print("Usage: /oled dim 0-100")
        end
        return
    end

    -- Help
    print("|cff00ff00OLED AFK Screen commands:|r")
    print("/oled start - Force AFK dim")
    print("/oled stop - Stop AFK dim")
    print("/oled dim 0-100 - Adjust dim level")
end
