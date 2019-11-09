# pimatic-luftdaten
<div style="text-align: right">![alt text](https://github.com/bertreb/pimatic-luftdaten/blob/master/images/nodev10.png) </div>


Pimatic plugin retrieves air quality sensor data from Luftdaten.info or a Luftdaten local sensor. Depending on the sensor the following information can be retrieved:
- Particulate Matter (PM 10 and PM 2.5)
- Temperature
- Humidity
- Pressure
- Noise Level (average, max and min levels)

More info at [luftdaten.info](https://luftdaten.info), where you can find instructions for building a luftdaten sensor (incl noise sensor) and how to get de Sensor ID or local IP address. The Air Quality Index (AQI) is calculated from pm10 and pm2.5 sensor data and is based on the [U.S. EPA](https://en.wikipedia.org/wiki/Air_quality_index#United_States).
The plugin supports also the Luftdaten noise sensor. In the gui a dBa classification (0-140 dBa) is added to the noise level data.

The plugin enables automatically attributes when data for an attribute  is received. Sometimes a refresh of the gui is needed to see the values.

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
      "sensorId": "Luftdaten sensor ID or local IP address of sensor",
      "latitude": latitude coordinate of the location you want info for,
      "longitude": longitude coordinate of the location you want info for,
      "radius": the radius of the cel for searching the closest sensor, default 1 km,
      "attributes": [
        "sensorId", "distance", "pm10", "pm25",
        "temperature", "humidity", "bar", "barSeaLevel",
        "wifi", "noiseLevel", "noiseLeq",
        "noiseLmin", "noiseLmax", "aqi",
        "aqiCode", "aqiAirQuality"
        ] // this is the maximum set of attributes
      "minutes": 60, time between updates
    }
```
You need to configure a Luftdaten SensorId or a latitude/longitude/range combination. If you use de lat/lon option, make sure the range is not to narrow (= no sensors). The maximum radius is 50 km. The device will automatically search for the closest sensors to get a complete data set. In the gui an attribute becomes visible when added in the device config.

* Luftdaten Home Device.

Gets pm10, pm2.5, humidity, temperature and bar data from a local Luftdaten sensor. The Air Quality Index (AQI) data is calculated from that.
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

The following variables are available to you in Pimatic for the LuftdatenDevice (after selection in de config!). 

* ${luftdaten device id}.pm10             - Particals Matter 10 µg/m³
* ${luftdaten device id}.pm25             - Particals Matter 2.5 µg/m³
* ${luftdaten device id}.temperature      - Temperature in °C
* ${luftdaten device id}.humidity         - Humidity in %
* ${luftdaten device id}.bar              - Pressure at the altitude of the sensor in hPa
* ${luftdaten device id}.bar              - Pressure at sea level in hPa
* ${luftdaten device id}.wifi             - Wifi signal strength in dBm
* ${luftdaten device id}.noiseLevel       - Current noise level classification
* ${luftdaten device id}.noiseLeq         - Current noise level (average per 2.5 minutes) in dBa
* ${luftdaten device id}.noieLmin         - Lowest noise level in dBa
* ${luftdaten device id}.noiseLmax        - Highest noise level in dBa
* ${luftdaten device id}.aqi              - index between 0 (very good) and 500 (very bad) air quality
* ${luftdaten device id}.aqiCode          - color code of air quality (green - purple)
* ${luftdaten device id}.aqiAirQuality    - textual info on air quality level
* ${luftdaten device id}.sensorId         - Luftdaten ID of the sensor
* ${luftdaten device id}.distance         - Distance to the sensor (km)

The LuftdatenHome Device provides a subset of this data determined by the capabilities of the local sensor. The maximum supported attributes are: pm10, pm25, temperature, humidity and bar.


In the gui an attribute becomes visible when added in the device config.

---------

The plugin is Node v10 compatible and in development. You could backup Pimatic before you are using this plugin!
