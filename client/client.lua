-- client/client.lua
ESX = exports['es_extended']:getSharedObject()

-- ////////////////////////////
-- // Basics
local debugEnabled            = Config.Debugging
local leftBlinker, rightBlinker, hazardLights = false, false, false
local lockCooldown            = Config.LockSystemSettings.lockCooldown * 1000
local canToggleLock           = true
local lockpickTime            = Config.LockSystemSettings.LockpickDuration * 1000
local LockpickHonkDuration    = Config.LockSystemSettings.LockpickHonkDuration * 1000
local lockpickSession         = {}
local canUseLockpick          = true
local lockpickCooldown        = Config.LockSystemSettings.LockpickCooldown * 1000
local maxAirTime              = Config.CruiseControlSettings.maxAirTime * 1000
local CruiseControlCooldown   = Config.CruiseControlSettings.cooldown * 1000
local lastCruiseToggle        = 0

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
    dbg(('notifyClient(client): sending %s'):format(key))
    local notif = Config.NotificationSettings
    if not notif.Client or not notif.Templates or not notif.Templates[key] then
        dbg(('notifyClient(client): template missing for key %s'):format(key))
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
    if fn then
        fn()
        dbg(('notifyClient(client): notification %s executed'):format(key))
    else
        dbg(('notifyClient(client): failed to execute notification %s'):format(key))
    end
    TriggerEvent('Car-Improvements:client:notify', key)
end

-- ////////////////////////////
-- // Indicator Lights
if Config.EnableIndicatorLights then
    local function toggleBlinker(side)
        dbg(('toggleBlinker(client): called for side %s'):format(side))
        local ped = PlayerPedId()
        local veh = GetVehiclePedIsIn(ped, false)
        if veh ~= 0 and GetPedInVehicleSeat(veh, -1) == ped then
            if side == 'left' then
                leftBlinker = not leftBlinker
                rightBlinker, hazardLights = false, false
            elseif side == 'right' then
                rightBlinker = not rightBlinker
                leftBlinker, hazardLights = false, false
            elseif side == 'hazard' then
                hazardLights = not hazardLights
                leftBlinker, rightBlinker = false, false
            end
            dbg(('toggleBlinker(client): new state left=%s right=%s hazard=%s'):format(leftBlinker, rightBlinker, hazardLights))
            SetVehicleIndicatorLights(veh, 1, leftBlinker  or hazardLights)
            SetVehicleIndicatorLights(veh, 0, rightBlinker or hazardLights)
            TriggerServerEvent('Car-Improvements:syncBlinker',
                NetworkGetNetworkIdFromEntity(veh),
                { left = leftBlinker or hazardLights, right = rightBlinker or hazardLights }
            )
            TriggerEvent('Car-Improvements:client:toggleBlinker', side, leftBlinker, rightBlinker, hazardLights)
        end
    end

    local blinkerSideMapping = {
        toggleLeftBlinker  = 'left',
        toggleRightBlinker = 'right',
        toggleHazardLights = 'hazard',
    }

    for cmd, mapping in pairs(Config.IndicatorKeyMappings) do
        RegisterCommand(cmd, function()
            local side = blinkerSideMapping[cmd]
            if side then toggleBlinker(side) end
        end, false)
        RegisterKeyMapping(cmd, mapping.description, 'keyboard', mapping.key)
    end
end

