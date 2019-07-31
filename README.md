# Proxy [![Swift](https://img.shields.io/badge/swift-5.1-orange.svg?style=flat)](#)

Swift package that implements mutable and immutable *proxy objects* through `@dynamicMemberLookup`, 
and lazy proxy-based object builders.

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

var proxyBuilder = ProxyBuilder(createInstanceClosure: { Foo() })
proxyBuilder.label = "Bar"
proxyBuilder.number = 1
let obj = proxyBuilder.build()
obj.label // "Bar"
obj.number // 1

```
