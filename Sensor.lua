local class = require 'middleclass'

local core = require 'libipmi.core'

local sensor = class('sensor', core)

local ffi = require("ffi")

function sensor:initialize()
    self:register()
end

-- Get all sensors and return as lua table
-- On failure, return error code
function sensor:get_sensors()
    local count = ffi.new("int[1]")
    local wRet = self.library.LIBIPMI_HL_GetSensorCount(self.IPMISession, count, DEFAULT_TIMEOUT)

    local sensor_data = {}

    if wRet == 0 then
    	local sensors = ffi.new("struct sensor_data[?]", tonumber(count[0]))
    	local nCSensors = ffi.new("uint32[1]")
	--Let know the LIBIPMI_HL_GetAllSensorReadings API that we have allocated memory for number of records
    	nCSensors[0] = tonumber(count[0])
	wRet = self.library.LIBIPMI_HL_GetAllSensorReadings(self.IPMISession, sensors, nCSensors, DEFAULT_TIMEOUT)

    	if wRet == 0 then
    		local c = 0;
    		local nSensors = tonumber(nCSensors[0])

    		while c<nSensors do
    			local data = {}
				if tonumber(sensors[c].sensor_num) > 0 then
    				data['sensor_name'] = ffi.string(sensors[c].sensor_name)
    				data['sensor_number'] = tonumber(sensors[c].sensor_num)
    				data['sensor_type'] = tonumber(sensors[c].sensor_type)
                    		data['discrete'] = tonumber(sensors[c].discrete_state)
            		if tonumber(sensors[c].SensorAccessibleFlags) == 0 then
                		data['sensor_reading'] = tonumber(sensors[c].sensor_reading)
                		data['accessible'] = true
            		else
                		data['sensor_reading'] = 0
                		data['accessible'] = false
            		end
            		data['lower_non_recoverable_threshold'] = tonumber(sensors[c].low_non_recov_thresh)
            		data['lower_critical_threshold'] = tonumber(sensors[c].low_crit_thresh)
            		data['lower_non_critical_threshold'] = tonumber(sensors[c].low_non_crit_thresh)
            		data['upper_non_critical_threshold'] = tonumber(sensors[c].high_non_crit_thresh)
            		data['upper_critical_threshold'] = tonumber(sensors[c].high_crit_thresh)
            		data['upper_non_recoverable_threshold'] = tonumber(sensors[c].high_non_recov_thresh)
    			end

    			table.insert(sensor_data, data)
    			
				c = c+1    			
    		end
    	end
    elseif wRet == 16 then
        -- Session expired. Reset the session
        self:trigger_session_expired()
    end



    return wRet, sensor_data

end

return sensor