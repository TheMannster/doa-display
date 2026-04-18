-- City cars module (server).
--
-- Spawns a configurable amount of each car model at random parking spots
-- around the city to simulate stealable "hot cars" - normal unlocked
-- vehicles with blank plates that any player can jump in and drive off.
--
-- Behaviour:
--   * Every Config.CityCars.RotationInterval ms the city is rotated:
--       - cars that nobody touched are deleted
--       - cars that were sat in or driven away (>StolenDistance) are
--         released - we forget about them and leave them in the world for
--         AdvancedParking to take ownership of
--       - the full per-model maxActive set is then spawned again at fresh
--         random unused locations
--   * That means if maxActive = 1 for a model and a player steals it,
--     no new one appears until the next rotation tick - and at that tick
--     the slot is refilled at a new random spot.
--   * Released cars are NEVER deleted by us.
--
-- Server-side spawning means every player sees the same cars in the same
-- spots (requires OneSync).
--
-- Integration with kiminaze AdvancedParking:
--   AdvancedParking persists any vehicle a player has interacted with.
--   The moment a player sits in one of our cars we mark it as released and
--   never touch it again - so we will never despawn it out from under the
--   parking system.

if not Config.Modules or not Config.Modules.citycars then return end
if not Config.CityCars then
    TM.Log.warn('citycars', 'module enabled but Config.CityCars is missing')
    return
end

-- Each entry: { entity = vehHandle, loc = vec4 }
local activeVehicles = {}

-- Released cars we're watching for abandoned-cleanup (only populated when
-- Config.CityCars.PersistReleasedCars is false). Each entry:
--   { entity = vehHandle, abandonedSince = nil | timestamp(ms) }
-- abandonedSince is set the first tick we observe no player nearby and
-- cleared the moment a player gets close again.
local releasedVehicles = {}

-- How close a player has to be to a released car to keep it "alive".
-- Roughly outside normal client render range so we don't yank cars out from
-- under players who can still see them.
local ABANDONED_NEARBY_DISTANCE = 150.0

-- How often the abandoned-cleanup watchdog wakes up.
local ABANDONED_CHECK_INTERVAL_MS = 60 * 1000

local function locationKey(loc)
    return ('%.2f|%.2f|%.2f'):format(loc.x, loc.y, loc.z)
end

local function shuffledLocations()
    local pool = {}
    for i = 1, #Config.CityCars.Locations do
        pool[i] = Config.CityCars.Locations[i]
    end
    -- Fisher-Yates shuffle
    for i = #pool, 2, -1 do
        local j = math.random(i)
        pool[i], pool[j] = pool[j], pool[i]
    end
    return pool
end

-- Returns true if any seat is occupied or the car has moved past
-- StolenDistance from its spawn point.
local function isTouched(entry)
    if not DoesEntityExist(entry.entity) then return true end

    for seat = -1, 4 do
        local ped = GetPedInVehicleSeat(entry.entity, seat)
        if ped and ped ~= 0 then return true end
    end

    local pos    = GetEntityCoords(entry.entity)
    local origin = vector3(entry.loc.x, entry.loc.y, entry.loc.z)
    local maxDist = Config.CityCars.StolenDistance or 10.0
    if #(pos - origin) > maxDist then return true end

    return false
end

local function spawnCar(model, loc)
    local hash = (type(model) == 'string') and joaat(model) or model
    local veh = CreateVehicle(hash, loc.x, loc.y, loc.z, loc.w or 0.0, true, false)
    if not veh or veh == 0 then
        TM.Log.warn('citycars', ('failed to spawn %s at %s'):format(tostring(model), locationKey(loc)))
        return nil
    end

    -- 8 spaces = blank-looking plate (GTA plates are max 8 chars).
    if Config.CityCars.BlankPlates then
        SetVehicleNumberPlateText(veh, '        ')
    end

    return veh
end

-- Despawn untouched entries, release touched ones (untrack but keep alive).
-- If PersistReleasedCars is false, released cars are added to releasedVehicles
-- so the abandoned-cleanup watchdog can deal with them later.
local function despawnUntouched()
    local despawned, released = 0, 0
    local watchReleased = not Config.CityCars.PersistReleasedCars

    for _, entry in ipairs(activeVehicles) do
        if not DoesEntityExist(entry.entity) then
            -- already gone
        elseif isTouched(entry) then
            released = released + 1
            if watchReleased then
                releasedVehicles[#releasedVehicles + 1] = {
                    entity = entry.entity,
                    abandonedSince = nil,
                }
            end
        else
            DeleteEntity(entry.entity)
            despawned = despawned + 1
        end
    end
    activeVehicles = {}
    return despawned, released
