local _debug = false;
local _unitxp_loaded, _timer_id, _timer_button_move_id, _timer_tooltip_id
local _prev_x, _prev_y, _last_spell_cast
local _last_update_time = 0
local TooltipFrame, MinimapFrame, MinimapButtonFrame

local function Print()
    if not DEFAULT_CHAT_FRAME or not msg then
        return;
    end
    if type(msg) == 'table' then return print_r(msg) end
    DEFAULT_CHAT_FRAME:AddMessage("Blinker " .. msg);
end

local function SpellId(spellname)
    local id = 1;
    for i = 1, GetNumSpellTabs() do
        local _, _, _, numSpells = GetSpellTabInfo(i);
        for j = 1, numSpells do
            local _spell_name = GetSpellName(id, BOOKTYPE_SPELL);
            if _spell_name == spellname then
                return id;
            end
            id = id + 1;
        end
    end
    return nil;
end
local function SpellReady(spellname)
    local id = SpellId(spellname);
    if not id then
        return nil;
    end

    local start, duration = GetSpellCooldown(id, 0);
    if start == 0 and duration == 0 and _last_spell_cast + 1 <= GetTime() then
        return true;
    end
end

local function IsMoving(x, y)
    if not _prev_x or not _prev_y then
        _prev_x, _prev_y = GetPlayerMapPosition("player");
    end

    if _prev_x > x or _prev_x < x or _prev_y > y or _prev_y < y then
        _prev_x = x;
        _prev_y = y;
        return true;
    end

    return false;
end

function TooltipFrame_Show(parent, text, r, g, b)
    if _timer_tooltip_id then
        UnitXP("timer", "disarm", _timer_tooltip_id)
        _timer_tooltip_id = nil
    end

    anchor = "ANCHOR_CURSOR"
    timeout = 3000
    if parent ~= UIParent then
        anchor = "ANCHOR_LEFT"
        timeout = 1000
    end

    TooltipFrame:SetOwner(parent, anchor, 0, 0)
    TooltipFrame:SetText("[Blinker] " .. text, r, g, b)
    TooltipFrame:Show()

    _timer_tooltip_id = UnitXP("timer", "arm", timeout, 0, "TooltipFrame_Hide");
end
function TooltipFrame_Hide()
    TooltipFrame:Hide()
end
function MinimapButtonFrame_OnMove()
    if IsShiftKeyDown() then
        return
    end

    MinimapButtonFrame:StopMovingOrSizing()
    UnitXP("timer", "disarm", _timer_button_move_id)
    _timer_button_move_id = nil
end
function Blinker_UI()
    StaticPopupDialogs["BLINKER_UI_FRAME_DIALOG_SPELL"] = {
        text = "Enter spell name:",
        hasEditBox = true,
        OnAccept = function()
            if SpellId(StaticPopup1EditBox:GetText()) then
                Blinker_Settings.spell_name = StaticPopup1EditBox:GetText()
                TooltipFrame_Show(UIParent, "Successfully set to: " .. Blinker_Settings.spell_name)
            else
                TooltipFrame_Show(UIParent, "Error: " .. StaticPopup1EditBox:GetText() .. " does not exist.", 1.0, 0.0,
                    0.0)
            end
        end,
        OnCancel = function()
            StaticPopup_Hide("BLINKER_UI_FRAME_DIALOG_SPELL")
        end,
        button1 = ACCEPT,
        button2 = CANCEL,
        maxLetters = 50,
        timeout = 0,
        whileDead = true,
        hideOnEscape = true
    }

    TooltipFrame = CreateFrame("GameTooltip", "BLINKER_UI_FRAME_TOOLTIP", UIParent, "GameTooltipTemplate")

    MinimapButtonFrame = CreateFrame("Button", "BLINKER_UI_FRAME_MINIMAP_BUTTON", Minimap)
    MinimapButtonFrame:SetWidth(24)
    MinimapButtonFrame:SetHeight(24)
    MinimapButtonFrame:SetFrameStrata("MEDIUM")
    MinimapButtonFrame:SetMovable(true)
    MinimapButtonFrame:SetPoint("TOPLEFT", Minimap, "TOPLEFT", 0, 0)
    MinimapButtonFrame:EnableMouse(true)
    MinimapButtonFrame:RegisterForClicks("LeftButtonDown", "RightButtonDown");
    MinimapButtonFrame:SetNormalTexture("Interface\\Icons\\Spell_Arcane_Blink")
    MinimapButtonFrame:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square")
    MinimapButtonFrame:SetScript("OnEnter", function(self, event)
        local status
        if _timer_id then
            status = "active"
        else
            status = "inactive"
        end

        TooltipFrame_Show(MinimapButtonFrame, status .. ": " .. Blinker_Settings.spell_name)
    end)

    MinimapButtonFrame:SetScript("OnClick", function(self)
        if IsShiftKeyDown() then
            if _timer_button_move_id then
                UnitXP("timer", "disarm", _timer_button_move_id)
                _timer_button_move_id = nil
            end
            this:StartMoving()
            _timer_button_move_id = UnitXP("timer", "arm", 200, 200, "MinimapButtonFrame_OnMove");

        elseif arg1 == "LeftButton" then
            if _timer_id then
                Blinker_Disable()
                TooltipFrame_Show(MinimapButtonFrame, Blinker_Settings.spell_name .. " is disabled.")
            else
                Blinker_Enable()
                TooltipFrame_Show(MinimapButtonFrame, Blinker_Settings.spell_name .. " is enabled.")
            end
        elseif arg1 == "RightButton" then
            StaticPopup_Show("BLINKER_UI_FRAME_DIALOG_SPELL")
        end
    end)
