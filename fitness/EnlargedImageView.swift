import SwiftUI


struct EnlargedImageView: View {
    let imageName: String
    @State private var image: UIImage?
    @State private var isLoading = true
    @State private var loadError = false
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        VStack {
            if isLoading {
                ProgressView()
            } else if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .padding()
            } else if loadError {
                Text("Failed to load image")
                    .foregroundColor(.red)
            }
            
            Button("關閉") {
                presentationMode.wrappedValue.dismiss()
            }
            .padding()
        }
        .onAppear {
            loadFullSizeImage()
        }
    }
    
    private func loadFullSizeImage() {
        isLoading = true
        loadError = false
        
        DispatchQueue.global(qos: .userInitiated).async {
            let loadedImage = self.loadImageFromDisk(named: imageName)
            DispatchQueue.main.async {
                self.image = loadedImage
                self.isLoading = false
                self.loadError = loadedImage == nil
            }
        }
    }
    
    private func loadImageFromDisk(named fileName: String) -> UIImage? {
        let fileManager = FileManager.default
        let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        let fileURL = documentsDirectory.appendingPathComponent(fileName)
        print("Attempting to load full size image from: \(fileURL.path)")
        
        if fileManager.fileExists(atPath: fileURL.path) {
            if let imageData = try? Data(contentsOf: fileURL) {
                if let image = UIImage(data: imageData) {
                    print("Successfully loaded full size image: \(fileName)")
                    return image
                } else {
                    print("File exists but couldn't be converted to UIImage: \(fileName)")
                }
            } else {
                print("Failed to read file data: \(fileName)")
            }
        } else {
            print("File does not exist: \(fileName)")
        }
        
        return nil
    }
}
