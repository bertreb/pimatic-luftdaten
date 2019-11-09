# pimatic-luftdaten

Pimatic plugin retrieves air quality sensordata from Luftdaten.info or a luftdaten local sensor. Depending on the sensor the following information can be retrieved:
- Particulate Matter (PM 10 and PM 2.5)
- Temperature
- Humidity
- Pressure
- Noise Level

More info at [luftdaten.info](https://luftdaten.info), where you can find instructions for building a luftdaten sensor (incl noise sensor) and how to get de Sensor ID or local IP address. The Air Quality Index (AQI) is calculated from PM10 and PM2.5 sensor data and is based on the [U.S. EPA](https://en.wikipedia.org/wiki/Air_quality_index#United_States).
The plugin supports the Luftdaten Noise sensor. A dBa classification (0-140 dBa) is added to the noise level data. 

The plugin enables automatically attributes when data for these attributes is received. Sometimes a refresh of the gui is needed to see the values.

For the plugin no API key is required, it uses the open lufdaten.info API or the local sensor API.

### Installation

To install the plugin add the plugin to the config.json of pimatic:
```    
    {
      "plugin": "luftdaten"
    }
```
### Device Configuration

There are 2 devices available

* Luftdaten Device.

Gets air quality data from a specific sensor or area. The Air Quality Index (AQI) data is calculated from that.
Add the device to the devices section:
```    
    {
      "id": "luftdaten",
      "class": "LuftdatenDevice",
      "name": "Device for retrieving data from Luftdaten server",
      "sensorId": "Luftdaten ID of the required sensor",
      "latitude": latitude coordinate of the location you want info for,
      "longitude": longitude coordinate of the location you want info for,
      "radius": the radius in km within for the closest sensor is searched, default 1 km,
      "minutes": 60, time between updates
    }
```
You need to configure a sensorId or a latitude/longitude/range combination. If you use de lat/lon option, make sure the range is not to narrow (no sensors) or to broad. Too many sensors in a too broad area. The device will automaticly search for the closest sensors to get a complete data set. In the debug mode you can the number sensor within the specified range. Try to get the number of sensors back to 1 by reducing the range.

* Luftdaten Home Device.

Gets PM10, PM2.5, HUM, Temp, BAR. The Air Quality Index (AQI) data is calculated from that.
Add the device with the local IP address into the devices section:
```    
    {
      "id": "luftdaten",
      "class": "LuftdatenHomeDevice",
      "name": "Device for retrieving data from local sensor",
      "sensorIp": "local IP address of sensor",
      "minutes": 60, time between updates
    }
```
### Usage

This makes the following variables available to you in Pimatic for the LuftdatenDevice. LuftdatenHomeDevice a subset if local sensor supports it (PM10, PM25, TEMP, HUM and Bar).

* ${luftdaten device id}.PM10             - Particals 10 µg/m³
* ${luftdaten device id}.PM25             - Particals 2.5 µg/m³
* ${luftdaten device id}.TEMP             - Temperature in °C
* ${luftdaten device id}.HUM              - Humidity in %
* ${luftdaten device id}.BAR              - Pressure at the altitude of the sensor in hPa
* ${luftdaten device id}.BAR_SEA_LEVEL    - Pressure at sea level in hPa
* ${luftdaten device id}.WIFI             - Wifi signal strength in dBm
* ${luftdaten device id}.NOISE_Leq        - Current noise level (average per 2.5 minutes) in dBa
* ${luftdaten device id}.NOISE_Lmin       - Lowest noise level in dBa
* ${luftdaten device id}.NOISE_Lmax       - Highest noise level in dBa
* ${luftdaten device id}.AQI              - index between 0 (very good) and 500 (very bad) air quality
* ${luftdaten device id}.AQI_CODE         - color code of airquality (green - purple)
* ${luftdaten device id}.AIR_AIR_QUALITY  - textual info on air quality level
* ${luftdaten device id}.SENSOR_ID        - Luftdaten ID of the sensor
* ${luftdaten device id}.DISTANCE         - Distance to the sensor (km)


In the gui an attribute is not visible when no value is received. The variable is set to 0 is no value is received.

---------

The plugin is Node v10 compatible and in development. You could backup Pimatic before you are using this plugin!
