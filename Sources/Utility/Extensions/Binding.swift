import Foundation
#if canImport(SwiftUI)
import SwiftUI

/// Optional Coalescing for `Binding`.
public func ?? <T>(lhs: Binding<T?>, rhs: T) -> Binding<T> {
  Binding(
    get: { lhs.wrappedValue ?? rhs },
    set: { lhs.wrappedValue = $0 }
  )
}

public extension Binding {
  
  /// When the `Binding`'s `wrappedValue` changes, the given closure is executed.
  ///
  /// - Parameter closure: Chunk of code to execute whenever the value changes.
  /// - Returns: New `Binding`.
  func onUpdate(_ closure: @escaping () -> Void) -> Binding<Value> {
    Binding(
      get: { wrappedValue },
      set: {
        wrappedValue = $0
        closure()
      })
  }
}

#endif
