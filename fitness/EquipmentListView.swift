import SwiftUI

struct EquipmentListView: View {
    @ObservedObject var dataManager: DataManager
    @State private var selectedImage: SelectedImage?
    @State private var editingEquipment: Equipment?
    @State private var showingAddEquipment = false
    @State private var showingManageLocations = false
    @State private var showingManageVariants = false
    @State private var imageLoadStates: [UUID: ImageLoadState] = [:]
    @State private var showNoImageAlert = false
    @State private var searchText = ""
    @State private var quickName = ""
    @State private var quickMainPart = "全身"
    @State private var quickLocation = ""
    @State private var quickTagInput = ""
    @State private var quickTags: [String] = []
    @State private var quickActionInput = ""
    @State private var quickActions: [String] = []
    @State private var quickImage: UIImage?
    @State private var showingQuickImagePicker = false
    @State private var showingQuickImageSourceMenu = false
    @State private var showingQuickImagePreview = false
    @State private var quickImageSourceType: UIImagePickerController.SourceType = .photoLibrary
    @State private var showCameraUnavailableAlert = false
    @State private var showQuickAddAlert = false
    @State private var quickAddMessage = ""
    
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            NavigationLink(isActive: $showingAddEquipment) {
                QuickAddEquipmentView(
                    isPresented: $showingAddEquipment,
                    quickName: $quickName,
                    quickMainPart: $quickMainPart,
                    quickLocation: $quickLocation,
                    quickTagInput: $quickTagInput,
                    quickTags: $quickTags,
                    quickActionInput: $quickActionInput,
                    quickActions: $quickActions,
                    quickImage: $quickImage,
                    showingQuickImagePicker: $showingQuickImagePicker,
                    showingQuickImageSourceMenu: $showingQuickImageSourceMenu,
                    showingQuickImagePreview: $showingQuickImagePreview,
                    quickImageSourceType: $quickImageSourceType,
                    showCameraUnavailableAlert: $showCameraUnavailableAlert,
                    onSave: saveQuickEquipment
                )
            } label: {
                EmptyView()
            }

            ScrollView {
                VStack(spacing: 16) {
                    VStack(spacing: 16) {
                        ForEach(filteredEquipments) { equipment in
                            EquipmentCard(
                                equipment: equipment,
                                imageLoadState: loadState(for: equipment),
                                muscleTags: equipmentMuscleTags(for: equipment),
                                variants: equipmentVariants(for: equipment),
                                onShowDetails: {
                                    editingEquipment = equipment
                                },
                                onShowImage: {
                                    if let imageName = equipment.imageName {
                                        self.selectedImage = SelectedImage(fileName: imageName)
                                    } else {
                                        showNoImageAlert = true
                                    }
                                }
                            )
                            .onAppear {
                                loadImage(for: equipment, isFullSize: false)
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

                }
            }
            .background(Color(UIColor.systemGroupedBackground))
            .navigationTitle("健身器材")
            .navigationBarTitleDisplayMode(.large)
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
        .alert(isPresented: $showNoImageAlert) {
            Alert(title: Text("無圖片"), message: Text("此器材尚未上傳圖片"), dismissButton: .default(Text("確定")))
        }
        .alert(isPresented: $showQuickAddAlert) {
            Alert(title: Text("提示"), message: Text(quickAddMessage), dismissButton: .default(Text("確定")))
        }
    }

    private func saveQuickEquipment() {
        let trimmed = quickName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            quickAddMessage = "請輸入器材名稱"
            showQuickAddAlert = true
            return
        }
        let trimmedLocation = quickLocation.trimmingCharacters(in: .whitespacesAndNewlines)
        let locationValue = trimmedLocation.isEmpty ? nil : trimmedLocation
        if let locationValue = locationValue, !dataManager.locations.contains(locationValue) {
            dataManager.addLocation(locationValue)
        }
        let imageName = quickImage.flatMap { saveImage($0) }
        let newEquipment = Equipment(
            id: UUID(),
            name: trimmed,
            imageName: imageName,
            nfcTagId: nil,
            location: locationValue,
            pr: nil,
            mainPart: quickMainPart,
            muscleTags: quickTags,
            actions: quickActions
        )
        dataManager.addEquipment(newEquipment)
        quickName = ""
        quickMainPart = "全身"
        quickLocation = ""
        quickTagInput = ""
        quickTags = []
        quickActionInput = ""
        quickActions = []
        quickImage = nil
        showingAddEquipment = false
    }

    private var filteredEquipments: [Equipment] {
        if searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return dataManager.equipments
        }
        let keyword = searchText.lowercased()
        return dataManager.equipments.filter { $0.name.lowercased().contains(keyword) }
    }

