import Foundation
#if canImport(UIKit)
import UIKit
#endif

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

func formatDate(dateString: String) -> String {
    if let date = ISO8601DateFormatter().date(from: dateString) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd/MM/yyyy hh:mm:ss a"
        dateFormatter.amSymbol = "AM"
        dateFormatter.pmSymbol = "PM"
        return dateFormatter.string(from: date)
    } else {
        return dateString
    }
}

func formatDateRelative(dateString: String) -> String {
    if let date = ISO8601DateFormatter().date(from: dateString) {
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .short
        formatter.allowedUnits = [.year, .month, .weekOfMonth, .day, .hour, .minute]
        formatter.zeroFormattingBehavior = .dropAll
        return "\(formatter.string(from: date.timeIntervalSinceNow)!.replacingOccurrences(of: "-", with: "")) ago"
    } else {
        return dateString
    }
}

#if os(iOS) || targetEnvironment(macCatalyst)
let up1: UIImage = UIImage(named: "UpLogoSequence/1")!
let up2: UIImage = UIImage(named: "UpLogoSequence/2")!
let up3: UIImage = UIImage(named: "UpLogoSequence/3")!
let up4: UIImage = UIImage(named: "UpLogoSequence/4")!
let up5: UIImage = UIImage(named: "UpLogoSequence/5")!
let up6: UIImage = UIImage(named: "UpLogoSequence/6")!
let up7: UIImage = UIImage(named: "UpLogoSequence/7")!
let up8: UIImage = UIImage(named: "UpLogoSequence/8")!
let upImages: [UIImage] = [up1, up2, up3, up4, up5, up6, up7, up8]
let upAnimation: UIImage =  UIImage.animatedImage(with: upImages, duration: 0.65)!
#endif
