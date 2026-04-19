if not Config.Modules or not Config.Modules.citycars then return end

local function nearestVehicle()
    local ped = PlayerPedId()
    local pos = GetEntityCoords(ped)
    local veh = GetClosestVehicle(pos.x, pos.y, pos.z, 5.0, 0, 70)
    if not veh or veh == 0 then return nil end
    return veh
end

lib.callback.register('tm-streetside:isNearCityCar', function()
    local veh = nearestVehicle()
    if not veh then return false end
    return Entity(veh).state.tm_streetside == true
end)
