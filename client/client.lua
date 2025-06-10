ESX = exports['es_extended']:getSharedObject()

-- ////////////////////////////
-- // Basics
local debugEnabled    = Config.Debugging
local leftBlinker     = false
local rightBlinker    = false
local hazardLights    = false
local lockCooldown    = Config.LockSystemSettings.lockCooldown * 1000
local canToggleLock   = true
local lockpickTime    = Config.LockSystemSettings.LockpickDuration * 1000
local LockpickHonkDuration    = Config.LockSystemSettings.LockpickHonkDuration * 1000
local lockpickSession = {}
local canUseLockpick  = true
local lockpickCooldown= Config.LockSystemSettings.LockpickCooldown * 1000

-- ////////////////////////////
-- // Debug Helper
local function dbg(msg)
    if debugEnabled then
        print(('[carlock DEBUG] %s'):format(msg))
    end
end

-- ////////////////////////////
-- // Notification Helper
local function notifyClient(key)
    local notif = Config.NotificationSettings
    if not notif.Client or not notif.Templates or not notif.Templates[key] then
        return
    end
    local svc = notif.Client.service
    local tpl = notif.Templates[key]
    local str = svc
        :gsub("{type}", tpl.type)
        :gsub("{duration}", tostring(tpl.duration))
        :gsub("{title}", tpl.title)
        :gsub("{text}", tpl.text)
    local fn = load(str)
    if fn then fn() end
end

-- ////////////////////////////
-- // Indicator Lights
local function toggleBlinker(side)
    if not Config.EnableIndicatorLights then return end
    local ped = PlayerPedId()
    local veh = GetVehiclePedIsIn(ped, false)
    if veh ~= 0 and GetPedInVehicleSeat(veh, -1) == ped then
        if side == 'left' then leftBlinker = not leftBlinker; rightBlinker, hazardLights = false, false
        elseif side == 'right' then rightBlinker = not rightBlinker; leftBlinker, hazardLights = false, false
        elseif side == 'hazard' then hazardLights = not hazardLights; leftBlinker, rightBlinker = false, false
        end
        SetVehicleIndicatorLights(veh, 1, leftBlinker or hazardLights)
        SetVehicleIndicatorLights(veh, 0, rightBlinker or hazardLights)
        TriggerServerEvent('Car-Improvements:syncBlinker', NetworkGetNetworkIdFromEntity(veh), {
            left  = leftBlinker or hazardLights,
            right = rightBlinker or hazardLights
        })
    end
end

-- ////////////////////////////
-- // Window Controls
local function toggleWindow(idx)
    if not Config.EnableWindowControls then return end
    local ped = PlayerPedId()
    local veh = GetVehiclePedIsIn(ped, false)
    if veh ~= 0 and GetPedInVehicleSeat(veh, -1) == ped then
        if IsVehicleWindowIntact(veh, idx) then RollDownWindow(veh, idx)
        else RollUpWindow(veh, idx) end
    end
end

-- ////////////////////////////
-- // Sync Events
RegisterNetEvent('Car-Improvements:syncBlinker')
AddEventHandler('Car-Improvements:syncBlinker', function(netId, blinkerState)
    dbg(('syncBlinker(client): netId=%d state=%s'):format(netId, json.encode(blinkerState)))
    local veh = NetworkGetEntityFromNetworkId(netId)
    if DoesEntityExist(veh) then
        SetVehicleIndicatorLights(veh, 0, blinkerState.right)
        SetVehicleIndicatorLights(veh, 1, blinkerState.left)
    end
end)

RegisterNetEvent('Car-Improvements:turnOffVehicleComponents')
AddEventHandler('Car-Improvements:turnOffVehicleComponents', function(netId)
    dbg(('turnOffVehicleComponents(client): netId=%d'):format(netId))
    local veh = NetworkGetEntityFromNetworkId(netId)
    if DoesEntityExist(veh) then
        SetVehicleEngineOn(veh, false, true, false)
        SetVehicleLights(veh, 1)
        for i = 0, 3 do SetVehicleNeonLightEnabled(veh, i, false) end
        SetVehicleIndicatorLights(veh, 0, false)
        SetVehicleIndicatorLights(veh, 1, false)
        SetVehicleRadioEnabled(veh, false)
    end
end)

