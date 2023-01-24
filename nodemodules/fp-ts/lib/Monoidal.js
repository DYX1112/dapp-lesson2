"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
var function_1 = require("./function");
function fromApplicative(F) {
    var f = function (a) { return function (b) { return [a, b]; }; };
    return {
        URI: F.URI,
        map: F.map,
        unit: function () { return F.of(undefined); },
        mult: function (fa, fb) { return F.ap(F.map(fa, f), fb); }
    };
}
exports.fromApplicative = fromApplicative;
function toApplicative(M) {
    return {
        URI: M.URI,
        map: M.map,
        of: function (a) { return M.map(M.unit(), function_1.constant(a)); },
        ap: function (fab, fa) { return M.map(M.mult(fab, fa), function (_a) {
            var f = _a[0], a = _a[1];
            return f(a);
        }); }
    };
}
exports.toApplicative = toApplicative;