    private func equipmentMuscleTags(for equipment: Equipment) -> [String] {
        if !equipment.muscleTags.isEmpty {
            return equipment.muscleTags
        }
        let tags = dataManager.trainingLogs.flatMap { $0.sets }
            .filter { $0.equipment.id == equipment.id }
            .map { $0.mainMuscle }
        return Array(NSOrderedSet(array: tags)).compactMap { $0 as? String }
    }

    private func equipmentVariants(for equipment: Equipment) -> [String] {
        if !equipment.actions.isEmpty {
            return equipment.actions
        }
        let tags = dataManager.trainingLogs.flatMap { $0.sets }
            .filter { $0.equipment.id == equipment.id }
            .compactMap { $0.variant }
        return Array(NSOrderedSet(array: tags)).compactMap { $0 as? String }
    }

    private func loadState(for equipment: Equipment) -> ImageLoadState {
        imageLoadStates[equipment.id] ?? .loading
    }

    private func saveImage(_ image: UIImage) -> String? {
        let imageName = UUID().uuidString + ".jpg"
        guard let data = image.jpegData(compressionQuality: 0.8),
              let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return nil
        }
        let fileURL = documentsDirectory.appendingPathComponent(imageName)
        do {
            try data.write(to: fileURL)
            return imageName
        } catch {
            print("Error saving image: \(error)")
            return nil
        }
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

private struct QuickAddEquipmentView: View {
    @Binding var isPresented: Bool
    @Binding var quickName: String
    @Binding var quickMainPart: String
    @Binding var quickLocation: String
    @Binding var quickTagInput: String
    @Binding var quickTags: [String]
    @Binding var quickActionInput: String
    @Binding var quickActions: [String]
    @Binding var quickImage: UIImage?
    @Binding var showingQuickImagePicker: Bool
    @Binding var showingQuickImageSourceMenu: Bool
    @Binding var showingQuickImagePreview: Bool
    @Binding var quickImageSourceType: UIImagePickerController.SourceType
    @Binding var showCameraUnavailableAlert: Bool
    let onSave: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                sectionHeader("基本資訊")

                VStack(spacing: 0) {
                    formRow(title: "器材名稱") {
                        TextField("例如：啞鈴、臥推架", text: $quickName)
                            .textFieldStyle(.plain)
                    }

                    Divider().padding(.leading, 16)

                    formRow(title: "位置 (選填)") {
                        TextField("例如：二樓自由重量區", text: $quickLocation)
                            .textFieldStyle(.plain)
                    }
                }
                .background(cardBackground)
                .cornerRadius(16)

                sectionHeader("器材照片")

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    imageTile(title: "新增主圖", systemImage: "camera") {
                        showingQuickImageSourceMenu = true
                    }

                    if let image = quickImage {
                        previewTile(image: image)
                    } else {
                        emptyPreviewTile
                    }
                }

                sectionHeader("涉及肌群")

                VStack(alignment: .leading, spacing: 12) {
                    HStack(alignment: .top, spacing: 12) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("主要訓練部位")
                                .font(.caption.bold())
                                .foregroundColor(.secondary)
                            Picker("主要訓練部位", selection: $quickMainPart) {
                                ForEach(["全身", "上肢", "下肢", "核心"], id: \.self) { part in
                                    Text(part).tag(part)
                                }
                            }
                            .pickerStyle(MenuPickerStyle())
                            .padding(.vertical, 10)
                            .padding(.horizontal, 12)
                            .background(Color(UIColor.systemGray6))
                            .cornerRadius(12)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)

