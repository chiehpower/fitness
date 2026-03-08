import SwiftUI

struct EquipmentListView: View {
    @ObservedObject var dataManager: DataManager
    @State private var selectedImage: SelectedImage?
    @State private var editingEquipment: Equipment?
    @State private var showingAddEquipment = false
    @State private var showingManageMuscles = false
    @State private var showingManageSubMuscles = false
    @State private var showingManageLocations = false
    @State private var showingManageVariants = false
    @State private var imageLoadStates: [UUID: ImageLoadState] = [:]
    @State private var showNoImageAlert = false
    @State private var searchText = ""
    @State private var quickName = ""
    @State private var quickMainPart = "全身"
    @State private var quickTagInput = ""
    @State private var quickTags: [String] = []
    @State private var quickActionInput = ""
    @State private var quickActions: [String] = []
    @State private var showQuickAddAlert = false
    @State private var quickAddMessage = ""
    
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            ScrollView {
                VStack(spacing: 16) {
                    headerView

                    VStack(spacing: 16) {
                        ForEach(filteredEquipments) { equipment in
                            EquipmentCard(
                                equipment: equipment,
                                imageLoadState: loadState(for: equipment),
                                muscleTags: equipmentMuscleTags(for: equipment),
                                variants: equipmentVariants(for: equipment),
                                onShowDetails: {
                                    editingEquipment = equipment
                                }
                            )
                            .onAppear {
                                loadImage(for: equipment, isFullSize: false)
                            }
                            .onTapGesture {
                                if let imageName = equipment.imageName {
                                    self.selectedImage = SelectedImage(fileName: imageName)
                                } else {
                                    showNoImageAlert = true
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
                    .padding(.horizontal, 16)

                    addEquipmentCard
                        .padding(.horizontal, 16)
                        .padding(.bottom, 80)
                }
            }
            .background(Color(UIColor.systemGroupedBackground))
            .refreshable {
                await refreshData()
            }

            Button(action: {
                showingAddEquipment = true
            }) {
                Image(systemName: "plus")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: 56, height: 56)
                    .background(Color.customAccent)
                    .clipShape(Circle())
                    .shadow(color: Color.customAccent.opacity(0.2), radius: 8, x: 0, y: 4)
            }
            .padding(.trailing, 20)
            .padding(.bottom, 24)
        }
        .sheet(item: $selectedImage) { image in
            EnlargedImageView(imageName: image.fileName)
        }
        .sheet(item: $editingEquipment) { equipment in
            NavigationView {
                EditEquipmentView(dataManager: dataManager, equipment: equipment)
            }
        }
        .sheet(isPresented: $showingAddEquipment) {
            AddEquipmentView(dataManager: dataManager)
        }
        .alert(isPresented: $showNoImageAlert) {
            Alert(title: Text("無圖片"), message: Text("此器材尚未上傳圖片"), dismissButton: .default(Text("確定")))
        }
        .alert(isPresented: $showQuickAddAlert) {
            Alert(title: Text("提示"), message: Text(quickAddMessage), dismissButton: .default(Text("確定")))
        }
    }

    private var headerView: some View {
        HStack {
            HStack(spacing: 8) {
                Image(systemName: "figure.strengthtraining.traditional")
                    .foregroundColor(.customAccent)
                Text("健身器材")
                    .font(.headline)
            }
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
        .padding(.bottom, 8)
    }

    private var addEquipmentCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 8) {
                Image(systemName: "plus.circle.fill")
                    .foregroundColor(.customAccent)
                Text("新增器材")
                    .font(.headline)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("器材名稱")
                    .font(.subheadline.bold())
                TextField("例如：龍門架", text: $quickName)
                    .textFieldStyle(.plain)
                    .padding(.vertical, 12)
                    .padding(.horizontal, 14)
                    .background(Color(UIColor.systemGray6))
                    .cornerRadius(14)
            }

            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("主要訓練部位")
                        .font(.subheadline.bold())
                    Picker("主要訓練部位", selection: $quickMainPart) {
                        ForEach(["全身", "上肢", "下肢", "核心"], id: \.self) { part in
                            Text(part).tag(part)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    .padding(.vertical, 10)
                    .padding(.horizontal, 14)
                    .background(Color(UIColor.systemGray6))
                    .cornerRadius(14)
                }
                VStack(alignment: .leading, spacing: 8) {
                    Text("圖片上傳")
                        .font(.subheadline.bold())
                    Button(action: { showingAddEquipment = true }) {
                        Image(systemName: "camera")
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity)
                            .frame(height: 42)
                            .background(Color(UIColor.systemGray6))
                            .cornerRadius(14)
                    }
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("涉及肌群（標籤）")
                    .font(.subheadline.bold())
                HStack {
                    TextField("輸入肌群", text: $quickTagInput)
                        .textFieldStyle(.plain)
                    Button(action: {
                        let trimmed = quickTagInput.trimmingCharacters(in: .whitespacesAndNewlines)
                        guard !trimmed.isEmpty else { return }
                        quickTags.append(trimmed)
                        quickTagInput = ""
                    }) {
                        Text("+ 新增")
                            .font(.caption.bold())
                            .foregroundColor(.customAccent)
                    }
                }
                .padding(.vertical, 10)
                .padding(.horizontal, 12)
                .background(Color(UIColor.systemGray6))
                .cornerRadius(14)

                if !quickTags.isEmpty {
                    WrapLayout(spacing: 8, lineSpacing: 8) {
                        ForEach(quickTags, id: \.self) { tag in
                            HStack(spacing: 4) {
                                Text(tag)
                                    .font(.caption)
                                Image(systemName: "xmark")
                                    .font(.caption2)
                            }
                            .padding(.vertical, 6)
                            .padding(.horizontal, 8)
                            .background(Color(UIColor.systemGray5))
                            .cornerRadius(8)
                            .onTapGesture {
                                quickTags.removeAll { $0 == tag }
                            }
                        }
                    }
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("動作列表")
                    .font(.subheadline.bold())
                HStack(spacing: 8) {
                    TextField("輸入動作名稱", text: $quickActionInput)
                        .textFieldStyle(.plain)
                        .padding(.vertical, 12)
                        .padding(.horizontal, 14)
                        .background(Color(UIColor.systemGray6))
                        .cornerRadius(14)
                    Button(action: {
                        let trimmed = quickActionInput.trimmingCharacters(in: .whitespacesAndNewlines)
                        guard !trimmed.isEmpty else { return }
                        quickActions.append(trimmed)
                        quickActionInput = ""
                    }) {
                        Image(systemName: "plus")
                            .foregroundColor(.white)
                            .frame(width: 44, height: 44)
                            .background(Color.customAccent)
                            .cornerRadius(12)
                    }
                }

                if !quickActions.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        ForEach(quickActions, id: \.self) { action in
                            HStack {
                                Text(action)
                                    .font(.footnote)
                                    .foregroundColor(.secondary)
                                Spacer()
                                Image(systemName: "trash")
                                    .foregroundColor(.red)
                                    .onTapGesture {
                                        quickActions.removeAll { $0 == action }
                                    }
                            }
                        }
                    }
                }
            }

