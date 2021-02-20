import Foundation
import UIKit

let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
let appBuild = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "Unknown"
let appName = Bundle.main.infoDictionary?["CFBundleDisplayName"] as? String ?? Bundle.main.infoDictionary?["CFBundleName"] as? String ?? "Provenance"
let appCopyright = Bundle.main.infoDictionary?["NSHumanReadableCopyright"] as? String ?? "Copyright © 2021 Paul Tavitian"

protocol URLQueryParameterStringConvertible {
    var queryParameters: String {
        get
    }
}
extension Dictionary : URLQueryParameterStringConvertible {
    var queryParameters: String {
        var parts: [String] = []
        for (key, value) in self {
            let part = String(format: "%@=%@",
                              String(describing: key).addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!,
                              String(describing: value).addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!)
            parts.append(part as String)
        }
        return parts.joined(separator: "&")
    }
}
extension URL {
    func appendingQueryParameters(_ parametersDictionary : Dictionary<String, String>) -> URL {
        let URLString : String = String(format: "%@?%@", self.absoluteString, parametersDictionary.queryParameters)
        return URL(string: URLString)!
    }
}

var up1: UIImage = UIImage(named: "UpLogoSequence/1")!
var up2: UIImage = UIImage(named: "UpLogoSequence/2")!
var up3: UIImage = UIImage(named: "UpLogoSequence/3")!
var up4: UIImage = UIImage(named: "UpLogoSequence/4")!
var up5: UIImage = UIImage(named: "UpLogoSequence/5")!
var up6: UIImage = UIImage(named: "UpLogoSequence/6")!
var up7: UIImage = UIImage(named: "UpLogoSequence/7")!
var up8: UIImage = UIImage(named: "UpLogoSequence/8")!
var upImages: [UIImage] = [up1, up2, up3, up4, up5, up6, up7, up8]
let upAnimation: UIImage =  UIImage.animatedImage(with: upImages, duration: 0.65)!
