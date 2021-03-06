###
| Timm
| (c) Guillermo Grau Panea 2016
| License: MIT
###

INVALID_ARGS = 'INVALID_ARGS'

#-----------------------------------------------
#- ### Helpers
#-----------------------------------------------
_throw = (msg) -> throw new Error msg

_clone = (obj) ->
  if Array.isArray obj then return [].concat obj
  keys = Object.keys obj
  out = {}
  out[key] = obj[key] for key in keys
  out

_merge = (fAddDefaults) ->
  args = arguments
  len = args.length
  out = args[1]
  not(out?) and _throw \
    if process.env.NODE_ENV isnt 'production' \
    then "At least one object should be provided to merge()" \
    else INVALID_ARGS
  fChanged = false
  for idx in [2...len] by 1
    obj = args[idx]
    continue if not obj?
    keys = Object.keys obj
    continue if not keys.length
    for key in keys
      continue if fAddDefaults and out[key] isnt undefined
      nextVal = obj[key]
      continue if nextVal is undefined
      continue if nextVal is out[key]
      if not fChanged
        fChanged = true
        out = _clone out
      out[key] = nextVal
  out

_isObject = (o) ->
  type = typeof o
  return o? and (type is 'object' or type is 'function')

## _deepFreeze = (obj) ->
##   Object.freeze obj
##   for key in Object.getOwnPropertyNames obj
##     val = obj[key]
##     if _isObject(val) and not Object.isFrozen val
##       _deepFreeze val
##   obj

#-----------------------------------------------
# ### Arrays
#-----------------------------------------------

# #### addLast()
# Returns a new array with an appended item or items.
# 
# Usage: `addLast(array: Array, val: Array | any): Array`
# 
# ```js
# arr = ['a', 'b']
# arr2 = addLast(arr, 'c')
# // ['a', 'b', 'c']
# arr2 === arr
# // false
# arr3 = addLast(arr, ['c', 'd'])
# // ['a', 'b', 'c', 'd']
# ```
## `array.concat(val)` also handles the array case,
## but is apparently very slow
addLast = (array, val) -> 
  if Array.isArray val then return array.concat val
  return array.concat [val]

# #### addFirst()
# Returns a new array with a prepended item or items.
# 
# Usage: `addFirst(array: Array, val: Array | any): Array`
# 
# ```js
# arr = ['a', 'b']
# arr2 = addFirst(arr, 'c')
# // ['c', 'a', 'b']
# arr2 === arr
# // false
# arr3 = addFirst(arr, ['c', 'd'])
# // ['c', 'd', 'a', 'b']
# ```
addFirst = (array, val) -> 
  if Array.isArray val then return val.concat array
  return [val].concat array

# #### insert()
# Returns a new array obtained by inserting an item or items
# at a specified index.
#
# Usage: `insert(array: Array, idx: number, val: Array | any): Array`
# 
# ```js
# arr = ['a', 'b', 'c']
# arr2 = insert(arr, 1, 'd')
# // ['a', 'd', 'b', 'c']
# arr2 === arr
# // false
# insert(arr, 1, ['d', 'e'])
# // ['a', 'd', 'e', 'b', 'c']
# ```
insert = (array, idx, val) ->
  return array.slice(0, idx)
    .concat if Array.isArray val then val else [val]
    .concat array.slice(idx)

# #### removeAt()
# Returns a new array obtained by removing an item at
# a specified index.
#
# Usage: `removeAt(array: Array, idx: number): Array`
# 
# ```js
# arr = ['a', 'b', 'c']
# arr2 = removeAt(arr, 1)
# // ['a', 'c']
# arr2 === arr
# // false
# ```
removeAt = (array, idx) -> array.slice(0, idx).concat array.slice(idx + 1)

# #### replaceAt()
# Returns a new array obtained by replacing an item at
# a specified index. If the provided item is the same
# (*referentially equal to*) the previous item at that position, 
# the original array is returned.
#
# Usage: `replaceAt(array: Array, idx: number, newItem: any): Array`
#
# ```js
# arr = ['a', 'b', 'c']
# arr2 = replaceAt(arr, 1, 'd')
# // ['a', 'd', 'c']
# arr2 === arr
# // false
#
# // ... but the same object is returned if there are no changes:
# replaceAt(arr, 1, 'b') === arr
# // true
# ```
replaceAt = (array, idx, newItem) ->
  return array if array[idx] is newItem
  return array.slice(0, idx)
    .concat [newItem]
    .concat array.slice(idx + 1)

