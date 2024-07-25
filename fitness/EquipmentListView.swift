// 器材列表視圖
struct EquipmentListView: View {
    @Binding var equipments: [Equipment]
    
    var body: some View {
        List {
            Section(header:
                        HStack {
                            Text("ID").frame(width: 50)
                            Text("名稱").frame(width: 80)
                            Text("部位").frame(width: 60)
                            Text("細部位").frame(width: 60)
                            Text("圖片")
                        }
            ) {
                ForEach(equipments) { equipment in
                    HStack {
                        Text(equipment.id.uuidString.prefix(8)).frame(width: 50)
                        Text(equipment.name).frame(width: 80)
                        Text(equipment.mainMuscle).frame(width: 60)
                        Text(equipment.subMuscle).frame(width: 60)
                        if let imageName = equipment.imageName, let uiImage = UIImage(named: imageName) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 50, height: 50)
                        } else {
                            Image(systemName: "photo")
                                .frame(width: 50, height: 50)
                        }
                    }
                }
                .onDelete(perform: deleteEquipment)
            }
        }
    }
    
    func deleteEquipment(at offsets: IndexSet) {
        equipments.remove(atOffsets: offsets)
    }
}
