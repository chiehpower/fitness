import SwiftUI
struct Equipment: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var mainMuscle: String
    var subMuscle: String
    var imageName: String?
    var location: String  // 新增
    var pr: Double?       // 新增

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
    var color: String
    var subMuscles: [SubMuscle]
}

struct SubMuscle: Codable, Hashable {
    var name: String
    var color: String
}

struct TrainingSet: Identifiable, Codable {
    let id: UUID
    var equipment: Equipment
    var sets: [SetInfo]
}

struct SetInfo: Codable {
    var reps: Int
    var weight: Double
    var weightUnit: String
    var time: Int
    var timeUnit: String
}

struct TrainingLog: Identifiable, Codable {
    let id: UUID
    var date: Date
    var sets: [TrainingSet]
}

// 數據管理器
class DataManager: ObservableObject {
    @Published var muscles: [Muscle] = []
    @Published var equipments: [Equipment] = []
    @Published var trainingLogs: [TrainingLog] = []
    @Published var preferredWeightUnit: WeightUnit = .kg
    @Published var locations: [String] = []

    init() {
        loadData()
    }

    func loadData() {
        loadMuscles()
        loadEquipments()
        loadTrainingLogs()
        loadPreferredWeightUnit()
        loadLocations()
    }

    // MARK: - Muscles

    func loadMuscles() {
        if let musclesData = UserDefaults.standard.data(forKey: "muscles"),
           let decodedMuscles = try? JSONDecoder().decode([Muscle].self, from: musclesData) {
            self.muscles = decodedMuscles
        }
    }

    func saveMuscles() {
        if let encoded = try? JSONEncoder().encode(muscles) {
            UserDefaults.standard.set(encoded, forKey: "muscles")
        }
    }

    func addMuscle(_ muscle: Muscle) {
        muscles.append(muscle)
        saveMuscles()
    }

    func updateMuscle(_ updatedMuscle: Muscle) {
        if let index = muscles.firstIndex(where: { $0.id == updatedMuscle.id }) {
            muscles[index] = updatedMuscle
            saveMuscles()
        }
    }

    func deleteMuscle(_ muscle: Muscle) {
        muscles.removeAll { $0.id == muscle.id }
        saveMuscles()
    }

    // MARK: - Equipments

    func loadEquipments() {
        if let equipmentsData = UserDefaults.standard.data(forKey: "equipments"),
           let decodedEquipments = try? JSONDecoder().decode([Equipment].self, from: equipmentsData) {
            self.equipments = decodedEquipments
        }
    }

    func saveEquipments() {
        if let encoded = try? JSONEncoder().encode(equipments) {
            UserDefaults.standard.set(encoded, forKey: "equipments")
        }
    }

    func addEquipment(_ equipment: Equipment) {
        equipments.append(equipment)
        saveEquipments()
    }

    func updateEquipment(_ updatedEquipment: Equipment) {
        if let index = equipments.firstIndex(where: { $0.id == updatedEquipment.id }) {
            equipments[index] = updatedEquipment
            saveEquipments()
        }
    }
    
    func deleteEquipment(_ equipment: Equipment) {
        equipments.removeAll { $0.id == equipment.id }
        saveEquipments()
    }

    // MARK: - Training Logs

    func loadTrainingLogs() {
    if let logsData = UserDefaults.standard.data(forKey: "trainingLogs"),
       let decodedLogs = try? JSONDecoder().decode([TrainingLog].self, from: logsData) {
        self.trainingLogs = decodedLogs
        print("加载了 \(trainingLogs.count) 条训练记录")
    } else {
        print("没有找到保存的训练记录或解码失败")
    }
    }

    func saveTrainingLogs() {
    if let encoded = try? JSONEncoder().encode(trainingLogs) {
        UserDefaults.standard.set(encoded, forKey: "trainingLogs")
        print("保存了 \(trainingLogs.count) 条训练记录")
    }
    }

    func addTrainingLog(_ log: TrainingLog) {
        trainingLogs.append(log)
        saveTrainingLogs()
    }

    func updateTrainingLog(_ updatedLog: TrainingLog) {
        if let index = trainingLogs.firstIndex(where: { $0.id == updatedLog.id }) {
            trainingLogs[index] = updatedLog
            saveTrainingLogs()
        }
    }

    func deleteTrainingLog(_ log: TrainingLog) {
        trainingLogs.removeAll { $0.id == log.id }
        saveTrainingLogs()
    }

    // MARK: - Preferred Weight Unit

    private func loadPreferredWeightUnit() {
        if let unitString = UserDefaults.standard.string(forKey: "preferredWeightUnit"),
           let unit = WeightUnit(rawValue: unitString) {
            preferredWeightUnit = unit
        }
    }

    func savePreferredWeightUnit() {
        UserDefaults.standard.set(preferredWeightUnit.rawValue, forKey: "preferredWeightUnit")
    }

    // MARK: - Locations

    func loadLocations() {
        if let locationsData = UserDefaults.standard.stringArray(forKey: "locations") {
            self.locations = locationsData
        }
    }

    func saveLocations() {
        UserDefaults.standard.set(locations, forKey: "locations")
    }

    func addLocation(_ location: String) {
        locations.append(location)
        saveLocations()
    }

    func updateLocation(at index: Int, with newName: String) {
        locations[index] = newName
        saveLocations()
    }

    func deleteLocation(at index: Int) {
        locations.remove(at: index)
        saveLocations()
    }

    // MARK: - Utility Methods

    func convertWeight(_ weight: Double, to unit: WeightUnit) -> Double {
        switch unit {
        case .kg:
            return weight
        case .lb:
            return weight * 2.20462 // 公斤转磅
        }
    }
}