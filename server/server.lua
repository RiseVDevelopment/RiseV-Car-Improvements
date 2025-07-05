ESX = exports['es_extended']:getSharedObject()

-- ////////////////////////////
-- // Basics
local lockedVehicles         = {}
local playerActionTimestamps = {}
local pendingVehicles        = {}
local lockCooldown           = Config.LockSystemSettings.lockCooldown * 1000
local debugEnabled           = Config.Debugging

-- ////////////////////////////
-- // Debug Helper
local function dbg(msg)
    if debugEnabled then
        print(('[carlock DEBUG] %s'):format(msg))
    end
end

-- ////////////////////////////
-- // Notification Helper
local function notifyServer(playerId, key)
    dbg(('notifyServer(server): sending %s to player %d'):format(key, playerId))
    local notif = Config.NotificationSettings
    if not notif.Server or not notif.Templates or not notif.Templates[key] then
        dbg(('notifyServer(server): template missing for key %s'):format(key))
        return
    end
    local svc = notif.Server.service
    local tpl = notif.Templates[key]
    local str = svc
        :gsub("{playerId}", tostring(playerId))
        :gsub("{type}", tpl.type)
        :gsub("{duration}", tostring(tpl.duration))
        :gsub("{title}", tpl.title)
        :gsub("{text}", tpl.text)
    local fn = load(str)
    if fn then
        fn()
        dbg(('notifyServer(server): notification %s executed'):format(key))
    else
        dbg(('notifyServer(server): failed to execute notification %s'):format(key))
    end
    TriggerEvent('Car-Improvements:server:notify', playerId, key)
end

-- ////////////////////////////
-- // Authorization Helper
local function isAuthorized(playerId, plate, jobName, vehicleJob, cb)
    dbg(('isAuthorized: Checking ownership of %s for player %d (job=%s, vehicleJob=%s)'):format(plate, playerId, jobName, tostring(vehicleJob)))
    exports.oxmysql:execute('SELECT owner FROM owned_vehicles WHERE plate = @plate', {
        ['@plate'] = plate
    }, function(result)
        local xPlayer = ESX.GetPlayerFromId(playerId)
        local allowed = false
        if result[1] and xPlayer and xPlayer.identifier == result[1].owner then
            dbg(('isAuthorized: Player %d is owner of %s'):format(playerId, plate))
            allowed = true
        elseif vehicleJob and xPlayer and xPlayer.job.name == vehicleJob then
            dbg(('isAuthorized: Player %d has vehicle job %s'):format(playerId, vehicleJob))
            allowed = true
        else
            dbg(('isAuthorized: Player %d not authorized for %s'):format(playerId, plate))
        end
        TriggerEvent('Car-Improvements:server:isAuthorized', playerId, plate, allowed)
        cb(allowed)
    end)
end

-- ////////////////////////////
-- // Entity Management
AddEventHandler('entityCreated', function(entity)
    if GetEntityType(entity) == 2 then
        Citizen.Wait(50)
        local netId = NetworkGetNetworkIdFromEntity(entity)
        local plate = GetVehicleNumberPlateText(entity) or ""
        dbg(('entityCreated(server): Detected vehicle entity=%d netId=%d plate=%s'):format(entity, netId, plate))
        pendingVehicles[netId] = { plate = plate, job = nil }
        TriggerClientEvent('Car-Improvements:requestVehicleClass', -1, netId)
        TriggerEvent('Car-Improvements:server:entityCreated', entity, netId, plate)
    end
end)

RegisterNetEvent('Car-Improvements:replyVehicleClass')
AddEventHandler('Car-Improvements:replyVehicleClass', function(netId, vehClass)
    local data = pendingVehicles[netId]
    if not data then return end
    pendingVehicles[netId] = nil

    dbg(('replyVehicleClass(server): netId=%d returned class=%d'):format(netId, vehClass))

    local excluded = Config.LockSystemSettings.LockExcludedVehicleClasses
    local function isExcluded(cls)
        for _, c in ipairs(excluded) do
            if cls == c then return true end
        end
        return false
    end

    local initialLocked = not isExcluded(vehClass)
    lockedVehicles[netId] = { plate = data.plate, job = nil, locked = initialLocked }

    TriggerClientEvent('Car-Improvements:initialLockState', -1, netId, initialLocked)
    dbg(('InitialLock on %s for netId=%d'):format(tostring(initialLocked), netId))
    TriggerEvent('Car-Improvements:server:initialLockState', netId, initialLocked)
end)

