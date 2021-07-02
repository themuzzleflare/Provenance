import Foundation
import SwiftDate

func formatDateAbsolute(for dateString: String) -> String {
    guard let date = dateString.toDate() else {
        return dateString
    }

    return date.toString(.dateTime(.medium))
}

func formatDateRelative(for dateString: String) -> String {
    guard let date = dateString.toDate() else {
        return dateString
    }

    return date.toString(.relative(style: nil))
}
