pimatic-luftdaten
=================

Pimatic plugin that retrieves PM10 and pM2.5 sensordata from Luftdaten.info or a luftdaten local sensor.
More info at https://luftdaten.info

No API key required, uses: 
- https://api.luftdaten.info/v1/sensor/{#sensorID}/
- http://{#sensorIp}/data.json

### Manual installation

```
cd pimatic-app/node_modules
git clone https://github.com/bertreb/pimatic-luftdaten
cd pimatic-luftdaten
npm install
```

### Automatic installation

Add the plugin to the plugin section:

    {
      "plugin": "luftdaten",
      "debug": false
    }

#### Device Configuration

There are 2 devices available

1. Luftdaten Device
Gets PM10, PM2.5 data from specific sensor. The AQI data is calculated from that
Add the device with the Sensor ID into the devices section:
    {
      "id": "luftdaten",
      "class": "LuftdatenDevice",
      "name": "Device for retrieving data from Luftdaten server",
      "sensorId": "Luftdaten ID of sensor",
      "minutes": 60
    }
    
2. Luftdaten Home Device
Gets PM10, PM2.5, HUM, Temp, BAR. The AQI data is calculated from that
Add the device with the local IP address into the devices section:
    {
      "id": "luftdaten",
      "class": "LuftdatenHomeDevice",
      "name": "Device for retrieving data from local sensor",
      "sensorIp": "local IP address of sensor",
      "minutes": 60
    }
    

### Usage

This makes the following variables available to you in Pimatic.
- $<luftdaten device id>.PM10	(LuftdatenDevice, LuftdatenHomeDevice)
- $<luftdaten device id>.PM25	(LuftdatenDevice, LuftdatenHomeDevice) 
- $<luftdaten device id>.TEMP	(LuftdatenHomeDevice)
- $<luftdaten device id>.HUM	(LuftdatenHomeDevice)
- $<luftdaten device id>.BAR	(LuftdatenHomeDevice)
- $<luftdaten device id>.WIFI	(LuftdatenHomeDevice)
- $<luftdaten device id>.AQI	(LuftdatenDevice, LuftdatenHomeDevice)
- $<luftdaten device id>.AQI_CODE	(LuftdatenDevice, LuftdatenHomeDevice)
- $<luftdaten device id>.AIR_AIR_QUALITY  (LuftdatenDevice, LuftdatenHomeDevice)
