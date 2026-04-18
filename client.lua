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

    for i, data in ipairs(Config.DisplayVehicles) do
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

        -- Disable vehicle collision with players so they can't push it around,
        -- but keep it visible obviously.
        SetEntityHasGravity(veh, false)

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
        local ped = PlayerPedId()
        local pos = GetEntityCoords(ped)

        -- Check distance to the first configured vehicle as a reference point
        if #Config.DisplayVehicles > 0 then
            local refCoords = Config.DisplayVehicles[1].coords
            local dist = #(pos - vector3(refCoords.x, refCoords.y, refCoords.z))

            if dist < Config.SpawnDistance then
                spawnDisplayVehicles()
                sleep = 500
            elseif dist > Config.SpawnDistance + 20.0 then
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
                    local vehCoords = GetEntityCoords(veh)
                    local dist = #(GetEntityCoords(ped) - vehCoords)

                    if dist < 6.0 then
                        sleep = 0
                        -- Disable entering the vehicle (default enter key)
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

-- Cleanup on resource stop
AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    deleteDisplayVehicles()
end)
