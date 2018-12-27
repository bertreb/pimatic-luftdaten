module.exports ={
  title: "pimatic-luftdaten device config schemas"
  LuftdatenDevice: {
    title: "LuftdatenDevice"
    type: "object"
    extensions: ["xLink", "xAttributeOptions"]
    properties:
      sensorId:
        description: "Sensor ID of Luftdaten sensor"
        type: "string"
        required: true
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
