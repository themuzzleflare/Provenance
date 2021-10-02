import IGListKit

extension IGListAdapterUpdateType {
  var description: String {
    switch self {
    case .itemUpdates:
      return "Item Updates"
    case .performUpdates:
      return "Perform Updates"
    case .reloadData:
      return "Reload Data"
    }
  }
}
