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
    @Published var locations: [String] = []  // 新添加的locations屬性

    init() {
        loadData()
    }

    func loadData() {
        loadMuscles()
        loadEquipments()
        loadTrainingLogs()
        loadPreferredWeightUnit()
        loadLocations()  // 新添加的方法調用
    }

    func loadMuscles() {
        if let musclesData = UserDefaults.standard.data(forKey: "muscles"),
           let decodedMuscles = try? JSONDecoder().decode([Muscle].self, from: musclesData) {
            self.muscles = decodedMuscles
        }
    }

    func loadEquipments() {
        if let equipmentsData = UserDefaults.standard.data(forKey: "equipments"),
           let decodedEquipments = try? JSONDecoder().decode([Equipment].self, from: equipmentsData) {
            self.equipments = decodedEquipments
        }
    }

    func loadTrainingLogs() {
        if let logsData = UserDefaults.standard.data(forKey: "trainingLogs"),
           let decodedLogs = try? JSONDecoder().decode([TrainingLog].self, from: logsData) {
            self.trainingLogs = decodedLogs
        }
    }

    private func loadPreferredWeightUnit() {
        if let unitString = UserDefaults.standard.string(forKey: "preferredWeightUnit"),
           let unit = WeightUnit(rawValue: unitString) {
            preferredWeightUnit = unit
        }
    }

    func savePreferredWeightUnit() {
        UserDefaults.standard.set(preferredWeightUnit.rawValue, forKey: "preferredWeightUnit")
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
    
    private func saveEquipments() {
        if let encoded = try? JSONEncoder().encode(equipments) {
            UserDefaults.standard.set(encoded, forKey: "equipments")
        }
    }

    func convertWeight(_ weight: Double, to unit: WeightUnit) -> Double {
        switch unit {
        case .kg:
            return weight
        case .lb:
            return weight * 2.20462 // 公斤转磅
        }
    }
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

    func deleteLocation(at index: Int) {
        locations.remove(at: index)
        saveLocations()
    }

    func updateLocation(at index: Int, with newName: String) {
        locations[index] = newName
        saveLocations()
    }
}
