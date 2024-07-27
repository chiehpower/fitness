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
    var time: Date  // 新添加的屬性
}

struct TrainingLog: Identifiable, Codable {
    let id: UUID
    var date: Date
    var sets: [TrainingSet]
}

// 數據管理器
// 更新 DataManager
public class DataManager: ObservableObject {
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