-- ////////////////////////////
-- // Window Controls
if Config.EnableWindowControls then
    local windowIdxMapping = {
        toggleWindowLeft      = 0,
        toggleWindowRight     = 1,
        toggleWindowRearLeft  = 2,
        toggleWindowRearRight = 3,
    }

    local function toggleWindow(idx)
        dbg(('toggleWindow(client): idx=%d'):format(idx))
        local ped = PlayerPedId()
        local veh = GetVehiclePedIsIn(ped, false)
        if veh ~= 0 and GetPedInVehicleSeat(veh, -1) == ped then
            if IsVehicleWindowIntact(veh, idx) then
                RollDownWindow(veh, idx)
            else
                RollUpWindow(veh, idx)
            end
            TriggerEvent('Car-Improvements:client:toggleWindow', idx)
        end
    end

    for cmd, mapping in pairs(Config.WindowKeyMappings) do
        RegisterCommand(cmd, function()
            local idx = windowIdxMapping[cmd]
            if idx then toggleWindow(idx) end
        end, false)
        RegisterKeyMapping(cmd, mapping.description, 'keyboard', mapping.key)
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
        TriggerEvent('Car-Improvements:client:turnOffComponents', netId)
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
                if cls == c then return false end end
            return true
        end

        local ped = PlayerPedId()
        local pos = GetEntityCoords(ped)

        if IsPedInAnyVehicle(ped, false) then
            local vehIn = GetVehiclePedIsIn(ped, false)
            if DoesEntityExist(vehIn) and classAllowed(GetVehicleClass(vehIn)) then
                dbg('using current vehicle')
                return vehIn
            end
        end

        local veh = GetClosestVehicle(pos.x, pos.y, pos.z, dist, 0, 71)
        if not DoesEntityExist(veh) or veh == 0 then
            dbg('no car/motorbike found, trying boats/heli')
            veh = GetClosestVehicle(pos.x, pos.y, pos.z, dist, 0, 12294)
        end

        if DoesEntityExist(veh) and veh ~= 0 and classAllowed(GetVehicleClass(veh)) then
            dbg(('found veh=%d class=%d'):format(veh, GetVehicleClass(veh)))
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
        canToggleLock = false
        Citizen.SetTimeout(lockCooldown, function() canToggleLock = true end)

        local ped = PlayerPedId()
        local veh = getClosestLockableVehicle()
        if veh == 0 then
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
            TaskPlayAnim(ped,
                Config.LockSystemSettings.LockToggleAnimationDict,
                Config.LockSystemSettings.LockToggleAnimationName,
                8.0, -8.0, 500, 0, 0, false, false, false
            )
            TriggerServerEvent('Car-Improvements:toggleLock', netId, plate)
            TriggerEvent('Car-Improvements:client:toggleLock', netId, plate)
        end
    end

    RegisterCommand('toggleLock', toggleLock, false)
    RegisterKeyMapping('toggleLock',
        Config.LockSystemSettings.toggleLock.description,
        'keyboard',
        Config.LockSystemSettings.toggleLock.key
    )

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
        if veh == 0 then
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
        dbg(('Car-Improvements:attempt(client): successChance=%d result=%s')
            :format(Config.LockSystemSettings.LockpickSuccessRate, tostring(success)))
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
        while not HasAnimDictLoaded(Config.LockSystemSettings.LockpickAnimationDict) do
            Citizen.Wait(0)
        end
        TaskPlayAnim(ped,
            Config.LockSystemSettings.LockpickAnimationDict,
            Config.LockSystemSettings.LockpickAnimationName,
            8.0, -8.0, lockpickTime, 0, 0, false, false, false
        )
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
        TriggerEvent('Car-Improvements:client:cleanComplete', veh)
    else
        dbg('Car-Improvements:clean(client): no veh found')
        notifyClient('CleanFail')
    end
end)

-- ////////////////////////////
-- // Repairkit System 
RegisterNetEvent('Car-Improvements:useRepairkit')
AddEventHandler('Car-Improvements:useRepairkit', function()
    dbg('Car-Improvements:useRepairkit(client): called')
    if not Config.EnableRepairkit then return end
    local ped = PlayerPedId()
    local pos = GetEntityCoords(ped)
    local veh = IsPedInAnyVehicle(ped, false) and GetVehiclePedIsIn(ped, false)
                or GetClosestVehicle(pos.x, pos.y, pos.z,
                    Config.RepairkitSettings.VehicleDetectionDistance, 0, 71)
    if DoesEntityExist(veh) then
        TaskTurnPedToFaceEntity(ped, veh, 1000)
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
        TriggerEvent('Car-Improvements:client:repairComplete', veh)
    else
        dbg('Car-Improvements:useRepairkit(client): no veh found')
        notifyClient('NoVehicleNearby')
    end
end)

-- ////////////////////////////
-- // Engine Control
if Config.TurnOnOffEngine then
    RegisterCommand('toggleEngine', function()
        dbg('toggleEngine(client): called')
        local ped = PlayerPedId()
        local veh = GetVehiclePedIsIn(ped, false)
        if veh ~= 0 and GetPedInVehicleSeat(veh, -1) == ped then
            local running = GetIsVehicleEngineRunning(veh)
            SetVehicleEngineOn(veh, not running, true, true)
            dbg(('toggleEngine(client): engine running=%s'):format(tostring(not running)))
            notifyClient(running and 'EngineOff' or 'EngineOn')
            TriggerEvent('Car-Improvements:client:toggleEngine', not running)
        end
    end, false)

    RegisterKeyMapping('toggleEngine',
        Config.EngineControlSettings.toggleKey.description,
        'keyboard',
        Config.EngineControlSettings.toggleKey.key
    )
