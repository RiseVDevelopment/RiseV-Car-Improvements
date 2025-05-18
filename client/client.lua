ESX = nil

Citizen.CreateThread(function()
    while ESX == nil do
        TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
        Citizen.Wait(0)
    end
end)

local leftBlinker = false
local rightBlinker = false
local hazardLights = false
local canToggleLock = true
local lockCooldown = Config.ActionCooldown * 1000

RegisterNetEvent('carlock:syncBlinker')
AddEventHandler('carlock:syncBlinker', function(netId, blinkerState)
    local vehicle = NetworkGetEntityFromNetworkId(netId)
    if DoesEntityExist(vehicle) then
        SetVehicleIndicatorLights(vehicle, 0, blinkerState.right)
        SetVehicleIndicatorLights(vehicle, 1, blinkerState.left)
    end
end)

AddEventHandler('playerLeaveVehicle', function(vehicle)
    if DoesEntityExist(vehicle) then
        TriggerServerEvent('carlock:turnOffVehicleComponents', NetworkGetNetworkIdFromEntity(vehicle))
    end
end)

local function toggleBlinker(side)
    if not Config.EnableBlinker then return end
    local playerPed = PlayerPedId()
    local vehicle = GetVehiclePedIsIn(playerPed, false)
    if vehicle ~= 0 and GetPedInVehicleSeat(vehicle, -1) == playerPed then
        if side == 'left' then
            leftBlinker = not leftBlinker
            rightBlinker = false
            hazardLights = false
        elseif side == 'right' then
            rightBlinker = not rightBlinker
            leftBlinker = false
            hazardLights = false
        elseif side == 'hazard' then
            hazardLights = not hazardLights
            leftBlinker = false
            rightBlinker = false
        end

        SetVehicleIndicatorLights(vehicle, 1, leftBlinker or hazardLights)
        SetVehicleIndicatorLights(vehicle, 0, rightBlinker or hazardLights)

        if Config.EnableSyncBlinker then
            TriggerServerEvent('carlock:syncBlinker', NetworkGetNetworkIdFromEntity(vehicle), {
                left = leftBlinker or hazardLights,
                right = rightBlinker or hazardLights
            })
        end
    end
end

local function toggleWindow(windowIndex)
    if not Config.EnableFensterSteuerung then return end
    local playerPed = PlayerPedId()
    local vehicle = GetVehiclePedIsIn(playerPed, false)
    if vehicle ~= 0 and GetPedInVehicleSeat(vehicle, -1) == playerPed then
        local windowIntact = IsVehicleWindowIntact(vehicle, windowIndex)
        if windowIntact then
            RollDownWindow(vehicle, windowIndex)
        else
            RollUpWindow(vehicle, windowIndex)
        end
    end
end

local function toggleLock()
    if not Config.EnableLockSystem then return end
    if not canToggleLock then
        TriggerEvent('RiP-Notify:Notify', 'error', 3000, "Carlock", "Bitte warte kurz bevor du erneut sperrst.")
        return
    end

    local playerPed = PlayerPedId()
    local vehicle = nil

    if IsPedInAnyVehicle(playerPed, false) then
        vehicle = GetVehiclePedIsIn(playerPed, false)
    else
        local coords = GetEntityCoords(playerPed)
        vehicle = GetClosestVehicle(coords, Config.VehicleDetectionDistance, 0, 70)
    end

    if vehicle and vehicle ~= 0 then
        local netId = NetworkGetNetworkIdFromEntity(vehicle)
        local plate = GetVehicleNumberPlateText(vehicle)

        if plate and plate ~= "" then
            TriggerServerEvent('carlock:toggleLock', netId, plate)
        else
            TriggerEvent('RiP-Notify:Notify', 'error', 3000, "Carlock", "Fahrzeug hat kein gültiges Kennzeichen.")
        end
    else
        TriggerEvent('RiP-Notify:Notify', 'error', 3000, "Carlock", "Kein Fahrzeug in der Nähe.")
    end

    canToggleLock = false
    Citizen.SetTimeout(lockCooldown, function()
        canToggleLock = true
    end)
end

RegisterNetEvent('carlock:updateLockState')
AddEventHandler('carlock:updateLockState', function(netId, isLocked)
    local vehicle = NetworkGetEntityFromNetworkId(netId)
    if DoesEntityExist(vehicle) then
        SetVehicleDoorsLocked(vehicle, isLocked and 2 or 1)
        if Config.EffectsOnLock then
            StartVehicleHorn(vehicle, 100, "HELDDOWN", false)
            SetVehicleLights(vehicle, isLocked and 2 or 0)
            Citizen.Wait(500)
            SetVehicleLights(vehicle, 0)
        end
    end
end)

