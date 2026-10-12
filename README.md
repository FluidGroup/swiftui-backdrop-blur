# SwiftUI Backdrop Blur

<img width="1280" height="960" alt="backdrop-blur-showcase Large" src="https://github.com/user-attachments/assets/1155a3f2-7358-4bda-b258-3d8e44e94979" />

Uniform and progressive backdrop blur views for SwiftUI on iOS 17 and later.
Requires Swift 6. The package has no external dependencies.

Both views use private native backdrop and Core Animation filter runtime APIs.
Those APIs must be available on the running OS. Encoding a runtime class name
is not a guarantee of compatibility or App Store acceptance.

## Add the package

[Version 1.0.0](https://github.com/FluidGroup/swiftui-backdrop-blur/releases/tag/1.0.0)
is available through Swift Package Manager.

In Xcode, choose **File → Add Package Dependencies**, enter
`https://github.com/FluidGroup/swiftui-backdrop-blur`, and select **Up to Next Major
Version** starting at **1.0.0**. Add the `BackdropBlur` product to your app target.

For a `Package.swift` manifest, add:

```swift
.package(
  url: "https://github.com/FluidGroup/swiftui-backdrop-blur",
  from: "1.0.0"
)
```

Add the `BackdropBlur` library product to the consuming target:

```swift
.product(name: "BackdropBlur", package: "swiftui-backdrop-blur")
```

For a local checkout, use the package folder instead of the remote dependency:

```swift
.package(path: "/path/to/swiftui-backdrop-blur")
```

## Uniform blur

```swift
import BackdropBlur
import SwiftUI

ContentView()
  .overlay {
    BackdropBlurView(blurRadius: 16)
      .frame(width: 240, height: 180)
      .clipShape(RoundedRectangle(cornerRadius: 24))
  }
```

The radius is finite and nonnegative. Zero leaves the background sharp.
Changes participate in `withAnimation` and `.animation(_:value:)`.

## Progressive blur

```swift
import BackdropBlur
import SwiftUI

ContentView()
  .overlay(alignment: .top) {
    VariableBlurView(
      maxBlurRadius: 20,
      configuration: .init(
        direction: .blurredTopClearBottom,
        startOffset: -0.1
      )
    )
    .frame(height: 200)
  }
```

Use `.blurredBottomClearTop` to reverse the direction. The maximum radius
animates with SwiftUI; direction and offset changes apply immediately.
`startOffset` is finite and less than one:

- Zero spreads the gradient across the full height.
- Positive values leave a fully clear region near the opposite edge.
- Negative values leave some blur at the opposite edge.

The 100 × 100 alpha mask is drawn with Core Graphics and retained by each
backing view. Only direction or offset changes regenerate it. Radius animations
and layout changes reuse the mask. No Core Image context or filter is created.

Both views add no tint and disable interaction on their UIKit backing views.
They sample live content behind their bounds rather than taking a snapshot.
Give the views an explicit size or use an overlay/background that supplies one.

## Photo showcase

The screenshot shows the views rendering live in an iOS 18.6 Simulator.
From left to right:

- **Uniform:** `BackdropBlurView` behind a floating collection panel.
- **Progressive:** `VariableBlurView` fading from clear to blurred at the bottom.
- **Layered:** a uniform search surface with a progressive lower toolbar.

The phone frames and interface are SwiftUI artwork on one iPad canvas. The blur
comes from the package's live native layers; the demo adds a subtle tint for
text contrast.

## Development

Both views include `#Preview` examples. Build and test on an iOS Simulator;
this UIKit package does not support macOS or Linux builds with `swift test`.

```sh
xcodebuild test -scheme swiftui-backdrop-blur \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro' \
  -derivedDataPath /tmp/swiftui-backdrop-blur-derived
```

The progressive-filter approach was informed by
[nikstar/VariableBlur](https://github.com/nikstar/VariableBlur).

Licensed under Apache 2.0; see [LICENSE](LICENSE).