                        VStack(alignment: .leading, spacing: 6) {
                            Text("新增標籤")
                                .font(.caption.bold())
                                .foregroundColor(.secondary)
                            HStack {
                                TextField("輸入肌群", text: $quickTagInput)
                                    .textFieldStyle(.plain)
                                Button(action: {
                                    let trimmed = quickTagInput.trimmingCharacters(in: .whitespacesAndNewlines)
                                    guard !trimmed.isEmpty else { return }
                                    quickTags.append(trimmed)
                                    quickTagInput = ""
                                }) {
                                    Image(systemName: "plus")
                                        .font(.caption.bold())
                                        .foregroundColor(.customAccent)
                                }
                            }
                            .padding(.vertical, 10)
                            .padding(.horizontal, 12)
                            .background(Color(UIColor.systemGray6))
                            .cornerRadius(12)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    if quickTags.isEmpty {
                        Text("尚未新增標籤")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else {
                        WrapLayout(spacing: 8, lineSpacing: 8) {
                            ForEach(quickTags, id: \.self) { tag in
                                HStack(spacing: 6) {
                                    Text(tag)
                                        .font(.caption)
                                    Image(systemName: "xmark")
                                        .font(.caption2)
                                }
                                .padding(.vertical, 8)
                                .padding(.horizontal, 12)
                                .background(Color.customAccent.opacity(0.12))
                                .foregroundColor(.customAccent)
                                .cornerRadius(999)
                                .onTapGesture {
                                    quickTags.removeAll { $0 == tag }
                                }
                            }
                        }
                    }
                }

                sectionHeader("動作姿勢列表")

                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 8) {
                        TextField("輸入動作名稱", text: $quickActionInput)
                            .textFieldStyle(.plain)
                            .padding(.vertical, 12)
                            .padding(.horizontal, 14)
                            .background(Color(UIColor.systemGray6))
                            .cornerRadius(12)
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
                        VStack(spacing: 10) {
                            ForEach(quickActions, id: \.self) { action in
                                HStack {
                                    Text(action)
                                        .font(.subheadline.bold())
                                    Spacer()
                                    Button(role: .destructive) {
                                        quickActions.removeAll { $0 == action }
                                    } label: {
                                        Image(systemName: "trash")
                                    }
                                    .foregroundColor(.red)
                                }
                                .padding(12)
                                .background(cardBackground)
                                .cornerRadius(12)
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 32)
        }
        .background(Color(UIColor.systemGroupedBackground))
        .navigationTitle("新增器材")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("取消") {
                    isPresented = false
                }
                .foregroundColor(.customAccent)
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("儲存") {
                    onSave()
                }
                .foregroundColor(.customAccent)
                .font(.body.bold())
            }
        }
        .safeAreaInset(edge: .bottom) {
            Button(action: onSave) {
                Text("完成並新增器材")
                    .font(.headline.bold())
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.customAccent)
                    .foregroundColor(.white)
                    .cornerRadius(16)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 12)
            .background(Color(UIColor.systemGroupedBackground).opacity(0.95))
        }
        .sheet(isPresented: $showingQuickImagePicker) {
            ImagePicker(image: $quickImage, sourceType: quickImageSourceType)
        }
        .sheet(isPresented: $showingQuickImagePreview) {
            if let image = quickImage {
                QuickImagePreviewView(image: image)
            }
        }
        .sheet(isPresented: $showingQuickImageSourceMenu) {
            QuickImageSourceSheet(
                onSelectPhoto: {
                    quickImageSourceType = .photoLibrary
                    showingQuickImagePicker = true
                },
                onSelectCamera: {
                    if UIImagePickerController.isSourceTypeAvailable(.camera) {
                        quickImageSourceType = .camera
                        showingQuickImagePicker = true
                    } else {
                        showCameraUnavailableAlert = true
                    }
                }
            )
        }
        .alert("無法使用相機", isPresented: $showCameraUnavailableAlert) {
            Button("確定", role: .cancel) {}
        } message: {
            Text("此裝置或模擬器不支援相機。")
        }
    }

    private var cardBackground: Color {
        Color(UIColor.systemBackground)
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.caption.bold())
            .foregroundColor(.secondary)
            .textCase(.uppercase)
            .padding(.horizontal, 2)
    }

    private func formRow<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        HStack(alignment: .center) {
            Text(title)
                .font(.footnote)
                .foregroundColor(.secondary)
            Spacer()
            content()
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 16)
    }

    private func imageTile(title: String, systemImage: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: systemImage)
                    .font(.system(size: 28, weight: .semibold))
                Text(title)
                    .font(.caption)
            }
            .foregroundColor(.secondary)
            .frame(maxWidth: .infinity)
            .frame(height: 180)
            .background(Color(UIColor.systemGray6))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.gray.opacity(0.3), style: StrokeStyle(lineWidth: 1, dash: [6]))
            )
            .cornerRadius(16)
        }
    }

    private func previewTile(image: UIImage) -> some View {
        ZStack(alignment: .topTrailing) {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(maxWidth: .infinity)
                .frame(height: 180)
                .clipped()
                .cornerRadius(16)
                .onTapGesture {
                    showingQuickImagePreview = true
                }

            Button(action: { quickImage = nil }) {
                Image(systemName: "xmark")
                    .font(.caption.bold())
                    .foregroundColor(.white)
                    .padding(8)
                    .background(Color.black.opacity(0.55))
                    .clipShape(Circle())
            }
            .padding(8)
        }
    }

    private var emptyPreviewTile: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(UIColor.systemGray6))
            Text("預覽效果")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(height: 180)
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