AddEventHandler('entityRemoved', function(entity)
    if GetEntityType(entity) == 2 then
        local netId = NetworkGetNetworkIdFromEntity(entity)
        if lockedVehicles[netId] then
            lockedVehicles[netId] = nil
            dbg(('entityRemoved(server): netId=%d cleaned up'):format(netId))
            TriggerEvent('Car-Improvements:server:entityRemoved', entity, netId)
        end
    end
end)

-- ////////////////////////////
-- // Blinker System
RegisterNetEvent('Car-Improvements:syncBlinker')
AddEventHandler('Car-Improvements:syncBlinker', function(netId, blinkerState)
    dbg(('syncBlinker(server): netId=%d state=%s'):format(netId, json.encode(blinkerState)))
    TriggerClientEvent('Car-Improvements:syncBlinker', -1, netId, blinkerState)
    TriggerEvent('Car-Improvements:server:syncBlinker', netId, blinkerState)
end)

-- ////////////////////////////
-- // Vehicle Components System
RegisterNetEvent('Car-Improvements:turnOffVehicleComponents')
AddEventHandler('Car-Improvements:turnOffVehicleComponents', function(netId)
    dbg(('turnOffVehicleComponents(server): netId=%d'):format(netId))
    TriggerClientEvent('Car-Improvements:turnOffVehicleComponents', source, netId)
    TriggerEvent('Car-Improvements:server:turnOffVehicleComponents', source, netId)
end)

-- ////////////////////////////
-- // Lock System & Lockpick
if Config.EnableLockSystem then
    RegisterNetEvent('Car-Improvements:toggleLock')
    AddEventHandler('Car-Improvements:toggleLock', function(netId, plate)
        local _src    = source
        dbg(('toggleLock(server): called for netId=%d plate=%s'):format(netId, plate))
        local xPlayer = ESX.GetPlayerFromId(_src)
        if not xPlayer then
            dbg('toggleLock(server): xPlayer not found, abort')
            return
        end

        local now = GetGameTimer()
        if now - (playerActionTimestamps[_src] or 0) < lockCooldown then
            dbg(('toggleLock(server): cooldown active for player %d'):format(_src))
            return
        end
        playerActionTimestamps[_src] = now

        local data = lockedVehicles[netId]
        if not data then
            dbg(('toggleLock(server): no data for netId=%d, creating default'):format(netId))
            data = { plate = plate, job = nil, locked = true }
            lockedVehicles[netId] = data
        end

        isAuthorized(_src, plate, xPlayer.job.name, data.job, function(allowed)
            if not allowed then
                dbg(('toggleLock(server): authorization failed for player %d'):format(_src))
                notifyServer(_src, 'NotAuthorized')
                return
            end

            data.locked = not data.locked
            local key = data.locked and 'VehicleLocked' or 'VehicleUnlocked'
            notifyServer(_src, key)
            TriggerClientEvent('Car-Improvements:updateLockState', -1, netId, data.locked)
            dbg(('toggleLock(server): netId=%d newState=%s'):format(netId, tostring(data.locked)))
            TriggerEvent('Car-Improvements:server:toggleLock', _src, netId, data.locked)
        end)
    end)

    ESX.RegisterServerCallback('Car-Improvements:getLockState', function(src, cb, netId)
        dbg(('getLockState(server): src=%d netId=%d'):format(src, netId))
        local state = lockedVehicles[netId] and lockedVehicles[netId].locked or true
        cb(state)
        TriggerEvent('Car-Improvements:server:getLockState', src, netId, state)
    end)

    ESX.RegisterUsableItem('lockpick', function(src)
        dbg(('lockpick item used by player %d'):format(src))
        TriggerClientEvent('Car-Improvements:attempt', src)
        TriggerEvent('Car-Improvements:server:useLockpickItem', src)
    end)

    RegisterNetEvent('Car-Improvements:consumeLockpick')
    AddEventHandler('Car-Improvements:consumeLockpick', function()
        dbg(('consumeLockpick(server): called by player %d'):format(source))
        local xPlayer = ESX.GetPlayerFromId(source)
        if xPlayer then
            xPlayer.removeInventoryItem(Config.LockSystemSettings.LockpickItem, Config.LockSystemSettings.requiredItemCount)
            dbg(('consumeLockpick(server): removed lockpick from %d'):format(source))
            TriggerEvent('Car-Improvements:server:consumeLockpick', source)
        end
    end)

    RegisterNetEvent('Car-Improvements:lockpickVehicle')
    AddEventHandler('Car-Improvements:lockpickVehicle', function(netId, plate)
        dbg(('lockpickVehicle(server): netId=%d plate=%s'):format(netId, plate))
        local _src = source
        lockedVehicles[netId] = lockedVehicles[netId] or { plate = plate, job = nil }
        lockedVehicles[netId].locked = false
        TriggerClientEvent('Car-Improvements:updateLockState', -1, netId, false)
        notifyServer(_src, 'Lockpicked')
        TriggerClientEvent('Car-Improvements:vehicleHonk', -1, netId)
        dbg(('lockpickVehicle(server): forced unlock netId=%d'):format(netId))
        TriggerEvent('Car-Improvements:server:lockpickVehicle', _src, netId)
    end)
