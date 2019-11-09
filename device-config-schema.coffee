module.exports ={
  title: "pimatic-luftdaten device config schemas"
  LuftdatenDevice: {
    title: "LuftdatenDevice"
    type: "object"
    extensions: ["xLink", "xAttributeOptions"]
    properties:
      sensorId:
        description: "Luftdaten sensor ID or local IP address of Luftdaten sensor"
        type: "string"
        required: false
      latitude:
        description: "Latitude of the location you want luftdaten info for"
        type: "number"
        required: false
      longitude:
        description: "Longitude of the location you want luftdaten info for"
        type: "number"
        required: false
      radius:
        description: "The radius in km for detecting a luftdaten sensor, default is 1 km"
        type: "number"
        default: 1
        required: false
      attributes:
        description: "Attributes which shall be exposed by the device"
        type: "array"
        default: [
          {
            name: "sensorId"
            label: "sensor"
          },
          {
            name: "pm10"
            label: "pm10"
          },
          {
            name: "pm25"
            label: "pm25"
          }
        ]
        format: "table"
        items:
          type: "object"
          properties:
            name:
              enum: [
                "sensorId", "distance", "pm10", "pm25",
                "temperature", "humidity", "bar", "barSeaLevel",
                "wifi", "noiseLevel", "noiseLeq",
                "noiseLmin", "noiseLmax", "aqi",
                "aqiCode", "aqiAirQuality"
              ]
              description: "Air quality related attributes"
      interval:
        description: "Minutes for updating data"
        type: "integer"
        default: 60
  },
  LuftdatenHomeDevice: {
    title: "LuftdatenHomeDevice"
    type: "object"
    extensions: ["xLink", "xAttributeOptions"]
    properties:
      sensorIp:
        description: "Local IP address of Luftdaten sensor"
        type: "string"
        required: true
      interval:
        description: "Minutes for updating data"
        type: "integer"
        default: 60
  }
}
