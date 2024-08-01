import SwiftUI

struct EquipmentListView: View {
    @ObservedObject var dataManager: DataManager
    @State private var selectedImage: UIImage?
    @State private var isShowingEnlargedImage = false
    @State private var editingEquipment: Equipment?
    @State private var showingAddEquipment = false
    @State private var showingManageMuscles = false
    @State private var showingManageSubMuscles = false
    @State private var showingManageLocations = false
    
    var body: some View {
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
        .navigationTitle("健身器材")
        .navigationBarItems(trailing: Menu {
            Button("新增器材") {
                showingAddEquipment = true
            }
            Button("管理部位") {
                showingManageMuscles = true
            }
            Button("管理細部位") {
                showingManageSubMuscles = true
            }
            Button("管理地點") {
                showingManageLocations = true
            }
        } label: {
            Image(systemName: "ellipsis.circle")
        })
        .sheet(isPresented: $showingAddEquipment) {
            AddEquipmentView(dataManager: dataManager)
        }
        .sheet(isPresented: $showingManageMuscles) {
            ManageMusclesView(muscles: $dataManager.muscles)
        }
        .sheet(isPresented: $showingManageSubMuscles) {
            ManageSubMusclesView(muscles: $dataManager.muscles)
        }
        .sheet(isPresented: $showingManageLocations) {
            NavigationView {
                ManageLocationsView(dataManager: dataManager)
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
        // 使用 dataManager 的實例方法來重新加載數據
        dataManager.loadEquipments()
    }
}
import SwiftUI

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
            
            Text("位置: \(equipment.location)")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            if let pr = equipment.pr {
                Text("個人記錄: \(String(format: "%.1f", pr)) kg")
                    .font(.subheadline)
                    .foregroundColor(.green)
            } else {
                Text("尚無個人記錄")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
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