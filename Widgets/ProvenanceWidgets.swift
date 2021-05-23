import SwiftUI
import WidgetKit

@main
struct ProvenanceWidgets: WidgetBundle {
    var body: some Widget {
        AccountBalance()
        LatestTransaction()
    }
}