RegisterCommand('toggleLeftBlinker', function() toggleBlinker('left') end, false)
RegisterCommand('toggleRightBlinker', function() toggleBlinker('right') end, false)
RegisterCommand('toggleHazardLights', function() toggleBlinker('hazard') end, false)
RegisterCommand('toggleWindowLeft', function() toggleWindow(0) end, false)
RegisterCommand('toggleWindowRight', function() toggleWindow(1) end, false)
RegisterCommand('toggleWindowRearLeft', function() toggleWindow(2) end, false)
RegisterCommand('toggleWindowRearRight', function() toggleWindow(3) end, false)
RegisterCommand('toggleLock', toggleLock, false)

RegisterKeyMapping('toggleLeftBlinker', 'Linker Blinker', 'keyboard', Config.BlinkerLeft)
RegisterKeyMapping('toggleRightBlinker', 'Rechter Blinker', 'keyboard', Config.BlinkerRight)
RegisterKeyMapping('toggleHazardLights', 'Warnblinker', 'keyboard', Config.HazardLights)
RegisterKeyMapping('toggleWindowLeft', 'Linkes Fenster', 'keyboard', Config.FensterVorneLinksToggle)
RegisterKeyMapping('toggleWindowRight', 'Rechtes Fenster', 'keyboard', Config.FensterVorneRechtsToggle)
RegisterKeyMapping('toggleWindowRearLeft', 'Hinteres linkes Fenster', 'keyboard', Config.FensterHintenLinksToggle)
RegisterKeyMapping('toggleWindowRearRight', 'Hinteres rechtes Fenster', 'keyboard', Config.FensterHintenRechtsToggle)
RegisterKeyMapping('toggleLock', 'Fahrzeug sperren/entsperren', 'keyboard', Config.LockToggle)






RegisterNetEvent('sponge:clean')
AddEventHandler('sponge:clean', function()
    local playerPed = PlayerPedId()
    local pos = GetEntityCoords(playerPed)
    local vehicle = GetClosestVehicle(pos, 3.0, 0, 70)
    if DoesEntityExist(vehicle) then
        TaskStartScenarioInPlace(playerPed, "WORLD_HUMAN_MAID_CLEAN", 0, true)
        Citizen.Wait(6000)
        ClearPedTasks(playerPed)
        SetVehicleDirtLevel(vehicle, 0.0)
        WashDecalsFromVehicle(vehicle, 1.0)
        TriggerEvent('RiP-Notify:Notify', 'default', 3000, "Schwamm", "Fahrzeug gereinigt.")
    else
        TriggerEvent('RiP-Notify:Notify', 'error', 3000, "Schwamm", "Kein Fahrzeug in der Nähe.")
    end
end)




RegisterNetEvent('lockpick:attempt')
AddEventHandler('lockpick:attempt', function()
    local playerPed = PlayerPedId()
    local pos = GetEntityCoords(playerPed)
    local vehicle = GetClosestVehicle(pos, 3.0, 0, 70)
    if DoesEntityExist(vehicle) then
        local animDict = "mini@repair"
        local animName = "fixing_a_ped"
        RequestAnimDict(animDict)
        while not HasAnimDictLoaded(animDict) do
            Citizen.Wait(0)
        end
        TaskPlayAnim(playerPed, animDict, animName, 8.0, -8.0, 5000, 0, 0, false, false, false)
        Citizen.Wait(5000)
        ClearPedTasks(playerPed)
        local netId = NetworkGetNetworkIdFromEntity(vehicle)
        local plate = GetVehicleNumberPlateText(vehicle)
        if math.random(1, 100) <= (Config.LockpickSuccessRate or 50) then
            TriggerServerEvent('carlock:lockpickVehicle', netId, plate)
        else
            TriggerEvent('RiP-Notify:Notify', 'error', 3000, "Lockpick", "Fahrzeug Lockpick fehlgeschlagen.")
        end
    else
        TriggerEvent('RiP-Notify:Notify', 'error', 3000, "Lockpick", "Kein Fahrzeug in der Nähe gefunden.")
    end
end)

RegisterNetEvent('carlock:vehicleHonk')
AddEventHandler('carlock:vehicleHonk', function(netId)
    local vehicle = NetworkGetEntityFromNetworkId(netId)
    if DoesEntityExist(vehicle) then
        Citizen.CreateThread(function()
            local startTime = GetGameTimer()
            while (GetGameTimer() - startTime) < 5000 do
                StartVehicleHorn(vehicle, 250, "HELDDOWN", false)
                Citizen.Wait(500)
            end
        end)
    end
end)