end

-- Wipe everything we still own (resource stop). Released cars are no longer
-- in activeVehicles so they're never touched here.
local function despawnAll()
    for _, entry in ipairs(activeVehicles) do
        if DoesEntityExist(entry.entity) then
            DeleteEntity(entry.entity)
        end
    end
    activeVehicles = {}
end

-- Full city respawn at fresh random spots. Always tops every model back up
-- to its maxActive count.
local function spawnRound()
    local _, released = despawnUntouched()

    local locations = shuffledLocations()
    local nextLoc = 1

    for _, vehCfg in ipairs(Config.CityCars.Vehicles) do
        for _ = 1, (vehCfg.maxActive or 0) do
            local loc = locations[nextLoc]
            if not loc then
                TM.Log.warn('citycars',
                    'ran out of unique locations - add more entries to Config.CityCars.Locations')
                return released
            end
            nextLoc = nextLoc + 1

            local veh = spawnCar(vehCfg.model, loc)
            if veh then
                activeVehicles[#activeVehicles + 1] = { entity = veh, loc = loc }
            end
        end
    end

    return released
end

-- Rotation timer - the only thing that spawns cars.
CreateThread(function()
    Wait(2000)   -- give the resource time to fully come up
    while true do
        local released = spawnRound()
        TM.Log.info('citycars',
            ('rotated - ^2%d^7 active, ^3%d^7 released this round, next rotation in ^2%dm^7'):format(
                #activeVehicles,
                released,
                math.floor(Config.CityCars.RotationInterval / 60000)))
        Wait(Config.CityCars.RotationInterval)
    end
end)

-- Returns true if any connected player is within ABANDONED_NEARBY_DISTANCE
-- of the given coords. Used by the watchdog below to decide whether a
-- released car still has someone around it.
local function anyPlayerNear(coords)
    for _, playerId in ipairs(GetPlayers()) do
        local ped = GetPlayerPed(playerId)
        if ped and ped ~= 0 then
            local pPos = GetEntityCoords(ped)
            if #(pPos - coords) <= ABANDONED_NEARBY_DISTANCE then
                return true
            end
        end
    end
    return false
end

-- Abandoned-cleanup watchdog.
-- Only runs when the server has no external persistence resource
-- (PersistReleasedCars = false). Periodically walks every released car:
--   * if the entity is gone, drop it
--   * if a player is nearby, mark it as "not abandoned"
--   * otherwise, start (or continue) an abandoned timer; once it crosses
--     AbandonedCleanupMinutes we delete the car so it doesn't stick around
--     forever.
CreateThread(function()
    Wait(5000)
    while true do
        Wait(ABANDONED_CHECK_INTERVAL_MS)

        if Config.CityCars.PersistReleasedCars then
            -- Persistence resource owns these now - drop our list and stop.
            releasedVehicles = {}
            goto continue
        end

        local now = GetGameTimer()
        local maxAbandonedMs = (Config.CityCars.AbandonedCleanupMinutes or 30) * 60 * 1000
        local survivors, deleted = {}, 0

        for _, entry in ipairs(releasedVehicles) do
            if not DoesEntityExist(entry.entity) then
                -- car already gone (cleanup, manual delete, etc) - drop it
            else
                local pos = GetEntityCoords(entry.entity)
                if anyPlayerNear(pos) then
                    entry.abandonedSince = nil
                    survivors[#survivors + 1] = entry
                else
                    entry.abandonedSince = entry.abandonedSince or now
                    if (now - entry.abandonedSince) >= maxAbandonedMs then
                        DeleteEntity(entry.entity)
                        deleted = deleted + 1
                    else
                        survivors[#survivors + 1] = entry
                    end
                end
            end
        end

        releasedVehicles = survivors

        if deleted > 0 then
            TM.Log.info('citycars',
                ('cleaned up ^2%d^7 abandoned released car(s) (^2%d^7 still being watched)'):format(
                    deleted, #releasedVehicles))
        end

        ::continue::
    end
end)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    despawnAll()
end)