#-----------------------------------------------
# ### Collections (objects and arrays)
#-----------------------------------------------

# #### getIn()
# Returns a value from an object at a given path. Works with
# nested arrays and objects. If the path does not exist, it returns
# `undefined`.
#
# Usage: `getIn(obj: Object, path: Array<string>): any`
#
# ```js
# obj = {a: 1, b: 2, d: {d1: 3, d2: 4}, e: ['a', 'b', 'c']}
# getIn(obj, ['d', 'd1'])
# // 3
# getIn(obj, ['e', 1])
# // 'b'
# ```
getIn = (obj, path) ->
  not(Array.isArray path) and _throw \
    if process.env.NODE_ENV isnt 'production' \
    then "A path array should be provided when calling getIn()" \
    else INVALID_ARGS
  ptr = obj
  return undefined if not ptr?
  for segment in path
    ptr = ptr?[segment]
    return ptr if ptr is undefined
  ptr

# #### set()
# Returns a new object with a modified attribute. 
# If the provided value is the same (*referentially equal to*)
# the previous value, the original object is returned.
#
# Usage: `set(obj: Object, key: string, val: any): Object`
#
# ```js
# obj = {a: 1, b: 2, c: 3}
# obj2 = set(obj, 'b', 5)
# // {a: 1, b: 5, c: 3}
# obj2 === obj
# // false
#
# // ... but the same object is returned if there are no changes:
# set(obj, 'b', 2) === obj
# // true
# ```
set = (obj, key, val) ->
  obj ?= {}
  return obj if obj[key] is val
  obj2 = _clone obj
  obj2[key] = val
  obj2

# #### setIn()
# Returns a new object with a modified **nested** attribute.
#
# Notes:
#
# * If the provided value is the same (*referentially equal to*)
# the previous value, the original object is returned.
#
# * If the path does not exist, it will be created before setting
# the new value.
#
# Usage: `setIn(obj: Object, path: Array<string>, val: any): Object`
#
# ```js
# obj = {a: 1, b: 2, d: {d1: 3, d2: 4}, e: {e1: 'foo', e2: 'bar'}}
# obj2 = setIn(obj, ['d', 'd1'], 4)
# // {a: 1, b: 2, d: {d1: 4, d2: 4}, e: {e1: 'foo', e2: 'bar'}}
# obj2 === obj
# // false
# obj2.d === obj.d
# // false
# obj2.e === obj.e
# // true
#
# // ... but the same object is returned if there are no changes:
# obj3 = setIn(obj, ['d', 'd1'], 3)
# // {a: 1, b: 2, d: {d1: 3, d2: 4}, e: {e1: 'foo', e2: 'bar'}}
# obj3 === obj
# // true
# obj3.d === obj.d
# // true
# obj3.e === obj.e
# // true
#
# // ... unknown paths create intermediate keys:
# setIn({a: 3}, ['unknown', 'path'], 4)
# // {a: 3, unknown: {path: 4}}
# ```
setIn = (obj, path, val) ->
  return val if not path.length
  return _setIn obj, path, val, 0

_setIn = (obj, path, val, idx) ->
  key = path[idx]
  if idx is path.length - 1
    newValue = val
  else
    nestedObj = if _isObject obj then obj[key] else {}
    newValue = _setIn nestedObj, path, val, idx + 1
  return set obj, key, newValue

