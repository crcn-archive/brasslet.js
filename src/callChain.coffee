flatstack = require "flatstack"
events    = require "events"
async     = require "async"
toarray   = require "toarray"
flatten   = require "flatten"


class CallChain extends events.EventEmitter
  
  ###
  ###

  constructor: (options) ->

 
    {@fasten, @target, @methods, @type} = options
    @_callstack = @fasten._callstack

    for methodName of @methods
      @_addMethod methodName, @methods[methodName]




  ###
  ###

  _addMethod: (name, options) ->

    type     = options.type or @type
    map      = options.map or (result) -> result
    onResult = options.onResult or () -> 
    onCall   = options.onCall or () -> 

    @[name] = (args...) =>

      callChain = @fasten.wrap(type)
      callChain.parent = @

      # shove in a queue
      @_callstack.push (next) =>

        setTimeout (() =>

          if @__err
            return next()

          targets = toarray(@target).filter (target) =>
            return true unless @_filter
            @_filter target

          if @_limit
            targets = targets.slice(0, @_limit)

          async.mapSeries targets, ((target, next) =>

            @_bubble "call", { chain: @, type: @type, method: name, target: target, args: args }
            onCall target
            
            call = options.call or target[name]

            call.apply target, args.concat (err, result) =>
              return next(err) if err?
              @_bubble "result", { chain: @, type: @type, target: target, method: name, data: result, args: args }
              onResult result
              next null, map.call target, result
          ), (err, newTarget) =>

            callChain.__err = err

            if err
              @_error(err)
            else
              callChain.target = flatten newTarget

            next()
        ), 1


      callChain


  ###
  ###

  filter: (value) =>
    @_filter = value
    @

  ###
  ###

  limit: (count) =>
    @_limit = count
    @

  ###
  ###

  one: () ->
    @limit 1

  ###
  ###

  root: () ->
    p = @
    while p.parent
      p = p.parent
    p

  ###
  ###

  bubble: () ->
    @emit arguments...
    @parent?.bubble arguments...

  ###
  ###

  _bubble: () ->
    @fasten.emit arguments...
    @bubble arguments...


  ###
  ###

  then: (next) ->
    @_callstack.push () =>
      try
        next.call @target, @__err, @target
      catch e
        @__err = e
    @


  ###
  ###

  _error: (err) =>
    @__err = err

module.exports = CallChain
