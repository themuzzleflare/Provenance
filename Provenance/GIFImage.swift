import SwiftUI

struct GIFImage: UIViewRepresentable {
    var image: UIImage
    
    func makeUIView(context: Self.Context) -> UIImageView {
        return UIImageView(image: image)
    }
    
    func updateUIView(_ uiView: UIImageView, context: UIViewRepresentableContext<GIFImage>) {
    }
}
