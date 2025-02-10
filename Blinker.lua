local _debug = false;
local _is_active
local _unitxp_loaded, _timer_id, _timer_button_move_id, _timer_tooltip_id
local _prev_x, _prev_y, _last_spell_cast
local _last_update_time = 0
local TooltipFrame, MinimapFrame, MinimapButtonFrame

local function print_r(t)
    local print_r_cache = {}
    local function sub_print_r(t, indent)
        if (print_r_cache[tostring(t)]) then
            print(indent .. "*" .. tostring(t))
        else
            print_r_cache[tostring(t)] = true
            if type(t) == "table" then
                for i in t do
                    local val = t[i]
                    if (type(val) == "table") then
                        print(indent .. "#[" .. i .. "] => " .. tostring(t) .. " {")
                        sub_print_r(val, indent .. string.rep(" ", string.len(i) + 8))
                        print(indent .. string.rep(" ", string.len(i) + 6) .. "}")
                    elseif (type(val) == "string") then
                        print(indent .. "#[" .. i .. '] => "' .. val .. '"')
                    else
                        print(indent .. "#[" .. i .. "] => " .. tostring(val))
                    end
                end
                for pos, val in pairs(t) do
                    if type(pos) ~= "number" or math.floor(pos) ~= pos or (pos < 1 or pos > tLen) then
                        if (type(val) == "table") then
                            print(indent .. "[" .. pos .. "] => " .. tostring(t) .. " {")
                            sub_print_r(val, indent .. string.rep(" ", string.len(pos) + 8))
                            print(indent .. string.rep(" ", string.len(pos) + 6) .. "}")
                        elseif (type(val) == "string") then
                            print(indent .. "[" .. pos .. '] => "' .. val .. '"')
                        else
                            print(indent .. "[" .. pos .. "] => " .. tostring(val))
                        end
                    end
                end
            else
                print(indent .. tostring(t))
            end
        end
    end

    if (type(t) == "table") then
        print(tostring(t) .. " {")
        sub_print_r(t, "  ")
        print("}")
    else
        sub_print_r(t, "  ")
    end

    print()
end

local function Print(msg)
    if not DEFAULT_CHAT_FRAME or not msg then
        return;
    end

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

local function Status()
    local txt = "";
    local n = UnitXP("timer", "size");
    if _timer_id then
        txt = "id: " .. _timer_id;
    end
    Print("Status:" .. txt .. " Running: #" .. n);
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

function Blinker_UI()
    StaticPopupDialogs["BLINKER_UI_FRAME_DIALOG_SPELL"] = {
        text = "Enter spell name:",
        hasEditBox = true,
        OnAccept = function(self)
            if SpellId(StaticPopup1EditBox:GetText()) then
                Blinker_Settings.spell_name = StaticPopup1EditBox:GetText()
                TooltipFrame_Show(UIParent, "Successfully set to: " .. Blinker_Settings.spell_name)
            else
                TooltipFrame_Show(UIParent, "Error: " .. StaticPopup1EditBox:GetText() .. " does not exist.", 1.0, 0.0, 0.0)
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
    MinimapButtonFrame:EnableMouse(true)
    MinimapButtonFrame:SetMovable(true)
    MinimapButtonFrame:SetUserPlaced(true)
    MinimapButtonFrame:SetPoint("TOPLEFT", Minimap)

    MinimapButtonFrame:SetWidth(24)
    MinimapButtonFrame:SetHeight(24)
    MinimapButtonFrame:SetFrameStrata("MEDIUM")
    MinimapButtonFrame:RegisterForClicks("LeftButtonDown", "RightButtonDown");
    MinimapButtonFrame:SetNormalTexture("Interface\\Icons\\Spell_Arcane_Blink")
    MinimapButtonFrame:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square")
    MinimapButtonFrame:RegisterForDrag("LeftButton")
    MinimapButtonFrame:SetScript("OnDragStart", function() if IsShiftKeyDown() then MinimapButtonFrame:StartMoving() end end)
    MinimapButtonFrame:SetScript("OnDragStop", function() MinimapButtonFrame:StopMovingOrSizing() end)

    MinimapButtonFrame:SetScript("OnEnter", function(self, event)
        local str = ""
        if _timer_id then
            str = str .. "active"
        else
            str = str .. "inactive"
        end

        TooltipFrame_Show(MinimapButtonFrame, str .. ": " .. Blinker_Settings.spell_name)
    end)



    MinimapButtonFrame:SetScript("OnClick", function(self)
        if IsShiftKeyDown() then
            return nil
        end

        if arg1 == "LeftButton" then
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
    if not _unitxp_loaded then
        Print("cannot load. Dependency UnitXP_SP3 not found. [https://github.com/allfoxwy/UnitXP_SP3].");
        return;
    end

    if not Blinker_Settings then
        Blinker_Settings = {
            spell_name = "Blink"
        }
    end

    if _timer_id and _debug then
        Status()
    end

    _last_spell_cast = GetTime()
    _timer_id = UnitXP("timer", "arm", 100, 100, "Blinker");
    if _debug then
        Print("Blinker_Enable: id=" .. _timer_id);
        Status()
    end
    Print("is enabled.")
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
function Blinker_OnLoad()
    this:RegisterEvent("ADDON_LOADED")
    this:RegisterEvent("PLAYER_LOGIN")
    this:RegisterEvent("PLAYER_LOGOUT")
end
function Blinker_OnEvent(event)
    if event == "ADDON_LOADED" and arg1 == "Blinker" then
        if pcall(UnitXP, "nop", "nop") then
            _unitxp_loaded = true
        end
        Blinker_UI()

        this:UnregisterEvent("ADDON_LOADED")
    elseif event == "PLAYER_LOGIN" then
        Blinker_Enable()
    elseif event == "PLAYER_LOGOUT" then
        Blinker_Disable()
    end
end
