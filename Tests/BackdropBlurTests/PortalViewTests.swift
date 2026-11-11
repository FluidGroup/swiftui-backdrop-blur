import Testing
import UIKit
@testable import BackdropBlur

@MainActor
struct PortalViewTests {

  @Test
  func mirrorsOnlyWhileInTheHierarchyAndReconnectsOnReinsertion() {
    let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 320, height: 480))
    window.isHidden = false
    defer { window.isHidden = true }

    let source = UIView(frame: CGRect(x: 0, y: 0, width: 120, height: 80))
    window.addSubview(source)
    let portal = PortalView.BackingView(frame: source.bounds)
    portal.update(sourceLayer: source.layer, hidesSourceLayer: true)
    #expect(portal.layer.value(forKey: PortalView.Runtime.sourceKey) == nil)

    window.addSubview(portal)
    #expect(portal.layer.value(forKey: PortalView.Runtime.sourceKey) as? CALayer === source.layer)
    #expect(portal.layer.value(forKey: PortalView.Runtime.hidesSourceKey) as? Bool == true)
    #expect(!portal.isUserInteractionEnabled)
    #expect(portal.layer.masksToBounds)

    portal.removeFromSuperview()
    #expect(portal.layer.value(forKey: PortalView.Runtime.sourceKey) == nil)
    #expect(!source.isHidden)

    window.addSubview(portal)
    #expect(portal.layer.value(forKey: PortalView.Runtime.sourceKey) as? CALayer === source.layer)
  }

  @Test
  func replacesAndClearsTheSourceWithoutReplacingThePortalLayer() {
    let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 320, height: 480))
    window.isHidden = false
    defer { window.isHidden = true }

    let first = CALayer()
    let second = CALayer()
    window.layer.addSublayer(first)
    window.layer.addSublayer(second)
    let portal = PortalView.BackingView(frame: .zero)
    window.addSubview(portal)
    let layer = portal.layer

    portal.update(sourceLayer: first, hidesSourceLayer: true)
    #expect(layer.value(forKey: PortalView.Runtime.sourceKey) as? CALayer === first)

    portal.update(sourceLayer: second, hidesSourceLayer: false)
    #expect(layer.value(forKey: PortalView.Runtime.sourceKey) as? CALayer === second)
    #expect(layer.value(forKey: PortalView.Runtime.hidesSourceKey) as? Bool == false)

    portal.update(sourceLayer: nil, hidesSourceLayer: false)
    #expect(layer.value(forKey: PortalView.Runtime.sourceKey) == nil)
    #expect(portal.layer === layer)
  }

  @Test
  func detachedPortalDoesNotRetainItsSource() {
    let portal = PortalView.BackingView(frame: .zero)
    weak var releasedSource: CALayer?

    autoreleasepool {
      let source = CALayer()
      releasedSource = source
      portal.update(sourceLayer: source, hidesSourceLayer: false)
    }

    #expect(releasedSource == nil)
    #expect(portal.layer.value(forKey: PortalView.Runtime.sourceKey) == nil)
  }
}
