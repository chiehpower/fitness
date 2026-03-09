import SwiftUI
import Combine
struct Equipment: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var imageName: String?
    var nfcTagId: String?
    var location: String?
    var pr: Double?
    var mainPart: String
    var muscleTags: [String]
    var actions: [String]

    init(
        id: UUID,
        name: String,
        imageName: String?,
        nfcTagId: String?,
        location: String?,
        pr: Double?,
        mainPart: String = "全身",
        muscleTags: [String] = [],
        actions: [String] = []
    ) {
        self.id = id
        self.name = name
        self.imageName = imageName
        self.nfcTagId = nfcTagId
        self.location = location
        self.pr = pr
        self.mainPart = mainPart
        self.muscleTags = muscleTags
        self.actions = actions
    }

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case imageName
        case nfcTagId
        case location
        case pr
        case mainPart
        case muscleTags
        case actions
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        imageName = try container.decodeIfPresent(String.self, forKey: .imageName)
        nfcTagId = try container.decodeIfPresent(String.self, forKey: .nfcTagId)
        location = try container.decodeIfPresent(String.self, forKey: .location)
        pr = try container.decodeIfPresent(Double.self, forKey: .pr)
        mainPart = try container.decodeIfPresent(String.self, forKey: .mainPart) ?? "全身"
        muscleTags = try container.decodeIfPresent([String].self, forKey: .muscleTags) ?? []
        actions = try container.decodeIfPresent([String].self, forKey: .actions) ?? []
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encodeIfPresent(imageName, forKey: .imageName)
        try container.encodeIfPresent(nfcTagId, forKey: .nfcTagId)
        try container.encodeIfPresent(location, forKey: .location)
        try container.encodeIfPresent(pr, forKey: .pr)
        try container.encode(mainPart, forKey: .mainPart)
        try container.encode(muscleTags, forKey: .muscleTags)
        try container.encode(actions, forKey: .actions)
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

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
    var mainMuscle: String
    var subMuscle: String?
    var variant: String?
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
    @Published var variants: [String] = []

    init() {
        loadData()
    }

    func loadData() {
        loadMuscles()
        loadEquipments()
        loadTrainingLogs()
        loadPreferredWeightUnit()
        loadLocations()
        loadVariants()
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

    func equipment(forNfcTagId nfcTagId: String) -> Equipment? {
        equipments.first { $0.nfcTagId == nfcTagId }
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

    // MARK: - Variants

    func loadVariants() {
        if let variantsData = UserDefaults.standard.stringArray(forKey: "variants") {
            self.variants = variantsData
        }
    }

    func saveVariants() {
        UserDefaults.standard.set(variants, forKey: "variants")
    }

    func addVariant(_ variant: String) {
        variants.append(variant)
        saveVariants()
    }

    func updateVariant(at index: Int, with newName: String) {
        variants[index] = newName
        saveVariants()
    }

    func deleteVariant(at index: Int) {
        variants.remove(at: index)
        saveVariants()
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

    func exportBackupData() -> Data? {
        let payload = BackupPayload(
            exportedAt: Date(),
            muscles: muscles,
            equipments: equipments,
            trainingLogs: trainingLogs,
            preferredWeightUnit: preferredWeightUnit,
            locations: locations,
            variants: variants
        )
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        return try? encoder.encode(payload)
    }

    func applyBackup(_ payload: BackupPayload) {
        muscles = payload.muscles
        equipments = payload.equipments
        trainingLogs = payload.trainingLogs
        preferredWeightUnit = payload.preferredWeightUnit
        locations = payload.locations
        variants = payload.variants ?? []

        saveMuscles()
        saveEquipments()
        saveTrainingLogs()
        savePreferredWeightUnit()
        saveLocations()
        saveVariants()
    }
}

struct BackupPayload: Codable {
    let exportedAt: Date
    let muscles: [Muscle]
    let equipments: [Equipment]
    let trainingLogs: [TrainingLog]
    let preferredWeightUnit: WeightUnit
    let locations: [String]
    let variants: [String]?
}
