ESX = nil

TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)

local lockedVehicles = {}
local playerActionTimestamps = {}
local ACTION_COOLDOWN = Config.ActionCooldown * 1000

RegisterNetEvent('carlock:syncBlinker')
AddEventHandler('carlock:syncBlinker', function(netId, blinkerState)
    local vehicle = NetworkGetEntityFromNetworkId(netId)
    if DoesEntityExist(vehicle) then
        TriggerClientEvent('carlock:syncBlinker', -1, netId, blinkerState)
    end
end)

local function isAuthorized(playerId, plate, job, vehicleJob, tempOwner, cb)
    exports.oxmysql:execute('SELECT owner FROM owned_vehicles WHERE plate = @plate', {
        ['@plate'] = plate
    }, function(result)
        local xPlayer = ESX.GetPlayerFromId(playerId)
        if result[1] then
            local owner = result[1].owner
            if xPlayer and xPlayer.identifier == owner then
                cb(true)
                return
            end
        end

        if vehicleJob and xPlayer and xPlayer.job.name == vehicleJob then
            cb(true)
            return
        end

        if tempOwner and xPlayer and xPlayer.identifier == tempOwner then
            cb(true)
            return
        end

        cb(false)
    end)
end

RegisterNetEvent('carlock:setInitialLockState')
AddEventHandler('carlock:setInitialLockState', function(netId, plate)
    lockedVehicles[netId] = { locked = true }
    TriggerClientEvent('carlock:updateLockState', -1, netId, true)
end)

RegisterNetEvent('carlock:toggleLock')
AddEventHandler('carlock:toggleLock', function(netId, plate)
    local _source = source
    local xPlayer = ESX.GetPlayerFromId(_source)

    if not xPlayer then
        return
    end

    local currentTime = GetGameTimer()
    local lastAction = playerActionTimestamps[_source] or 0

    if currentTime - lastAction < ACTION_COOLDOWN then
        print(('carlock: %s (ID: %s) versucht, Aktionen zu schnell auszuführen!'):format(xPlayer.getName(), xPlayer.identifier))
        return
    end

    playerActionTimestamps[_source] = currentTime

    local vehicleData = lockedVehicles[netId]
    if vehicleData then
        isAuthorized(_source, plate, xPlayer.job.name, vehicleData.job, vehicleData.tempOwner, function(isAuthorized)
            if isAuthorized then
                local newLockState = not vehicleData.locked
                lockedVehicles[netId].locked = newLockState

                if newLockState then
                    TriggerClientEvent('RiP-Notify:Notify', _source, 'default', 3000, "Gesperrt", "Dein Fahrzeug wurde abgeschlossen.")
                else
                    TriggerClientEvent('RiP-Notify:Notify', _source, 'default', 3000, "Entsperrt", "Dein Fahrzeug wurde entriegelt.")
                end

                TriggerClientEvent('carlock:updateLockState', -1, netId, newLockState)
            else
                print(('DEBUG: Spieler %s versucht, ein Fahrzeug zu sperren, das ihm nicht gehört.'):format(xPlayer.identifier))
                TriggerClientEvent('RiP-Notify:Notify', _source, 'error', 3000, "Carlock", "Du bist nicht berechtigt, dieses Fahrzeug zu sperren.")
            end
        end)
    else
        TriggerClientEvent('RiP-Notify:Notify', _source, 'error', 3000, "Carlock", "Ungültige Fahrzeugdaten.")
    end
end)

RegisterNetEvent('jobs_creator:temporary_garage:vehicleSpawned')
AddEventHandler('jobs_creator:temporary_garage:vehicleSpawned', function(vehicle, vehicleName, vehiclePlate)
    local tempOwner = GetPlayerIdentifiers(source)[1]
    local job = ESX.GetPlayerFromId(source).job.name

    if vehiclePlate and job then
        print(("Fahrzeug %s für Job %s wurde gespawnt."):format(vehiclePlate, job))

        lockedVehicles[NetworkGetNetworkIdFromEntity(vehicle)] = {
            plate = vehiclePlate,
            job = job,
            tempOwner = tempOwner,
            locked = false
        }
        TriggerClientEvent('carlock:updateLockState', -1, NetworkGetNetworkIdFromEntity(vehicle), false)
    end
end)

RegisterNetEvent('carlock:turnOffVehicleComponents')
AddEventHandler('carlock:turnOffVehicleComponents', function(netId)
    local vehicle = NetworkGetEntityFromNetworkId(netId)
    if DoesEntityExist(vehicle) then
        SetVehicleEngineOn(vehicle, false, true, false)
        SetVehicleLights(vehicle, 1)
        for i = 0, 3 do
            SetVehicleNeonLightEnabled(vehicle, i, false)
        end
        SetVehicleIndicatorLights(vehicle, 0, false)
        SetVehicleIndicatorLights(vehicle, 1, false)
        SetVehicleRadioEnabled(vehicle, false)
    end
end)

ESX.RegisterServerCallback('carlock:getLockState', function(source, cb, netId)
    cb(lockedVehicles[netId] and lockedVehicles[netId].locked or false)
end)




ESX = nil
TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)

ESX.RegisterUsableItem('sponge', function(source)
	local xPlayer = ESX.GetPlayerFromId(source)
	TriggerClientEvent('sponge:clean', source)
	xPlayer.removeInventoryItem('sponge', 1)
end)




ESX.RegisterUsableItem('lockpick', function(source)
    TriggerClientEvent('lockpick:attempt', source)
    local xPlayer = ESX.GetPlayerFromId(source)
    xPlayer.removeInventoryItem('lockpick', 1)
end)

RegisterNetEvent('carlock:lockpickVehicle')
AddEventHandler('carlock:lockpickVehicle', function(netId, plate)
    local _source = source
    if lockedVehicles[netId] then
        lockedVehicles[netId].locked = false
    else
        lockedVehicles[netId] = { plate = plate, locked = false }
    end
    TriggerClientEvent('carlock:updateLockState', -1, netId, false)
    TriggerClientEvent('RiP-Notify:Notify', _source, 'default', 3000, "Lockpick", "Fahrzeug erfolgreich aufgebrochen.")
    TriggerClientEvent('carlock:vehicleHonk', -1, netId)
end)

