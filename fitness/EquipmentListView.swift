import SwiftUI

struct EquipmentListView: View {
    @ObservedObject var dataManager: DataManager
    @State private var selectedImageName: String?
    @State private var isShowingEnlargedImage = false
    @State private var editingEquipment: Equipment?
    @State private var showingAddEquipment = false
    @State private var showingManageMuscles = false
    @State private var showingManageSubMuscles = false
    @State private var showingManageLocations = false
    @State private var imageLoadStates: [UUID: ImageLoadState] = [:]
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.flexible())], spacing: 20) {
                ForEach(dataManager.equipments) { equipment in
                    EquipmentCard(equipment: equipment,
                                  imageLoadState: loadState(for: equipment),
                                  dataManager: dataManager)
                       .onAppear {
                           loadImage(for: equipment, isFullSize: false)
                       }
                       .onTapGesture {
                           self.selectedImageName = equipment.imageName
                           self.isShowingEnlargedImage = true
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
        .onAppear {
            print("EquipmentListView appeared. Total equipments: \(dataManager.equipments.count)")
        }
        .refreshable {
            await refreshData()
        }
        .sheet(isPresented: $isShowingEnlargedImage) {
                    if let imageName = selectedImageName {
                        EnlargedImageView(imageName: imageName)
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
            ManageMusclesView(dataManager: dataManager)
        }
        .sheet(isPresented: $showingManageSubMuscles) {
            ManageSubMusclesView(muscles: Binding(
                get: { self.dataManager.muscles },
                set: { newValue in
                    self.dataManager.muscles = newValue
                    self.dataManager.saveMuscles()
                }
            ))
        }
        .sheet(isPresented: $showingManageLocations) {
            NavigationView {
                ManageLocationsView(dataManager: dataManager)
            }
        }
    }

    private func loadState(for equipment: Equipment) -> ImageLoadState {
        imageLoadStates[equipment.id] ?? .loading
    }
    
    private func loadImage(for equipment: Equipment, isFullSize: Bool) {
        guard let imageName = equipment.imageName else {
            print("No image name for equipment: \(equipment.name)")
            imageLoadStates[equipment.id] = .failed
            return
        }
        
        if case .loaded = imageLoadStates[equipment.id] {
            return  // Image already loaded
        }
        
        imageLoadStates[equipment.id] = .loading
        
        DispatchQueue.global(qos: .userInitiated).async {
            let image = self.loadImageFromDisk(named: imageName, isFullSize: isFullSize)
            DispatchQueue.main.async {
                if let image = image {
                    self.imageLoadStates[equipment.id] = .loaded(image)
                    print("Successfully loaded \(isFullSize ? "full size" : "thumbnail") image for equipment: \(equipment.name)")
                } else {
                    print("Failed to load \(isFullSize ? "full size" : "thumbnail") image for equipment: \(equipment.name)")
                    self.imageLoadStates[equipment.id] = .failed
                }
            }
        }
    }
    
    private func loadImageFromDisk(named fileName: String, isFullSize: Bool) -> UIImage? {
        let fileManager = FileManager.default
        let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        let fileURL = documentsDirectory.appendingPathComponent(fileName)
        print("Attempting to load \(isFullSize ? "full size" : "thumbnail") image from: \(fileURL.path)")
        
        if fileManager.fileExists(atPath: fileURL.path) {
            if let imageData = try? Data(contentsOf: fileURL) {
                if let image = UIImage(data: imageData) {
                    print("Successfully loaded \(isFullSize ? "full size" : "thumbnail") image: \(fileName)")
                    if isFullSize {
                        return image
                    } else {
                        // 创建缩略图
                        let size = CGSize(width: 200, height: 200)
                        let renderer = UIGraphicsImageRenderer(size: size)
                        return renderer.image { (context) in
                            image.draw(in: CGRect(origin: .zero, size: size))
                        }
                    }
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
    private func deleteEquipment(_ equipment: Equipment) {
        dataManager.deleteEquipment(equipment)
        imageLoadStates.removeValue(forKey: equipment.id)
    }
    
    private func refreshData() async {
        dataManager.loadEquipments()
        for equipment in dataManager.equipments {
            loadImage(for: equipment, isFullSize: true)
        }
    }
}

enum ImageLoadState {
    case loading
    case loaded(UIImage)
    case failed
}

struct EquipmentCard: View {
    let equipment: Equipment
    let imageLoadState: ImageLoadState
    let dataManager: DataManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Group {
                switch imageLoadState {
                case .loading:
                    ProgressView()
                        .frame(height: 200)
                case .loaded(let image):
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(height: 200)
                        .clipped()
                case .failed:
                    Image(systemName: "photo")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(height: 200)
                        .foregroundColor(.gray)
                }
            }
            .frame(height: 200)
            .background(Color.gray.opacity(0.1))
            .cornerRadius(10)
            
            HStack {
                Text(equipment.name)
                    .font(.headline)
                Spacer()
                Text(equipment.mainMuscle)
                    .font(.subheadline)
                    .padding(5)
                    .background(colorForMuscle(equipment.mainMuscle).opacity(0.2))
                    .cornerRadius(5)
                Text(equipment.subMuscle)
                    .font(.subheadline)
                    .padding(5)
                    .background(colorForMuscle(equipment.subMuscle).opacity(0.2))
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
    
    private func colorForMuscle(_ muscleName: String) -> Color {
        if let muscle = dataManager.muscles.first(where: { $0.name == muscleName }) {
            return Color(hex: muscle.color) ?? .gray
        } else if let muscle = dataManager.muscles.first(where: { $0.subMuscles.contains(where: { $0.name == muscleName }) }),
                  let subMuscle = muscle.subMuscles.first(where: { $0.name == muscleName }) {
            return Color(hex: subMuscle.color) ?? .gray
        }
        return .gray
    }
}
