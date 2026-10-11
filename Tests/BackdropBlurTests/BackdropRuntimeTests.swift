import Testing
import Foundation
@testable import BackdropBlur

/// Exercises the uniform filter's encoded factory and input keys on the runtime.
@MainActor
struct BackdropRuntimeTests {
  @Test
  func uniformFilterAcceptsRadiusAndEdgeNormalization() {
    let filter = BackdropRuntime.makeFilter(kind: .uniform)
    filter.setValue(12.0, forKey: BackdropRuntime.radiusKey)
    filter.setValue(true, forKey: BackdropRuntime.edgeNormalizationKey)

    #expect((filter.value(forKey: BackdropRuntime.radiusKey) as? NSNumber)?.doubleValue == 12)
    #expect((filter.value(forKey: BackdropRuntime.edgeNormalizationKey) as? NSNumber)?.boolValue == true)
  }
}
