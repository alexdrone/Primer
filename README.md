# Proxy [![Swift](https://img.shields.io/badge/swift-5.1-orange.svg?style=flat)](#)
<img src="https://raw.githubusercontent.com/alexdrone/Proxy/master/Docs/logo.png" width=150 alt="Proxy" align=right />

Swift package that implements mutable and immutable *proxy objects* through `@dynamicMemberLookup`, 
and lazy proxy-based object builders (`Partials`).

#### TL;DR

```swift

struct Foo {
  let constant = 1337
  var label = "Initial"
  var number = 42
}

var immutableProxy = ImmutableProxyRef(of: Foo())
immutableProxy.label // "Initial"
immutableProxy.number // 42

var mutableProxy = ProxyRef(of: Foo())
mutableProxy.label // "Initial"
mutableProxy.label = "New"
mutableProxy.label // "New"

var partial = Partial(createInstanceClosure: { Foo() })
partial.label = "Bar"
partial.number = 1
let obj = partial.build()
obj.label // "Bar"
obj.number // 1

```
