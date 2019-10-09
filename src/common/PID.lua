local PID = {}
local Common   = game.ReplicatedStorage.Pioneers.Common

local Util = require(Common.Util)

local defaultPIDInfo = {PreviousError = 0, I = 0, SetPoint = 0, Kp = 0.03, Ki = 0, Kd = 0}

function PID.getValue(info, input, dt)
    assert(info, "invalid info passed to PID.getValue")
    assert(input, "invalid input passed to PID.getValue")
    assert(dt, "invalid dt passed to PID.getValue")

    if (not info) then
        info = Util.tableCopy(defaultPIDInfo)
    end

    local error = info.SetPoint - input
    local integral = (info.I + error * dt) / info.integral_limiter
    local derivative = (error - info.PreviousError) / dt
    local output = info.Kp * error + info.Ki * integral + info.Kd * derivative
    
    info.PreviousError = error
    info.I = integral

    return output, info
end

function PID.newController(info)
    return Util.tableCopy(info or defaultPIDInfo)
end

return PID