-- ////////////////////////////
-- // Lock System & Lockpick
if Config.EnableLockSystem then
    local function getClosestLockableVehicle(radius)
        dbg(('getClosestLockableVehicle(client): radius=%.1f'):format(radius or Config.LockSystemSettings.VehicleDetectionDistance))
        local dist     = radius or Config.LockSystemSettings.VehicleDetectionDistance
        local excluded = Config.LockSystemSettings.LockExcludedVehicleClasses
        local function classAllowed(cls)
            for _, c in ipairs(excluded) do
                if cls == c then return false end
            end
            return true
        end

        local ped = PlayerPedId()
        local pos = GetEntityCoords(ped)

        if IsPedInAnyVehicle(ped, false) then
            local vehIn = GetVehiclePedIsIn(ped, false)
            local cls   = GetVehicleClass(vehIn)
            if DoesEntityExist(vehIn) and classAllowed(cls) then
                dbg('using current vehicle')
                return vehIn
            end
        end

        local veh = GetClosestVehicle(pos.x, pos.y, pos.z, dist, 0, 71)
        if not DoesEntityExist(veh) or veh == 0 then
            dbg('no car/motorbike found, trying boats/heli')
            veh = GetClosestVehicle(pos.x, pos.y, pos.z, dist, 0, 12294)
        end

        local cls = GetVehicleClass(veh)
        if DoesEntityExist(veh) and veh ~= 0 and classAllowed(cls) then
            dbg(('found veh=%d class=%d'):format(veh, cls))
            return veh
        end

        dbg('no suitable vehicle found')
        return 0
    end

    RegisterNetEvent('Car-Improvements:requestVehicleClass')
    AddEventHandler('Car-Improvements:requestVehicleClass', function(netId)
        dbg(('requestVehicleClass(client): netId=%d'):format(netId))
        local veh = NetworkGetEntityFromNetworkId(netId)
        if DoesEntityExist(veh) then
            TriggerServerEvent('Car-Improvements:replyVehicleClass', netId, GetVehicleClass(veh))
            dbg(('requestVehicleClass(client): netId=%d class sent'):format(netId))
        end
    end)

    RegisterNetEvent('Car-Improvements:initialLockState')
    AddEventHandler('Car-Improvements:initialLockState', function(netId, isLocked)
        dbg(('initialLockState(client): netId=%d locked=%s'):format(netId, tostring(isLocked)))
        local veh = NetworkGetEntityFromNetworkId(netId)
        if DoesEntityExist(veh) then
            SetVehicleDoorsLocked(veh, isLocked and 2 or 1)
        end
    end)

    RegisterNetEvent('Car-Improvements:updateLockState')
    AddEventHandler('Car-Improvements:updateLockState', function(netId, isLocked)
        dbg(('updateLockState(client): netId=%d locked=%s'):format(netId, tostring(isLocked)))
        local veh = NetworkGetEntityFromNetworkId(netId)
        if DoesEntityExist(veh) then
            SetVehicleDoorsLocked(veh, isLocked and 2 or 1)
            if Config.LockSystemSettings.EffectsOnLock then
                StartVehicleHorn(veh, 100, "HELLDOWN", false)
                SetVehicleLights(veh, isLocked and 2 or 0)
                Citizen.Wait(500)
                SetVehicleLights(veh, 0)
            end
        end
    end)

    RegisterNetEvent('Car-Improvements:vehicleHonk')
    AddEventHandler('Car-Improvements:vehicleHonk', function(netId)
        dbg(('vehicleHonk(client): netId=%d'):format(netId))
        local veh = NetworkGetEntityFromNetworkId(netId)
        if DoesEntityExist(veh) then
            Citizen.CreateThread(function()
                local t0 = GetGameTimer()
                while GetGameTimer() - t0 < 5000 do
                    StartVehicleHorn(veh, 250, "HELDDOWN", false)
                    Citizen.Wait(500)
                end
            end)
        end
    end)

    local function toggleLock()
        dbg('toggleLock(client): invoked')
        if not canToggleLock then
            dbg('toggleLock(client): cooldown active')
            return notifyClient('ToggleCooldown')
        end

        local ped = PlayerPedId()
        local veh = getClosestLockableVehicle()
        if not DoesEntityExist(veh) then
            dbg('toggleLock(client): no veh found')
            return notifyClient('NoVehicle')
        end

        local netId = NetworkGetNetworkIdFromEntity(veh)
        local plate = GetVehicleNumberPlateText(veh)
        dbg(('toggleLock(client): netId=%d plate=%s'):format(netId, plate))
        if plate and plate ~= "" then
            RequestAnimDict(Config.LockSystemSettings.LockToggleAnimationDict)
            while not HasAnimDictLoaded(Config.LockSystemSettings.LockToggleAnimationDict) do
                Citizen.Wait(0)
            end
            TaskPlayAnim(ped, Config.LockSystemSettings.LockToggleAnimationDict, Config.LockSystemSettings.LockToggleAnimationName, 8.0, -8.0, 500, 0, 0, false, false, false)
            TriggerServerEvent('Car-Improvements:toggleLock', netId, plate)
        end

        canToggleLock = false
        Citizen.SetTimeout(lockCooldown, function() canToggleLock = true end)
    end

    RegisterCommand('toggleLock', toggleLock, false)
    RegisterKeyMapping('toggleLock', Config.LockSystemSettings.toggleLock.description, 'keyboard', Config.LockSystemSettings.toggleLock.key)

    RegisterNetEvent('Car-Improvements:attempt')
    AddEventHandler('Car-Improvements:attempt', function()
        dbg('Car-Improvements:attempt(client): start')
        if not canUseLockpick then
            dbg('Car-Improvements:attempt(client): cooldown active')
            return notifyClient('LockpickCooldown')
        end
        canUseLockpick = false
        Citizen.SetTimeout(lockpickCooldown, function() canUseLockpick = true end)

        local ped = PlayerPedId()
        local veh = getClosestLockableVehicle()
        if not DoesEntityExist(veh) then
            dbg('Car-Improvements:attempt(client): no veh found')
            return notifyClient('NoVehicle')
        end
        if GetVehicleDoorLockStatus(veh) ~= 2 then
            dbg('Car-Improvements:attempt(client): veh not locked')
            return notifyClient('AlreadyUnlocked')
        end

        local netId = NetworkGetNetworkIdFromEntity(veh)
        dbg(('Car-Improvements:attempt(client): proceeding on netId=%d'):format(netId))
        lockpickSession[netId] = (lockpickSession[netId] or 0) + 1
        local mySession = lockpickSession[netId]
        ClearPedTasksImmediately(ped)

        Citizen.CreateThread(function()
            local t0 = GetGameTimer()
            while GetGameTimer() - t0 < LockpickHonkDuration do
                if lockpickSession[netId] ~= mySession then break end
                if not DoesEntityExist(veh) then break end
                StartVehicleHorn(veh, 250, "HELDDOWN", false)
                Citizen.Wait(500)
            end
        end)

        local success = math.random(100) <= Config.LockSystemSettings.LockpickSuccessRate
        dbg(('Car-Improvements:attempt(client): successChance=%d result=%s'):format(Config.LockSystemSettings.LockpickSuccessRate, tostring(success)))
        local broken = false
        if not success then
            Citizen.SetTimeout(math.random(0, lockpickTime), function()
                if lockpickSession[netId] == mySession and not broken then
                    broken = true
                    dbg('Car-Improvements:attempt(client): pick broken')
                    ClearPedTasksImmediately(ped)
                    TriggerServerEvent('Car-Improvements:consumeLockpick')
                    notifyClient('LockpickBroken')
                end
            end)
        end

        RequestAnimDict(Config.LockSystemSettings.LockpickAnimationDict)
        while not HasAnimDictLoaded(Config.LockSystemSettings.LockpickAnimationDict) do Citizen.Wait(0) end
        TaskPlayAnim(ped, Config.LockSystemSettings.LockpickAnimationDict, Config.LockSystemSettings.LockpickAnimationName, 8.0, -8.0, lockpickTime, 0, 0, false, false, false)
        Citizen.Wait(lockpickTime)
        ClearPedTasksImmediately(ped)

        if broken or lockpickSession[netId] ~= mySession then
            dbg('Car-Improvements:attempt(client): aborted mid-process')
            return
        end
        TriggerServerEvent('Car-Improvements:consumeLockpick')
        if success then
            dbg('Car-Improvements:attempt(client): success, sending lockpickVehicle')
            TriggerServerEvent('Car-Improvements:lockpickVehicle', netId, GetVehicleNumberPlateText(veh))
        else
            dbg('Car-Improvements:attempt(client): failed attempt')
            notifyClient('LockpickFail')
        end
    end)
