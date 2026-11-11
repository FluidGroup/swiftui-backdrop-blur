import SwiftUI
import UIKit

/// Displays a live mirror of a view or layer without moving the source.
///
/// Give the portal an explicit size. It draws at the source's scale, clips to
/// its bounds, and passes touches through. The source must remain in the same
/// on-screen layer tree and must not contain the portal itself.
/// This view depends on private native Core Animation runtime APIs.
public struct PortalView: View {

  private let source: CALayer?
  private let hidesSource: Bool

  public init(sourceLayer: CALayer?, hidesSourceLayer: Bool = false) {
    self.source = sourceLayer
    self.hidesSource = hidesSourceLayer
  }

  public init(sourceView: UIView?, hidesSourceLayer: Bool = false) {
    self.init(sourceLayer: sourceView?.layer, hidesSourceLayer: hidesSourceLayer)
  }

  public var body: some View {
    Representable(source: source, hidesSource: hidesSource)
  }

  private struct Representable: UIViewRepresentable {

    let source: CALayer?
    let hidesSource: Bool

    func makeUIView(context: Context) -> BackingView {
      let view = BackingView(frame: .zero)
      view.update(sourceLayer: source, hidesSourceLayer: hidesSource)
      return view
    }

    func updateUIView(_ uiView: BackingView, context: Context) {
      uiView.update(sourceLayer: source, hidesSourceLayer: hidesSource)
    }

    static func dismantleUIView(_ uiView: BackingView, coordinator: ()) {
      uiView.update(sourceLayer: nil, hidesSourceLayer: false)
    }
  }

  // Adapted from FluidGroup/FluidInterfaceKit's FluidPortal:
  // https://github.com/FluidGroup/FluidInterfaceKit/blob/main/Sources/FluidPortal/PortalView.swift
  final class BackingView: UIView {

    private weak var source: CALayer?
    private var isInHierarchy = false

    override class var layerClass: AnyClass {
      Runtime.layerClass
    }

    override init(frame: CGRect) {
      super.init(frame: frame)
      isOpaque = false
      isUserInteractionEnabled = false
      layer.masksToBounds = true
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
      fatalError("init(coder:) has not been implemented")
    }

    func update(sourceLayer: CALayer?, hidesSourceLayer: Bool) {
      self.source = sourceLayer

      CATransaction.begin()
      CATransaction.setDisableActions(true)
      layer.setValue(hidesSourceLayer, forKey: Runtime.hidesSourceKey)
      updateSource()
      CATransaction.commit()
    }

    override func action(for layer: CALayer, forKey event: String) -> CAAction? {
      switch event {
      case kCAOnOrderIn:
        isInHierarchy = true
        updateSource()
      case kCAOnOrderOut:
        isInHierarchy = false
        updateSource()
      default:
        break
      }
      return super.action(for: layer, forKey: event)
    }

    private func updateSource() {
      let activeSource = isInHierarchy ? source : nil
      guard (layer.value(forKey: Runtime.sourceKey) as? CALayer) !== activeSource else {
        return
      }
      layer.setValue(activeSource, forKey: Runtime.sourceKey)
    }
  }

  @MainActor
  enum Runtime {

    static let sourceKey = decode("tpvsdfMbzfs")
    static let hidesSourceKey = decode("ijeftTpvsdfMbzfs")

    static let layerClass: AnyClass = {
      guard let layerClass = NSClassFromString(decode("DBQpsubmMbzfs")) as? CALayer.Type else {
        preconditionFailure("Native portal layer is unavailable on this runtime")
      }
      return layerClass
    }()

    @inline(never)
    private static func decode(_ encoded: String) -> String {
      String(encoded.unicodeScalars.map { Character(UnicodeScalar($0.value - 1)!) })
    }
  }
}

#if DEBUG

private struct PortalDemo: View {

  @State private var sourceView = UILabel()
  @State private var count = 0
  @State private var hidesSource = false
  @State private var showsPortal = true

  var body: some View {
    VStack(spacing: 24) {
      Source(view: sourceView, count: count)
        .frame(width: 240, height: 120)

      if showsPortal {
        PortalView(sourceView: sourceView, hidesSourceLayer: hidesSource)
          .frame(width: 240, height: 120)
          .clipShape(RoundedRectangle(cornerRadius: 24))
      }

      Button("Update source: \(count)") {
        count += 1
      }

      Toggle("Hide source while mirroring", isOn: $hidesSource)
      Toggle("Show portal", isOn: $showsPortal)
    }
    .padding()
  }

  private struct Source: UIViewRepresentable {

    let view: UILabel
    let count: Int

    func makeUIView(context: Context) -> UILabel {
      view.backgroundColor = .systemIndigo
      view.textColor = .white
      view.font = .preferredFont(forTextStyle: .largeTitle)
      view.textAlignment = .center
      return view
    }

    func updateUIView(_ uiView: UILabel, context: Context) {
      uiView.text = "Live mirror \(count)"
    }
  }
}

#Preview("Live portal") {
  PortalDemo()
}

#endif
