// 新增器材視圖
struct AddEquipmentView: View {
    @Binding var equipments: [Equipment]
    let muscles: [Muscle]
    @State private var name = ""
    @State private var selectedMuscle = ""
    @State private var selectedSubMuscle = ""
    @State private var image: UIImage?
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            Form {
                TextField("器材名稱", text: $name)
                Picker("主要部位", selection: $selectedMuscle) {
                    ForEach(muscles) { muscle in
                        Text(muscle.name).tag(muscle.name)
                    }
                }
                if let muscle = muscles.first(where: { $0.name == selectedMuscle }) {
                    Picker("細部位", selection: $selectedSubMuscle) {
                        ForEach(muscle.subMuscles, id: \.self) { subMuscle in
                            Text(subMuscle).tag(subMuscle)
                        }
                    }
                }
                Button("上傳圖片") {
                    // 實現圖片上傳功能
                }
            }
            .navigationBarTitle("新增器材", displayMode: .inline)
            .navigationBarItems(trailing: Button("儲存") {
                let newEquipment = Equipment(name: name, mainMuscle: selectedMuscle, subMuscle: selectedSubMuscle, imageName: nil)
                equipments.append(newEquipment)
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
}
