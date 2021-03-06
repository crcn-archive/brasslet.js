flatstack = require "flatstack"
events    = require "events"
async     = require "async"
toarray   = require "toarray"
flatten   = require "flatten"


class CallChain extends events.EventEmitter
  
  ###
  ###

  constructor: (options) ->

    @_delay = -1

 
    {@fasten, @methods, @type, @callstack} = options

    @_target options.target

    for methodName of @methods
      @_addMethod methodName, @methods[methodName]

    @on "error", () ->

  ###
  ###

  _addMethod: (name, options) ->

    type     = options.type or @type
    map      = options.map or (result) -> result
    onResult = options.onResult or () -> 
    onCall   = options.onCall or () -> 

    @[name] = (args...) =>

      callChain = @fasten.wrap(type, undefined, @callstack)
      callChain.parent = @

      # shove in a queue
      @callstack.push (next) =>

        setTimeout (() =>

          if @__err
            callChain.__err = @__err
            return next()

          fn = if @_parallel then async.map else async.mapSeries

          fn.call async, @target, ((target, next) =>

            @_bubble "call", { chain: @, type: @type, method: name, target: target, args: args }
            onCall.call @, target
            
            call = options.call or target[name]


            call.apply target, args.concat (err, result) =>
              return next(err) if err?
              @_bubble "result", { chain: @, type: @type, target: target, method: name, data: result, args: args }
              onResult.call @, result

              v = map.call target, result

              if ~@_delay
                setTimeout(next, @_delay, null, v)
              else
                next null, v

          ), (err, newTarget) =>

            callChain.__err = err

            if err
              @_error(err)
            else
              callChain._target flatten newTarget

            next()
        ), 1


      callChain

  ###
  ###

  _target: (target) ->

    targets = toarray(target).filter (target) =>
      return true unless @_filter
      @_filter target

    if @_limit?
      targets = targets.slice(0, @_limit)

    @target = targets

  ###
  ###

  count: () ->
    @then (err, targets) =>
      @target = [targets.length]

  ###
  ###

  series: () ->
    @_parallel = false
    @

  ###
  ###

  parallel: () ->
    @_parallel = true
    @

  ###
  ###

  delay: (value) ->
    @_delay = value
    @

  ###
  ###

  detach: () ->
    @callstack = flatstack()
    @

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
    @callstack.push () =>
      try
        next.call @target, @__err, @target
      catch e
        @__err = e
    @


  ###
  ###

  _error: (err) =>
    @__err = err
    @emit "error", err

module.exports = CallChain
