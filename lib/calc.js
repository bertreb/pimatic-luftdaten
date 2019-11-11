//'use strict';

var aqi_breakpoints = [
    [0, 50],
    [51, 100],
    [101, 150],
    [151, 200],
    [201, 300],
    [301, 400],
    [401, 500],
];
var pm10_breakpoints = [
    [0, 54],
    [55, 154],
    [155, 254],
    [255, 354],
    [355, 424],
    [425, 504],
    [505, 604],
];
var pm25_breakpoints = [
    [0.0, 12.0],
    [12.1, 35.4],
    [35.5, 55.4],
    [55.5, 150.4],
    [150.5, 250.4],
    [250.5, 350.4],
    [350.5, 500.0],
];
var aqi_labels = [
    'Good',
    'Moderate',
    'Unhealthy for Sensitive Groups',
    'Unhealthy',
    'Very Unhealthy',
    'Hazardous',
    'Hazardous'
];
var aqi_colors = [
    'Green',
    'Yellow',
    'Orange',
    'Red',
    'Purple',
    'Purple',
    'Maroon'
];
var dba_breakpoints = [
    [0, 20],
    [20, 30],
    [30, 50],
    [50, 70],
    [70, 90],
    [90, 120],
    [120, 130],
    [130, 150]
];

var dba_labels = [
    'Silence',
    'Faint',
    'Soft',
    'Moderate',
    'Loud',
    'Very loud',
    'Uncomfortable',
    'Dangerous & painful'
];
var dba_colors = [
    'White',
    'Purple',
    'Blue',
    'Green',
    'Yellow',
    'Red',
    'Brown',
    'Maroon'
];
/*
if (undefined === Array.prototype.findIndex) {
    Array.prototype.findIndex = function (callback) {
        for (var i = 0; i < this.length; i++) {
            if (callback.call(this, this[i], i, this)) {
                return i;
            }
        }
        return -1;
    };
}

function breakpointIndex (value, breakpoints) {
    return breakpoints.findIndex(function (breakpoint) {
        if (null === breakpoint) {
            return false;
        }
        return breakpoint[0] <= value && value <= breakpoint[1];
    });
}
*/

if (undefined === Array.prototype.findIndex) {
    Array.prototype.findIndex = function (callback) {
        for (var i = 0; i < this.length; i++) {
            if (callback.call(this, this[i], i, this)) {
                return i;
            }
        }
        return -1;
    };
}

function breakpointIndex (value, breakpoints) {
    return breakpoints.findIndex(function (breakpoint) {
        if (null === breakpoint) {
            return false;
        }
        return breakpoint[0] <= value && value <= breakpoint[1];
    });
}

function dba (dbaLevel, breakpoints) {
    var index = breakpointIndex(dbaLevel, breakpoints);
    if (-1 === index) {
        return NaN;
    }
    return index;
}

function aqi (concentration, breakpoints) {
    var index = breakpointIndex(concentration, breakpoints);

    if (-1 === index) {
        return NaN;
    }

    var i_high = aqi_breakpoints[index][1],
        i_low = aqi_breakpoints[index][0],
        c_high = breakpoints[index][1],
        c_low = breakpoints[index][0];

    return Math.round((i_high - i_low) / (c_high - c_low) * (concentration - c_low) + i_low);
}


exports.pm10 = function (concentration) {
    return aqi(concentration, pm10_breakpoints);
};

exports.pm25 = function (concentration) {
    return aqi(concentration, pm25_breakpoints);
};

// Airnow.gov descriptions by range
exports.aqi_label = function (aqi) {
    var idx = breakpointIndex(aqi, aqi_breakpoints);
    return aqi_labels[idx];
};

// Aqi color mapping. Returns hex color code.
exports.aqi_color = function (aqi) {
    var idx = breakpointIndex(aqi, aqi_breakpoints);
    return aqi_colors[idx];
};

exports.dba = function (dbaLevel) {
    return dba(dbaLevel, dba_breakpoints);
};

// Airnow.gov descriptions by range
exports.dba_label = function (dbaLevel) {
    var idx = breakpointIndex(dbaLevel, dba_breakpoints);
    return dba_labels[idx];
};

// Aqi color mapping. Returns hex color code.
exports.dba_color = function (dbaLevel) {
    var idx = breakpointIndex(dbaLevel, dba_breakpoints);
    return dba_colors[idx];
};
