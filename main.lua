local MOD_NAME = "Example Curse";
local MOD_VERSION = "1.0";

ExampleCurse = RegisterMod(MOD_NAME, 1);
local mod = ExampleCurse;

mod.settings = {
    weight = 1.0; -- Curse weight
    enabled = true; -- Curse enabled
}

-- start save/load settings
local json = require("json");

local function loadTable(sourceTable, destinationTable)
    for k, _ in pairs(destinationTable) do
        if sourceTable[k] ~= nil then
            local type_s = type(sourceTable[k]);
            local type_d = type(destinationTable[k]);

            if type_s == "table" and type_d == "table" then
                loadTable(sourceTable[k], destinationTable[k]);
            elseif type_s == type_d then
                destinationTable[k] = sourceTable[k];
            end
        end;
    end
end

local function loadSettings()
    if not mod:HasData() then
        return;
    end;

    local jsonString = mod:LoadData();

    local loadData
    if (pcall(function() loadData = json.decode(jsonString) end)) then
        if type(loadData) == "table" then
            loadTable(loadData, mod.settings);
        end
    end
end

if not REPENTOGON then
    mod:AddCallback(ModCallbacks.MC_POST_GAME_STARTED, loadSettings); -- load config data before a run
else
    -- Fixes the bug where config isn't loaded for first floor curse generation.
    -- As far as I'm aware, there isn't a non-repentogon way to fix this bug.
    local loadedSlot = -1;

    function mod:repentogonLoad(saveslot, isslotselected, rawslot)
        if not isslotselected then return end;
        if rawslot == 0 then return end;
        if saveslot == loadedSlot then return end;

        loadedSlot = saveslot;
        loadSettings();
    end

    mod:AddCallback(ModCallbacks.MC_POST_SAVESLOT_LOAD, mod.repentogonLoad);
end

function mod:saveSettings()
    local jsonString = json.encode(mod.settings)
    mod:SaveData(jsonString)

    -- Dequeue the save, since it has been saved now
    mod:RemoveCallback(ModCallbacks.MC_PRE_GAME_EXIT, mod.saveSettings);
end

function mod:queueSave()
    mod:AddCallback(ModCallbacks.MC_PRE_GAME_EXIT, mod.saveSettings);
end
-- end save/load settings

-- start BetterCurseAPI setup
-- Ensure BetterCurseAPI is installed
if not BetterCurseAPI then
    print(MOD_NAME .. ": Failed to load BetterCurseAPI");
    print(MOD_NAME .. ": Mod loading cancelled");
    return;
end;

local CURSE_NAME = "Example Curse"; -- Name should be exactly the same as the one in curses.xml
local CURSE_WEIGHT = function () return mod.settings.weight end;
local IS_ALLOWED = function () return mod.settings.enabled end;

local ICON_SPRITE = Sprite();
ICON_SPRITE:Load("gfx/ui/example_curse_icon.anm2", true);
local CURSE_ICON = { ICON_SPRITE, "curses", 0 };

mod.CURSE_ID = BetterCurseAPI:registerCurse(CURSE_NAME, CURSE_WEIGHT, IS_ALLOWED, CURSE_ICON);

if mod.CURSE_ID == -1 then
    print(MOD_NAME .. ": Unknown error while registering \"" .. CURSE_NAME .. "\"")
    return;
end

-- start ModConfigMenu setup
if ModConfigMenu then
    local paramsTable = {
        enabled_current_setting = function () return mod.settings.enabled end;
        on_change_enabled = function (b)
            mod.settings.enabled = b;
            mod:queueSave();
        end;
        default_enabled = true;
        on_weight_change = function (n)
            mod.settings.weight = n;
            mod:queueSave();
        end;
        default_weight = 1.0;

        text = "Added by '" .. MOD_NAME .. "'\n (Version " .. MOD_VERSION .. ")";
    }

    BetterCurseAPI:addCurseConfig(mod.CURSE_ID, paramsTable);
end
-- end ModConfigMenu setup
-- end BetterCurseAPI setup

-- start Curse Behavior
local function onNewRoom()
    -- Only apply if curse is active
	if BetterCurseAPI:curseIsActive(mod.CURSE_ID) then
        Game():GetHUD():ShowFortuneText("Example Curse Effect");
    end
end

mod:AddCallback(ModCallbacks.MC_POST_NEW_ROOM, onNewRoom);
-- end Curse Behavior
