if not Config.Modules or not Config.Modules.citycars then return end

local function isPoliceJob(name)
    if not name then return false end
    for _, job in ipairs(Config.CityCars.PoliceJobs or {}) do
        if name == job then return true end
    end
    return false
end

local function getOnlineCops()
    local count = 0
    for _, src in ipairs(GetPlayers()) do
        local player = exports.qbx_core:GetPlayer(tonumber(src))
        if player and player.PlayerData and player.PlayerData.job then
            local job = player.PlayerData.job
            if isPoliceJob(job.name) then
                if Config.CityCars.RequireOnDuty then
                    if job.onduty then count = count + 1 end
                else
                    count = count + 1
                end
            end
        end
    end
    return count
end

local function canSteal()
    return getOnlineCops() >= (Config.CityCars.MinPoliceOnline or 1)
end

exports('CanSteal', canSteal)
exports('GetOnlineCops', getOnlineCops)

local function notify(src, msg)
    TriggerClientEvent('ox_lib:notify', src, {
        title       = 'Streetside',
        description = msg,
        type        = 'error',
    })
end

local function tryLockpickGate(src, advanced)
    local isCityCar = lib.callback.await('tm-streetside:isNearCityCar', src)
    if not isCityCar then return 'passthrough' end
    if not canSteal() then
        notify(src, Config.CityCars.NotEnoughCopsText or 'Not enough cops online.')
        return 'blocked'
    end
    TriggerClientEvent('MK_VehicleKeys:Client:UseLockpick', src,
        advanced and 'advancedlockpick' or 'lockpick',
        { Advanced = advanced })
    return 'lockpicked'
end

-- ox_inventory handler for lockpick / advancedlockpick. Wire in items.lua:
--   server = { export = 'tm-streetside.uselockpick' }
exports('uselockpick', function(event, item, inventory, _slot, _data)
    if event ~= 'usingItem' then return end

    local advanced = item.name == 'advancedlockpick'
    local result   = tryLockpickGate(inventory.id, advanced)

    if result == 'blocked' then return false end
    if result == 'passthrough' then
        TriggerClientEvent('MK_VehicleKeys:Client:UseLockpick', inventory.id,
            advanced and 'advancedlockpick' or 'lockpick',
            { Advanced = advanced })
    end
end)

-- ox_inventory handler for r14-evidence's access tool. Blocks the use when
-- next to a city car and not enough cops are online; otherwise forwards
-- straight to r14-evidence so its normal opening / evidence logic runs.
exports('useaccesstool', function(event, item, inventory, slot, data)
    if event ~= 'usingItem' then return end

    local src = inventory.id
    local isCityCar = lib.callback.await('tm-streetside:isNearCityCar', src)
    if isCityCar and not canSteal() then
        notify(src, Config.CityCars.NotEnoughCopsText or 'Not enough cops online.')
        return false
    end

    return exports['r14-evidence']:accesstool(event, item, inventory, slot, data)
end)
