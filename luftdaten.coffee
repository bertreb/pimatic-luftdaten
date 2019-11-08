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
      SENSOR_ID:
        description: "The ID(s) of the sensor(s)"
        type: "string"
        unit: ''
        acronym: 'sensor'
        hidden: false
      DISTANCE:
        description: "The distance of the sensor in km"
        type: "number"
        unit: 'km'
        acronym: 'distance'
        hidden: false
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
      BAR_SEA:
        description: "The air pressure"
        type: "number"
        unit: 'hPa'
        acronym: 'Psea'
      WIFI:
        description: "The Wifi signal strength"
        type: "number"
        unit: 'dBm'
        acronym: 'W'
      NOISE_Leq:
        description: "Noise"
        type: "number"
        unit: 'dBA'
        acronym: 'Noise'
      NOISE_Lmin:
        description: "Noise"
        type: "number"
        unit: 'dBA'
        acronym: 'NoiseLm'
      NOISE_Lmax:
        description: "Noise"
        type: "number"
        unit: 'dBA'
        acronym: 'NoiseLM'
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
      @sensorId = if @config?.sensorId? or @config?.sensorID is "" then @config.sensorId else null
      @latitude = if @config?.latitude? or @config?.latitude is "" then @config.latitude else null
      @longitude = if @config?.longitude? or @config?.longitude is "" then @config.longitude else null
      @radius = if @config?.radius? or @config?.radius is ""  then @config.radius else 1
      if @sendorId is 0 and (@latitude is 0 or @longitude is 0)
        throw new Error("No sensor configured")

      @urlLuftdaten = "https://api.luftdaten.info/v1/sensor/#{@sensorId}/"
      @urlLuftdatenArea = "https://api.luftdaten.info/v1/filter/area=#{@latitude},#{@longitude},#{@radius}"
      @urlLocal = "http://#{@sensorId}/data.json"
      @url = null
      @timeout = @config.interval * 60000 # Check for changes every interval in minutes

      if @sensorId?
        if Number.isInteger(Number @sensorId)
          @url = @urlLuftdaten
        else if @sensorId.match(
              "^([01]?\\d\\d?|2[0-4]\\d|25[0-5])\\." +
              "([01]?\\d\\d?|2[0-4]\\d|25[0-5])\\." +
              "([01]?\\d\\d?|2[0-4]\\d|25[0-5])\\." +
              "([01]?\\d\\d?|2[0-4]\\d|25[0-5])$")
            @url = @urlLocal
      else if @latitude? and @longitude?
        @url = @urlLuftdatenArea     

      if not @url? then throw new Error("No valid sensorID, Lat/Lon coordinates or local IP adress")
      
      @attributeValues = {}
      @attributeValues.PM10 = lastState?.PM10?.value or 0.0
      @attributeValues.PM25 = lastState?.PM25?.value or 0.0
      @attributeValues.TEMP = lastState?.TEMP?.value or 0.0
      @attributeValues.HUM = lastState?.HUM?.value or 0.0
      @attributeValues.BAR = lastState?.BAR?.value or 0.0
      @attributeValues.BAR_SEA = lastState?.BAR_SEA?.value or 0.0
      @attributeValues.WIFI = lastState?.WIFI?.value or 0
      @attributeValues.NOISE_Leq = lastState?.NOISE_Leq?.value or 0.0
      @attributeValues.NOISE_Lmin = lastState?.NOISE_Lmin?.value or 0.0
      @attributeValues.NOISE_Lmax = lastState?.NOISE_Lmax?.value or 0.0
      @attributeValues.AQI = lastState?.AQI?.value or 0
      @attributeValues.AQI_CODE = lastState?.AQI_CODE?.value or 0
      @attributeValues.AQI_AIR_QUALITY = lastState?.AQI_AIR_QUALITY?.value or 0
      @attributeValues.DISTANCE = lastState?.DISTANCE?.value or 0
      @attributeValues.SENSOR_ID = lastState?.SENSOR_ID?.value or 0

      for _attr of @attributes
        do (_attr) =>
          @attributes[_attr].hidden = true
          @_createGetter(_attr, =>
            return Promise.resolve @attributeValues[_attr]
          )

      @attributes["DISTANCE"].hidden = true
      @attributes["SENSOR_ID"].hidden = true

      @requestData()

      super()


    destroy: () ->
      @requestPromise.cancel() if @requestPromise?
      clearTimeout @requestTimeout if @requestTimeout?
      super()

    requestData: () =>
      @requestPromise = rp(@url)
        .then((data) =>
          d = JSON.parse(data)
          @_luftdaten = {}
          @_sensors = []
          @_usedSensors = ""
          if Array.isArray(d)
            @_luftdaten = d[0]
            @_lastDistance = 10000
            for _record in d
              if @latiude isnt null and @longitude isnt null
                @_dist = @_distance(@latitude, @longitude, _record.location.latitude, _record.location.longitude)
                if @_dist <= @_lastDistance
                  @_lastDistance = @_dist
                  @attributeValues.DISTANCE = @_dist
                  @attributes["DISTANCE"].hidden = false
                  @attributeValues.SENSOR_ID = _record.sensor.id
                  @attributes["SENSOR_ID"].hidden = false
                  for _val in _record.sensordatavalues
                    # update data will closer values
                    if _val.value_type in @_luftdaten.sensordatavalues
                      @_luftdaten.sensordatavalues[_val.value_type].value = String _record.sensordatavalues[_val.value_type].value
                    #add missing values               
                    unless @_luftdaten.sensordatavalues[_val.value_type]?
                      env.logger.debug _val.value_type + " added to @_luftdaten.sensordatavalues "
                      @_luftdaten.sensordatavalues[_val.value_type] =
                        value_type: _val.value_type
                        value: String _val.value
                        id: _val.id 
              else if @sensorId?
                @attributeValues.SENSOR_ID = _record.sensor.id
                @attributes["SENSOR_ID"].hidden = false
                # ...
                          
              @_sensors.push _record.sensor.id unless _record.sensor.id in @_sensors
          else
            @_luftdaten = d

          if not @_luftdaten?
            env.logger.debug "no data from " + @url
            return
          
          for k, val of @_luftdaten.sensordatavalues
            if (val.value_type).match("P1")
              @attributeValues.PM10 = Number(Math.round(val.value+'e1')+'e-1')
              @attributes.PM10.hidden = false
              @attributes.AQI.hidden = false
              @attributes.AQI_CODE.hidden = false
              @attributes.AQI_AIR_QUALITY.hidden = false
            if (val.value_type).match("P2")
              @attributeValues.PM25 = Number(Math.round(val.value+'e1')+'e-1')
              @attributes.PM25.hidden = false
              @attributes.AQI.hidden = false
              @attributes.AQI_CODE.hidden = false
              @attributes.AQI_AIR_QUALITY.hidden = false
            if (val.value_type).match("temperature")
              @attributeValues.TEMP = Number(Math.round(val.value+'e1')+'e-1')
              @attributes.TEMP.hidden = false
            if (val.value_type).match("humidity")
              @attributeValues.HUM = Number(Math.round(val.value+'e1')+'e-1')
              @attributes.HUM.hidden = false
            if (val.value_type).match("pressure")
              @attributeValues.BAR = Number(Math.round(val.value/100+'e1')+'e-1')
              @attributes.BAR.hidden = false
            if (val.value_type).match("pressure_at_sealevel")
              @attributeValues.BAR_SEA = Number(Math.round(val.value/100+'e1')+'e-1')
              @attributes.BAR_SEA.hidden = false
            if (val.value_type).match("signal")
              @attributeValues.WIFI = Number(Math.round(val.value+'e1')+'e-1')
              @attributes.WIFI.hidden = false
            if (val.value_type).match("noise_LAeq")
              @attributeValues.NOISE_Leq = Number(Math.round(val.value+'e1')+'e-1')
              @attributes.NOISE_Leq.hidden = false
            if (val.value_type).match("noise_LA_min")
              @attributeValues.NOISE_Lmin = Number(Math.round(val.value+'e1')+'e-1')
              @attributes.NOISE_Lmin.hidden = false
            if (val.value_type).match("noise_LA_max")
              @attributeValues.NOISE_Lmax = Number(Math.round(val.value+'e1')+'e-1')
              @attributes.NOISE_Lmax.hidden = false
          
          lAqi = Math.max(aqi.pm10(@attributeValues.PM10), aqi.pm25(@attributeValues.PM25))
          lAqi = Math.min(lAqi, 500)
          lAqi = Math.max(lAqi, 0)
          @attributeValues.AQI = lAqi
          @attributeValues.AQI_CODE = aqi.aqi_color(lAqi)
          @attributeValues.AQI_AIR_QUALITY = aqi.aqi_label(lAqi) 
          
          for _attr of @attributes
            @emit _attr, @attributeValues[_attr]
          @_currentRequest = Promise.resolve()       
        )
        .catch((err) =>
          for _attr of @attributes
            @attributeValues[_attr] = 0
            @emit _attr, @attributeValues[_attr]
          env.logger.error(err.message)
        )

      @_currentRequest = @requestPromise unless @_currentRequest?
      @requestTimeout = setTimeout(@requestData, @timeout)
      return @requestPromise

    _distance: (lat1, lon1, lat2, lon2) ->
      R = 6371
      # Radius of the earth in km
      dLat = @_deg2rad(lat2 - lat1)
      # deg2rad below
      dLon = @_deg2rad(lon2 - lon1)
      a = Math.sin(dLat / 2) * Math.sin(dLat / 2) + Math.cos(@_deg2rad(lat1)) * Math.cos(@_deg2rad(lat2)) * Math.sin(dLon / 2) * Math.sin(dLon / 2)
      c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a))
      d = R * c
      # Distance in km
      return Number d

    _deg2rad: (deg) ->
      return deg * Math.PI / 180


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