end

function Blinker()
    local x, y = GetPlayerMapPosition("player");
    if IsMoving(x, y) and SpellReady(Blinker_Settings.spell_name) and IsShiftKeyDown() then
        CastSpellByName(Blinker_Settings.spell_name);
        _last_spell_cast = GetTime()
    end
end

function Blinker_Enable()
end
function Blinker_Disable()
    if not _unitxp_loaded then
        if _debug then
            Print("Error: UnitXP is not loaded.");
        end
        return;
    end
    if _timer_id then
        if _debug then
            Print("Blinker_Disabled: id=" .. _timer_id)
            Status()
        end
        UnitXP("timer", "disarm", _timer_id)
        _timer_id = nil;
    end
    Print("is disabled.")
end


UnitXPUtil = {
    loaded = false,
    timers = {}
}
function UnitXPUtil:new()
    if pcall(UnitXP, "nop", "nop") then
        self.loaded = true
    end

    return setmetatable(UnitXPUtil, { __index = UnitXPUtil })
end
function UnitXPUtil:timer(id, ms)
    if self.timers[id] then
        UnitXP("timer", "disarm", id)
    end
    self.timers[id] = UnitXP("timer", "arm", ms, ms, id);
    return self.timers[id]
end
function UnitXPUtil:disable(id)
    if not self.timers[id] then
        Printf()
    end
    UnitXP("timer", "disarm", self.timers[id])
    self.timers[id] = nil
end

Blinker = {
    UnitXP = UnitXPUtil:new(),
    Frame = nil,
    enabled = false, debug = false,
    prev_x = nil, prev_y = nil, 
    last_spell_cast = GetTime(),

    TooltipFrame = nil,
    MinimapFrame = nil,
    MinimapButtonFrame = nil,
}

function Blinker:new()
    return setmetatable(Blinker, { __index = Blinker })
end
function Blinker:init()
    self.Frame = CreateFrame("Frame", "BLINKER_UI_FRAME")
    self.Frame:RegisterEvent("ADDON_LOADED")
    self.Frame:RegisterEvent("PLAYER_LOGIN")
    self.Frame:RegisterEvent("PLAYER_LOGOUT")
    self.Frame:SetScript('OnEvent', function ()
        if event == "ADDON_LOADED" and arg1 == "Blinker" then
            if not Blinker_Settings then
                Blinker_Settings = {
                    spell_name = "Blink"
                }
            end
            this:UnregisterEvent("ADDON_LOADED")
        elseif event == "PLAYER_LOGIN" then
            self:enable()
        elseif event == "PLAYER_LOGOUT" then
            self:disable()
        end
    end)
end
function Blinker:enable()
    if not self.UnitXP.loaded then
        Print("cannot load. Dependency UnitXP_SP3 not found. [https://github.com/allfoxwy/UnitXP_SP3].");
        return;
    end

    self.UnitXP:timer("Blinker", 100);
    Print("is enabled.")
end
function Blinker:disable()
    self.UnitXP:disable("Blinker")
    Print('Disabled.')
end

Blinker = Blinker:new()
Blinker:init()
