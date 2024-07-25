import SwiftUI

// 更新 Equipment 結構體
struct Equipment: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var mainMuscle: String
    var subMuscle: String
    var imageName: String?
    
    // 實現 Hashable 協議
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    // 實現 Equatable 協議（Hashable 需要）
    static func == (lhs: Equipment, rhs: Equipment) -> Bool {
        return lhs.id == rhs.id
    }
}

struct Muscle: Identifiable, Codable {
    let id: UUID
    var name: String
    var subMuscles: [String]
}

struct TrainingSet: Identifiable, Codable {
    let id: UUID
    var equipment: Equipment
    var reps: Int
    var weight: Double
}

struct TrainingLog: Identifiable, Codable {
    let id: UUID
    var date: Date
    var sets: [TrainingSet]
}

// 數據管理器
// 更新 DataManager
class DataManager: ObservableObject {
    @Published var muscles: [Muscle] {
        didSet { saveMuscles() }
    }
    @Published var equipments: [Equipment] {
        didSet { saveEquipments() }
    }
    @Published var trainingLogs: [TrainingLog] {
        didSet { saveTrainingLogs() }
    }
    
    init() {
        self.muscles = DataManager.loadMuscles()
        self.equipments = DataManager.loadEquipments()
        self.trainingLogs = DataManager.loadTrainingLogs()
    }
    
    func saveMuscles() {
        if let encoded = try? JSONEncoder().encode(muscles) {
            UserDefaults.standard.set(encoded, forKey: "muscles")
        }
    }
    
    func saveEquipments() {
        if let encoded = try? JSONEncoder().encode(equipments) {
            UserDefaults.standard.set(encoded, forKey: "equipments")
        }
    }
    
    static func loadMuscles() -> [Muscle] {
        if let musclesData = UserDefaults.standard.data(forKey: "muscles"),
           let decodedMuscles = try? JSONDecoder().decode([Muscle].self, from: musclesData) {
            return decodedMuscles
        }
        return [
            Muscle(id: UUID(), name: "胸", subMuscles: ["上胸", "中胸", "下胸"]),
            Muscle(id: UUID(), name: "背", subMuscles: ["上背", "下背"])
        ]
    }
    
    static func loadEquipments() -> [Equipment] {
        if let equipmentsData = UserDefaults.standard.data(forKey: "equipments"),
           let decodedEquipments = try? JSONDecoder().decode([Equipment].self, from: equipmentsData) {
            return decodedEquipments
        }
        return []
    }
    
    func saveTrainingLogs() {
        if let encoded = try? JSONEncoder().encode(trainingLogs) {
            UserDefaults.standard.set(encoded, forKey: "trainingLogs")
        }
    }
    
    static func loadTrainingLogs() -> [TrainingLog] {
        if let logsData = UserDefaults.standard.data(forKey: "trainingLogs"),
           let decodedLogs = try? JSONDecoder().decode([TrainingLog].self, from: logsData) {
            return decodedLogs
        }
        return []
    }
}


// 訓練記錄視圖
struct TrainingLogView: View {
    @ObservedObject var dataManager: DataManager
    @State private var selectedDate = Date()
    @State private var showingAddSet = false
    
    var body: some View {
        NavigationView {
            VStack {
                DatePicker("選擇日期", selection: $selectedDate, displayedComponents: .date)
                    .datePickerStyle(GraphicalDatePickerStyle())
                    .padding()
                
                List {
                    ForEach(dataManager.trainingLogs.filter { Calendar.current.isDate($0.date, inSameDayAs: selectedDate) }) { log in
                        ForEach(log.sets) { set in
                            HStack {
                                Text(set.equipment.name)
                                Spacer()
                                Text("\(set.reps) 次")
                                Text("\(set.weight, specifier: "%.1f") kg")
                            }
                        }
                    }
                }
                
                Button("新增訓練組") {
                    showingAddSet = true
                }
                .padding()
            }
            .navigationTitle("訓練記錄")
            .sheet(isPresented: $showingAddSet) {
                AddTrainingSetView(dataManager: dataManager, date: selectedDate)
            }
        }
    }
}

