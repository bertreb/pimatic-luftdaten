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
          #env.logger.debug(d[1].sensordatavalues[0])

          if d[1]
            PM10 = d[1].sensordatavalues[0].value
            PM25 = d[1].sensordatavalues[1].value
          else if d[0]
            PM10 = d[0].sensordatavalues[0].value
            PM25 = d[0].sensordatavalues[1].value

          PM10 = Number(Math.round(PM10+'e1')+'e-1') #SDS011 PM10
          PM25 = Number(Math.round(PM25+'e1')+'e-1') #SDS011 PM2.5
          lAqi = Math.max(aqi.pm10(PM10), aqi.pm25(PM25))
          lAqi = Math.min(lAqi, 500)
          lAqi = Math.max(lAqi, 0)
          #lAqi = aqi(PM10, PM25)
 
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
          @_setAttribute "AQI_CODE", "GREEN"
          @_setAttribute "AQI_AIR_QUALITY", "Good"
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
          #env.logger.debug(d.sensordatavalues)

          PM10 = Number(Math.round(d.sensordatavalues[0].value+'e1')+'e-1') #SDS011 PM10
          PM25 = Number(Math.round(d.sensordatavalues[1].value+'e1')+'e-1') #SDS011 PM2.5
          TEMP = Number(Math.round(d.sensordatavalues[2].value+'e1')+'e-1') #BME280_temperature
          HUM = Number(Math.round(d.sensordatavalues[3].value+'e1')+'e-1') #BME280_humidity
          BAR = Number(Math.round(d.sensordatavalues[4].value/100+'e1')+'e-1') #BME280_pressure
          WIFI = Number(Math.round(d.sensordatavalues[8].value+'e1')+'e-1') #signal

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
          #@_setAttribute "PM10", 0 
          #@_setAttribute "PM25", 0
          #@_setAttribute "AQI", 0
          #@_setAttribute "AQI_CODE", "GREEN"
          #@_setAttribute "AQI_AIR_QUALITY", "Good"
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
