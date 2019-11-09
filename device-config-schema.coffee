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
