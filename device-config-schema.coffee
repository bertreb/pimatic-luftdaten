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
            name: "SENSOR_ID"
          },
          {
            name: "PM10"
          },
          {
            name: "PM25"
          }
        ]
        format: "table"
        items:
          type: "object"
          properties:
            name:
              enum: [
                "SENSOR_ID", "DISTANCE", "PM10", "PM25",
                "TEMP", "HUM", "BAR", "BAR_SEA",
                "WIFI", "NOISE_LEVEL", "NOISE_LEQ",
                "NOISE_LMIN", "NOISE_LMAX", "AQI",
                "AQI_CODE", "AQI_AIR_QUALITY"
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
