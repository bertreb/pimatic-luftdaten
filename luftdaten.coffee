module.exports = (env) ->
  rp = require 'request-promise'
  calc = require './lib/calc.js'
  _ = env.require 'lodash'

  class Luftdaten extends env.plugins.Plugin
    init: (app, @framework, @config) =>
      deviceConfigDef = require("./device-config-schema")

      @framework.deviceManager.registerDeviceClass("LuftdatenDevice", {
        configDef: deviceConfigDef.LuftdatenDevice,
        createCallback: (config) -> new LuftdatenDevice(config)
      })
      @framework.deviceManager.registerDeviceClass("LuftdatenHomeDevice", {
        configDef: deviceConfigDef.LuftdatenHomeDevice,
        createCallback: (config) -> new LuftdatenHomeDevice(config)
      })

  class LuftdatenDevice extends env.devices.Device

    attributesTemplate:
      SENSOR_ID:
        description: "The ID(s) of the sensor(s)"
        type: "string"
        unit: ''
        acronym: 'sensor'
      DISTANCE:
        description: "The distance of the sensor in km"
        type: "number"
        unit: 'km'
        acronym: 'distance'
      PM10:
        description: "The PM10 air quality"
        type: "number"
        unit: 'ug/m3'
        acronym: 'PM10'
      PM25:
        description: "The PM2.5 air quality"
        type: "number"
        unit: 'ug/m3'
        acronym: 'pm2.5'
      TEMP:
        description: "The temperature"
        type: "number"
        unit: '°C'
        acronym: 'temp'
      HUM:
        description: "The humidity"
        type: "number"
        unit: '%'
        acronym: 'hum'
      BAR:
        description: "The air pressure"
        type: "number"
        unit: 'hPa'
        acronym: 'bar'
      BAR_SEA:
        description: "The air pressure"
        type: "number"
        unit: 'hPa'
        acronym: 'barsea'
      WIFI:
        description: "The Wifi signal strength"
        type: "number"
        unit: 'dBm'
        acronym: 'wifi'
      NOISE_LEVEL:
        description: "Noise level"
        type: "string"
        unit: ''
        acronym: 'sounds'
      NOISE_LEQ:
        description: "Noise"
        type: "number"
        unit: 'dBA'
        acronym: 'noise'
      NOISE_LMIN:
        description: "noiseLm"
        type: "number"
        unit: 'dBA'
        acronym: 'noiseLm'
      NOISE_LMAX:
        description: "Noise"
        type: "number"
        unit: 'dBA'
        acronym: 'noiseLM'
      AQI:
        description: "The Air Quality Index"
        type: "number"
        unit: '/500'
        acronym: 'aqi'
      AQI_CODE:
        description: "The Air Quality Index code"
        type: "string"
        unit: ''
        acronym: 'aqiCode'
      AQI_AIR_QUALITY:
        description: "The Air Quality Description"
        type: "string"
        unit: ''
        acronym: 'airQuality'

    constructor: (@config) ->
      @id = @config.id
      @name = @config.name
      @sensorId = if @config?.sensorId? and @config?.sensorId isnt "" then @config.sensorId else null
      @latitude = if @config?.latitude?  and @config?.latitude isnt "" then @config.latitude else null
      @longitude = if @config?.longitude?  and @config?.longitude isnt "" then @config.longitude else null
      @radius = if @config?.radius? or @config?.radius is ""  then @config.radius else 1
      @connErrs = 0
      if @sendorId is null and (@latitude is null or @longitude is null)
        throw new Error("No sensor configured")
      
      @attributes = _.cloneDeep(@attributes)
      @usedSensors = {}
      @sensorId = if @sensorId? then @sensorId.replace(/\s+/g,'')
      @_requestTypes = 
        single: 1
        multi: 2
        area: 3
        local: 4
      @requestType = null

      @urlLuftdaten = "https://api.luftdaten.info/v1/sensor/#{@sensorId}/"
      @urlLuftdatenArea = "https://api.luftdaten.info/v1/filter/area=#{@latitude},#{@longitude},#{@radius}"
      @urlLocal = "http://#{@sensorId}/data.json"
      @url = null
      @timeout = @config.interval * 60000 # Check for changes every interval in minutes
      @maxDistance = 50 # km
      if @radius > @maxDistance
        @radius = @maxDistance
        env.logger.info "Radius is too large and is set to maximum = " + @maxDistance + " km"

      if @sensorId?
        if Number.isInteger(Number @sensorId)
          @url = @urlLuftdaten
          @requestType = @_requestTypes.single
        else if @sensorId.match(
              "^([01]?\\d\\d?|2[0-4]\\d|25[0-5])\\." +
              "([01]?\\d\\d?|2[0-4]\\d|25[0-5])\\." +
              "([01]?\\d\\d?|2[0-4]\\d|25[0-5])\\." +
              "([01]?\\d\\d?|2[0-4]\\d|25[0-5])$")
            @url = @urlLocal
            @requestType = @_requestTypes.local
      else if @latitude? and @longitude?
        @url = @urlLuftdatenArea
        @requestType = @_requestTypes.area

      if not @url? then throw new Error("Not a valid sensorID, Lat/Lon coordinates or local IP adress")

      @attributeValues = {}
      @attributeValues.PM10 = lastState?.PM10?.value or 0.0
      @attributeValues.PM25 = lastState?.PM25?.value or 0.0
      @attributeValues.TEMP = lastState?.TEMP?.value or 0.0
      @attributeValues.HUM = lastState?.HUM?.value or 0.0
      @attributeValues.BAR = lastState?.BAR?.value or 0.0
      @attributeValues.BAR_SEA = lastState?.BAR_SEA?.value or 0.0
      @attributeValues.WIFI = lastState?.WIFI?.value or 0
      @attributeValues.NOISE_LEVEL = lastState?.NOISE_LEVEL?.value or ""
      @attributeValues.NOISE_LEQ = lastState?.NOISE_LEQ?.value or 0.0
      @attributeValues.NOISE_LMIN = lastState?.NOISE_LMIN?.value or 0.0
      @attributeValues.NOISE_LMAX = lastState?.NOISE_LMAX?.value or 0.0
      @attributeValues.AQI = lastState?.AQI?.value or 0
      @attributeValues.AQI_CODE = lastState?.AQI_CODE?.value or 0
      @attributeValues.AQI_AIR_QUALITY = lastState?.AQI_AIR_QUALITY?.value or 0
      @attributeValues.DISTANCE = lastState?.DISTANCE?.value or 0
      @attributeValues.SENSOR_ID = lastState?.SENSOR_ID?.value or 0

      for attribute in @config.attributes
        do (attribute) =>
          @attributes[attribute.name] =
            description: @attributesTemplate[attribute.name].description
            type: @attributesTemplate[attribute.name].type
            unit: if @attributesTemplate[attribute.name].unit? then @attributesTemplate[attribute.name].unit else ""
            label: if @attributesTemplate[attribute.name].label? then @attributesTemplate[attribute.name].label else attribute.name
            acronym: if  @attributesTemplate[attribute.name].acronym? then @attributesTemplate[attribute.name].acronym else attribute.name
          @_createGetter attribute.name, () =>
            return Promise.resolve @attributeValues[attribute]

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
          if Array.isArray(d)
            @_luftdaten = d[0]
            @_lastDistance = Math.min(@radius, @maxDistance)
            for _record in d
              if @requestType is @_requestTypes.single # or @requestType is @_requestTypes.multi#@sensorId?
                #check if most recent record is used
                for _values in _record.sensordatavalues
                  @usedSensors[_values.value_type] =
                    value_type: _values.value_type
                    id: _record.sensor.id
                  #check if most recent record is used
                if new Date(_record.timestamp) >= new Date(@_luftdaten.timestamp)
                  @attributeValues.SENSOR_ID = _record.sensor.id
                  @_luftdaten = _record
                if @requestType is @_requestTypes.area #@latitude isnt null and @longitude isnt null
                  @_dist = @_distance(@latitude, @longitude, _record.location.latitude, _record.location.longitude)
                  @attributeValues.DISTANCE = @_dist
              else if @requestType is @_requestTypes.area #@latiude isnt null and @longitude isnt null
                # search outside in for closest sensors to get full data
                @_dist = @_distance(@latitude, @longitude, _record.location.latitude, _record.location.longitude)
                if @_dist <= @_lastDistance
                  @_lastDistance = @_dist
                  @attributeValues.DISTANCE = @_dist
                  for _val in _record.sensordatavalues
                    # update data will closer values
                    @usedSensors[_val.value_type] =
                      value_type: _val.value_type
                      id: _record.sensor.id
                    if _val.value_type in @_luftdaten.sensordatavalues
                      #update value of existing value_type
                      @_luftdaten.sensordatavalues[_val.value_type].value = String _record.sensordatavalues[_val.value_type].value
                    else 
                      #add closer missing value_type, value and id
                      env.logger.debug _val.value_type + " added to sensor data, sensorID: " + _record.sensor.id
                      @_luftdaten.sensordatavalues[_val.value_type] =
                        value_type: _val.value_type
                        value: String _val.value
                        id: _val.id
          else
            @_luftdaten = d

          @sensorList = []
          for sensor, val of @usedSensors
            unless val.id in @sensorList
              @sensorList.push val.id
          @attributeValues.SENSOR_ID = @sensorList

          if not @_luftdaten?
            env.logger.debug "no data from " + @url
            return
 
          for k, val of @_luftdaten.sensordatavalues
            if (val.value_type).match("P1")
              @attributeValues.PM10 = Number(Math.round(val.value+'e1')+'e-1')
            if (val.value_type).match("P2")
              @attributeValues.PM25 = Number(Math.round(val.value+'e1')+'e-1')
            if (val.value_type).match("temperature")
              @attributeValues.TEMP = Number(Math.round(val.value+'e1')+'e-1')
            if (val.value_type).match("humidity")
              @attributeValues.HUM = Number(Math.round(val.value+'e1')+'e-1')
            if (val.value_type).match("pressure")
              @attributeValues.BAR = Number(Math.round(val.value/100+'e1')+'e-1')
            if (val.value_type).match("pressure_at_sealevel")
              @attributeValues.BAR_SEA = Number(Math.round(val.value/100+'e1')+'e-1')
            if (val.value_type).match("signal")
              @attributeValues.WIFI = Number(Math.round(val.value+'e1')+'e-1')
            if (val.value_type).match("noise_LAeq")
              @attributeValues.NOISE_LEQ = Number(Math.round(val.value+'e1')+'e-1')
              @attributeValues.NOISE_LEVEL = calc.dba_label(@attributeValues.NOISE_LEQ)
            if (val.value_type).match("noise_LA_min")
              @attributeValues.NOISE_LMIN = Number(Math.round(val.value+'e1')+'e-1')
            if (val.value_type).match("noise_LA_max")
              @attributeValues.NOISE_LMAX = Number(Math.round(val.value+'e1')+'e-1')

          lAqi = Math.max(calc.pm10(@attributeValues.PM10), calc.pm25(@attributeValues.PM25))
          lAqi = Math.min(lAqi, 500)
          lAqi = Math.max(lAqi, 0)
          @attributeValues.AQI = lAqi
          @attributeValues.AQI_CODE = calc.aqi_color(lAqi)
          @attributeValues.AQI_AIR_QUALITY = calc.aqi_label(lAqi)

          for _attr of @attributes
            @emit _attr, @attributeValues[_attr]
          @_currentRequest = Promise.resolve()
          @connErrs = 0
        )
        .catch((err) =>
          if err.indexOff('ETIMEDOUT') >= 0
            env.logger.error("Luftdaten is not responding")
            @connErrs +=1
            if @connErrs > 4
              for _attr of @attributes
                @attributeValues[_attr] = 0
                @emit _attr, @attributeValues[_attr]
              @connErrs = 0
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
        acronym: 'pm10'
      PM25:
        description: "The PM2.5 air quality"
        type: "number"
        unit: 'ug/m3'
        acronym: 'pm2.5'
      TEMP:
        description: "The temperature"
        type: "number"
        unit: '°C'
        acronym: 'temp'
      HUM:
        description: "The humidity"
        type: "number"
        unit: '%'
        acronym: 'hum'
      BAR:
        description: "The air pressure"
        type: "number"
        unit: 'hPa'
        acronym: 'bar'
      WIFI:
        description: "The Wifi signal strength"
        type: "number"
        unit: 'dBm'
        acronym: 'wifi'
      AQI:
        description: "The Air Quality Index"
        type: "number"
        unit: '/500'
        acronym: 'aqi'
      AQI_CODE:
        description: "The Air Quality Index Code"
        type: "string"
        unit: ''
        acronym: 'aqiCode'
      AQI_AIR_QUALITY:
        description: "The Air Quality Description"
        type: "string"
        unit: ''
        acronym: 'airQuality'

    constructor: (@config) ->
      @id = @config.id
      @name = @config.name
      @sensorIp = @config.sensorIp
      @url = "http://#{@sensorIp}/data.json"
      @timeout = @config.interval * 60000 # Check for changes every interval in minutes
      @connErrs = 0
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

          lAqi = Math.max(calc.pm10(PM10), calc.pm25(PM25))
          lAqi = Math.min(lAqi, 500)
          lAqi = Math.max(lAqi, 0)

          @_setAttribute "PM10", PM10
          @_setAttribute "PM25", PM25
          @_setAttribute "TEMP", TEMP
          @_setAttribute "HUM", HUM
          @_setAttribute "BAR", BAR
          @_setAttribute "WIFI", WIFI
          @_setAttribute "AQI", lAqi
          @_setAttribute "AQI_CODE", calc.aqi_color(lAqi)
          @_setAttribute "AQI_AIR_QUALITY", calc.aqi_label(lAqi)
          @_currentRequest = Promise.resolve()
        )
        .catch((err) =>
          if err.indexOff('ETIMEDOUT') >= 0
            env.logger.error("Luftdaten is not responding")
            @connErrs +=1
            if @connErrs > 4
              @_setAttribute "PM10", 0
              @_setAttribute "PM25", 0
              @_setAttribute "AQI", 0
              @_setAttribute "AQI_CODE", "Unknown"
              @_setAttribute "AQI_AIR_QUALITY", "Unknown"
              @connErrs = 0
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
      @_currentRequest.then(=> @bar)

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
