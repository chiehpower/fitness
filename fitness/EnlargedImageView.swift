import SwiftUI

struct EnlargedImageView: View {
    let image: UIImage
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        VStack {
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .padding()
            
            Button("關閉") {
                presentationMode.wrappedValue.dismiss()
            }
            .padding()
        }
    }
}
