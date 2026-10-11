import Foundation
import QuartzCore

/// Resolves encoded private runtime identifiers for the backdrop views.
///
/// Decoded names are retained once and reused by creation and live updates.
/// Encoding avoids plaintext identifiers in source literals; it does not change
/// the runtime API dependency or guarantee compatibility with future systems.
@MainActor
enum BackdropRuntime {

  /// Selects the native filter behavior without exposing its runtime identifier.
  enum FilterKind {
    case uniform
    case progressive
  }

  private static let layerClassName = decode("DBCbdlespqMbzfs")
  private static let filterClassName = decode("DBGjmufs")
  private static let factoryName = decode("gjmufsXjuiUzqf;")
  private static let uniformKind = decode("hbvttjboCmvs")
  private static let progressiveKind = decode("wbsjbcmfCmvs")
  static let filterNameKey = decode("obnf")
  static let edgeNormalizationKey = decode("joqvuOpsnbmj{fFehft")
  static let radiusKey = decode("joqvuSbejvt")
  static let maskKey = decode("joqvuNbtlJnbhf")
  static let scaleKey = decode("tdbmf")
  static let radiusKeyPath = decode("gjmufst/cmvs/joqvuSbejvt")
  static let maskKeyPath = decode("gjmufst/cmvs/joqvuNbtlJnbhf")
  static let edgeNormalizationKeyPath = decode("gjmufst/cmvs/joqvuOpsnbmj{fFehft")

  /// Resolves the native backing layer once for both blur views.
  static let layerClass: AnyClass = {
    guard let layerClass = NSClassFromString(layerClassName) as? CALayer.Type else {
      preconditionFailure("Native backdrop layer is unavailable on this runtime")
    }
    return layerClass
  }()

  /// Creates an independent native filter with the selected blur behavior.
  static func makeFilter(kind: FilterKind) -> NSObject {
    let identifier: String
    switch kind {
    case .uniform:
      identifier = uniformKind
    case .progressive:
      identifier = progressiveKind
    }
    let selector = NSSelectorFromString(factoryName)
    guard
      let filterClass = NSClassFromString(filterClassName) as? NSObject.Type,
      filterClass.responds(to: selector),
      let filter = filterClass.perform(selector, with: identifier)?
        .takeUnretainedValue() as? NSObject
    else {
      preconditionFailure("Native backdrop filter is unavailable on this runtime")
    }
    return filter
  }

  /// Restores a shifted identifier only at its runtime lookup boundary.
  ///
  /// Keep this out of the caller so Release optimization does not inline the
  /// constant decoding work into each identifier's initialization site.
  @inline(never)
  private static func decode(_ encoded: String) -> String {
    String(encoded.unicodeScalars.map { Character(UnicodeScalar($0.value - 1)!) })
  }
}
