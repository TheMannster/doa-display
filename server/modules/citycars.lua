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
    DOA.Log.warn('citycars', 'module enabled but Config.CityCars is missing')
    return
end

-- Each entry: { entity = vehHandle, loc = vec4 }
local activeVehicles = {}

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
        DOA.Log.warn('citycars', ('failed to spawn %s at %s'):format(tostring(model), locationKey(loc)))
        return nil
    end

    -- 8 spaces = blank-looking plate (GTA plates are max 8 chars).
    if Config.CityCars.BlankPlates then
        SetVehicleNumberPlateText(veh, '        ')
    end

    return veh
end

-- Despawn untouched entries, release touched ones (untrack but keep alive).
local function despawnUntouched()
    local despawned, released = 0, 0
    for _, entry in ipairs(activeVehicles) do
        if not DoesEntityExist(entry.entity) then
            -- already gone
        elseif isTouched(entry) then
            released = released + 1
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
                DOA.Log.warn('citycars',
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
        DOA.Log.info('citycars',
            ('rotated - ^2%d^7 active, ^3%d^7 released this round, next rotation in ^2%dm^7'):format(
                #activeVehicles,
                released,
                math.floor(Config.CityCars.RotationInterval / 60000)))
        Wait(Config.CityCars.RotationInterval)
    end
end)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    despawnAll()
end)
