import SwiftUI

struct EditEquipmentView: View {
    @ObservedObject var dataManager: DataManager
    @State private var equipment: Equipment
    @State private var name: String
    @State private var selectedMuscle: String
    @State private var selectedSubMuscle: String
    @State private var location: String  // 新增
    @State private var pr: Double?       // 新增
    @State private var image: UIImage?
    @State private var showingImagePicker = false
    @State private var showingSourceTypeMenu = false
    @State private var sourceType: UIImagePickerController.SourceType = .photoLibrary
    @Environment(\.presentationMode) var presentationMode

    init(dataManager: DataManager, equipment: Equipment) {
        self._dataManager = ObservedObject(wrappedValue: dataManager)
        self._equipment = State(initialValue: equipment)
        _name = State(initialValue: equipment.name)
        _selectedMuscle = State(initialValue: equipment.mainMuscle)
        _selectedSubMuscle = State(initialValue: equipment.subMuscle)
        _location = State(initialValue: equipment.location)  // 新增
        _pr = State(initialValue: equipment.pr)              // 新增
        if let imageName = equipment.imageName {
            _image = State(initialValue: loadImage(named: imageName))
        }
    }

    var body: some View {
        Form {
            TextField("器材名稱", text: $name)
            
            Picker("主要部位", selection: $selectedMuscle) {
                ForEach(dataManager.muscles) { muscle in
                    Text(muscle.name).tag(muscle.name)
                }
            }
            
            if let muscle = dataManager.muscles.first(where: { $0.name == selectedMuscle }) {
                Picker("細部位", selection: $selectedSubMuscle) {
                    ForEach(muscle.subMuscles, id: \.name) { subMuscle in
                        Text(subMuscle.name).tag(subMuscle.name)
                    }
                }
            }
            
            TextField("位置", text: $location)  // 新增
            
            HStack {  // 新增
                Text("個人記錄")
                Spacer()
                TextField("PR", value: $pr, format: .number)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
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
        .navigationTitle("編輯器材")
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

    private func saveEquipment() {
        var updatedEquipment = equipment
        updatedEquipment.name = name
        updatedEquipment.mainMuscle = selectedMuscle
        updatedEquipment.subMuscle = selectedSubMuscle
        updatedEquipment.location = location  // 新增
        updatedEquipment.pr = pr              // 新增
        
        if let newImage = image, newImage != loadImage(named: equipment.imageName ?? "") {
            if let imageName = saveImage(newImage) {
                updatedEquipment.imageName = imageName
            }
        }
        
        dataManager.updateEquipment(updatedEquipment)
        presentationMode.wrappedValue.dismiss()
    }

    private func saveImage(_ image: UIImage) -> String? {
        let imageName = UUID().uuidString
        if let data = image.jpegData(compressionQuality: 0.8),
           let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            let fileURL = documentsDirectory.appendingPathComponent(imageName)
            try? data.write(to: fileURL)
            return imageName
        }
        return nil
    }

    private func loadImage(named: String) -> UIImage? {
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
        guard let filePath = documentsDirectory?.appendingPathComponent(named).path else {
            return nil
        }
        return UIImage(contentsOfFile: filePath)
    }
}