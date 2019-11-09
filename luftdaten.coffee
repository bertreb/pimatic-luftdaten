module.exports = (env) ->
  rp = require 'request-promise'
  aqi = require './lib/aqicalc2.js'
  dba = require './lib/dbacalc.js'
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
      sensorId:
        description: "The ID(s) of the sensor(s)"
        type: "string"
        unit: ''
        acronym: 'sensor'
      distance:
        description: "The distance of the sensor in km"
        type: "number"
        unit: 'km'
        acronym: 'distance'
      pm10:
        description: "The PM10 air quality"
        type: "number"
        unit: 'ug/m3'
        acronym: 'pm10'
      pm25:
        description: "The PM2.5 air quality"
        type: "number"
        unit: 'ug/m3'
        acronym: 'pm2.5'
      temperature:
        description: "The temperature"
        type: "number"
        unit: '°C'
        acronym: 'temp'
      humidity:
        description: "The humidity"
        type: "number"
        unit: '%'
        acronym: 'hum'
      bar:
        description: "The air pressure"
        type: "number"
        unit: 'hPa'
        acronym: 'bar'
      barSea:
        description: "The air pressure"
        type: "number"
        unit: 'hPa'
        acronym: 'barsea'
      wifi:
        description: "The Wifi signal strength"
        type: "number"
        unit: 'dBm'
        acronym: 'wifi'
      noiseLevel:
        description: "Noise level"
        type: "string"
        unit: ''
        acronym: 'noiseL'
      noiseLeq:
        description: "Noise"
        type: "number"
        unit: 'dBA'
        acronym: 'noise'
      noiseLmin:
        description: "noiseLm"
        type: "number"
        unit: 'dBA'
        acronym: 'noiseLm'
      noiseLmax:
        description: "Noise"
        type: "number"
        unit: 'dBA'
        acronym: 'noiseLM'
      aqi:
        description: "The Air Quality Index"
        type: "number"
        unit: '/500'
        acronym: 'aqi'
      aqiCode:
        description: "The Air Quality Index code"
        type: "string"
        unit: ''
        acronym: 'aqiCode'
      aqiAirQuality:
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
      if @sendorId is null and (@latitude is null or @longitude is null)
        throw new Error("No sensor configured")
      
      @attributes = _.cloneDeep(@attributes)

      @urlLuftdaten = "https://api.luftdaten.info/v1/sensor/#{@sensorId}/"
      @urlLuftdatenArea = "https://api.luftdaten.info/v1/filter/area=#{@latitude},#{@longitude},#{@radius}"
      @urlLocal = "http://#{@sensorId}/data.json"
      @url = null
      @timeout = @config.interval * 60000 # Check for changes every interval in minutes
      @maxDistance = 50 # km
      if @radius > @maxDistance
        env.logger.info "Radius is too large and is set to maximum = " + @maxDistance + " km"

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
      @attributeValues.pm10 = lastState?.pm10?.value or 0.0
      @attributeValues.pm25 = lastState?.pm25?.value or 0.0
      @attributeValues.temperature = lastState?.temperature?.value or 0.0
      @attributeValues.humidity = lastState?.humidity?.value or 0.0
      @attributeValues.bar = lastState?.bar?.value or 0.0
      @attributeValues.barSea = lastState?.barSea?.value or 0.0
      @attributeValues.wifi = lastState?.wifi?.value or 0
      @attributeValues.noiseLevel = lastState?.noiseLevel?.value or ""
      @attributeValues.noiseLeq = lastState?.noiseLeq?.value or 0.0
      @attributeValues.noiseLmin = lastState?.noiseLmin?.value or 0.0
      @attributeValues.noiseLmax = lastState?.noiseLmax?.value or 0.0
      @attributeValues.aqi = lastState?.aqi?.value or 0
      @attributeValues.aqiCode = lastState?.aqiCode?.value or 0
      @attributeValues.aqiAirQuality = lastState?.aqiAirQuality?.value or 0
      @attributeValues.distance = lastState?.distance?.value or 0
      @attributeValues.sensorId = lastState?.sensorId?.value or 0

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

      ###
      for _attr of @attributes
        do (_attr) =>
          @attributes[_attr].hidden = true
          @_createGetter(_attr, =>
            return Promise.resolve @attributeValues[_attr]
          )
      ###    

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
              if @sensorId isnt null
                #check if most recent record is used
                if new Date(_record.timestamp) >= new Date(@_luftdaten.timestamp)
                  @attributeValues.sensorId = _record.sensor.id
                  @_luftdaten = _record
                if @latitude isnt null and @longitude isnt null
                  @_dist = @_distance(@latitude, @longitude, _record.location.latitude, _record.location.longitude)
                  @attributeValues.distance = @_dist
              else if @latiude isnt null and @longitude isnt null
                # search outside in for closest sensors to get full data
                @_dist = @_distance(@latitude, @longitude, _record.location.latitude, _record.location.longitude)
                if @_dist <= @_lastDistance
                  @_lastDistance = @_dist
                  @attributeValues.distance = @_dist
                  @attributeValues.sensorId = _record.sensor.id
                  for _val in _record.sensordatavalues
                    # update data will closer values
                    if _val.value_type in @_luftdaten.sensordatavalues
                      @_luftdaten.sensordatavalues[_val.value_type].value = String _record.sensordatavalues[_val.value_type].value
                    #add missing values
                    unless @_luftdaten.sensordatavalues[_val.value_type]?
                      env.logger.debug _val.value_type + " added to sensor data, sensorID: " + _record.sensor.id
                      @_luftdaten.sensordatavalues[_val.value_type] =
                        value_type: _val.value_type
                        value: String _val.value
                        id: _val.id
          else
            @_luftdaten = d

          if not @_luftdaten?
            env.logger.debug "no data from " + @url
            return
          # test

          for k, val of @_luftdaten.sensordatavalues
            if (val.value_type).match("P1")
              @attributeValues.pm10 = Number(Math.round(val.value+'e1')+'e-1')
            if (val.value_type).match("P2")
              @attributeValues.pm25 = Number(Math.round(val.value+'e1')+'e-1')
            if (val.value_type).match("temperature")
              @attributeValues.temperature = Number(Math.round(val.value+'e1')+'e-1')
            if (val.value_type).match("humidity")
              @attributeValues.humidity = Number(Math.round(val.value+'e1')+'e-1')
            if (val.value_type).match("pressure")
              @attributeValues.bar = Number(Math.round(val.value/100+'e1')+'e-1')
            if (val.value_type).match("pressure_at_sealevel")
              @attributeValues.barSea = Number(Math.round(val.value/100+'e1')+'e-1')
            if (val.value_type).match("signal")
              @attributeValues.wifi = Number(Math.round(val.value+'e1')+'e-1')
            if (val.value_type).match("noise_LAeq")
              @attributeValues.noiseLeq = Number(Math.round(val.value+'e1')+'e-1')
              @attributeValues.noiseLevel = dba.label(@attributeValues.noiseLeq)
            if (val.value_type).match("noise_LA_min")
              @attributeValues.noiseLmin = Number(Math.round(val.value+'e1')+'e-1')
            if (val.value_type).match("noise_LA_max")
              @attributeValues.noiseLmax = Number(Math.round(val.value+'e1')+'e-1')

          lAqi = Math.max(aqi.pm10(@attributeValues.pm10), aqi.pm25(@attributeValues.pm25))
          lAqi = Math.min(lAqi, 500)
          lAqi = Math.max(lAqi, 0)
          @attributeValues.aqi = lAqi
          @attributeValues.aqiCode = aqi.aqi_color(lAqi)
          @attributeValues.aqiAirQuality = aqi.aqi_label(lAqi)

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
      pm10:
        description: "The PM10 air quality"
        type: "number"
        unit: 'ug/m3'
        acronym: 'pm10'
      pm25:
        description: "The PM2.5 air quality"
        type: "number"
        unit: 'ug/m3'
        acronym: 'pm2.5'
      temperature:
        description: "The temperature"
        type: "number"
        unit: '°C'
        acronym: 'temp'
      humidity:
        description: "The humidity"
        type: "number"
        unit: '%'
        acronym: 'hum'
      bar:
        description: "The air pressure"
        type: "number"
        unit: 'hPa'
        acronym: 'bar'
      wifi:
        description: "The Wifi signal strength"
        type: "number"
        unit: 'dBm'
        acronym: 'wifi'
      aqi:
        description: "The Air Quality Index"
        type: "number"
        unit: '/500'
        acronym: 'aqi'
      aqiCode:
        description: "The Air Quality Index Code"
        type: "string"
        unit: ''
        acronym: 'aqiCode'
      aqiAirQuality:
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
          pm10 = pm25 = temperature = humidity = bar = wifi = 0
          for k, val of d.sensordatavalues
              if (val.value_type).match("P1")
                pm10 = Number(Math.round(val.value+'e1')+'e-1') #PM10
              if (val.value_type).match("P2")
                pm25 = Number(Math.round(val.value+'e1')+'e-1') #PM2.5
              if (val.value_type).match("temperature")
                temperature = Number(Math.round(val.value+'e1')+'e-1') #Temperature
              if (val.value_type).match("humidity")
                humidity = Number(Math.round(val.value+'e1')+'e-1') #Humidity
              if (val.value_type).match("signal")
                wifi = Number(Math.round(val.value+'e1')+'e-1') #Signal
              if (val.value_type).match("pressure")
                bar = Number(Math.round(val.value/100+'e1')+'e-1') #Pressure

          lAqi = Math.max(aqi.pm10(pm10), aqi.pm25(pm25))
          lAqi = Math.min(lAqi, 500)
          lAqi = Math.max(lAqi, 0)

          @_setAttribute "pm10", pm10
          @_setAttribute "pm25", pm25
          @_setAttribute "temperature", temperature
          @_setAttribute "humidity", humidity
          @_setAttribute "bar", bar
          @_setAttribute "wifi", wifi
          @_setAttribute "aqi", lAqi
          @_setAttribute "aqiCode", aqi.aqi_color(lAqi)
          @_setAttribute "aqiAirQuality", aqi.aqi_label(lAqi)
          @_currentRequest = Promise.resolve()
        )
        .catch((err) =>
          @_setAttribute "pm10", 0
          @_setAttribute "pm25", 0
          @_setAttribute "aqi", 0
          @_setAttribute "aqiCode", "Unknown"
          @_setAttribute "aqiairQuality", "Unknown"
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

    getPm10: ->
      @_currentRequest.then(=> @pm10)

    getPm25: ->
      @_currentRequest.then(=> @pm25)

    getTemperature: ->
      @_currentRequest.then(=> @temperature)

    getHumidity: ->
      @_currentRequest.then(=> @humidity)

    getBar: ->
      @_currentRequest.then(=> @bar)

    getWifi: ->
      @_currentRequest.then(=> @wifi)

    getAqi: ->
      @_currentRequest.then(=> @aqi)

    getAqiCode: ->
      @_currentRequest.then(=> @aqiCode)

    getAqiAirQuality: ->
      @_currentRequest.then(=> @aqiAirQuality)

  plugin = new Luftdaten
  return plugin
