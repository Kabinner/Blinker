-- Simpler Addon lib

Addon = {
    Frame = nil
}
function Addon:new(class)
    self.Frame = CreateFrame("Frame")
    self.Frame:RegisterEvent("ADDON_LOADED")
    self.Frame:RegisterEvent("PLAYER_LOGIN")
    self.Frame:RegisterEvent("PLAYER_LOGOUT")
    self.Frame:SetScript('OnEvent', function ()
        if event == "ADDON_LOADED" and arg1 == "Blinker" then
            super.onLoad()
            this:UnregisterEvent("ADDON_LOADED")
        elseif event == "PLAYER_LOGIN" then
            super.onLogin()
        elseif event == "PLAYER_LOGOUT" then
            super.onLogout()
        end
    end)

    setmetatable(Addon, { __index = Addon })
    return class:new()
end

-- Implement Addon
Timer = {
    timers = {}
}
function Timer:new()
    return setmetatable(Timer, { __index = Timer })
end
function Timer:add(id, ms)
    if self.timers[id] then
        UnitXP("timer", "disarm", id)
    end
    self.timers[id] = UnitXP("timer", "arm", ms, ms, id);
    return self.timers[id]
end
function UnitXPUtil:del(id)
    if not self.timers[id] then
        Printf()
    end
    UnitXP("timer", "disarm", self.timers[id])
    self.timers[id] = nil
end

Blinker = {
    Frame = nil,
    UnitXP = false, debug = false,
    prev_x = nil, prev_y = nil, 
    last_spell_cast = GetTime(),

    TooltipFrame = nil,
    MinimapFrame = nil,
    MinimapButtonFrame = nil,
}

function Blinker:new()
    return setmetatable(Blinker, { __index = Blinker })
end

function Blinker:load()
    if not pcall(UnitXP, "nop", "nop") then
        self.UnitXP = false
    end   
    if not Blinker_Settings then
        Blinker_Settings = {
            spell_name = "Blink"
        }
    end
end

function Blinker:enable()
    if not self.UnitXP then
        Print("cannot load. Dependency UnitXP_SP3 not found. [https://github.com/allfoxwy/UnitXP_SP3].");
        return;
    end

    timer:add("Blinker", 100);
    Print("is enabled.")
end

function Blinker:disable()
    timer:del("Blinker")
    Print('Disabled.')
end

-- Initialize Addon

timer = Timer:new()
blinker = new Addon(Blinker)
blinker:on("ADDON_LOADED", self:load)
blinker:on("PLAYER_LOGIN", self:enable)
blinker:on("PLAYER_LOGOUT", self:disable)
