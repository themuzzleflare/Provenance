import Foundation
import UIKit
import Alamofire
import SwiftyGif
import Rswift

// MARK: - UserDefaults Suite for Provenance Application Group

let appDefaults = UserDefaults(suiteName: "group.cloud.tavitian.provenance")!

// MARK: - UserDefaults Extension for Value Observation

extension UserDefaults {
    @objc dynamic var apiKey: String {
        get {
            return string(forKey: "apiKey") ?? ""
        }
        set {
            set(newValue, forKey: "apiKey")
            print("Set API Key to: \(newValue)")
        }
    }

    @objc dynamic var dateStyle: String {
        get {
            return string(forKey: "dateStyle") ?? "Absolute"
        }
        set {
            set(newValue, forKey: "dateStyle")
            print("Set Date Style to: \(newValue)")
        }
    }

    var appVersion: String {
        get {
            return string(forKey: "appVersion") ?? "Unknown"
        }
    }

    var appBuild: String {
        get {
            return string(forKey: "appBuild") ?? "Unknown"
        }
    }
}

// MARK: - Application Metadata & Reusable Values

let appName = Bundle.main.infoDictionary?["CFBundleDisplayName"] as? String ?? Bundle.main.infoDictionary?["CFBundleName"] as? String ?? "Provenance"
let appCopyright = Bundle.main.infoDictionary?["NSHumanReadableCopyright"] as? String ?? "Copyright © 2021 Paul Tavitian"

var selectedBackgroundCellView: UIView {
    let view = UIView()
    view.backgroundColor = R.color.accentColour()
    return view
}

// MARK: - UICollectionView Layouts

func twoColumnGridLayout() -> UICollectionViewLayout {
    return UICollectionViewCompositionalLayout { sectionIndex, layoutEnvironment in
        let columns = 2
        let spacing = CGFloat(10)
        let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .fractionalHeight(1.0))
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(100))
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitem: item, count: columns)
        group.interItemSpacing = .fixed(spacing)
        let section = NSCollectionLayoutSection(group: group)
        section.interGroupSpacing = spacing
        section.contentInsets = NSDirectionalEdgeInsets(top: 10, leading: 10, bottom: 10, trailing: 10)
        return section
    }
}

func gridLayout() -> UICollectionViewLayout {
    let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(0.2), heightDimension: .fractionalHeight(1.0))
    let item = NSCollectionLayoutItem(layoutSize: itemSize)
    let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .fractionalWidth(0.2))
    let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
    let section = NSCollectionLayoutSection(group: group)
    let layout = UICollectionViewCompositionalLayout(section: section)
    return layout
}

// MARK: - GIF Stickers Array

private let stickerTwo = try! UIImage(gifName: "StickerTwo.gif")
private let stickerThree = try! UIImage(gifName: "StickerThree.gif")
private let stickerSix = try! UIImage(gifName: "StickerSix.gif")
private let stickerSeven = try! UIImage(gifName: "StickerSeven.gif")

let stickerGifs = [stickerTwo, stickerThree, stickerSix, stickerSeven]

// MARK: - Animated Application Logo

let upAnimation = UIImage.animatedImage(with: [
    R.image.upLogoSequence.first()!,
    R.image.upLogoSequence.second()!,
    R.image.upLogoSequence.third()!,
    R.image.upLogoSequence.fourth()!,
    R.image.upLogoSequence.fifth()!,
    R.image.upLogoSequence.sixth()!,
    R.image.upLogoSequence.seventh()!,
    R.image.upLogoSequence.eighth()!
], duration: 0.65)!

// MARK: - Alamofire Predicates for Up API

var authorisationHeader: HTTPHeader {
    .authorization(bearerToken: appDefaults.apiKey)
}

let acceptJsonHeader: HTTPHeader = .accept("application/json")
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

// MARK: - Protocols & Extensions for URLSession Query Parameter Support

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

func formatDateAbsolute(dateString: String) -> String {
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
