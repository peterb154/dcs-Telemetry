local modName = 'DCS-p51Telemetry'
TARGET_AIRCRAFT = "P-51D"
THIS_AIRCRAFT = LoGetObjectById(LoGetPlayerPlaneId()).Name
log.write(modName, log.DEBUG, "Loading modName: " .. modName)
local headers_printed = false

function LuaExportStart()
    -- Works once just before mission start.
    if not string.find(THIS_AIRCRAFT, TARGET_AIRCRAFT) then
        -- if this is not the target aircraft, get out
        return
    end
    -- configure log output
    log.set_output(modName, modName, log.TRACE, log.MESSAGE)
    headers_printed = false
    local version = LoGetVersionInfo()
    local pilot = LoGetPilotName() -- (args - 0, results - 1 (text string))
    version = string.format("DCS Version: %d.%d.%d.%d",
            version.ProductVersion[1],
            version.ProductVersion[2],
            version.ProductVersion[3],
            version.ProductVersion[4])
    logEvent("=========== Mission Start ," .. version .. ", Pilot: " .. pilot .. ", Type: " .. THIS_AIRCRAFT)
end

function LuaExportBeforeNextFrame()
    -- Works just before every simulation frame.
end

function LuaExportAfterNextFrame()
    -- Works just after every simulation frame.
end

function LuaExportStop()
    if not string.find(THIS_AIRCRAFT, TARGET_AIRCRAFT) then
        -- if this is not the target aircraft, get out
        return
    end
    -- Works once just after mission stop.
    logEvent("=========== Mission End")
    -- close the log file, means that new log file gets created every mission
    log.set_output(modName, '', 0, 0)
    logFile = lfs.writedir() .. "\Logs\\" .. modName .. ".log"
    timeStamp = os.date("%Y-%m-%d_%H-%M-%S")
    csvFile = lfs.writedir() .. "\Logs\\" .. modName .. "." .. timeStamp .. ".csv"
    log.write(modName, log.INFO, "Moving file: " .. logFile .. " to: " .. csvFile)
    os.execute('move "' .. logFile .. '" "' .. csvFile .. '"')
    os.rename(logFile, csvFile)
end

function LuaExportActivityNextEvent(t)
    if not string.find(THIS_AIRCRAFT, TARGET_AIRCRAFT) then
        -- if this is not the target aircraft, get out
        return
    end
    local tNext = t
    data = getTelemetry()
    if (not headers_printed) then
        log.write(modName, log.TRACE, "date, time, " .. getHeaderString(data))
        headers_printed = true
    end
    logEvent(getValueString(data))
    tNext = tNext + 1.0
    return tNext
end

-- logging function
function logEvent(message, level)
    -- level log.TRACE guarantees log events are written (log.INFO is best effort)
    level = log.TRACE or level
    message = os.date("%Y-%m-%d,%H:%M:%S") .. "," .. message
    log.write(modName, level, message)
end

