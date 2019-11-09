# Release History

* 20190416, V0.2.7
  * Added possibility to use Temperature/Humidity sensor without Pressure (like DHT22). In that case Pressure will have value 0.
* 20190501, V0.3.0
  * Improved API handling and ready for node v8
* 20191108, v0.4.0
  * Luftdaten device is capable of handling Luftdaten and local sensor. In the SensorId field you can input both types of identifiers.
  * Attributes will become visible when data for that attribute is received
  * Luftdaten Noise sensor added
  * Added lat, lon, radius option to find closest sensors
  * Automatic combining of data from closest sensors to get complete dataset
  * The LuftdatenHome device will become obsolete.