# #### updateIn()
# Returns a new object with a modified **nested** attribute, 
# calculated via a user-provided callback based on the current value.
# If the calculated value is the same (*referentially equal to*)
# the previous value, the original object is returned.
# 
# Usage: `updateIn(obj: Object, path: Array<string>, fnUpdate: (prevValue: any) => any): Object`
# 
# ```js
# obj = {a: 1, d: {d1: 3, d2: 4}}
# obj2 = updateIn(obj, ['d', 'd1'], function(val){return val + 1})
# // {a: 1, d: {d1: 4, d2: 4}}
# obj2 === obj
# // false
#
# // ... but the same object is returned if there are no changes:
# obj3 = updateIn(obj, ['d', 'd1'], function(val){return val})
# // {a: 1, d: {d1: 3, d2: 4}}
# obj3 === obj
# // true
# ```
updateIn = (obj, path, fnUpdate) ->
  prevVal = getIn obj, path
  nextVal = fnUpdate prevVal
  return setIn obj, path, nextVal

# #### merge()
# Returns a new object built as follows: the overlapping keys from the 
# second one overwrite the corresponding entries from the first one.
# Similar to `Object.assign()`, but immutable.
#
# Usage: `merge(obj1: Object, obj2: Object): Object`
#
# Variadic: `merge(obj1: Object, ...objects: Object[]): Object`
#
# The unmodified `obj1` is returned if `obj2` does not *provide something
# new to* `obj1`, i.e. if either of the following
# conditions are true:
#
# * `obj2` is `null` or `undefined`
# * `obj2` is an object, but it is empty
# * All attributes of `obj2` are referentially equal to the
#   corresponding attributes of `obj`
#
# ```js
# obj1 = {a: 1, b: 2, c: 3}
# obj2 = {c: 4, d: 5}
# obj3 = merge(obj1, obj2)
# // {a: 1, b: 2, c: 4, d: 5}
# obj3 === obj1
# // false
#
# // ... but the same object is returned if there are no changes:
# merge(obj1, {c: 3}) === obj1
# // true
# ```
merge = (a, b, c, d, e, f) -> 
  if arguments.length <= 6
    return _merge false, a, b, c, d, e, f
  else
    return _merge false, arguments...

# #### mergeIn()
# Similar to `merge()`, but merging the value at a given nested path.
#
# Usage: `mergeIn(obj1: Object, path: Array<string>, obj2: Object): Object`
#
# Variadic: `mergeIn(obj1: Object, path: Array<string>, ...objects: Object[]): Object`
#
# ```js
# obj1 = {a: 1, d: {b: {d1: 3, d2: 4}}}
# obj2 = {d3: 5}
# obj2 = mergeIn(obj1, ['d', 'b'], obj2)
# // {a: 1, d: {b: {d1: 3, d2: 4, d3: 5}}}
# obj3 === obj1
# // false
#
# // ... but the same object is returned if there are no changes:
# mergeIn(obj1, ['d', 'b'], {d2: 4}) === obj1
# // true
# ```
mergeIn = (a, path, b, c, d, e, f) ->
  prevVal = getIn a, path
  prevVal ?= {}
  if arguments.length <= 7
    nextVal = _merge false, prevVal, b, c, d, e, f
  else
    mergeArgs = [false, prevVal].concat [].slice.call(arguments, 2)
    nextVal = _merge.apply null, mergeArgs
  return setIn a, path, nextVal

# #### addDefaults()
# Returns a new object built as follows: `undefined` keys in the first one
# are filled in with the corresponding values from the second one
# (even if they are `null`).
#
# Usage: `addDefaults(obj: Object, defaults: Object): Object`
#
# Variadic: `addDefaults(obj: Object, ...defaultObjects: Object[]): Object`
#
# ```js
# obj1 = {a: 1, b: 2, c: 3}
# obj2 = {c: 4, d: 5, e: null}
# obj3 = addDefaults(obj1, obj2)
# // {a: 1, b: 2, c: 3, d: 5, e: null}
# obj3 === obj1
# // false
#
# // ... but the same object is returned if there are no changes:
# addDefaults(obj1, {c: 4}) === obj1
# // true
# ```
addDefaults = (a, b, c, d, e, f) ->
  if arguments.length <= 6
    return _merge true, a, b, c, d, e, f
  else
    return _merge true, arguments...

#-----------------------------------------------
#- ### Public API
#-----------------------------------------------
module.exports = {
  addLast, addFirst,
  insert,
  removeAt, replaceAt,

  getIn,
  set, setIn,
  updateIn,
  merge, mergeIn,
  addDefaults,
}
