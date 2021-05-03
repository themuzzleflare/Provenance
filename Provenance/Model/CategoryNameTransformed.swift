import Foundation

func categoryNameTransformed(_ category: FilterCategory) -> String {
    switch category {
        case .gamesAndSoftware:
            return "Apps, Games & Software"
        case .carInsuranceAndMaintenance:
            return "Car Insurance, Rego & Maintenance"
        case .tvAndMusic:
            return "TV, Music & Streaming"
        default:
            return category.rawValue.replacingOccurrences(of: "and", with: "&").replacingOccurrences(of: "-", with: " ").capitalized
    }
}
