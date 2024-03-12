# MacBatteryCycle (Prototype)

This script automates the process of battery management, optimizing battery health by controlling cyclical charging and discharging based on user-defined thresholds. 

It allows to let the Mac's power cable be plugged in all the time. The script monitors the battery level and controls a cyclical charging/discharging based on upper and lower battery level thresholds. This is also a pro-feature ('Sailing Mode') in the Mac-Software ['AlDente'](https://apphousekitchen.com)
You will be prompted to set upper and lower charging limits as well as to choose if battery will be used as power source wafter upper limit has been reached or not. If not, the battery will not be discharged, and the power adapter will remain as the primary energy source.
The script includes a cleanup function for graceful exit and log file management for size constraints.
Battery status and actions taken are logged to 'battery_cycle_logs.log' file in the MacBatteryCycle.app/Contents folder (Hint: right click on MacBatteryCycle.app).  

The script requires the free [Battery CLI tool](https://github.com/actuallymentor/battery) to be installed.  

**Unzip MacBatteryCycle.app.zip and run script by starting MacBatteryCycle.app.**  
Tip: use spotlight search "MacBatteryCycle"

##
**Author:** René Sesgör  
**Last Update:** 2024-01-12
