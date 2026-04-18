-- Server boot: prints the multiscript-style banner showing which modules are
-- enabled along with a one-line summary for each. Module logic itself lives
-- in server/modules/*.lua.

-- Order modules appear in the banner.
local MODULE_ORDER = { 'display', 'citycars' }

-- Per-module info string generators. Computed from Config so this works even
-- for modules that have no server-side runtime (e.g. display is client only).
local INFO = {
    display = function()
        if not Config.Display then return 'misconfigured' end
        return ('%d vehicle(s), %.0fm spawn radius'):format(
            #Config.Display.Vehicles, Config.Display.SpawnDistance)
    end,
    citycars = function()
        if not Config.CityCars then return 'misconfigured' end
        local total = 0
        for _, v in ipairs(Config.CityCars.Vehicles) do
            total = total + (v.maxActive or 0)
        end
        local mins = math.floor(Config.CityCars.RotationInterval / 60000)
        return ('%d model(s), %d slot(s) across %d location(s), rotates every %dm'):format(
            #Config.CityCars.Vehicles, total, #Config.CityCars.Locations, mins)
    end,
}

CreateThread(function()
    -- Tiny delay so module files have finished loading before we summarise.
    Wait(100)

    DOA.Log.banner()

    local active, total = 0, 0
    for _, name in ipairs(MODULE_ORDER) do
        total = total + 1
        local enabled = Config.Modules and Config.Modules[name] == true
        if enabled then
            active = active + 1
            local info = INFO[name] and INFO[name]() or 'active'
            DOA.Log.module(name, true, info)
        else
            DOA.Log.module(name, false)
        end
    end

    DOA.Log.footer(active, total)
end)
