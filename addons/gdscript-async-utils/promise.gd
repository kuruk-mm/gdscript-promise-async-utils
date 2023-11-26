# Promises for GDScript
# Every function that must be awaited has an `async_` prefix

class_name Promise

signal on_resolved

var _resolved: bool = false
var _data: Variant = null
var _on_resolve_cbs: Array[Callable] = []
var _on_reject_cbs: Array[Callable] = []


func _valid_callback(callback: Callable) -> bool:
	if !callback.is_valid():
		printerr("Invalid callback")
		return false

	if callback.get_bound_arguments_count() >= 2:
		printerr("Invalid arguments on callback")
		return false

	return true


func then(on_resolved: Callable) -> Promise:
	if !_valid_callback(on_resolved):
		printerr("Invalid callback")
		return self

	if is_resolved() and !is_rejected():
		on_resolved.call(_data)
	else:
		_on_resolve_cbs.push_back(on_resolved)

	return self


func catch(on_rejected: Callable) -> Promise:
	if !_valid_callback(on_rejected):
		printerr("Invalid callback")
		return self

	if is_resolved() and is_rejected():
		on_rejected.call(_data)
	else:
		_on_reject_cbs.push_back(on_rejected)

	return self


func resolve():
	resolve_with_data(null)


func resolve_with_data(data):
	if is_resolved():
		return
	_resolved = true
	_data = data

	if data is Promise.Error:
		for on_reject in _on_reject_cbs:
			if on_reject.is_valid():
				on_reject.call(_data)
	else:
		for on_resolve in _on_resolve_cbs:
			if on_resolve.is_valid():
				on_resolve.call(_data)

	on_resolved.emit()


func get_data():
	return _data


func reject(reason: String):
	resolve_with_data(Promise.Error.create(reason))


func is_rejected() -> bool:
	return _data is Promise.Error


func is_resolved() -> bool:
	return _resolved


func async_awaiter() -> Variant:
	if !_resolved:
		await on_resolved
	if _data is Promise:  # Chain promises
		return _data.async_awaiter()

	return _data


class Error:
	var _error_description: String = ""

	static func create(description: String) -> Promise.Error:
		var error = Promise.Error.new()
		error._error_description = description
		return error

	func get_error() -> String:
		return _error_description


# Internal helper function
class _Internal:
	static func async_call_and_get_promise(f) -> Promise:
		if f is Promise:
			return f

		if f is Callable:
			var res = await f.call()
			if res is Promise:
				return res

			printerr("Func doesn't return a Promise")
			return null

		printerr("Func is not a callable nor promise")
		return null


class AllAwaiter:
	var results: Array = []
	var _mask: int
	var _promise: Promise = Promise.new()

	func _init(funcs: Array) -> void:
		var size := funcs.size()
		if size == 0:  # inmediate resolve, no funcs to await...
			_promise.resolve()
			return

		results.resize(size)
		results.fill(null)  # by default, the return will be null
		assert(size < 64)
		_mask = (1 << size) - 1
		for i in size:
			_async_call_func(i, funcs[i])

	func _async_call_func(i: int, f) -> void:
		@warning_ignore("redundant_await")
		var promise = await Promise._Internal.async_call_and_get_promise(f)
		var data = await promise.async_awaiter()
		results[i] = data

		_mask &= ~(1 << i)

		if not _mask and not _promise.is_resolved():
			_promise.resolve_with_data(results)


class AnyAwaiter:
	var _promise: Promise = Promise.new()

	func _init(funcs: Array) -> void:
		var size := funcs.size()
		if size == 0:  # inmediate resolve, no funcs to await...
			_promise.resolve()
			return
		for i in size:
			_async_call_func(i, funcs[i])

	func _async_call_func(_i: int, f) -> void:
		@warning_ignore("redundant_await")
		var promise: Promise = await Promise._Internal.async_call_and_get_promise(f)
		var res = await promise.async_awaiter()

		# Promise.async_any ignores promises with errors
		if !promise.is_rejected() and not _promise.is_resolved():
			_promise.resolve_with_data(res)


class RaceAwaiter:
	var _promise: Promise = Promise.new()

	func _init(funcs: Array) -> void:
		var size := funcs.size()
		if size == 0:  # inmediate resolve, no funcs to await...
			_promise.resolve()
			return
		for i in size:
			_async_call_func(i, funcs[i])

	func _async_call_func(_i: int, f) -> void:
		@warning_ignore("redundant_await")
		var promise: Promise = await Promise._Internal.async_call_and_get_promise(f)
		var res = await promise.async_awaiter()

		# Promise.async_race doesn't ignore on error, you get the first one, with or without an error
		if not _promise.is_resolved():
			_promise.resolve_with_data(res)


# `async_all` is a static function that takes an array of functions (`funcs`)
# and returns an array. It awaits the resolution of all the given functions.
# Each function in the array is expected to be a coroutine or a function
# that returns a promise.
static func async_all(funcs: Array) -> Array:
	if funcs.is_empty():
		return []
	return await AllAwaiter.new(funcs)._promise.async_awaiter()


# `async_any` is a static function similar to `async_all`, but it resolves as soon as any of the
# functions in the provided array resolves. It returns the result of the first function
# that resolves. It ignores the rejections (differently from async_race)
static func async_any(funcs: Array) -> Variant:
	return await AnyAwaiter.new(funcs)._promise.async_awaiter()


# `async_race` is another static function that takes an array of functions and returns
# a variant. It behaves like a race condition, returning the result of the function
# that completes first, even if it fails (differently from async_any)
static func async_race(funcs: Array) -> Variant:
	return await RaceAwaiter.new(funcs)._promise.async_awaiter()
