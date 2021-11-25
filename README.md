# Dcs p51 Telemetry

## installation
1. Put the [p51Telemetry.lua](./dcsTelemetry/p51Telemetry.lua) file somewhere
2. Edit the Saved Games/DCS.xxx/Scripts/Export.lua to include something like
   the following.. Updating the location of the telemetry.lua
    ```lua
    dofile([[C:\Users\brian\Projects\dcs-Telemetry\dcsTelemetry\p51Telemetry.lua]])
    ```
3. Go fly

## Usage
1. Tool logs data every second
2. Csv telemetry data will be saved in Saved Games \ DCS.xxx \ Logs \ DCS-p51Telemetry-DATE.csv after every mission
3. Open with excel and chart away!