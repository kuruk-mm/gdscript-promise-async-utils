# GDScript Async Utils

This addons provides helpers for using the Promise class in GDScript to handle asynchronous operations.

Every function that must be `await` has a `co` prefix.

## Basic Promise Usage

These examples demonstrate different ways to create, resolve, and work with promises.

### Creating and Resolving a Promise

```gdscript
var promise = Promise.new()
promise.resolve()
await promise.co_awaiter()
```

### Resolving a Promise with Data

```gdscript
var promise = Promise.new()
promise.resolve_with_data(5)
var data = await promise.co_awaiter()
# data will be 5
```

### Resolving a Promise After a Delay

```gdscript
func wait_and_resolve_with_data(promise: Promise, data: Variant)
    await test.get_tree().create_timer(0.1).timeout
    promise.resolve_with_data(data)

var promise = Promise.new()
wait_and_resolve_with_data(promise, data)
var data = await promise.co_awaiter() # data will be 32 after some time
```

### Rejecting a Promise

```gdscript
var promise = Promise.new()
promise.reject("Rejected")
var result = await promise.co_awaiter()
if result is Promise.Error:
    prints("Promise rejected, error:", result.get_error())
```

## Advanced Promise Usage

### Chaining promises

```gdscript
var promise1 = Promise.new()
var promise2 = Promise.new()
promise1.resolve_with_data(promise2)
promise2.resolve_with_data("Chained data")
var data = await promise1.co_awaiter()
print(data) # data will be "Chained data"
```

### Handling multiple promises (Promise.co_all, Promise.co_any, Promise.co_Race)

#### Waiting for All Promises (Promise.co_all)
```gdscript
func wait_and_resolve_with_data(promise: Promise, data: Variant)
    await test.get_tree().create_timer(0.1).timeout
    promise.resolve_with_data(data)

var promise1 = Promise.new()
var promise2 = Promise.new()
wait_and_resolve_with_data(promise1, "Data 1")
wait_and_resolve_with_data(promise2, "Data 2")
var results = await Promise.co_all([promise1, promise2])
# results will be an array ["Data 1", "Data 2"]
```

#### Waiting for Any Promise to Resolve (Promise.co_any) (ignores rejections)

```gdscript
func wait_and_resolve_with_data(promise: Promise, data: Variant, time_secs: float)
    await test.get_tree().create_timer(time_secs).timeout
    promise.resolve_with_data(data)

var promise1 = Promise.new()
var promise2 = Promise.new()
wait_and_resolve_with_data(promise1, "Data 1", 0.3) # takes more time...
wait_and_resolve_with_data(promise2, "Data 2", 0.1)
var result = await Promise.co_any([promise1, promise2])
# result will be "Data 2" since promise1 takes more time
```

#### Racing Promises (Promise.co_race) (doesn't ignore rejections)

```gdscript
func wait_and_resolve_with_data(promise: Promise, data: Variant)
    await test.get_tree().create_timer(0.1).timeout
    promise.resolve_with_data(data)

var promise1 = Promise.new()
var promise2 = Promise.new()
wait_and_resolve_with_data(self, promise1, "Data 1")
promise2.reject("Rejected")
var result = await Promise.co_race([promise1, promise2])
# result will be either Promise.Error, because was resolved first
```

## More examples

You can extract more examples in the [tests](test/test_promise.gd)