            Button(action: {
                let trimmed = quickName.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !trimmed.isEmpty else {
                    quickAddMessage = "請輸入器材名稱"
                    showQuickAddAlert = true
                    return
                }
                let location = dataManager.locations.first ?? "未設定"
                let newEquipment = Equipment(
                    id: UUID(),
                    name: trimmed,
                    imageName: nil,
                    nfcTagId: nil,
                    location: location,
                    pr: nil
                )
                dataManager.addEquipment(newEquipment)
                quickName = ""
                quickMainPart = "全身"
                quickTagInput = ""
                quickTags = []
                quickActionInput = ""
                quickActions = []
            }) {
                Text("儲存並建立")
                    .font(.headline.bold())
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.customAccent)
                    .foregroundColor(.white)
                    .cornerRadius(18)
            }
        }
        .padding(20)
        .background(Color.white)
        .cornerRadius(22)
        .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 3)
    }

    private var filteredEquipments: [Equipment] {
        if searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return dataManager.equipments
        }
        let keyword = searchText.lowercased()
        return dataManager.equipments.filter { $0.name.lowercased().contains(keyword) }
    }

    private func equipmentMuscleTags(for equipment: Equipment) -> [String] {
        let tags = dataManager.trainingLogs.flatMap { $0.sets }
            .filter { $0.equipment.id == equipment.id }
            .map { $0.mainMuscle }
        return Array(NSOrderedSet(array: tags)).compactMap { $0 as? String }
    }

    private func equipmentVariants(for equipment: Equipment) -> [String] {
        let tags = dataManager.trainingLogs.flatMap { $0.sets }
            .filter { $0.equipment.id == equipment.id }
            .compactMap { $0.variant }
        return Array(NSOrderedSet(array: tags)).compactMap { $0 as? String }
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

struct SelectedImage: Identifiable {
    let id = UUID()
    let fileName: String
}

enum ImageLoadState {
    case loading
    case loaded(UIImage)
    case failed
}

struct EquipmentCard: View {
    let equipment: Equipment
    let imageLoadState: ImageLoadState
    let muscleTags: [String]
    let variants: [String]
    let onShowDetails: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            thumbnailView
                .frame(height: 240)
                .frame(maxWidth: .infinity)
                .background(Color(UIColor.systemGray6))
                .clipped()

            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text(equipment.name)
                        .font(.headline)
                    Spacer()
                    tagView(text: primaryCategoryText())
                }

                HStack(spacing: 6) {
                    Image(systemName: "person.2")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                    Text(muscleTags.isEmpty ? "肌群: 尚無紀錄" : "肌群: \(muscleTags.prefix(3).joined(separator: "、"))")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }

                HStack(alignment: .top, spacing: 6) {
                    Image(systemName: "figure.strengthtraining.traditional")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                    Text(variants.isEmpty ? "動作: 尚無紀錄" : "動作: \(variants.prefix(3).joined(separator: "、"))")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }

                HStack(spacing: 12) {
                    Button(action: onShowDetails) {
                        Text("查看詳情")
                            .font(.subheadline.bold())
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(Color.customAccent.opacity(0.06))
                            .foregroundColor(.customAccent)
                            .cornerRadius(12)
                    }
                    Button(action: onShowDetails) {
                        Image(systemName: "pencil")
                            .foregroundColor(.secondary)
                            .frame(width: 44, height: 40)
                            .background(Color(UIColor.systemGray6))
                            .cornerRadius(12)
                    }
                }
                .padding(.top, 4)
            }
            .padding(16)
        }
        .background(Color.white)
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 3)
    }

    private var thumbnailView: some View {
        Group {
            switch imageLoadState {
            case .loading:
                ProgressView()
            case .loaded(let image):
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            case .failed:
                Image(systemName: "photo")
                    .resizable()
                    .scaledToFit()
                    .padding(12)
                    .foregroundColor(.secondary)
            }
        }
        .background(Color(UIColor.systemGray6))
        .clipped()
    }

    private func tagView(text: String) -> some View {
        Text(text)
            .font(.caption2.bold())
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.customAccent.opacity(0.08))
            .foregroundColor(.customAccent)
            .cornerRadius(999)
    }

    private func primaryCategoryText() -> String {
        if let first = muscleTags.first {
            return first
        }
        return "未分類"
    }
}

