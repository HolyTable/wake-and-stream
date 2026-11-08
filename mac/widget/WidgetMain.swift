// wake-and-stream – entry of the widget extension (separate file, so preview.swift can reuse Widget.swift)
import SwiftUI
import WidgetKit

@main
struct WakeAndStreamBundle: WidgetBundle {
    var body: some Widget { WakeAndStreamWidget() }
}
