import SwiftUI

struct EditEquipmentView: View {
    @ObservedObject var dataManager: DataManager
    @State private var equipment: Equipment
    @State private var name: String
    @State private var location: String
    @State private var mainPart: String
    @State private var muscleTags: [String]
    @State private var muscleTagInput: String = ""
    @State private var actions: [String]
    @State private var actionInput: String = ""
    @State private var image: UIImage?
    @State private var showingImagePicker = false
    @State private var showingImageSourceMenu = false
    @State private var showingImagePreview = false
    @State private var sourceType: UIImagePickerController.SourceType = .photoLibrary
    @State private var showCameraUnavailableAlert = false
    @Environment(\.presentationMode) var presentationMode

    init(dataManager: DataManager, equipment: Equipment) {
        self._dataManager = ObservedObject(wrappedValue: dataManager)
        self._equipment = State(initialValue: equipment)
        _name = State(initialValue: equipment.name)
        _location = State(initialValue: equipment.location ?? "")
        _mainPart = State(initialValue: equipment.mainPart)
        _muscleTags = State(initialValue: equipment.muscleTags)
        _actions = State(initialValue: equipment.actions)
        if let imageName = equipment.imageName {
            _image = State(initialValue: loadImage(named: imageName))
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                sectionHeader("基本資訊")

                VStack(spacing: 0) {
                    formRow(title: "器材名稱") {
                        TextField("例如：啞鈴、臥推架", text: $name)
                            .textFieldStyle(.plain)
                    }

                    Divider().padding(.leading, 16)

                    formRow(title: "位置 (選填)") {
                        TextField("例如：二樓自由重量區", text: $location)
                            .textFieldStyle(.plain)
                    }
                }
                .background(cardBackground)
                .cornerRadius(16)

                sectionHeader("器材照片")

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    imageTile(title: image == nil ? "新增主圖" : "更換主圖", systemImage: "camera") {
                        showingImageSourceMenu = true
                    }

                    if let image = image {
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
                            Picker("主要訓練部位", selection: $mainPart) {
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
                                TextField("輸入肌群", text: $muscleTagInput)
                                    .textFieldStyle(.plain)
                                Button(action: addMuscleTag) {
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

                    if muscleTags.isEmpty {
                        Text("尚未新增標籤")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else {
                        WrapLayout(spacing: 8, lineSpacing: 8) {
                            ForEach(muscleTags, id: \.self) { tag in
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
                                    muscleTags.removeAll { $0 == tag }
                                }
                            }
                        }
                    }
                }

                sectionHeader("動作姿勢列表")

                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 8) {
                        TextField("輸入動作名稱", text: $actionInput)
                            .textFieldStyle(.plain)
                            .padding(.vertical, 12)
                            .padding(.horizontal, 14)
                            .background(Color(UIColor.systemGray6))
                            .cornerRadius(12)
                        Button(action: addAction) {
                            Image(systemName: "plus")
                                .foregroundColor(.white)
                                .frame(width: 44, height: 44)
                                .background(Color.customAccent)
                                .cornerRadius(12)
                        }
                    }

                    if !actions.isEmpty {
                        VStack(spacing: 10) {
                            ForEach(actions, id: \.self) { action in
                                HStack {
                                    Text(action)
                                        .font(.subheadline.bold())
                                    Spacer()
                                    Button(role: .destructive) {
                                        actions.removeAll { $0 == action }
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
        .navigationTitle("編輯器材")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("取消") {
                    presentationMode.wrappedValue.dismiss()
                }
                .foregroundColor(.customAccent)
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("儲存") {
                    saveEquipment()
                }
                .foregroundColor(.customAccent)
                .font(.body.bold())
            }
        }
        .safeAreaInset(edge: .bottom) {
            Button(action: saveEquipment) {
                Text("完成並儲存")
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
        .sheet(isPresented: $showingImagePicker) {
            ImagePicker(image: $image, sourceType: sourceType)
        }
        .sheet(isPresented: $showingImagePreview) {
            if let image = image {
                EditImagePreviewView(image: image)
            }
        }
        .sheet(isPresented: $showingImageSourceMenu) {
            EditImageSourceSheet(
                onSelectPhoto: {
                    sourceType = .photoLibrary
                    showingImagePicker = true
                },
                onSelectCamera: {
                    if UIImagePickerController.isSourceTypeAvailable(.camera) {
                        sourceType = .camera
                        showingImagePicker = true
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

    private func addMuscleTag() {
        let trimmed = muscleTagInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        muscleTags.append(trimmed)
        muscleTagInput = ""
    }

    private func addAction() {
        let trimmed = actionInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        actions.append(trimmed)
        actionInput = ""
    }

    private func saveEquipment() {
        var updatedEquipment = equipment
        updatedEquipment.name = name
        let trimmedLocation = location.trimmingCharacters(in: .whitespacesAndNewlines)
        updatedEquipment.location = trimmedLocation.isEmpty ? nil : trimmedLocation
        updatedEquipment.mainPart = mainPart
        updatedEquipment.muscleTags = muscleTags
        updatedEquipment.actions = actions

        if let locationValue = updatedEquipment.location,
           !locationValue.isEmpty,
           !dataManager.locations.contains(locationValue) {
            dataManager.addLocation(locationValue)
        }

        if let newImage = image {
            if newImage != loadImage(named: equipment.imageName ?? "") {
                if let imageName = saveImage(newImage) {
                    updatedEquipment.imageName = imageName
                }
            }
        } else {
            updatedEquipment.imageName = nil
        }

        dataManager.updateEquipment(updatedEquipment)
        presentationMode.wrappedValue.dismiss()
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

    private func loadImage(named: String) -> UIImage? {
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
        guard let filePath = documentsDirectory?.appendingPathComponent(named).path else {
            return nil
        }
        return UIImage(contentsOfFile: filePath)
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
                    showingImagePreview = true
                }

            Button(action: { self.image = nil }) {
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

private struct EditImagePreviewView: View {
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

private struct EditImageSourceSheet: View {
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
