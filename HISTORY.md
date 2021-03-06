# Release History

* 20190416, V0.2.7
  * Added possibility to use Temperature/Humidity sensor without Pressure (like DHT22). In that case Pressure will have value 0.
* 20190501, V0.3.0
  * Improved API handling and ready for node v8
* 20191109, v0.4.0
  * Luftdaten device is capable of handling Luftdaten and local sensor. In the SensorId field you can input a Luftdaten sensor ID or a local IP address.
  * Luftdaten noise sensor added
  * Added option for latitude, longitude and radius (max 50 km), to find closest sensors
  * Automatic combining of data from closest sensors to get complete dataset
  * Attributes to be shown in the gui, can be selected in the device config
  * The Luftdaten Home device is becoming obsolete and will be removed in a next release.
* 20191109, v0.4.1
  * Changed attribute names back to same names as in previous version (compatibility)
* 20191111, v0.4.2
  * Integrated support files for AQI and DBA calculations
  * All the used sensorId's are now showing in the Gui
* 20191111, v0.4.3
  * bugfix support lib
* 20191120, v0.4.4
  * edit readme.md
* 20191122, v0.4.5
  * better handling of ETIMEDOUT error. After 5 consecutive ETIMEDOUT error's, an error message and reset of values.
* 20191127, v0.4.7
  * bugfix HomeDevice.
