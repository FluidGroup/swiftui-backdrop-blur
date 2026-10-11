import QuartzCore
import SwiftUI
import UIKit

/// Blurs the content behind its bounds using a native backdrop layer.
///
/// Use this view in a background or overlay and give it a size through SwiftUI.
/// The blur has no additional tint or saturation effect and passes touches
/// through to the views underneath.
/// The radius participates in SwiftUI animations.
///
/// This view uses private native backdrop and filter runtime APIs.
/// Creating it requires those APIs to be available on the current runtime.
@MainActor
public struct BackdropBlurView: View, Animatable {

  /// The Gaussian blur's input radius. Must be finite and nonnegative.
  ///
  /// Zero leaves the backdrop sharp. SwiftUI interpolates animated changes;
  /// each sampled radius updates the existing backing layer directly.
  public nonisolated var blurRadius: CGFloat

  /// Provides the radius SwiftUI interpolates over successive animation frames.
  ///
  /// Spring overshoot below zero is clamped to keep the blur radius valid.
  public nonisolated var animatableData: CGFloat {
    get { blurRadius }
    set {
      precondition(newValue.isFinite, "Animated blur radius must be finite")
      blurRadius = max(0, newValue)
    }
  }

  /// Creates a backdrop blur with the given Gaussian radius.
  public init(blurRadius: CGFloat) {
    self.blurRadius = blurRadius
  }

  public var body: some View {
    Representable(blurRadius: blurRadius)
  }

  /// Applies SwiftUI's sampled radius to a stable UIKit backdrop view.
  private struct Representable: UIViewRepresentable {

    let blurRadius: CGFloat

    func makeUIView(context: Context) -> BackingView {
      BackingView(blurRadius: blurRadius)
    }

    func updateUIView(_ uiView: BackingView, context: Context) {
      uiView.setBlurRadius(blurRadius)
    }
  }

  /// Hosts the backdrop layer whose filter samples content behind this view.
  ///
  /// UIKit manages the layer's bounds and display scale. The representable
  /// creates this view and updates its radius for the lifetime of one mount.
  final class BackingView: UIView {

    /// Uses the native backdrop implementation as the view's backing layer.
    override class var layerClass: AnyClass {
      BackdropRuntime.layerClass
    }

    fileprivate init(blurRadius: CGFloat) {
      let filter = BackdropRuntime.makeFilter(kind: .uniform)
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
      setBlurRadius(blurRadius)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
      fatalError("init(coder:) has not been implemented")
    }

    /// Updates through the layer so Core Animation observes the filter change.
    fileprivate func setBlurRadius(_ blurRadius: CGFloat) {
      precondition(
        blurRadius.isFinite && blurRadius >= 0,
        "Blur radius must be finite and nonnegative"
      )

      CATransaction.begin()
      CATransaction.setDisableActions(true)
      // SwiftUI already supplies interpolated samples; implicit layer animation
      // would animate each sample again and lag behind the intended curve.
      // The filter's name forms this key path; mutating only the filter object
      // does not reliably notify the layer's rendering machinery.
      layer.setValue(blurRadius, forKeyPath: BackdropRuntime.radiusKeyPath)
      CATransaction.commit()
    }
  }
}

#if DEBUG

private extension BackdropBlurView {

  /// Shows sharp and blurred regions together while the radius is adjusted.
  struct Preview: View {

    @State private var blurRadius: CGFloat = 20

    var body: some View {
      VStack(spacing: 24) {
        Sample(blurRadius: blurRadius)
        Controls(blurRadius: $blurRadius)
      }
      .padding()
    }

    /// Places a bounded blur over a visible pattern for comparison.
    struct Sample: View {

      let blurRadius: CGFloat

      var body: some View {
        ZStack {
          LinearGradient(
            colors: [.pink, .orange, .indigo],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
          )

          VStack(spacing: 20) {
            ForEach(0..<6) { index in
              Text("Backdrop \(index)")
                .font(.largeTitle.bold())
            }
          }
          .foregroundStyle(.white)
        }
        .frame(height: 320)
        .overlay {
          BackdropBlurView(blurRadius: blurRadius)
            .frame(width: 240, height: 180)
            .clipShape(RoundedRectangle(cornerRadius: 24))
            .overlay {
              RoundedRectangle(cornerRadius: 24)
                .stroke(.white, lineWidth: 1)
            }
        }
      }
    }

    /// Lets the preview change the radius without replacing the backdrop view.
    struct Controls: View {

      @Binding var blurRadius: CGFloat

      var body: some View {
        VStack(spacing: 12) {
          Text("Radius: \(blurRadius, specifier: "%.1f")")
            .monospacedDigit()
          Slider(value: $blurRadius, in: 0...40) {
            Text("Blur radius")
          }
          Button("Animate blur") {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.65)) {
              blurRadius = blurRadius < 20 ? 40 : 0
            }
          }
        }
      }
    }
  }
}

#Preview("Backdrop blur") {
  BackdropBlurView.Preview()
}

#endif
