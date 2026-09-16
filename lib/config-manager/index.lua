--[[
Name: Config Manager
Author: Navatusein
License: MIT
Version: 1.0
Dependencies: Class Builder
--]]

return {
  manager = require("lib.config-manager.config-manager"),
  validators = {
    address = require("lib.config-manager.validators.address-validator"),
    boolean = require("lib.config-manager.validators.boolean-validator"),
    color = require("lib.config-manager.validators.color-validator"),
    enum = require("lib.config-manager.validators.enum-validator"),
    number = require("lib.config-manager.validators.number-validator"),
    object = require("lib.config-manager.validators.object-validator"),
    objectList = require("lib.config-manager.validators.object-list-validator"),
    side = require("lib.config-manager.validators.side-validator"),
    string = require("lib.config-manager.validators.string-validator"),
    typedObjectList = require("lib.config-manager.validators.typed-object-list-validator"),
  }
}