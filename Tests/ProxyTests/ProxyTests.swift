import Combine
import XCTest

@testable import Proxy

struct Foo {
  let constant = 1337
  var label = "Initial"
  var number = 42
}

@available(OSX 10.15, iOS 13.0, *)
final class ProxyTests: XCTestCase {
  var subscriber: Cancellable?

  func testImmutableProxy() {
    let proxy = ImmutableProxyRef(of: Foo())
    XCTAssert(proxy.constant == 1337)
    XCTAssert(proxy.label == "Initial")
    XCTAssert(proxy.number == 42)
  }

  func testMutableProxy() {
    var proxy = ProxyRef(of: Foo())
    XCTAssert(proxy.constant == 1337)
    XCTAssert(proxy.label == "Initial")
    XCTAssert(proxy.number == 42)
    proxy.label = "New"
    proxy.number = 1
    XCTAssert(proxy.label == "New")
    XCTAssert(proxy.number == 1)
  }

  func testProxyBuilder() {
    var builder = Partial(createInstanceClosure: { Foo() })
    builder.label = "New"
    builder.number = 1
    XCTAssert(builder.label == "New")
    XCTAssert(builder.number == 1)
    let object = builder.build()
    XCTAssert(object.label == "New")
    XCTAssert(object.number == 1)
  }

  func testProxy() {
    var proxy = ProxyRef(of: Foo())
    let expectation = XCTestExpectation(description: "didChangeEvent")
    subscriber
      = proxy.propertyDidChange.sink { change in
        if let _ = change.match(keyPath: \Foo.label) {
          expectation.fulfill()
        }
      }
    proxy.label = "Change"
    wait(for: [expectation], timeout: 1)
  }

  static var allTests = [
    ("testImmutableProxy", testImmutableProxy),
    ("testProxyBuilder", testProxyBuilder),
  ]
}
