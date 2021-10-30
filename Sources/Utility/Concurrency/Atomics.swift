import Foundation
import Atomics

public protocol UnsafeSendable { }

#if compiler(>=5.5) && canImport(_Concurrency)
extension UnsafeSendable: @unchecked Sendable
#endif

/// The `UncheckedSendable` protocol indicates that value of the given type can be safely used
/// in concurrent code, but disables some safety checking at the conformance site.
public protocol UncheckedSendable: UnsafeSendable { }

extension ManagedAtomic: UncheckedSendable { }
