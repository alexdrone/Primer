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
*Note*: A read-only object propagetes observable changes from its wrapped object.

 ```swift
 struct Todo { var title: String; var description: String }
 let todo = Todo(title: "A Title", description: "A Description")
 let readOnlyTodo = ReadOnly(todo)
 readOnlyTodo.title // "A title"
 ``` 

 ### Proxy
 
 Creates an observable Proxy for the object passed as argument.

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
