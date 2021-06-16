import Foundation

    // MARK: - UserDefaults Suite for Provenance Application Group

let appDefaults = UserDefaults(suiteName: "group.cloud.tavitian.provenance")!

    // MARK: - UserDefaults Extension for Value Observation

extension UserDefaults {
    var apiKey: String {
        get {
            return string(forKey: "apiKey") ?? ""
        }
    }

    var dateStyle: String {
        get {
            return string(forKey: "dateStyle") ?? "Absolute"
        }
    }
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
            let part = String(format: "%@=%@", String(describing: key).addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!, String(describing: value).addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!)
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
