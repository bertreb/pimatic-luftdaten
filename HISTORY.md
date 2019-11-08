# Release History

* 20190416, V0.2.7
  * Added possibility to use Temperature/Humidity sensor without Pressure (like DHT22). In that case Pressure will have value 0.
* 20190501, V0.3.0
  * Improved API handling and ready for node v8
* 20191108, v0.4.0
  * Added lat, lon, radius option to find closest sensors
  * Luftdaten device is capable of handling luftdaten and local sensor. In the SensorId field you can input both types of identifiers. The LuftdatenHome device will become obsolete.
  * attributes will become visible when data for that attribute is received
  * Automatic combining of data from closest sensors to get complete dataset
  * Luftdaten Noise sensor added