struct WrapLayout<Content: View>: View {
    let spacing: CGFloat
    let lineSpacing: CGFloat
    let content: Content

    init(spacing: CGFloat = 8, lineSpacing: CGFloat = 8, @ViewBuilder content: () -> Content) {
        self.spacing = spacing
        self.lineSpacing = lineSpacing
        self.content = content()
    }

    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 60), spacing: spacing)], spacing: lineSpacing) {
            content
        }
    }
}

struct ManageLocationsView: View {
    @ObservedObject var dataManager: DataManager
    @State private var newLocationName = ""

    var body: some View {
        List {
            Section(header: Text("新增地點")) {
                TextField("地點名稱", text: $newLocationName)
                Button("新增") {
                    let trimmed = newLocationName.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !trimmed.isEmpty else {
                        return
                    }
                    dataManager.addLocation(trimmed)
                    newLocationName = ""
                }
            }

            Section(header: Text("現有地點")) {
                ForEach(dataManager.locations, id: \.self) { location in
                    Text(location)
                }
                .onDelete(perform: deleteLocations)
            }
        }
        .navigationBarTitle("管理地點", displayMode: .inline)
        .navigationBarItems(trailing: EditButton())
    }

    private func deleteLocations(at offsets: IndexSet) {
        offsets.sorted(by: >).forEach { index in
            dataManager.deleteLocation(at: index)
        }
    }
}
