local _unitxp_loaded, _timer_id, _prev_x, _prev_y, _last_spell_cast, _last_update_time;
local _debug = false;

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
            local spellName = GetSpellName(id, BOOKTYPE_SPELL);
            if (spellName == spellname) then
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
    if _unitxp_loaded then
        local txt = ""
        local n = UnitXP("timer", "size");
        if _timer_id then
            txt = "id: " .. _timer_id;
        end
        Print("Status:" .. txt .. " Running: #" .. n);
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

function Blinker()
    local x, y = GetPlayerMapPosition("player");
    if isMoving(x, y) and SpellReady("Blink") and IsShiftKeyDown() then
        CastSpellByName("Blink");
    end
end

function Blinker_Enable()
    if _timer_id and _debug then
        Status()
        return;
    end

    if _unitxp_loaded then
        _timer_id = UnitXP("timer", "arm", 100, 100, "Blinker");
        if _debug then
            Print("Blinker_Enable: id=" .. _timer_id);
            Status()
        end
    else
        BlinkerFrame:SetScript("OnUpdate", function ()
            -- Limit frequency to 20Hz. Slow computer might need it
            if (GetTime() < _last_update_time + (1 / 20)) then
                return;
            else
                _last_update_time = GetTime();
                Blinker()
            end        
        end);
    end
    Print("is enabled.")
end
function Blinker_Disable()
    if _timer_id then
        Print("Blinker_Disabled: id=" .. _timer_id);
        UnitXP("timer", "disarm", _timer_id);
        _timer_id = nil;
    end
    if _debug then
        Status()
    end
    Print("is disabled.")
end
function Blinker_OnLoad()
    this:RegisterEvent("ADDON_LOADED")
    this:RegisterEvent("PLAYER_LOGIN");
    this:RegisterEvent("PLAYER_LOGOUT");
end
function Blinker_OnEvent(event)
    if event == "ADDON_LOADED" and arg1 == "Blinker" then
        if pcall(UnitXP, "nop", "nop") then
            _unitxp_loaded = true;
        end
        this:UnregisterEvent("ADDON_LOADED");
    elseif event == "PLAYER_LOGIN" then
        if not _unitxp_loaded then
            if _debug then
                Print("Error: UnitXP is not loaded.");
            end
            return;
        end

        _last_spell_cast = GetTime();
        Blinker_Enable()
    elseif event == "PLAYER_LOGOUT" then
        Blinker_Disable()
    end
end