private struct QuickImagePreviewView: View {
    let image: UIImage
    @Environment(\.presentationMode) private var presentationMode

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Color.black.ignoresSafeArea()

            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .padding(16)

            Button(action: { presentationMode.wrappedValue.dismiss() }) {
                Image(systemName: "xmark")
                    .foregroundColor(.white)
                    .padding(10)
                    .background(Color.black.opacity(0.6))
                    .clipShape(Circle())
            }
            .padding(16)
        }
    }
}

private struct QuickImageSourceSheet: View {
    let onSelectPhoto: () -> Void
    let onSelectCamera: () -> Void
    @Environment(\.presentationMode) private var presentationMode

    var body: some View {
        NavigationView {
            List {
                Button("從相簿選擇") {
                    presentationMode.wrappedValue.dismiss()
                    onSelectPhoto()
                }
                Button("使用相機拍照") {
                    presentationMode.wrappedValue.dismiss()
                    onSelectCamera()
                }
            }
            .navigationTitle("選擇圖片來源")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
}

struct EquipmentCard: View {
    let equipment: Equipment
    let imageLoadState: ImageLoadState
    let muscleTags: [String]
    let variants: [String]
    let onShowDetails: () -> Void
    let onShowImage: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            Button(action: onShowImage) {
                thumbnailView
                    .frame(height: 240)
                    .frame(maxWidth: .infinity)
                    .background(Color(UIColor.systemGray6))
                    .clipped()
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text(equipment.name)
                        .font(.headline)
                    Spacer()
                    tagView(text: primaryCategoryText())
                }

                if let location = equipment.location, !location.isEmpty {
                    HStack(spacing: 6) {
                        Image(systemName: "mappin.and.ellipse")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                        Text("位置: \(location)")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                    }
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

                Button(action: onShowDetails) {
                    Text("查看詳情")
                        .font(.subheadline.bold())
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Color.customAccent.opacity(0.06))
                        .foregroundColor(.customAccent)
                        .cornerRadius(12)
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
        if !equipment.mainPart.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return equipment.mainPart
        }
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
