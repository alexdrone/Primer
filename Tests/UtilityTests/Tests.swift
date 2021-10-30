import Combine
import SwiftUI
import XCTest

@testable import Utility

@available(OSX 10.15, iOS 13.0, *)
final class Tests: XCTestCase {
  var subscriber: Cancellable?

  func testImmutableProxy() {
    let proxy = ReadOnly(object: TestData())
    XCTAssert(proxy.constant == 1337)
    XCTAssert(proxy.label == "Initial")
    XCTAssert(proxy.number == 42)
  }

  func testMutableProxy() {
    var testData = TestData()
    let proxy = ObservableStore(object: Binding(get: { testData }, set: { testData = $0 }))
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
    var testData = TestData()
    let proxy = ObservableStore(object: Binding(get: { testData }, set: { testData = $0 }))
    let expectation = XCTestExpectation(description: "didChangeEvent")
    subscriber
      = proxy.propertyDidChange.sink { change in
        if let _ = change.match(keyPath: \TestData.label) {
          expectation.fulfill()
        }
      }
    proxy.label = "Change"
    wait(for: [expectation], timeout: 10)
  }
  
  static var allTests = [
    ("testImmutableProxy", testImmutableProxy),
    ("testMutableProxy", testMutableProxy),
    ("testProxyBuilder", testProxyBuilder),
    ("testProxy", testProxy),
  ]
}

// MARK: - Mocks

struct TestData {
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

enum TestEnum: Int { case started, ongoing, finished }
