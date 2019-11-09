//'use strict';

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

exports.calc = function (dbaLevel) {
    return dba(dbaLevel, dba_breakpoints);
};

// Airnow.gov descriptions by range
exports.label = function (dbaLevel) {
    var idx = breakpointIndex(dbaLevel, dba_breakpoints);
    return dba_labels[idx];
};

// Aqi color mapping. Returns hex color code.
exports.color = function (dbaLevel) {
    var idx = breakpointIndex(dbaLevel, dba_breakpoints);
    return dba_colors[idx];
};
