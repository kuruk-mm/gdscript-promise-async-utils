extends GutTest

func test_should_promise_not_be_completed():
	var promise = Promise.new()
	assert_eq(promise.is_resolved(), false, 'Promise should not be resolved')

func test_should_promise_gets_resolved():
	var promise = Promise.new()
	promise.resolve()
	await promise.co_awaiter()
	assert_eq(promise.is_resolved(), true, 'Promise should be resolved')
	assert_eq(promise.is_rejected(), false, 'Promise should not be rejected')

func test_should_promise_gets_resolved_with_data():
	var promise = Promise.new()
	promise.resolve_with_data(5)
	var data = await promise.co_awaiter()
	assert_eq(data, 5, 'Promise result should be 5')
	assert_eq(promise.is_resolved(), true, 'Promise should be resolved')
	assert_eq(promise.is_rejected(), false, 'Promise should not be rejected')

func test_should_promise_be_resolved_after_some_time():
	var promise = Promise.new()
	PromiseTestHelpers.resolve_after_time_with_data(self, promise, 32) # Dettached coroutine
	
	assert_eq(promise.is_resolved(), false, 'Promise should not be resolved')
	
	var data = await promise.co_awaiter()
	
	assert_eq(data, 32, 'Promise result should be 32')
	assert_eq(promise.is_resolved(), true, 'Promise should be resolved')
	assert_eq(promise.is_rejected(), false, 'Promise should not be rejected')

func test_should_promise_be_rejected():
	var promise = Promise.new()
	promise.reject("Rejected")
	var result = await promise.co_awaiter()
	if result is Promise.Error:
		pass_test("The promise failed as expected.")
	assert_eq(promise.is_resolved(), true, 'Promise should be resolved')
	assert_eq(promise.is_rejected(), true, 'Promise should not be rejected')
	
func test_should_promise_be_rejected_after_time():
	var promise = Promise.new()
	PromiseTestHelpers.reject_after_time(self, promise) # Dettached coroutine
	
	assert_eq(promise.is_resolved(), false, 'Promise should not be resolved')
	
	var data = await promise.co_awaiter()
	
	assert_eq(data is Promise.Error, true, 'Promise result should be a Promise.Error')
	assert_eq(promise.is_resolved(), true, 'Promise should be resolved')
	assert_eq(promise.is_rejected(), true, 'Promise should be rejected')

func test_should_chain_promises():
	var promise1 = Promise.new()
	var promise2 = Promise.new()
	promise1.resolve_with_data(promise2)
	promise2.resolve_with_data("Chained data")
	var data = await promise1.co_awaiter()
	assert_eq(data, "Chained data", 'Chained promise result should be "Chained data"')

func test_should_not_resolve_multiple_times():
	var promise = Promise.new()
	promise.resolve_with_data("First resolve")
	promise.resolve_with_data("Second resolve")
	var data = await promise.co_awaiter()
	assert_eq(data, "First resolve", 'Promise should only resolve once')

func test_parallel_promises_and_wait_for_all():
	var promise1 = Promise.new()
	var promise2 = Promise.new()
	PromiseTestHelpers.resolve_after_time_with_data(self, promise1, "Data 1")
	PromiseTestHelpers.resolve_after_time_with_data(self, promise2, "Data 2")
	var results = await Promise.co_all([promise1, promise2])
	assert_eq(results[0], "Data 1", 'First promise result should be "Data 1"')
	assert_eq(results[1], "Data 2", 'Second promise result should be "Data 2"')
	
# The promises will be executed inside the co_all function
func test_parallel_promises_and_wait_for_all_with_bind():
	var promise1 = Promise.new()
	var promise2 = Promise.new()
	var callable1 = PromiseTestHelpers.resolve_after_time_with_data.bind(self, promise1, "Data 1")
	var callable2 = PromiseTestHelpers.resolve_after_time_with_data.bind(self, promise2, "Data 2")
	var results = await Promise.co_all([callable1, callable2])
	assert_eq(results[0], "Data 1", 'First promise result should be "Data 1"')
	assert_eq(results[1], "Data 2", 'Second promise result should be "Data 2"')

func test_parallel_promises_and_wait_for_first_resolved():
	var promise1 = Promise.new()
	var promise2 = Promise.new()
	PromiseTestHelpers.resolve_after_long_time_with_data(self, promise1, "Data 1")
	PromiseTestHelpers.resolve_after_time_with_data(self, promise2, "Data 2") # Should be resolved first due to after_long_time of promise 1
	var result = await Promise.co_any([promise1, promise2])
	assert_eq(result, "Data 2", 'Second promise result should be "Data 2"')

func test_parallel_promises_and_wait_for_first_resolved_and_ignore_rejections():
	var promise1 = Promise.new()
	var promise2 = Promise.new()
	PromiseTestHelpers.resolve_after_time_with_data(self, promise1, "Data 1")
	promise2.reject("Rejected")
	var result = await Promise.co_any([promise1, promise2])
	assert_eq(result, "Data 1", 'Second promise result should be "Data 1"')
	

func test_parallel_promises_and_wait_for_first_resolved_and_take_rejections():
	var promise1 = Promise.new()
	var promise2 = Promise.new()
	PromiseTestHelpers.resolve_after_time_with_data(self, promise1, "Data 1")
	promise2.reject("Rejected")
	var result = await Promise.co_race([promise1, promise2])
	assert_eq(result is Promise.Error, true, 'Promise result should be a Promise.Error')
