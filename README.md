# SwiftUI Backdrop Blur

<img width="2752" height="2064" alt="backdrop-blur-showcase" src="https://github.com/user-attachments/assets/4c5a0171-dfa9-4697-b407-809703cacf14" />

Uniform and progressive backdrop blur views for SwiftUI on iOS 17 and later.
Requires Swift 6. The package has no external dependencies.

Both views use private native backdrop and Core Animation filter runtime APIs.
Those APIs must be available on the running OS. Encoding a runtime class name
is not a guarantee of compatibility or App Store acceptance.

## Add the package

For a local checkout, add the package folder in Xcode, or use:

```swift
.package(path: "/path/to/swiftui-backdrop-blur")
```

Add the `BackdropBlur` library product to the consuming target:

```swift
.product(name: "BackdropBlur", package: "swiftui-backdrop-blur")
```

The repository is https://github.com/FluidGroup/swiftui-backdrop-blur.
Remote installation requires the package to be committed and pushed there.

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
