# Promises for GDScript
# Every function that must be awaited has an `co_` prefix

class_name Promise

signal _on_resolved

var _resolved: bool = false
var _data: Variant = null


func resolve():
	if is_resolved():
		return
	_resolved = true
	_on_resolved.emit()


func resolve_with_data(data):
	if is_resolved():
		return
	_data = data
	resolve()


func get_data():
	return _data


func reject(reason: String):
	if is_resolved():
		return
	_data = Promise.Error.create(reason)
	resolve()


func is_rejected() -> bool:
	return _data is Promise.Error


func is_resolved() -> bool:
	return _resolved


func co_awaiter() -> Variant:
	if !_resolved:
		await _on_resolved
	if _data is Promise:  # Chain promises
		return _data.co_awaiter()
	else:
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
static func _co_call_and_get_promise(f) -> Promise:
	if f is Promise:
		return f
	elif f is Callable:
		var res = await f.call()
		if res is Promise:
			return res
		else:
			printerr("Func doesn't return a Promise")
			return null
	else:
		printerr("Func is not a callable nor promise")
		return null


class AllAwaiter:
	var _mask: int
	var _promise: Promise = Promise.new()
	var results: Array = []

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
			_call_func(i, funcs[i])

	func _call_func(i: int, f) -> void:
		@warning_ignore("redundant_await")
		var promise = await Promise._co_call_and_get_promise(f)
		var data = await promise.co_awaiter()
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
			_call_func(i, funcs[i])

	func _call_func(i: int, f) -> void:
		@warning_ignore("redundant_await")
		var promise: Promise = await Promise._co_call_and_get_promise(f)
		var res = await promise.co_awaiter()

		# Promise.co_any ignores promises with errors
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
			_call_func(i, funcs[i])

	func _call_func(i: int, f) -> void:
		@warning_ignore("redundant_await")
		var promise: Promise = await Promise._co_call_and_get_promise(f)
		var res = await promise.co_awaiter()

		# Promise.co_race doesn't ignore on error, you get the first one, with or without an error
		if not _promise.is_resolved():
			_promise.resolve_with_data(res)


# `co_all` is a static function that takes an array of functions (`funcs`)
# and returns an array. It awaits the resolution of all the given functions.
# Each function in the array is expected to be a coroutine or a function
# that returns a promise.
static func co_all(funcs: Array) -> Array:
	return await AllAwaiter.new(funcs)._promise.co_awaiter()


# `co_any` is a static function similar to `co_all`, but it resolves as soon as any of the
# functions in the provided array resolves. It returns the result of the first function
# that resolves. It ignores the rejections (differently from co_race)
static func co_any(funcs: Array) -> Variant:
	return await AnyAwaiter.new(funcs)._promise.co_awaiter()


# `co_race` is another static function that takes an array of functions and returns
# a variant. It behaves like a race condition, returning the result of the function
# that completes first, even if it fails (differently from co_any)
static func co_race(funcs: Array) -> Variant:
	return await RaceAwaiter.new(funcs)._promise.co_awaiter()
