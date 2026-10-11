import CoreGraphics
import QuartzCore
import SwiftUI
import UIKit

/// Progressively blurs the content behind its bounds using an alpha mask.
///
/// Give this view a size in a background or overlay. It adds no tint, passes
/// touches through, and animates its maximum radius with SwiftUI. The backing
/// view retains its Core Graphics mask until the gradient configuration changes.
///
/// This view requires private native backdrop and filter runtime APIs.
@MainActor
public struct VariableBlurView: View, Animatable {

  /// The edge at which the blur reaches its maximum radius.
  public enum Direction: Equatable, Sendable {
    /// Blurs the top edge and progressively clears toward the bottom.
    case blurredTopClearBottom
    /// Blurs the bottom edge and progressively clears toward the top.
    case blurredBottomClearTop
  }

  /// Describes the gradient independently of the animated blur radius.
  ///
  /// Changes replace the cached mask immediately; they are not interpolated.
  public struct Configuration: Equatable, Sendable {
    /// The edge at which the blur reaches its maximum radius.
    public var direction: Direction

    /// Moves the clear endpoint toward the blurred edge, as a fraction of height.
    ///
    /// Zero spans the whole view. Positive values leave a fully clear region;
    /// negative values leave some blur at the otherwise clear edge. Must be
    /// finite and less than one so the gradient retains a positive length.
    public var startOffset: CGFloat

    /// Creates a gradient whose clear endpoint is offset by a fraction of height.
    ///
    /// - Parameters:
    ///   - direction: The edge with the maximum blur radius.
    ///   - startOffset: A finite value less than one. Negative values retain
    ///     some blur at the opposite edge; zero spans the full height.
    public init(direction: Direction = .blurredTopClearBottom, startOffset: CGFloat = 0) {
      self.direction = direction
      self.startOffset = startOffset
    }
  }

  /// The maximum blur radius. Must be finite and nonnegative.
  public nonisolated var maxBlurRadius: CGFloat

  /// The direction and clear endpoint used to generate the mask.
  public var configuration: Configuration

  /// Clamps negative spring overshoot while SwiftUI interpolates the radius.
  public nonisolated var animatableData: CGFloat {
    get { maxBlurRadius }
    set {
      precondition(newValue.isFinite, "Animated blur radius must be finite")
      maxBlurRadius = max(0, newValue)
    }
  }

  /// Creates a progressive backdrop blur with an independently configured mask.
  public init(maxBlurRadius: CGFloat = 20, configuration: Configuration = .init()) {
    self.maxBlurRadius = maxBlurRadius
    self.configuration = configuration
  }

  public var body: some View {
    Representable(maxBlurRadius: maxBlurRadius, configuration: configuration)
  }

  /// Updates the existing UIKit view without rebuilding its layer or filter.
  private struct Representable: UIViewRepresentable {
    let maxBlurRadius: CGFloat
    let configuration: Configuration

    func makeUIView(context: Context) -> BackingView {
      BackingView(maxBlurRadius: maxBlurRadius, configuration: configuration)
    }

    func updateUIView(_ uiView: BackingView, context: Context) {
      uiView.update(maxBlurRadius: maxBlurRadius, configuration: configuration)
    }
  }

  /// Owns the native backdrop filter and a single mask for this view's lifetime.
  ///
  /// The filter retains the image. Only direction or offset changes regenerate
  /// it; radius updates and layout reuse the same image and backing layer.
  final class BackingView: UIView {
    private var maskConfiguration: Configuration?

    override class var layerClass: AnyClass {
      BackdropRuntime.layerClass
    }

    init(maxBlurRadius: CGFloat, configuration: Configuration) {
      let filter = BackdropRuntime.makeFilter(kind: .progressive)
      filter.setValue("blur", forKey: BackdropRuntime.filterNameKey)
      filter.setValue(true, forKey: BackdropRuntime.edgeNormalizationKey)
      filter.setValue(0.0, forKey: BackdropRuntime.radiusKey)

      super.init(frame: .zero)

      isOpaque = false
      backgroundColor = .clear
      isUserInteractionEnabled = false
      layer.masksToBounds = true
      layer.setValue(1.0, forKey: BackdropRuntime.scaleKey)
      layer.filters = [filter]
      update(maxBlurRadius: maxBlurRadius, configuration: configuration)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
      fatalError("init(coder:) has not been implemented")
    }

    /// Applies live inputs through the layer so Core Animation observes changes.
    func update(maxBlurRadius: CGFloat, configuration: Configuration) {
      precondition(
        maxBlurRadius.isFinite && maxBlurRadius >= 0,
        "Blur radius must be finite and nonnegative"
      )

      CATransaction.begin()
      CATransaction.setDisableActions(true)
      defer { CATransaction.commit() }

      if maskConfiguration != configuration {
        let image = GradientMask.makeImage(configuration: configuration)
        layer.setValue(image, forKeyPath: BackdropRuntime.maskKeyPath)
        maskConfiguration = configuration
      }
      // SwiftUI supplies interpolated samples. Implicit layer animations would
      // interpolate them a second time and lag behind the intended radius.
      layer.setValue(maxBlurRadius, forKeyPath: BackdropRuntime.radiusKeyPath)
    }
  }
}

#if DEBUG

private extension VariableBlurView {
  /// Exercises direction, mask replacement, and radius animation on live content.
  struct Preview: View {
    @State private var maxBlurRadius: CGFloat = 20
    @State private var configuration = Configuration()

    var body: some View {
      VStack(spacing: 24) {
        ScrollView {
          VStack(spacing: 16) {
            ForEach(0..<20) { index in
              Text("Backdrop \(index)")
                .font(.largeTitle.bold())
                .frame(maxWidth: .infinity)
            }
          }
        }
        .frame(height: 320)
        .background {
          LinearGradient(
            colors: [.pink, .orange, .indigo],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
          )
        }
        .overlay {
          VariableBlurView(maxBlurRadius: maxBlurRadius, configuration: configuration)
        }
        .clipShape(RoundedRectangle(cornerRadius: 24))

        Picker("Direction", selection: $configuration.direction) {
          Text("Blur top").tag(Direction.blurredTopClearBottom)
          Text("Blur bottom").tag(Direction.blurredBottomClearTop)
        }
        .pickerStyle(.segmented)

        Text("Radius: \(maxBlurRadius, specifier: "%.1f")")
          .monospacedDigit()
        Slider(value: $maxBlurRadius, in: 0...40)
        Text("Offset: \(configuration.startOffset, specifier: "%.2f")")
          .monospacedDigit()
        Slider(value: $configuration.startOffset, in: -0.3...0.8)
        Button("Animate blur") {
          withAnimation(.spring(response: 0.8, dampingFraction: 0.65)) {
            maxBlurRadius = maxBlurRadius < 20 ? 40 : 0
          }
        }
      }
      .padding()
    }
  }
}

#Preview("Variable backdrop blur") {
  VariableBlurView.Preview()
}

#endif