end

-- ////////////////////////////
-- // Seatbelt System
if Config.EnableSeatbeltSystem then
    local seatbeltOn = false
    local lastCrashTime = 0
    local vehicleSpeeds = {}

    RegisterCommand('toggleSeatbelt', function()
        seatbeltOn = not seatbeltOn
        dbg(('Seatbelt toggled: %s'):format(tostring(seatbeltOn)))
        notifyClient(seatbeltOn and 'SeatbeltOn' or 'SeatbeltOff')
        TriggerEvent('Car-Improvements:client:toggleSeatbelt', seatbeltOn)
    end, false)
    RegisterKeyMapping('toggleSeatbelt',
        Config.SeatbeltSettings.toggleKey.description,
        'keyboard',
        Config.SeatbeltSettings.toggleKey.key
    )

    Citizen.CreateThread(function()
        dbg('Seatbelt: speed tracking thread started')
        while true do
            Citizen.Wait(200)
            local ped = PlayerPedId()
            if IsPedInAnyVehicle(ped, false) then
                local veh = GetVehiclePedIsIn(ped, false)
                vehicleSpeeds[NetworkGetNetworkIdFromEntity(veh)] = GetEntitySpeed(veh) * 3.6
            end
        end
    end)

    AddEventHandler('gameEventTriggered', function(name, args)
        dbg(('gameEventTriggered(client): %s'):format(name))
        if name ~= 'CEventNetworkEntityDamage' then return end
        if not Config.SeatbeltSettings.FlyOutOnCrashIfNotBuckledUp then return end
        local now = GetGameTimer()
        if now - lastCrashTime < 1000 then return end

        local ped = PlayerPedId()
        if not IsPedInAnyVehicle(ped, false) or seatbeltOn then return end
        local veh = GetVehiclePedIsIn(ped, false)
        if args[1] ~= veh then return end

        local attacker = args[2]
        if Config.SeatbeltSettings.IgnoreFragileObjects
           and attacker
           and IsEntityAnObject(attacker)
           and not IsEntityAVehicle(attacker)
           and not IsEntityStatic(attacker) then
            lastCrashTime = now
            dbg(('Seatbelt: collision with fragile object model %s, skipping eject'):format(GetEntityModel(attacker)))
            return
        end

        local speedMps = GetEntitySpeed(veh)
        local speedKmh = speedMps * 3.6
        dbg(('Crash detected at %.2f km/h'):format(speedKmh))
        local storedSpeed = vehicleSpeeds[NetworkGetNetworkIdFromEntity(veh)] or 0.0
        dbg(('Stored speed: %.2f km/h'):format(storedSpeed))

        if speedKmh < Config.SeatbeltSettings.MinCrashSpeedKMH and storedSpeed < Config.SeatbeltSettings.MinCrashSpeedKMH then
            return
        end

        lastCrashTime = now
        local useSpeedMps = (storedSpeed >= Config.SeatbeltSettings.MinCrashSpeedKMH) and (storedSpeed/3.6) or speedMps
        -- perform ejection
        local m = Config.SeatbeltSettings.FlySpeedMultiplicator
        local forward = GetEntityForwardVector(veh)
        local flightDir = forward
        if attacker and DoesEntityExist(attacker) then
            local diff = vector3(0,0,0)
            if IsEntityAVehicle(attacker) then
                local vVel = GetEntityVelocity(veh); local aVel = GetEntityVelocity(attacker)
                diff = vector3(vVel.x - aVel.x, vVel.y - aVel.y, 0.0)
            else
                local vPos = GetEntityCoords(veh); local aPos = GetEntityCoords(attacker)
                diff = vector3(vPos.x - aPos.x, vPos.y - aPos.y, 0.0)
            end
            local len = #diff
            if len > 0 then flightDir = forward + (diff/len) end
        end
        local horizontal = vector3(flightDir.x, flightDir.y, 0)
        if #horizontal > 0 then horizontal = horizontal / #horizontal end
        local zVel = useSpeedMps * 0.2 * m
        dbg(('Eject dir: [%.2f, %.2f, %.2f], zVel=%.2f'):format(horizontal.x, horizontal.y, horizontal.z, zVel))
        ClearPedTasksImmediately(ped)
        SetPedToRagdoll(ped, 1000,1000,0,false,false,false)
        SetEntityVelocity(ped, horizontal.x*useSpeedMps*m, horizontal.y*useSpeedMps*m, zVel)
    end)