end

-- ////////////////////////////
-- // Cleaning System
RegisterNetEvent('Car-Improvements:clean')
AddEventHandler('Car-Improvements:clean', function()
  if not Config.EnableCleaningSystem then return end
  dbg('Car-Improvements:clean(client): called')
  local ped = PlayerPedId()
  local veh = GetClosestVehicle(
    GetEntityCoords(ped),
    Config.CleaningSettings.VehicleDetectionDistance, 0, 70
  )
  if DoesEntityExist(veh) then
    dbg('Car-Improvements:clean(client): cleaning vehicle')
    TaskTurnPedToFaceEntity(ped, veh, 1000)
    Citizen.Wait(1000)
    TaskStartScenarioInPlace(ped, Config.CleaningSettings.CleaningAnimation, 0, true)
    Citizen.Wait(Config.CleaningSettings.CleaningDuration * 1000)
    ClearPedTasks(ped)
    SetVehicleDirtLevel(veh, 0.0)
    WashDecalsFromVehicle(veh, 1.0)
    notifyClient('Cleaned')
    TriggerServerEvent('Car-Improvements:cleanComplete')
  else
    dbg('Car-Improvements:clean(client): no veh found')
    notifyClient('CleanFail')
  end
end)

-- ////////////////////////////
-- // Repairkit System 
RegisterNetEvent('Car-Improvements:useRepairkit')
AddEventHandler('Car-Improvements:useRepairkit', function()
  if not Config.EnableRepairkit then return end
  local ped = PlayerPedId()
  local pos = GetEntityCoords(ped)
  local veh = IsPedInAnyVehicle(ped, false) and GetVehiclePedIsIn(ped, false) or GetClosestVehicle(pos.x, pos.y, pos.z, Config.RepairkitSettings.VehicleDetectionDistance, 0, 71) if DoesEntityExist(veh) then TaskTurnPedToFaceEntity(ped, veh, 1000)
    Citizen.Wait(1000)

    TaskStartScenarioInPlace(ped, Config.RepairkitSettings.RepairingAnimation, 0, true)
    Citizen.Wait(Config.RepairkitSettings.RepairingTime * 1000)
    ClearPedTasks(ped)

    SetVehicleFixed(veh)
    SetVehicleDeformationFixed(veh)
    SetVehicleUndriveable(veh, false)
    SetVehicleEngineOn(veh, true, true, true)

    notifyClient('RepairCompleted')
    TriggerServerEvent('Car-Improvements:repairkit:removeItem')
    TriggerEvent('Car-Improvements:vehicleRepaired', veh)
  else
    notifyClient('NoVehicleNearby')
  end
end)

