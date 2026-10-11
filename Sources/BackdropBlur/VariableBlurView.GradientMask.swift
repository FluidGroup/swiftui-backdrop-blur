import CoreGraphics

extension VariableBlurView {

  /// Rasterizes a vertical alpha gradient without a Core Image context.
  ///
  /// Opaque pixels request the maximum radius; transparent pixels request zero.
  /// The filter maps this fixed-size image over the backdrop bounds, so layout
  /// does not require another bitmap. The caller owns cache invalidation.
  enum GradientMask {

    /// Creates a premultiplied RGBA image with alpha increasing to the blurred edge.
    static func makeImage(configuration: Configuration) -> CGImage {
      precondition(
        configuration.startOffset.isFinite && configuration.startOffset < 1,
        "Gradient start offset must be finite and less than one"
      )

      let width = 100
      let height = 100
      let colorSpace = CGColorSpaceCreateDeviceRGB()
      guard
        let context = CGContext(
          data: nil,
          width: width,
          height: height,
          bitsPerComponent: 8,
          bytesPerRow: width * 4,
          space: colorSpace,
          bitmapInfo: CGBitmapInfo.byteOrder32Big.rawValue
            | CGImageAlphaInfo.premultipliedLast.rawValue
        ),
        let gradient = CGGradient(
          colorSpace: colorSpace,
          colorComponents: [0, 0, 0, 1, 0, 0, 0, 0],
          locations: [0, 1],
          count: 2
        )
      else {
        preconditionFailure("Unable to create the variable blur gradient bitmap")
      }

      let blurredY: CGFloat
      let clearY: CGFloat
      // The bitmap context uses bottom-left drawing coordinates, while row zero
      // of the resulting CGImage is its top edge.
      switch configuration.direction {
      case .blurredTopClearBottom:
        blurredY = CGFloat(height)
        clearY = configuration.startOffset * CGFloat(height)
      case .blurredBottomClearTop:
        blurredY = 0
        clearY = (1 - configuration.startOffset) * CGFloat(height)
      }

      context.drawLinearGradient(
        gradient,
        start: CGPoint(x: 0, y: blurredY),
        end: CGPoint(x: 0, y: clearY),
        options: [.drawsBeforeStartLocation, .drawsAfterEndLocation]
      )
      guard let image = context.makeImage() else {
        preconditionFailure("Unable to make the variable blur gradient image")
      }
      return image
    }
  }
}
