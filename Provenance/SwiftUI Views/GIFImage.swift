import SwiftUI

#if os(iOS)
struct GIFImage: UIViewRepresentable {
    var image: UIImage
    
    func makeUIView(context: Self.Context) -> UIImageView {
        return UIImageView(image: image)
    }
    
    func updateUIView(_ uiView: UIImageView, context: UIViewRepresentableContext<GIFImage>) {
    }
}
#elseif os(macOS)
struct GIFImage: NSViewRepresentable {
    var image: NSImage
    
    func makeNSView(context: Self.Context) -> NSImageView {
        return NSImageView(image: image)
    }
    
    func updateNSView(_ nsView: NSImageView, context: NSViewRepresentableContext<GIFImage>) {
    }
}
#endif
