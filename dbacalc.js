//'use strict';

var dba_breakpoints = [
    [0, 10],
    [10, 20],
    [20, 30],
    [30, 40],
    [40, 50],
    [50, 60],
    [60, 70],
    [70, 80],
    [90, 100],
    [100, 110],
    [110, 120],
    [120, 130],
    [130, 140]
];

var dba_labels = [
    'no sound',
    'rustling leaves',
    'background tv studio',
    'quit bedroom',
    'quit library',
    'average home',
    'conversation',
    'vacuum cleaner 1m',
    'kirbside busy road',
    'diesel truck 10m',
    'disco 1m from speaker',
    'chainsaw 1m',
    'threshold of discomfort',
    'threshold of paim',
    'yet aircraft 50m'
];
var dba_colors = [
    'Green1',
    'Green2',
    'Green3',
    'Yellow1',
    'Yellow2',
    'Yellow3',
    'Orange1',
    'Orange2',
    'Red1',
    'Red2',
    'Purple1',
    'Purple2',
    'Maroon',
    'Black'
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