end

-- ////////////////////////////
-- // Cruise Control
if Config.EnableCruiseControl then
    local cruiseSpeed, cruiseActive, inputLock, releaseAllowed, lastCrashTime = 0.0, false, false, false, 0

    local function toggleCruise()
        dbg('toggleCruise(client): called')
        local now = GetGameTimer()
        if not cruiseActive then
            if now - lastCruiseToggle < CruiseControlCooldown then
                dbg('toggleCruise: Cooldown active')
                notifyClient('CruiseToggleCooldown')
                return
            end
            lastCruiseToggle = now
        else
            cruiseActive = false
            dbg('Cruise deactivated by toggle')
            notifyClient('CruiseOff')
            TriggerEvent('Car-Improvements:client:toggleCruise', false)
            return
        end

        local ped = PlayerPedId(); local veh = GetVehiclePedIsIn(ped,false)
        if veh == 0 or GetPedInVehicleSeat(veh,-1)~=ped then return end
        local speedKmh = GetEntitySpeed(veh)*3.6
        dbg(('Current speed: %.2f km/h'):format(speedKmh))
        if speedKmh>0 and speedKmh<=Config.CruiseControlSettings.maxSpeedKMH then
            cruiseSpeed = GetEntitySpeed(veh)
            cruiseActive, inputLock, releaseAllowed = true, false, false
            dbg(('Cruise activated at %.2f m/s'):format(cruiseSpeed))
            notifyClient('CruiseOn'); TriggerEvent('Car-Improvements:client:toggleCruise', true)
        else
            dbg('Cruise not activated: speed out of range')
            notifyClient('CruiseOverSpeedLimit')
        end
    end

    RegisterCommand('toggleCruise', toggleCruise, false)
    RegisterKeyMapping('toggleCruise',
        Config.CruiseControlSettings.toggleCruiseControl.description,
        'keyboard',
        Config.CruiseControlSettings.toggleCruiseControl.key
    )

    Citizen.CreateThread(function()
        dbg('Cruise control thread started')
        local airStartTime = nil
        while true do
            Citizen.Wait(0)
            if cruiseActive then
                local ped, veh = PlayerPedId(), GetVehiclePedIsIn(PlayerPedId(),false)
                if veh==0 or GetPedInVehicleSeat(veh,-1)~=ped then cruiseActive=false; break end
                local now = GetGameTimer()
                if IsEntityInAir(veh) then
                    if not airStartTime then airStartTime = now; dbg('Cruise: in air start') end
                    if now-airStartTime >= maxAirTime then cruiseActive=false; airStartTime=nil; dbg('Cruise off: too long in air'); notifyClient('CruiseOffInAir'); break end
                else
                    airStartTime=nil
                    SetVehicleForwardSpeed(veh, cruiseSpeed)
                    local isBrake, isAccel = IsControlPressed(0,71), IsControlPressed(0,72)
                    if isBrake or isAccel then
                        if not inputLock and not releaseAllowed then
                            inputLock=true; dbg('Cruise: first brake/accel blocked')
                        elseif releaseAllowed then
                            cruiseActive=false; inputLock=false; releaseAllowed=false; dbg('Cruise off: brake/accel again'); notifyClient('CruiseOff'); break
                        end
                    else
                        if inputLock then releaseAllowed=true; inputLock=false; dbg('Cruise: released input') end
                    end
                end
            end
        end
    end)

    AddEventHandler('gameEventTriggered', function(name,args)
        dbg(('gameEventTriggered(client): %s'):format(name))
        if name~='CEventNetworkEntityDamage' or not cruiseActive then return end
        local ped,veh=PlayerPedId(),GetVehiclePedIsIn(PlayerPedId(),false)
        if args[1]~=veh then return end
        local now=GetGameTimer()
        if now-lastCrashTime<1000 then return end
        lastCrashTime=now
        local attacker=args[2]
        if attacker and IsEntityAnObject(attacker) and not IsEntityAVehicle(attacker) and not IsEntityStatic(attacker) then
            dbg('Cruise: fragile object collision ignored'); return
        end
        cruiseActive=false; dbg('Cruise off: crash'); notifyClient('CruiseOffCrash'); TriggerEvent('Car-Improvements:client:toggleCruise', false)
    end)
end