// 更新 AddTrainingSetView
struct AddTrainingSetView: View {
    @ObservedObject var dataManager: DataManager
    @State private var selectedEquipment: Equipment?
    @State private var reps = 1
    @State private var weight = 0.0
    @State private var time = Date()
    @State private var showAlert = false
    @State private var alertMessage = ""
    let date: Date
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            Form {
                DatePicker("時間", selection: $time, displayedComponents: .hourAndMinute)
                
                Picker("器材", selection: $selectedEquipment) {
                    Text("選擇器材").tag(nil as Equipment?)
                    ForEach(dataManager.equipments) { equipment in
                        Text(equipment.name).tag(equipment as Equipment?)
                    }
                }
                
                Stepper("重複次數: \(reps)", value: $reps, in: 1...100)
                
                HStack {
                    Text("重量")
                    TextField("公斤", value: $weight, format: .number)
                        .keyboardType(.decimalPad)
                }
            }
            .navigationTitle("新增訓練組")
            .navigationBarItems(trailing: Button("儲存") {
                if validateInput() {
                    saveTrainingSet()
                } else {
                    showAlert = true
                }
            })
            .alert(isPresented: $showAlert) {
                Alert(title: Text("錯誤"), message: Text(alertMessage), dismissButton: .default(Text("確定")))
            }
        }
    }
    
    private func validateInput() -> Bool {
        guard selectedEquipment != nil else {
            alertMessage = "請選擇一個器材"
            return false
        }
        
        guard weight > 0 else {
            alertMessage = "請輸入有效的重量"
            return false
        }
        
        return true
    }
    
    private func saveTrainingSet() {
        guard let equipment = selectedEquipment else { return }
        
        let newSet = TrainingSet(id: UUID(), equipment: equipment, reps: reps, weight: weight)
        
        if let index = dataManager.trainingLogs.firstIndex(where: { Calendar.current.isDate($0.date, inSameDayAs: date) }) {
            dataManager.trainingLogs[index].sets.append(newSet)
        } else {
            let newLog = TrainingLog(id: UUID(), date: date, sets: [newSet])
            dataManager.trainingLogs.append(newLog)
        }
        
        presentationMode.wrappedValue.dismiss()
    }

}

// 主視圖
struct ContentView: View {
    @StateObject private var dataManager = DataManager()
    @State private var selection = 0
    @State private var showingAddEquipment = false
    @State private var showingManageMuscles = false
    @State private var showingManageSubMuscles = false
    
    var body: some View {
        TabView(selection: $selection) {
            NavigationView {
                EquipmentListView(equipments: $dataManager.equipments)
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
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    })
            }
            .tabItem {
                Image(systemName: "dumbbell.fill")
                Text("器材")
            }
            .tag(0)
            
            TrainingLogView(dataManager: dataManager)
                .tabItem {
                    Image(systemName: "book.fill")
                    Text("紀錄")
                }
                .tag(1)
            
            Text("設定").tabItem {
                Image(systemName: "gearshape.fill")
                Text("設定")
            }.tag(2)
            
            Text("計時").tabItem {
                Image(systemName: "timer")
                Text("計時")
            }.tag(3)
        }
        .sheet(isPresented: $showingAddEquipment) {
            AddEquipmentView(equipments: $dataManager.equipments, muscles: dataManager.muscles)
        }
        .sheet(isPresented: $showingManageMuscles) {
            ManageMusclesView(muscles: $dataManager.muscles)
        }
        .sheet(isPresented: $showingManageSubMuscles) {
            ManageSubMusclesView(muscles: $dataManager.muscles)
        }
    }
}

// 器材列表視圖
struct EquipmentListView: View {
    @Binding var equipments: [Equipment]
    @State private var selectedImage: UIImage?
    @State private var isShowingEnlargedImage = false
    