function getTelemetry()
    mps2mph = 2.23694
    meter2feet = 3.28084
    rad2deg = 57.2958
    mm2inch = 0.0393701
    data = {}
    data.IAS = round(LoGetIndicatedAirSpeed() * mps2mph, 0) -- (args - 0, results - 1 (m/s))
    data.TAS = round(LoGetTrueAirSpeed() * mps2mph, 0) -- (args - 0, results - 1 (m/s))
    data.ASL = round(LoGetAltitudeAboveSeaLevel() * meter2feet, 0) -- (args - 0, results - 1 (meters))
    data.AGL = round(LoGetAltitudeAboveGroundLevel() * meter2feet, 0) -- (args - 0, results - 1 (meters))
    data.AOA = round(LoGetAngleOfAttack(), 1) -- (args - 0, results - 1 (rad))

    self_data = LoGetSelfData()
    data.Heading = round(self_data.Heading * rad2deg, 0)
    data.Pitch = round(self_data.Pitch * rad2deg, 0)
    data.Bank = round(self_data.Bank * rad2deg, 0)

    accel = LoGetAccelerationUnits()
    data.ACC_X = round(accel.x, 1)
    data.ACC_Y = round(accel.y, 1)
    data.ACC_Z = round(accel.z, 1)

    data.VSI = round(LoGetVerticalVelocity() * meter2feet, 0) -- (args - 0, results - 1(m/s))
    data.MACH = round(LoGetMachNumber(), 3)        -- (args - 0, results - 1)
    data.BALL = LoGetSlipBallPosition()  -- (args - 0,results - 1)( -1 < result < 1)

    mainPanel = GetDevice(0)
    data.ALT_PRESS = round(map(mainPanel:get_argument_value(97), 0, 1, 28.1, 31.0), 2)
    data.AHorizon_Pitch_DEG = round(map(mainPanel:get_argument_value(15), 1, -1, -math.pi / 3.0, math.pi / 3.0)*100, 1)
    data.AHorizon_Bank_DEG = round(map(mainPanel:get_argument_value(14), 1, -1, -math.pi / 3.0, math.pi / 3.0)*180, 1)
    --data.GyroHeading = mainPanel:get_argument_value(12)
    --data.TurnNeedle = mainPanel:get_argument_value(27)
    data.SlipBall = round(mainPanel:get_argument_value(28), 2)
    data.FuelTankLeft = round(map(mainPanel:get_argument_value(155),0, 1, 0, 92), 1)
    data.FuelTankRight = round(map(mainPanel:get_argument_value(155),0, 1, 0, 92), 1)
    data.FuelTankFus = round(map(mainPanel:get_argument_value(160), 0, 1, 0, 85), 1)
    data.FuelTankFus = round(map(mainPanel:get_argument_value(32), 0, 1, 0, 25), 1)
    ----data.CompassHeading = mainPanel:get_argument_value(1)
    ----data.CommandedCourse = mainPanel:get_argument_value(2)
    ----data.CommandedCourseKnob = mainPanel:get_argument_value(3)

    data.Hydraulic_Pressure = round(map(mainPanel:get_argument_value(78), 0, 1, 0, 2000), 1)
    data.Manifold_Pressure = round(map(mainPanel:get_argument_value(10), 0, 1, 10, 75),1)
    data.Engine_RPM = round(map(mainPanel:get_argument_value(23), 0, 1, 0, 4500),0)
    data.Engine_RPM_100 = round(map(mainPanel:get_argument_value(23), 0, 1, 0, 4500)/100,2)
    data.Vacuum_Suction = round(map(mainPanel:get_argument_value(9), 0, 1, 0, 10), 1)
    data.Carb_Temperature = round(map(mainPanel:get_argument_value(21), 0, 1, -80, 150), 1)
    data.Coolant_Temperature = round(map(mainPanel:get_argument_value(22), 0, 1, -80, 150),1)
    data.Oil_Temperature = round(map(mainPanel:get_argument_value(30), 0, 1, 0, 100),1)
    data.Oil_Pressure = round(map(mainPanel:get_argument_value(31), 0, 1, 0, 200), 1)
    data.Accelerometer = round(map(mainPanel:get_argument_value(175), 0, 1, -5, 12), 1)
    data.Ammeter = round(map(mainPanel:get_argument_value(101), 0, 1, 0, 150), 1)
    data.WEP = mainPanel:get_argument_value(190)

    data.StickPitch_PCT = round(mainPanel:get_argument_value(50) * 100, 1)
    data.StickBank_PCT = round(mainPanel:get_argument_value(51) * 100, 1)
    data.RudderPedals = round(mainPanel:get_argument_value(54) * 100, 1)
    data.Throttle = round(mainPanel:get_argument_value(43)* 100, 1)

    return data
end

function getHeaderString(data)
    local result = ""
    for k,v in pairs(data) do
        result = result .. k .. ","
    end
    return result
end
function getValueString(data)
    local result = ""
    for k,v in pairs(data) do
        result = result .. v .. ","
    end
    return result
end

function round(num, numDecimalPlaces)
    local mult = 10^(numDecimalPlaces or 0)
    return math.floor(num * mult + 0.5) / mult
end

function map(sim_val, sim_min, sim_max, gau_min, gau_max)
    return (sim_val - sim_min) * (gau_max - gau_min) / (sim_max - sim_min) + gau_min
end