-- ////////////////////////////
-- // Door Control
if Config.EnableDoorControl then
    local function toggleDoor(idx)
        dbg(('toggleDoor(client): idx=%d'):format(idx))
        local ped,veh=PlayerPedId(),GetVehiclePedIsIn(PlayerPedId(),false)
        if veh~=0 and GetPedInVehicleSeat(veh,-1)==ped then
            if GetVehicleDoorAngleRatio(veh,idx)>0.0 then SetVehicleDoorShut(veh,idx,false)
            else SetVehicleDoorOpen(veh,idx,false,false) end
            TriggerEvent('Car-Improvements:client:toggleDoor', idx)
        end
    end

    for cmd,mapping in pairs(Config.DoorControlSettings) do
        local idx = ({ toggleFrontLeftDoor=0, toggleFrontRightDoor=1, toggleRearLeftDoor=2,
                      toggleRearRightDoor=3, toggleHood=4, toggleTrunk=5 })[cmd]
        RegisterCommand(cmd, function() toggleDoor(idx) end, false)
        RegisterKeyMapping(cmd, mapping.description, 'keyboard', mapping.key)
    end
end

-- ////////////////////////////
-- // Autopilot
if Config.EnableAutoPilot then
    local AutoPilotCooldown   = Config.AutoPilotSettings.cooldown * 1000
    local lastAutoPilotToggle = 0
    local autopilotActive     = false
    local targetCoords        = nil

    local function toggleAutoPilot()
        dbg('toggleAutoPilot(client): called')
        local now = GetGameTimer()
        local ped = PlayerPedId()
        local veh = GetVehiclePedIsIn(ped,false)
        if not autopilotActive then
            if GetFirstBlipInfoId(8)==0 then notifyClient('AutoPilotNoWaypoint'); return end
            if now-lastAutoPilotToggle<AutoPilotCooldown then notifyClient('AutoPilotToggleCooldown'); return end
            lastAutoPilotToggle=now
            if veh==0 or GetPedInVehicleSeat(veh,-1)~=ped then return end
            local tx,ty,tz = table.unpack(GetBlipInfoIdCoord(GetFirstBlipInfoId(8)))
            local found,nodePos = GetClosestVehicleNodeWithHeading(tx,ty,tz,1,10.0,0)
            if found and nodePos then targetCoords={x=nodePos.x,y=nodePos.y,z=nodePos.z}
            else targetCoords={x=tx,y=ty,z=tz} end
            dbg(('Autopilot target: [%.1f,%.1f,%.1f]'):format(targetCoords.x,targetCoords.y,targetCoords.z))
            autopilotActive=true; notifyClient('AutoPilotOn'); TriggerEvent('Car-Improvements:client:toggleAutoPilot', true)
            local maxSpeed = Config.AutoPilotSettings.maxSpeedKMH/3.6
            SetDriveTaskDrivingStyle(ped, Config.AutoPilotSettings.drivingStyleFlags)
            SetDriveTaskCruiseSpeed(ped, maxSpeed)
            TaskVehicleDriveToCoordLongrange(ped,veh,targetCoords.x,targetCoords.y,targetCoords.z,maxSpeed,Config.AutoPilotSettings.drivingStyleFlags)
            Citizen.CreateThread(function()
                while autopilotActive do
                    Citizen.Wait(100)
                    local pos=GetEntityCoords(veh)
                    local dist=#(pos-vector3(targetCoords.x,targetCoords.y,targetCoords.z))
                    if dist<=50 then SetDriveTaskCruiseSpeed(ped,60/3.6) end
                    if dist<=30 then SetDriveTaskCruiseSpeed(ped,40/3.6) end
                    if dist<=20 then SetDriveTaskCruiseSpeed(ped,20/3.6) end
                    if dist<=10 then
                        SetDriveTaskCruiseSpeed(ped,5/3.6)
                        autopilotActive=false
                        notifyClient('AutoPilotOff')
                        ClearPedTasks(ped)
                        triggerEvent('Car-Improvements:client:toggleAutoPilot', false)
                    end
                end
            end)
        else
            autopilotActive=false
            dbg('toggleAutoPilot(client): deactivating autopilot')
            notifyClient('AutoPilotOff')
            ClearPedTasks(ped)
            TriggerEvent('Car-Improvements:client:toggleAutoPilot', false)
        end
    end

    RegisterCommand('toggleAutoPilot', toggleAutoPilot, false)
    RegisterKeyMapping('toggleAutoPilot',
        Config.AutoPilotSettings.toggleAutoPilot.description,
        'keyboard',
        Config.AutoPilotSettings.toggleAutoPilot.key
    )
end