    var body: some View {
        List {
            ForEach(equipments) { equipment in
                HStack {
                    if let imageName = equipment.imageName, let uiImage = loadImage(named: imageName) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 50, height: 50)
                            .cornerRadius(5)
                            .onTapGesture {
                                self.selectedImage = uiImage
                                self.isShowingEnlargedImage = true
                            }
                    } else {
                        Image(systemName: "photo")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 50, height: 50)
                            .foregroundColor(.gray)
                    }
                    
                    VStack(alignment: .leading) {
                        Text(equipment.name)
                            .font(.headline)
                        HStack {
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
                }
                .padding(.vertical, 5)
            }
            .onDelete(perform: deleteEquipment)
        }
        .sheet(isPresented: $isShowingEnlargedImage) {
            if let image = selectedImage {
                EnlargedImageView(image: image)
            }
        }
    }
    
    func deleteEquipment(at offsets: IndexSet) {
        equipments.remove(atOffsets: offsets)
    }
    
    func loadImage(named: String) -> UIImage? {
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
        guard let filePath = documentsDirectory?.appendingPathComponent(named).path else {
            return nil
        }
        return UIImage(contentsOfFile: filePath)
    }
    
    func colorForMuscle(_ muscle: String) -> Color {
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

struct EnlargedImageView: View {
    let image: UIImage
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        VStack {
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .padding()
            
            Button("關閉") {
                presentationMode.wrappedValue.dismiss()
            }
            .padding()
        }
    }
}

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

struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Environment(\.presentationMode) var presentationMode
    let sourceType: UIImagePickerController.SourceType

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = sourceType
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker

        init(_ parent: ImagePicker) {
            self.parent = parent
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let uiImage = info[.originalImage] as? UIImage {
                parent.image = uiImage
            }
            parent.presentationMode.wrappedValue.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}

// 管理部位視圖
struct ManageMusclesView: View {
    @Binding var muscles: [Muscle]
    @State private var newMuscleName = ""
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("新增部位")) {
                    HStack {
                        TextField("部位名稱", text: $newMuscleName)
                        Button("新增") {
                            if !newMuscleName.isEmpty {
                                muscles.append(Muscle(id: UUID(), name: newMuscleName, subMuscles: []))
                                newMuscleName = ""
                            }
                        }
                    }
                }
                
                Section(header: Text("現有部位")) {
                    ForEach(muscles) { muscle in
                        Text(muscle.name)
                    }
                    .onDelete(perform: deleteMuscle)
                }
            }
            .navigationBarTitle("管理部位", displayMode: .inline)
            .navigationBarItems(trailing: EditButton())
        }
    }
    
    func deleteMuscle(at offsets: IndexSet) {
        muscles.remove(atOffsets: offsets)
    }
}

// 管理細部位視圖
struct ManageSubMusclesView: View {
    @Binding var muscles: [Muscle]
    @State private var selectedMuscle = ""
    @State private var newSubMuscleName = ""
    
    var body: some View {
        NavigationView {
            Form {
                Picker("選擇部位", selection: $selectedMuscle) {
                    ForEach(muscles) { muscle in
                        Text(muscle.name).tag(muscle.name)
                    }
                }
                
                if let muscleIndex = muscles.firstIndex(where: { $0.name == selectedMuscle }) {
                    Section(header: Text("新增細部位")) {
                        HStack {
                            TextField("細部位名稱", text: $newSubMuscleName)
                            Button("新增") {
                                if !newSubMuscleName.isEmpty {
                                    muscles[muscleIndex].subMuscles.append(newSubMuscleName)
                                    newSubMuscleName = ""
                                }
                            }
                        }
                    }
                    
                    Section(header: Text("現有細部位")) {
                        ForEach(muscles[muscleIndex].subMuscles, id: \.self) { subMuscle in
                            Text(subMuscle)
                        }
                        .onDelete { indexSet in
                            muscles[muscleIndex].subMuscles.remove(atOffsets: indexSet)
                        }
                    }
                }
            }
            .navigationBarTitle("管理細部位", displayMode: .inline)
            .navigationBarItems(trailing: EditButton())
        }
    }
}

// 預覽
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
