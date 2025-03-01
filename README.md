# Blinker 
```
Lets you cast A spell (default: Blink) by pressing Shift while using the movement keys.

Minimap Button:
  Right-clicking: Change the spell.
  Left-clicking: Toggle on/off.
  Shift: Drag the icon.

Functions:
  Could be used in macro's.
  /script Blinker_SetSpell(spellname) -- returns: true/false
  /script Blinker_Enable()
  /script Blinker_Disable()

Addon for WoW 1.12.1
```
```
Changelog:
    19/2/25 - Bugfix
        Fixed: Enabled/Disabled didn't save due to a bug.

    19/2/25 - Added features
        Button indicator for enabled/disabled, saves state on logout.

    10/2/25 - Bugfix.
        Button is now restored to the position a player drags it too, on login.

    8/2/25 - Added Minimap Button
        Move with shift.
        Left click is toggle on/off
        Right click is select Spell
```

## Required Dependency
1. UnitXP_SP3 [https://github.com/allfoxwy/UnitXP_SP3]

### Installation
1. Open `Code` dropdown menu (slightly to the top right)
2. Select `Download as ZIP`
3. Extract downloaded zip into `/Interface/AddOns`
4. Rename folder to `Blinker` from Blinker-master

### Credits
1. Turtle WoW [https://turtle-wow.org/]
2. Timer-facility [https://github.com/allfoxwy/UnitXP_SP3/wiki/Timer-facility]
3. Threat [https://github.com/allfoxwy/Threat]
4. 1.12.1 API [https://wowpedia.fandom.com/wiki/World_of_Warcraft_API?oldid=352751]
5. Lua 5.0 [https://www.lua.org/manual/5.0/manual.html]
