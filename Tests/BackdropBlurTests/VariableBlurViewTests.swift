import CoreGraphics
import Testing
import UIKit
@testable import BackdropBlur

/// Checks mask semantics and live updates on the native backdrop filter.
@MainActor
struct VariableBlurViewTests {

  @Test
  func gradientProgressesFromOpaqueTopToClearBottom() throws {
    let image = VariableBlurView.GradientMask.makeImage(configuration: .init())
    #expect(try alpha(image, row: 0) > 0.98)
    #expect(try abs(alpha(image, row: 49) - 0.5) < 0.02)
    #expect(try alpha(image, row: 99) < 0.02)
  }

  @Test
  func oppositeDirectionMirrorsTheAlphaDistribution() throws {
    let top = VariableBlurView.GradientMask.makeImage(configuration: .init())
    let bottom = VariableBlurView.GradientMask.makeImage(
      configuration: .init(direction: .blurredBottomClearTop)
    )
    for row in [0, 24, 49, 74, 99] {
      #expect(try abs(alpha(top, row: row) - alpha(bottom, row: 99 - row)) < 0.01)
    }
  }

  @Test(arguments: [VariableBlurView.Direction.blurredTopClearBottom, .blurredBottomClearTop])
  func offsetControlsTheClearRegion(direction: VariableBlurView.Direction) throws {
    let positive = VariableBlurView.GradientMask.makeImage(
      configuration: .init(direction: direction, startOffset: 0.5)
    )
    let negative = VariableBlurView.GradientMask.makeImage(
      configuration: .init(direction: direction, startOffset: -0.2)
    )
    let clearRow = direction == .blurredTopClearBottom ? 99 : 0
    #expect(try alpha(positive, row: clearRow) == 0)
    #expect(try abs(alpha(negative, row: clearRow) - 1.0 / 6.0) < 0.02)
  }

  @Test
  func radiusAndLayoutReuseTheMaskWhileConfigurationReplacesIt() throws {
    let view = VariableBlurView.BackingView(maxBlurRadius: 20, configuration: .init())
    let layer = view.layer
    let original = try maskImage(layer)

    view.update(maxBlurRadius: 8, configuration: .init())
    view.bounds = CGRect(x: 0, y: 0, width: 240, height: 320)
    view.layoutIfNeeded()
    let reused = try maskImage(layer)
    #expect(reused === original)
    #expect((layer.value(forKeyPath: BackdropRuntime.radiusKeyPath) as? NSNumber)?.doubleValue == 8)
    #expect(!view.isUserInteractionEnabled)

    view.update(maxBlurRadius: 0, configuration: .init(direction: .blurredBottomClearTop))
    let flipped = try maskImage(layer)
    #expect(flipped !== original)
    #expect(try alpha(flipped, row: 0) < 0.02)
    #expect((layer.value(forKeyPath: BackdropRuntime.radiusKeyPath) as? NSNumber)?.doubleValue == 0)

    view.update(
      maxBlurRadius: 16,
      configuration: .init(direction: .blurredBottomClearTop, startOffset: 0.5)
    )
    let shifted = try maskImage(layer)
    #expect(shifted !== flipped)
    #expect(try alpha(shifted, row: 25) == 0)
    #expect(view.layer === layer)
    #expect(layer.filters?.count == 1)
    #expect((layer.value(forKeyPath: BackdropRuntime.edgeNormalizationKeyPath) as? NSNumber)?.boolValue == true)
  }

  /// Validates the Core Foundation type before bridging the filter's KVC value.
  private func maskImage(_ layer: CALayer) throws -> CGImage {
    let value = try #require(layer.value(forKeyPath: BackdropRuntime.maskKeyPath))
    try #require(CFGetTypeID(value as CFTypeRef) == CGImage.typeID)
    return value as! CGImage
  }

  /// Reads alpha in the generated RGBA image's row order, with row zero at the top.
  private func alpha(_ image: CGImage, row: Int) throws -> Double {
    let data = try #require(image.dataProvider?.data)
    let bytes = try #require(CFDataGetBytePtr(data))
    return Double(bytes[row * image.bytesPerRow + (image.width / 2) * 4 + 3]) / 255
  }
}
