module.exports = (env) ->
  rp = require 'request-promise'
  aqi = require './aqicalc2.js'

  class Luftdaten extends env.plugins.Plugin
    init: (app, @framework, @config) =>
      deviceConfigDef = require("./device-config-schema")

      @framework.deviceManager.registerDeviceClass("LuftdatenDevice", {
        configDef: deviceConfigDef.LuftdatenDevice,
        createCallback: (config) => new LuftdatenDevice(config)
      })
      @framework.deviceManager.registerDeviceClass("LuftdatenHomeDevice", {
        configDef: deviceConfigDef.LuftdatenHomeDevice,
        createCallback: (config) => new LuftdatenHomeDevice(config)
      })

  class LuftdatenDevice extends env.devices.Device
    attributes:
      PM10:
        description: "The PM10 air quality"
        type: "number"
        unit: 'ug/m3'
        acronym: 'PM10'
      PM25:
        description: "The PM2.5 air quality"
        type: "number"
        unit: 'ug/m3'
        acronym: 'PM2.5'
      AQI:
        description: "The Air Quality Index"
        type: "number"
        unit: '/500'
        acronym: 'AQI'
      AQI_CODE:
        description: "The Air Quality Index code"
        type: "string"
        unit: ''
        acronym: 'AQI code'
      AQI_AIR_QUALITY:
        description: "The Air Quality Description"
        type: "string"
        unit: ''
        acronym: 'Air quality'

    constructor: (@config) ->
      @id = @config.id
      @name = @config.name
      @sensorId = @config.sensorId
      @url = "https://api.luftdaten.info/v1/sensor/#{@sensorId}/"
      @timeout = @config.interval * 60000 # Check for changes every interval in minutes
      @PM10_AQI = 0
      @PM25_AQI = 0
 
      super()
      @requestData()

    destroy: () ->
      @requestPromise.cancel() if @requestPromise?
      clearTimeout @requestTimeout if @requestTimeout?
      super()

    requestData: () =>
      @requestPromise = rp(@url)
        .then((data) =>
          d = JSON.parse(data)
          #reset all values
          PM10 = PM25 = 0
  
          if d[1] # test if second record is available and use that newest data
            dd = d[1]
          else if d[0] # use first record
            dd = d[0]
          for k, val of dd.sensordatavalues
            if (val.value_type).match("P1")
              PM10 = Number(Math.round(val.value+'e1')+'e-1') #PM10
            if (val.value_type).match("P2")
              PM25 = Number(Math.round(val.value+'e1')+'e-1') #PM2.5
  
          lAqi = Math.max(aqi.pm10(PM10), aqi.pm25(PM25))
          lAqi = Math.min(lAqi, 500)
          lAqi = Math.max(lAqi, 0)
  
          @_setAttribute "PM10", PM10
          @_setAttribute "PM25", PM25
          @_setAttribute "AQI", lAqi
          @_setAttribute "AQI_CODE", aqi.aqi_color(lAqi)          
          @_setAttribute "AQI_AIR_QUALITY", aqi.aqi_label(lAqi)          
          @_currentRequest = Promise.resolve()
        )
        .catch((err) =>
          @_setAttribute "PM10", 0 
          @_setAttribute "PM25", 0
          @_setAttribute "AQI", 0
          @_setAttribute "AQI_CODE", "Unknown"
          @_setAttribute "AQI_AIR_QUALITY", "Unknown"
          #env.logger.error(err.message)
          #env.logger.debug(err.stack)
         )

      @_currentRequest = @requestPromise unless @_currentRequest?
      @requestTimeout = setTimeout(@requestData, @timeout)
      return @requestPromise

    _setAttribute: (attributeName, value, discrete = false) ->
      if not discrete or @[attributeName] isnt value
        @[attributeName] = value
        @emit attributeName, value

    getPM10: ->
      @_currentRequest.then(=> @PM10)
      
    getPM25: ->
      @_currentRequest.then(=> @PM25)

    getAQI: ->
      @_currentRequest.then(=> @AQI)

    getAQI_CODE: ->
      @_currentRequest.then(=> @AQI_CODE)

    getAQI_AIR_QUALITY: ->
      @_currentRequest.then(=> @AQI_AIR_QUALITY)

  class LuftdatenHomeDevice extends env.devices.Device
    attributes:
      PM10:
        description: "The PM10 air quality"
        type: "number"
        unit: 'ug/m3'
        acronym: 'PM10'
      PM25:
        description: "The PM2.5 air quality"
        type: "number"
        unit: 'ug/m3'
        acronym: 'PM2.5'
      TEMP:
        description: "The temperature"
        type: "number"
        unit: '°C'
        acronym: 'T'
      HUM:
        description: "The humidity"
        type: "number"
        unit: '%'
        acronym: 'H'
      BAR:
        description: "The air pressure"
        type: "number"
        unit: 'hPa'
        acronym: 'P'
      WIFI:
        description: "The Wifi signal strength"
        type: "number"
        unit: 'dBm'
        acronym: 'W'
      AQI:
        description: "The Air Quality Index"
        type: "number"
        unit: '/500'
        acronym: 'AQI'
      AQI_CODE:
        description: "The Air Quality Index Code"
        type: "string"
        unit: ''
        acronym: 'AQI code'
      AQI_AIR_QUALITY:
        description: "The Air Quality Description"
        type: "string"
        unit: ''
        acronym: 'Air quality'

    constructor: (@config) ->
      @id = @config.id
      @name = @config.name
      @sensorIp = @config.sensorIp
      @url = "http://#{@sensorIp}/data.json"
      @timeout = @config.interval * 60000 # Check for changes every interval in minutes
 
      super()
      @requestData()

    destroy: () ->
      @requestPromise.cancel() if @requestPromise?
      clearTimeout @requestTimeout if @requestTimeout?
      super()

    requestData: () =>
      @requestPromise = rp(@url)
        .then((data) =>
          d = JSON.parse(data)
          #reset all values
          PM10 = PM25 = TEMP = HUM = BAR = WIFI = 0
          for k, val of d.sensordatavalues
              if (val.value_type).match("P1")
                PM10 = Number(Math.round(val.value+'e1')+'e-1') #PM10
              if (val.value_type).match("P2")
                PM25 = Number(Math.round(val.value+'e1')+'e-1') #PM2.5
              if (val.value_type).match("temperature")
                TEMP = Number(Math.round(val.value+'e1')+'e-1') #Temperature
              if (val.value_type).match("humidity")
                HUM = Number(Math.round(val.value+'e1')+'e-1') #Humidity
              if (val.value_type).match("signal")
                WIFI = Number(Math.round(val.value+'e1')+'e-1') #Signal
              if (val.value_type).match("pressure")
                BAR = Number(Math.round(val.value/100+'e1')+'e-1') #Pressure

          lAqi = Math.max(aqi.pm10(PM10), aqi.pm25(PM25))
          lAqi = Math.min(lAqi, 500)
          lAqi = Math.max(lAqi, 0)

          @_setAttribute "PM10", PM10
          @_setAttribute "PM25", PM25
          @_setAttribute "TEMP", TEMP
          @_setAttribute "HUM", HUM
          @_setAttribute "BAR", BAR
          @_setAttribute "WIFI", WIFI
          @_setAttribute "AQI", lAqi
          @_setAttribute "AQI_CODE", aqi.aqi_color(lAqi)          
          @_setAttribute "AQI_AIR_QUALITY", aqi.aqi_label(lAqi)          
          @_currentRequest = Promise.resolve()
        )
        .catch((err) =>
          @_setAttribute "PM10", 0 
          @_setAttribute "PM25", 0
          @_setAttribute "AQI", 0
          @_setAttribute "AQI_CODE", "Unknown"
          @_setAttribute "AQI_AIR_QUALITY", "Unknown"
          #env.logger.error(err.message)
          #env.logger.debug(err.stack)
         )

      @_currentRequest = @requestPromise unless @_currentRequest?
      @requestTimeout = setTimeout(@requestData, @timeout)
      return @requestPromise

    _setAttribute: (attributeName, value, discrete = false) ->
      if not discrete or @[attributeName] isnt value
        @[attributeName] = value
        @emit attributeName, value

    getPM10: ->
      @_currentRequest.then(=> @PM10)
      
    getPM25: ->
      @_currentRequest.then(=> @PM25)

    getTEMP: ->
      @_currentRequest.then(=> @TEMP)

    getHUM: ->
      @_currentRequest.then(=> @HUM)

    getBAR: ->
      @_currentRequest.then(=> @BAR)

    getWIFI: ->
      @_currentRequest.then(=> @WIFI)

    getAQI: ->
      @_currentRequest.then(=> @AQI)

    getAQI_CODE: ->
      @_currentRequest.then(=> @AQI_CODE)

    getAQI_AIR_QUALITY: ->
      @_currentRequest.then(=> @AQI_AIR_QUALITY)

  plugin = new Luftdaten
  return plugin
