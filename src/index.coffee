CallChain = require "./callChain"
flatstack = require "flatstack"
type      = require "type-component"
events = require("events")
_ = require "underscore"


class Fasten extends events.EventEmitter

  ###
  ###

  constructor: () ->
    @_callChainOptions = {}

  ###
  ###

  add: (name, options) ->   
    @_callChainOptions[name] = @_fixOps options
    @

  ###
  ###

  options: () -> @_callChainOptions

  ###
  ###

  all: (options) ->
    for key of @_callChainOptions
      _.extend @_callChainOptions[key], options



  ### 
  ###

  wrap: (type, target, callstack) ->
    new CallChain({ 
      fasten: @, 
      type: type, 
      target: target, 
      methods: @_callChainOptions[type],
      callstack: callstack ? flatstack()
    })

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