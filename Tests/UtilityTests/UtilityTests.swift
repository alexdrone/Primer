import Combine
import XCTest

@testable import Utility

struct Foo {
  let constant = 1337
  var label = "Initial"
  var number = 42
  
  init() {
  }
  
  init(label: String, number: Int) {
    self.label = label
    self.number = number
  }
}

@available(OSX 10.15, iOS 13.0, *)
final class UtilityTests: XCTestCase {
  var subscriber: Cancellable?

  func testImmutableProxy() {
    let proxy = ReadOnly(of: Foo())
    XCTAssert(proxy.constant == 1337)
    XCTAssert(proxy.label == "Initial")
    XCTAssert(proxy.number == 42)
  }

  func testMutableProxy() {
    var proxy = ObservableProxy(of: Foo())
    XCTAssert(proxy.constant == 1337)
    XCTAssert(proxy.label == "Initial")
    XCTAssert(proxy.number == 42)
    proxy.label = "New"
    proxy.number = 1
    XCTAssert(proxy.label == "New")
    XCTAssert(proxy.number == 1)
  }

  func testProxyBuilder() {
    struct Todo { var title: String; var description: String }
    var partial = Partial { .success(Todo(
      title: $0.get(\Todo.title, default: "Untitled"),
      description: $0.get(\Todo.description, default: "No description")))
    }
    partial.title = "A Title"
    partial.description = "A Description"
    XCTAssert(partial.title == "A Title")
    XCTAssert(partial.description == "A Description")
    var todo = try! partial.build().get()
    XCTAssert(todo.title == "A Title")
    XCTAssert(todo.description == "A Description")
    partial.description = "Another Descrition"
    XCTAssert(partial.description == "Another Descrition")
    todo = partial.merge(&todo)
    XCTAssert(todo.title == "A Title")
    XCTAssert(todo.description == "Another Descrition")
  }

  func testProxy() {
    var proxy = ObservableProxy(of: Foo())
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
