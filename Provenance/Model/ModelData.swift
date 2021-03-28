import Foundation
import UIKit
import Alamofire
import Rswift

let appDefaults = UserDefaults(suiteName: "group.cloud.tavitian.provenance")!

let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
let appBuild = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "Unknown"
let appName = Bundle.main.infoDictionary?["CFBundleDisplayName"] as? String ?? Bundle.main.infoDictionary?["CFBundleName"] as? String ?? "Provenance"
let appCopyright = Bundle.main.infoDictionary?["NSHumanReadableCopyright"] as? String ?? "Copyright © 2021 Paul Tavitian"

let circularStdBook = R.font.circularStdBook(size: UIFont.labelFontSize)
let circularStdBold = R.font.circularStdBold(size: UIFont.labelFontSize)

var apiKeyDisplay: String {
    switch appDefaults.string(forKey: "apiKey") {
        case nil, "": return "None"
        default: return appDefaults.string(forKey: "apiKey")!
    }
}

var bgCellView: UIView {
    let bgView = UIView()
    bgView.backgroundColor = R.color.accentColor()
    return bgView
}

let up1 = R.image.upLogoSequence.first()!
let up2 = R.image.upLogoSequence.second()!
let up3 = R.image.upLogoSequence.third()!
let up4 = R.image.upLogoSequence.fourth()!
let up5 = R.image.upLogoSequence.fifth()!
let up6 = R.image.upLogoSequence.sixth()!
let up7 = R.image.upLogoSequence.seventh()!
let up8 = R.image.upLogoSequence.eighth()!
let upImages = [up1, up2, up3, up4, up5, up6, up7, up8]
let upAnimation = UIImage.animatedImage(with: upImages, duration: 0.65)!

struct UpApi {
    struct Transactions {
        let listTransactions = "https://api.up.com.au/api/v1/transactions"
    }
    struct Accounts {
        let listAccounts = "https://api.up.com.au/api/v1/accounts"
        func listTransactionsByAccount(accountId: String) -> String {
            return "https://api.up.com.au/api/v1/accounts/\(accountId)/transactions"
        }
    }
    struct Categories {
        let listCategories = "https://api.up.com.au/api/v1/categories"
    }
    struct Tags {
        let listTags = "https://api.up.com.au/api/v1/tags"
    }
}

let acceptJsonHeader: HTTPHeader = .accept("application/json")
var authorisationHeader: HTTPHeader {
    return .authorization(bearerToken: appDefaults.string(forKey: "apiKey") ?? "")
}
let pageSize100Param: [String: Any] = ["page[size]": "100"]
let pageSize200Param: [String: Any] = ["page[size]": "200"]
func filterCategoryParam(categoryId: String) -> [String: Any] {
    return ["filter[category]": categoryId]
}
func filterCategoryAndPageSize100Params(categoryId: String) -> [String: Any] {
    return ["filter[category]": categoryId, "page[size]": "100"]
}
func filterTagParam(tagId: String) -> [String: Any] {
    return ["filter[tag]": tagId]
}
func filterTagAndPageSize100Params(tagId: String) -> [String: Any] {
    return ["filter[tag]": tagId, "page[size]": "100"]
}

// MARK: - URLSession Extensions for Query Parameter Support
protocol URLQueryParameterStringConvertible {
    var queryParameters: String {
        get
    }
}
extension Dictionary: URLQueryParameterStringConvertible {
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
        let URLString: String = String(format: "%@?%@", self.absoluteString, parametersDictionary.queryParameters)
        return URL(string: URLString)!
    }
}

// MARK: - Date Formatters
func formatDate(dateString: String) -> String {
    if let date = ISO8601DateFormatter().date(from: dateString) {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM/yyyy hh:mm:ss a"
        formatter.amSymbol = "AM"
        formatter.pmSymbol = "PM"
        return formatter.string(from: date)
    } else {
        return dateString
    }
}

func formatDateRelative(dateString: String) -> String {
    if let date = ISO8601DateFormatter().date(from: dateString) {
        let formatter = RelativeDateTimeFormatter()
        formatter.dateTimeStyle = .numeric
        return formatter.string(for: date)!
    } else {
        return dateString
    }
}
