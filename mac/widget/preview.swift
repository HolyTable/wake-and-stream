// wake-and-stream – renders the widget in all states to PNG files, to check the layout without
// adding it to Notification Center (Liquid Glass is not shown here, only a soft fill).
//   bash mac/widget/build.sh --preview <folder>
import AppKit
import SwiftUI
import WidgetKit

@main
enum Preview {
    @MainActor static func main() {
        // build.sh needs the Swift type name of the intent for Metadata.appintents
        if CommandLine.arguments.dropFirst().first == "--mangled" {
            print(_mangledTypeName(WidgetActionIntent.self) ?? ""); return
        }
        WAS.preview = true
        let out = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "."
        func st(_ f: (inout PCState) -> Void) -> PCState { var s = PCState(); s.home = true; s.lang = "de"; f(&s); return s }
        let cases: [(String, PCState?)] = [
            ("off", st { _ in }),
            ("sleep", st { $0.last = "sleep" }),
            ("on", st { $0.on = true }),
            ("rdp", st { $0.on = true; $0.rdp = true }),
            ("paused", st { $0.on = true; $0.stream = 1 }),
            ("streaming", st { $0.on = true; $0.stream = 2 }),
            ("busy", st { $0.busy = "on" }),
            ("busy-play", st { $0.on = true; $0.busy = "play" }),
            ("busy-play-off", st { $0.busy = "play" }),
            ("ask-wake", st { $0.last = "sleep"; $0.confirm = "on" }),
            ("ask-work", st { $0.confirm = "work" }),
            ("ask-off", st { $0.on = true; $0.confirm = "off" }),
            ("nohome", st { $0.home = false }),
            ("noapp", nil),
        ]
        for (name, state) in cases {
            for (fam, size) in [(WidgetFamily.systemSmall, CGSize(width: 170, height: 170)),
                                (.systemMedium, CGSize(width: 364, height: 170))] {
                for dark in [false, true] {
                    let view = WidgetView(entry: Entry(date: Date(), state: state), family: fam)
                        .padding(16)
                        .frame(width: size.width, height: size.height)
                        .background(dark ? Color(white: 0.17) : Color(white: 0.93),
                                    in: RoundedRectangle(cornerRadius: 22, style: .continuous))
                        .environment(\.colorScheme, dark ? .dark : .light)
                    let r = ImageRenderer(content: view)
                    r.scale = 2
                    guard let img = r.nsImage, let tiff = img.tiffRepresentation,
                          let png = NSBitmapImageRep(data: tiff)?.representation(using: .png, properties: [:]) else { continue }
                    let file = "\(out)/\(name)-\(fam == .systemSmall ? "small" : "medium")-\(dark ? "dark" : "light").png"
                    try? png.write(to: URL(fileURLWithPath: file))
                }
            }
        }
        print("✓ previews → \(out)")
    }
}
