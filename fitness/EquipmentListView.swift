import SwiftUI

import SwiftUI

public struct EquipmentListView: View {
    @ObservedObject var dataManager: DataManager
    @State private var selectedImage: UIImage?
    @State private var isShowingEnlargedImage = false
    @State private var editingEquipment: Equipment?
    
    public var body: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.flexible())], spacing: 20) {
                ForEach(dataManager.equipments) { equipment in
                    EquipmentCard(equipment: equipment)
                        .onTapGesture {
                            if let imageName = equipment.imageName,
                               let uiImage = loadImage(named: imageName) {
                                self.selectedImage = uiImage
                                self.isShowingEnlargedImage = true
                            }
                        }
                        .contextMenu {
                            Button(action: {
                                editingEquipment = equipment
                            }) {
                                Text("編輯")
                                Image(systemName: "pencil")
                            }
                            
                            Button(action: {
                                deleteEquipment(equipment)
                            }) {
                                Text("刪除")
                                Image(systemName: "trash")
                            }
                        }
                }
            }
            .padding()
        }
        .refreshable {
            await refreshData()
        }
        .sheet(isPresented: $isShowingEnlargedImage) {
            if let image = selectedImage {
                EnlargedImageView(image: image)
            }
        }
        .sheet(item: $editingEquipment) { equipment in
            NavigationView {
                EditEquipmentView(dataManager: dataManager, equipment: equipment)
            }
        }
    }
    
    private func deleteEquipment(_ equipment: Equipment) {
        dataManager.deleteEquipment(equipment)
    }
    
    private func loadImage(named: String) -> UIImage? {
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
        guard let filePath = documentsDirectory?.appendingPathComponent(named).path else {
            return nil
        }
        return UIImage(contentsOfFile: filePath)
    }
    
    private func refreshData() async {
        await dataManager.reloadEquipments()
    }
}
struct EquipmentCard: View {
    let equipment: Equipment
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            if let imageName = equipment.imageName, let uiImage = loadImage(named: imageName) {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(height: 200)
                    .clipped()
                    .cornerRadius(10)
            } else {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(height: 200)
                    .cornerRadius(10)
                    .overlay(
                        Image(systemName: "photo")
                            .foregroundColor(.gray)
                            .font(.largeTitle)
                    )
            }
            
            HStack {
                Text(equipment.name)
                    .font(.headline)
                Spacer()
                Text(equipment.mainMuscle)
                    .font(.subheadline)
                    .padding(5)
                    .background(colorForMuscle(equipment.mainMuscle))
                    .cornerRadius(5)
                Text(equipment.subMuscle)
                    .font(.subheadline)
                    .padding(5)
                    .background(colorForMuscle(equipment.mainMuscle).opacity(0.5))
                    .cornerRadius(5)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(15)
        .shadow(color: Color.gray.opacity(0.3), radius: 5, x: 0, y: 2)
    }
    
    private func loadImage(named: String) -> UIImage? {
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
        guard let filePath = documentsDirectory?.appendingPathComponent(named).path else {
            return nil
        }
        return UIImage(contentsOfFile: filePath)
    }
    
    private func colorForMuscle(_ muscle: String) -> Color {
        switch muscle {
        case "胸": return .red
        case "背": return .blue
        case "腿": return .green
        case "肩": return .orange
        case "手臂": return .purple
        default: return .gray
        }
    }
}