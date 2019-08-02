# Proxy [![Swift](https://img.shields.io/badge/swift-5.1-orange.svg?style=flat)](#)
<img src="https://raw.githubusercontent.com/alexdrone/Proxy/master/Docsogo.png" width=150 alt="Proxy" align=right />

Swift package that implements mutable and immutable *proxy objects* through `@dynamicMemberLookup`, 
and lazy proxy-based object builders.

#### TL;DR

```swift

struct Foo {
  let constant = 1337
  var label = "Initial"
  var number = 42
}

var immutableProxy = ImmutableProxy(of: Foo())
immutableProxy.label // "Initial"
immutableProxy.number // 42

var mutableProxy = MutableProxy(of: Foo())
mutableProxy.label // "Initial"
mutableProxy.label = "New"
mutableProxy.label // "New"

var proxyBuilder = ProxyBuilder(createInstanceClosure: { Foo() })
proxyBuilder.label = "Bar"
proxyBuilder.number = 1
let obj = proxyBuilder.build()
obj.label // "Bar"
obj.number // 1

```
