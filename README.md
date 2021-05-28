# Utility [![Swift](https://img.shields.io/badge/swift-5.1-orange.svg?style=flat)](#)

### Assign

This function is used to copy the values of all enumerable own properties from one or more
source struct to a target struct.
If the argument is a reference type the same refence is returned.

```swift
public func assign<T>(_ value: T, changes: (inout T) -> Void) -> T
```

### Partial

Constructs a type with all properties of T set to optional. This utility will return a type 
that represents all subsets of a given type.

The wrapped type can be then constructed at referred time by calling the `build()` method.
The instance can be later on changed with the `merge(inout _:)` method.

 ```swift
 struct Todo { var title: String; var description: String } 
 var partial = Partial { .success(Todo(
  title: $0.get(\Todo.title, default: "Untitled"),   
  description: $0.get(\Todo.description, default: "No description"))) 
} 
partial.title = "A Title" 
partial.description = "A Description" 
var todo = try! partial.build().get() 
partial.description = "Another Descrition" 
todo = partial.merge(&todo) 
```

### ReadOnly

Constructs a type with all properties of T set to readonly, meaning the properties of
the constructed type cannot be reassigned.

**Note**  A read-only object can propagate change events if the wrapped type ia an
`ObservableObject` by calling `propagateObservableObject()` at construction time.

 ```swift
 struct Todo { var title: String; var description: String }
 let todo = Todo(title: "A Title", description: "A Description")
 let readOnlyTodo = ReadOnly(todo)
 readOnlyTodo.title // "A title"
 ``` 

 ### ObservableProxy
 
 Creates an observable Proxy for the object passed as argument (with granularity at the 
 property level).
 

```swift
struct Todo { var title: String; var description: String }
let todo = Todo(title: "A Title", description: "A Description")
let proxy = Proxy(todo)
proxy.propertyDidChange.sink {
  if $0.match(keyPath: \.title) {
    ...
  }
}
proxy.title = "New Title"
```

### Concurrency

This package offer a variety of different lock implementations:
* `Mutex`: enforces limits on access to a resource when there are many threads 
of execution.
* `UnfairLock`: low-level lock that allows waiters to block efficiently on contention.
* `ReadersWriterLock`: readers-writer lock provided by the platform implementation 
of the POSIX Threads standard.

Property wrappers to work with any of the locks above or any `NSLocking` compliant lock:
* `@LockAtomic<L: Locking>`
* `@SyncDispatchQueueAtomic`
* `@ReadersWriterAtomic`


The package also includes `LockfreeAtomic`:  fine-grained atomic operations allowing for Lockfree concurrent programming. Each atomic operation is indivisible with regards to any other atomic operation that involves the same object.
