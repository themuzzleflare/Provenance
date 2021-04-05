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
7. Build the project with **⌘ + B** or by selecting **Product -> Build** from the menu bar (do this **at least once**).