-- ////////////////////////////
-- // Engine Control
if Config.TurnOnOffEngine then
  RegisterCommand('toggleEngine', function()
    local ped = PlayerPedId()
    local veh = GetVehiclePedIsIn(ped, false)
    if veh ~= 0 and GetPedInVehicleSeat(veh, -1) == ped then
      local running = GetIsVehicleEngineRunning(veh)
      SetVehicleEngineOn(veh, not running, true, true)
      notifyClient(running and 'EngineOff' or 'EngineOn')
    end
  end, false)

  RegisterKeyMapping(
    'toggleEngine',
    Config.EngineControlSettings.toggleKey.description,
    'keyboard',
    Config.EngineControlSettings.toggleKey.key
  )
end

-- ////////////////////////////
-- // Commands & KeyMappings
RegisterCommand('toggleLeftBlinker',  function() toggleBlinker('left')   end, false)
RegisterCommand('toggleRightBlinker', function() toggleBlinker('right')  end, false)
RegisterCommand('toggleHazardLights', function() toggleBlinker('hazard') end, false)
for cmd, mapping in pairs(Config.IndicatorKeyMappings) do
    RegisterKeyMapping(cmd, mapping.description, 'keyboard', mapping.key)
end

RegisterCommand('toggleWindowLeft',      function() toggleWindow(0) end, false)
RegisterCommand('toggleWindowRight',     function() toggleWindow(1) end, false)
RegisterCommand('toggleWindowRearLeft',  function() toggleWindow(2) end, false)
RegisterCommand('toggleWindowRearRight', function() toggleWindow(3) end, false)
for cmd, mapping in pairs(Config.WindowKeyMappings) do
    RegisterKeyMapping(cmd, mapping.description, 'keyboard', mapping.key)
end
