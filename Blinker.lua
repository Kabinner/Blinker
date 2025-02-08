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
