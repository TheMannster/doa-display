-- Display vehicles module (client).
-- Spawns a fixed set of locked, frozen, indestructible cars at configured
-- coordinates whenever a player is near. Players are prevented from entering
-- them.

if not Config.Modules or not Config.Modules.display then return end
if not Config.Display then
    DOA.Log.warn('display', 'module enabled but Config.Display is missing')
    return
end

local spawnedVehicles = {}
local vehiclesSpawned = false

local function loadModel(model)
    RequestModel(model)
    while not HasModelLoaded(model) do
        Wait(0)
    end
end

local function spawnDisplayVehicles()
    if vehiclesSpawned then return end
    vehiclesSpawned = true

    for i, data in ipairs(Config.Display.Vehicles) do
        local hash = GetHashKey(data.model)
        loadModel(hash)

        local veh = CreateVehicle(hash, data.coords.x, data.coords.y, data.coords.z, data.coords.w, false, false)
        SetEntityAsMissionEntity(veh, true, true)
        SetVehicleDoorsLocked(veh, 10)           -- lock all doors permanently
        FreezeEntityPosition(veh, true)
        SetEntityInvincible(veh, true)
        SetVehicleCanBeVisiblyDamaged(veh, false)
        SetVehicleNumberPlateText(veh, 'DEALER')
        SetEntityCanBeDamaged(veh, false)

        -- Disable gravity so players can't push it around even if a collision
        -- somehow happens, while keeping it visible.
        SetEntityHasGravity(veh, false)

        if data.color then
            SetVehicleColours(veh, data.color[1] or 0, data.color[2] or 0)
        end

        SetModelAsNoLongerNeeded(hash)

        spawnedVehicles[i] = veh
    end
end

local function deleteDisplayVehicles()
    if not vehiclesSpawned then return end

    for i, veh in pairs(spawnedVehicles) do
        if DoesEntityExist(veh) then
            SetEntityAsMissionEntity(veh, false, false)
            DeleteVehicle(veh)
        end
        spawnedVehicles[i] = nil
    end

    vehiclesSpawned = false
end

-- Proximity-based spawn/despawn loop
CreateThread(function()
    while true do
        local sleep = 1000
        local pos = GetEntityCoords(PlayerPedId())

        if #Config.Display.Vehicles > 0 then
            local refCoords = Config.Display.Vehicles[1].coords
            local dist = #(pos - vector3(refCoords.x, refCoords.y, refCoords.z))

            if dist < Config.Display.SpawnDistance then
                spawnDisplayVehicles()
                sleep = 500
            elseif dist > Config.Display.SpawnDistance + 20.0 then
                deleteDisplayVehicles()
            end
        end

        Wait(sleep)
    end
end)

-- Block entry into display vehicles
CreateThread(function()
    while true do
        local sleep = 250
        local ped = PlayerPedId()

        if vehiclesSpawned then
            for _, veh in pairs(spawnedVehicles) do
                if DoesEntityExist(veh) then
                    local dist = #(GetEntityCoords(ped) - GetEntityCoords(veh))

                    if dist < 6.0 then
                        sleep = 0
                        DisableControlAction(0, 23, true)  -- F / Enter vehicle
                        DisableControlAction(0, 75, true)  -- F (exit vehicle, also used contextually)

                        if IsPedInVehicle(ped, veh, false) then
                            TaskLeaveVehicle(ped, veh, 16)
                        end
                    end
                end
            end

            -- Fallback: if the player somehow gets in, kick them out
            local currentVeh = GetVehiclePedIsIn(ped, false)
            if currentVeh ~= 0 then
                for _, veh in pairs(spawnedVehicles) do
                    if currentVeh == veh then
                        TaskLeaveVehicle(ped, veh, 16)
                        break
                    end
                end
            end
        end

        Wait(sleep)
    end
end)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    deleteDisplayVehicles()
end)
