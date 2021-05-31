import SwiftUI
import WidgetKit

@main
struct ProvenanceWidgets: WidgetBundle {
    @WidgetBundleBuilder
    var body: some Widget {
        AccountBalance()
        LatestTransaction()
    }
}
