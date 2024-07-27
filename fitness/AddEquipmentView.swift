import SwiftUI

struct AddEquipmentView: View {
    @Binding var equipments: [Equipment]
    let muscles: [Muscle]
    @State private var name = ""
    @State private var selectedMuscle = ""
    @State private var selectedSubMuscle = ""
    @State private var image: UIImage?
    @State private var showingImagePicker = false
    @State private var showingSourceTypeMenu = false
    @State private var sourceType: UIImagePickerController.SourceType = .photoLibrary
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        NavigationView {
            Form {
                TextField("器材名稱", text: $name)
                Picker("主要部位", selection: $selectedMuscle) {
                    Text("選擇部位").tag("")
                    ForEach(muscles) { muscle in
                        Text(muscle.name).tag(muscle.name)
                    }
                }
                if let muscle = muscles.first(where: { $0.name == selectedMuscle }) {
                    Picker("細部位", selection: $selectedSubMuscle) {
                        Text("選擇細部位").tag("")
                        ForEach(muscle.subMuscles, id: \.self) { subMuscle in
                            Text(subMuscle).tag(subMuscle)
                        }
                    }
                }
                Section(header: Text("圖片")) {
                    if let image = image {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(height: 200)
                    }
                    Button(image == nil ? "上傳圖片" : "更改圖片") {
                        showingSourceTypeMenu = true
                    }
                }
            }
            .navigationBarTitle("新增器材", displayMode: .inline)
            .navigationBarItems(trailing: Button("儲存") {
                saveEquipment()
            })
            .actionSheet(isPresented: $showingSourceTypeMenu) {
                ActionSheet(title: Text("選擇圖片來源"), buttons: [
                    .default(Text("相冊")) {
                        self.sourceType = .photoLibrary
                        self.showingImagePicker = true
                    },
                    .default(Text("相機")) {
                        self.sourceType = .camera
                        self.showingImagePicker = true
                    },
                    .cancel()
                ])
            }
            .sheet(isPresented: $showingImagePicker) {
                ImagePicker(image: $image, sourceType: sourceType)
            }
        }
    }

    func saveEquipment() {
        let imageName = saveImage()
        let newEquipment = Equipment(id: UUID(), name: name, mainMuscle: selectedMuscle, subMuscle: selectedSubMuscle, imageName: imageName)
        equipments.append(newEquipment)
        presentationMode.wrappedValue.dismiss()
    }

    func saveImage() -> String? {
        guard let image = image else { return nil }
        let imageName = UUID().uuidString
        if let data = image.jpegData(compressionQuality: 0.8),
           let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            let fileURL = documentsDirectory.appendingPathComponent(imageName)
            try? data.write(to: fileURL)
            return imageName
        }
        return nil
    }
}
