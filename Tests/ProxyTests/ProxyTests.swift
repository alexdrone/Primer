import XCTest
@testable import Proxy

struct Foo {
  let constant = 1337
  var label = "Initial"
  var number = 42
}

final class ProxyTests: XCTestCase {

  func testImmutableProxy() {
    let proxy = ImmutableProxy(of: Foo())
    XCTAssert(proxy.constant == 1337)
    XCTAssert(proxy.label == "Initial")
    XCTAssert(proxy.number == 42)
  }

  func testMutableProxy() {
    var proxy = MutableProxy(of: Foo())
    XCTAssert(proxy.constant == 1337)
    XCTAssert(proxy.label == "Initial")
    XCTAssert(proxy.number == 42)
    proxy.label = "New"
    proxy.number = 1
    XCTAssert(proxy.label == "New")
    XCTAssert(proxy.number == 1)
  }

  func testProxyBuilder() {
    var builder = ProxyBuilder(createInstanceClosure: { Foo() })
    builder.label = "New"
    builder.number = 1
    XCTAssert(builder.label == "New")
    XCTAssert(builder.number == 1)
    let object = builder.build()
    XCTAssert(object.label == "New")
    XCTAssert(object.number == 1)
  }

    static var allTests = [
        ("testImmutableProxy", testImmutableProxy),
        ("testMutableProxy", testMutableProxy),
        ("testProxyBuilder", testProxyBuilder),
    ]
}
