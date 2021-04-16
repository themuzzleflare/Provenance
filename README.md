# Provenance
Provenance is a lightweight application that interacts with the Up Banking Developer API to display information about your bank accounts, transactions, categories, tags, and more.
## Building (macOS)
To proceed with the following steps, install [Homebrew Package Manager](https://brew.sh) along with the following packages:
- **GitHub** command-line tool (`brew install gh`),
- **CocoaPods** - Dependency manager for Cocoa projects (`brew install cocoapods`).

1. Open Terminal.
2. Clone the Provenance repository (`gh repo clone themuzzleflare/Provenance`).
3. Change your current working directory to the root directory of the cloned repository (`cd Provenance`).
4. Install the CocoaPods dependencies of the project (`pod install`).
5. Open the newly generated **Provenance.xcworkspace** file found in the root directory of the cloned repository.
6. Change the signing credentials under the **Signing & Capabilities** tab of the **Provenance**, **Provenance Widgets** and **Provenance Stickers** targets to your own.
7. Change the active App Group of the **Provenance** and **Provenance Widgets** targets to one that reflects your own identifier.
8. Update **Provenance -> Model -> ModelData.swift, line 8**, so that the `suiteName` of `UserDefaults` reflects the identifier of your app group.
9. Update **Widgets -> Model -> ModelData.swift, line 3**, so that the `suiteName` of `UserDefaults` reflects the identifier of your app group.
10. Update **Provenance -> Application -> Settings.bundle -> Root.plist** so that the value of the `ApplicationGroupContainerIdentifier` key reflects the identifier of your app group.
11. Build the project with **⌘ + B** or by selecting **Product -> Build** from the menu bar (do this **at least once**).
