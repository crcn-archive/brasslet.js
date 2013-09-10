CallChain = require "./callChain"
flatstack = require "flatstack"
type      = require "type-component"
events = require("events")


class Fasten extends events.EventEmitter

  ###
  ###

  constructor: () ->
    @_callChainOptions = {}
    @_callstack = flatstack()

  ###
  ###

  add: (name, options) ->   
    @_callChainOptions[name] = @_fixOps options
    @

  ### 
  ###

  wrap: (type, target) ->
    new CallChain({ fasten: @, type: type, target: target, methods: @_callChainOptions[type] })

  ###
  ###

  _fixOps: (ops) ->
    return @_arrayToOps(ops) if type(ops) is "array"
    return ops

  ###
  ###

  _arrayToOps: (ops) ->
    newOps = {}
    for opName in ops
      newOps[opName] = () -> @
    newOps


module.exports = () -> new Fasten()