import Foundation

func categoryName(for category: CategoryFilter) -> String {
    switch category {
    case .gamesAndSoftware:
        return "Apps, Games & Software"
    case .carInsuranceAndMaintenance:
        return "Car Insurance, Rego & Maintenance"
    case .family:
        return "Children & Family"
    case .homeMaintenanceAndImprovements:
        return "Maintenance & Improvements"
    case .newsMagazinesAndBooks:
        return "News, Magazines & Books"
    case .tollRoads:
        return "Tolls"
    case .carRepayments:
        return "Repayments"
    case .homeInsuranceAndRates:
        return "Rates & Insurance"
    case .tvAndMusic:
        return "TV, Music & Streaming"
    default:
        return category.rawValue
            .replacingOccurrences(of: "and", with: "&")
            .replacingOccurrences(of: "-", with: " ")
            .capitalized
    }
}
