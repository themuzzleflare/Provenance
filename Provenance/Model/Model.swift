import Foundation
import UIKit

#if canImport(Rswift)
import Rswift
#endif

let upApi = Up.self

let appName = Bundle.main.infoDictionary?["CFBundleDisplayName"] as? String ?? Bundle.main.infoDictionary?["CFBundleName"] as? String ?? "Provenance"
let appCopyright = Bundle.main.infoDictionary?["NSHumanReadableCopyright"] as? String ?? "Copyright © 2021 Paul Tavitian"

#if canImport(Rswift)
var selectedBackgroundCellView: UIView {
    let view = UIView()
    
    view.backgroundColor = R.color.accentColour()
    
    return view
}
#endif
