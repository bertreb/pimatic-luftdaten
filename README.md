pimatic-luftdaten
=================

Pimatic plugin that retrieves PM10 and PM2.5 sensordata from Luftdaten.info or a luftdaten local sensor.
More info at https://luftdaten.info, where you can find instructions for building a luftdaten sensor and how to get de Sensor ID or local IP address.

For the plugin no API key is required, it uses the lufdaten.info API (https://api.luftdaten.info/v1/sensor/{#sensorID}/) or the luftdaten local sensor API (http://{#sensorIP}/data.json).

### Installation

To install the plugin add the plugin to the config.json of pimatic:

###    
    {
      "plugin": "luftdaten"
    }
###

### Device Configuration

There are 2 devices available

1. Luftdaten Device.

Gets PM10, PM2.5 data from specific sensor. The Air Quality Index (AQI) data is calculated from that.
Add the device with the Sensor ID into the devices section:
###    
    {
      "id": "luftdaten",
      "class": "LuftdatenDevice",
      "name": "Device for retrieving data from Luftdaten server",
      "sensorId": "Luftdaten ID of sensor",
      "minutes": 60
    }
###

2. Luftdaten Home Device.

Gets PM10, PM2.5, HUM, Temp, BAR. The Air Quality Index (AQI) data is calculated from that.
Add the device with the local IP address into the devices section:
###    
    {
      "id": "luftdaten",
      "class": "LuftdatenHomeDevice",
      "name": "Device for retrieving data from local sensor",
      "sensorIp": "local IP address of sensor",
      "minutes": 60
    }
###    

### Usage

This makes the following variables available to you in Pimatic.
* ${luftdaten device id}.PM10 (LuftdatenDevice, LuftdatenHomeDevice)
* ${luftdaten device id}.PM25 (LuftdatenDevice, LuftdatenHomeDevice) 
* ${luftdaten device id}.TEMP (LuftdatenHomeDevice)
* ${luftdaten device id}.HUM  (LuftdatenHomeDevice)
* ${luftdaten device id}.BAR  (LuftdatenHomeDevice)
* ${luftdaten device id}.WIFI (LuftdatenHomeDevice)
* ${luftdaten device id}.AQI  (LuftdatenDevice, LuftdatenHomeDevice)
* ${luftdaten device id}.AQI_CODE (LuftdatenDevice, LuftdatenHomeDevice)
* ${luftdaten device id}.AIR_AIR_QUALITY  (LuftdatenDevice, LuftdatenHomeDevice)
