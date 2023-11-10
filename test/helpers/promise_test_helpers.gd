class_name PromiseTestHelpers

static func resolve_after_time(test: Node, promise: Promise):
	await test.get_tree().create_timer(0.1).timeout
	promise.resolve()
	return promise

static func resolve_after_time_with_data(test: Node, promise: Promise, data: Variant):
	await test.get_tree().create_timer(0.1).timeout
	promise.resolve_with_data(data)
	return promise
	
static func resolve_after_long_time_with_data(test: Node, promise: Promise, data: Variant):
	await test.get_tree().create_timer(0.5).timeout
	promise.resolve_with_data(data)
	return promise

static func reject_after_time(test: Node, promise: Promise):
	await test.get_tree().create_timer(0.1).timeout
	promise.reject("Rejected after time")
	return promise