end

-- ////////////////////////////
-- // Cleaning System
if Config.EnableCleaningSystem then
  ESX.RegisterUsableItem(Config.CleaningSettings.CleaningItem, function(src)
    dbg(('clean item used by player %d'):format(src))
    TriggerClientEvent('Car-Improvements:clean', src)
    TriggerEvent('Car-Improvements:server:useCleaningItem', src)
  end)

  RegisterNetEvent('Car-Improvements:cleanComplete')
  AddEventHandler('Car-Improvements:cleanComplete', function()
    dbg(('cleanComplete(server): called by player %d'):format(source))
    local xPlayer = ESX.GetPlayerFromId(source)
    if xPlayer then
      xPlayer.removeInventoryItem(
        Config.CleaningSettings.CleaningItem,
        Config.CleaningSettings.requiredItemCount
      )
      dbg(('cleanComplete(server): removed sponge from %d'):format(source))
      TriggerEvent('Car-Improvements:server:cleanComplete', source)
    end
  end)
end

-- ////////////////////////////
-- // Repairkit System 
if Config.EnableRepairkit then
  ESX.RegisterUsableItem(Config.RepairkitSettings.RepairkitItem, function(src)
    dbg(('repairkit item used by player %d'):format(src))
    TriggerClientEvent('Car-Improvements:useRepairkit', src)
    TriggerEvent('Car-Improvements:server:useRepairkitItem', src)
  end)

  RegisterNetEvent('Car-Improvements:repairkit:removeItem')
  AddEventHandler('Car-Improvements:repairkit:removeItem', function()
    dbg(('repairkit:removeItem(server): called by player %d'):format(source))
    local xPlayer = ESX.GetPlayerFromId(source)
    if xPlayer then
      xPlayer.removeInventoryItem(Config.RepairkitSettings.RepairkitItem, Config.RepairkitSettings.requiredItemCount)
      dbg(('repairkit:removeItem(server): removed repairkit from %d'):format(source))
      TriggerEvent('Car-Improvements:server:repairkitRemove', source)
    end
  end)
end

-- ////////////////////////////
-- // Server Exports
function ToggleLock(playerId, netId, plate)
    TriggerClientEvent('Car-Improvements:toggleLock', playerId, netId, plate)
end

function GetLockState(netId)
    return lockedVehicles[netId] and lockedVehicles[netId].locked or false
end

function ConsumeLockpick(playerId)
    TriggerClientEvent('Car-Improvements:consumeLockpick', playerId)
end

function ForceUnlock(playerId, netId)
    lockedVehicles[netId] = lockedVehicles[netId] or { plate = "", job = nil }
    lockedVehicles[netId].locked = false
    TriggerClientEvent('Car-Improvements:updateLockState', -1, netId, false)
end

function CleanVehicle(playerId)
    TriggerClientEvent('Car-Improvements:clean', playerId)
end

function RepairVehicle(playerId)
    TriggerClientEvent('Car-Improvements:useRepairkit', playerId)
end

function SyncBlinker(netId, state)
    TriggerClientEvent('Car-Improvements:syncBlinker', -1, netId, state)
end

function TurnOffComponents(playerId, netId)
    TriggerClientEvent('Car-Improvements:turnOffVehicleComponents', playerId, netId)
end

exports('ToggleLock', ToggleLock)
exports('GetLockState', GetLockState)
exports('ConsumeLockpick', ConsumeLockpick)
exports('ForceUnlock', ForceUnlock)
exports('CleanVehicle', CleanVehicle)
exports('RepairVehicle', RepairVehicle)
exports('SyncBlinker', SyncBlinker)
exports('TurnOffComponents', TurnOffComponents)
