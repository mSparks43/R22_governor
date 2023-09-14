--[[
Copyright 2023 mark 'mSparks' Parker

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and
associated documentation files (the “Software”), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense,
and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, 
subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions
of the Software.

THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
]]--

throttle_use = find_dataref("sim/flightmodel/engine/ENGN_thro_use")
throttle = find_dataref("sim/joystick/joy_mapped_axis_value")
throttle_overide = find_dataref("sim/operation/override/override_throttles")
rpm = find_dataref("sim/cockpit2/engine/indicators/engine_speed_rpm")
proprpm = find_dataref("sim/flightmodel2/engines/prop_rotation_speed_rad_sec")
governor= find_dataref("sim/cockpit2/engine/actuators/governor_on")
collective= find_dataref("sim/cockpit2/engine/actuators/prop_ratio")
throttle_overide = 1
current_throttle=0
simDRTime=find_dataref("sim/time/total_running_time_sec")
engineMP=find_dataref("sim/flightmodel/engine/ENGN_MPR")
lastUpdate=0
lastpropRPM=0
local throttleMod=0 --governors throttle modifications

maxRPM=2620
maxPropRPM=55
local targetProp=53 --engineRPM will equal 2532 
engineMP=find_dataref("sim/flightmodel/engine/ENGN_MPR")

function testingPrint(text)
    --print(text)
end

function do_throttle()
    --maintainance manual at https://robinsonheli.com/wp-content/uploads/2022/12/r22_mm_book.pdf
    --[[
        Verify throttle correlation. Set MAP to 22 inches and turn governor off. Without
        twisting throttle, lower collective to 12 inches MAP then raise it to 22.5 inches
        MAP. RPM must stay in green arc (Page 1.9)
    ]]
    throCoordinator=collective[0]*0.7
    current_throttle=throttle[4]
    local tThrottle=current_throttle+throCoordinator+throttleMod
    if tThrottle>1.0 then
        tThrottle=1.0
    elseif tThrottle<0.0 then
        tThrottle=0.0
    end
    throttle_use[0]=tThrottle
    local diff=simDRTime-lastUpdate
    if diff<0.2 then
        return
    end
    lastUpdate=simDRTime
    if throttle[4]<0.1 then
        throttleMod=0
    elseif throttleMod>1.0 then
        throttleMod=1.0
    elseif throttleMod<-1.0 then
        throttleMod=-1.0
    end
    if proprpm[0] < maxPropRPM*0.8 then
        testingPrint("governor below threshold")
        return
    end
    if governor[0]==0 then
        return
    end
    local propRate=proprpm[0]-lastpropRPM
    lastpropRPM=proprpm[0]
    testingPrint("throttle mod "..throttleMod)
    if proprpm[0]>maxPropRPM and propRate>0  then
        throttleMod=throttleMod-0.020
        testingPrint("throttle mod very fast down")
    elseif rpm[0]>(maxRPM) and propRate>0 then
        throttleMod=throttleMod-0.010
        testingPrint("throttle mod fast down")
    elseif (proprpm[0] <targetProp-1 or rpm[0]<(maxRPM-110)) and (engineMP[0]<25) and propRate<0 then
        throttleMod=throttleMod+0.010
        testingPrint("throttle mod fast up")
    elseif proprpm[0] <=targetProp-0.4 and (engineMP[0]<25) then
        throttleMod=throttleMod+0.0026
    elseif proprpm[0] >targetProp+0.4 and rpm[0]>(maxRPM-110) then
        throttleMod=throttleMod-0.0026
    end
    return
end

function after_physics()
	do_throttle()
end

