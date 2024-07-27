import SwiftUI

struct AddTrainingSetView: View {
    @ObservedObject var dataManager: DataManager
    @State private var selectedEquipment: Equipment?
    @State private var reps: Int
    @State private var weight: Double?
    @State private var time = Date()
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var weightUnit: WeightUnit
    let date: Date
    @Environment(\.presentationMode) var presentationMode
    
    enum WeightUnit: String, CaseIterable {
        case kg = "公斤"
        case lb = "磅"
    }
    
    init(dataManager: DataManager, date: Date) {
        self.dataManager = dataManager
        self.date = date
        
        let savedReps = UserDefaults.standard.integer(forKey: "lastEditedReps")
        _reps = State(initialValue: savedReps > 0 ? savedReps : 12)
        
        let savedUnit = UserDefaults.standard.string(forKey: "lastUsedWeightUnit") ?? WeightUnit.kg.rawValue
        _weightUnit = State(initialValue: WeightUnit(rawValue: savedUnit) ?? .kg)
    }
    
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
                    .onChange(of: reps) { _, newValue in
                        UserDefaults.standard.set(newValue, forKey: "lastEditedReps")
                    }
                
                HStack {
                    Text("重量")
                    TextField("輸入重量", value: $weight, format: .number)
                        .keyboardType(.decimalPad)
                    Picker("單位", selection: $weightUnit) {
                        ForEach(WeightUnit.allCases, id: \.self) { unit in
                            Text(unit.rawValue).tag(unit)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .frame(width: 100)
                }
                .onChange(of: weightUnit) { _, newValue in
                    UserDefaults.standard.set(newValue.rawValue, forKey: "lastUsedWeightUnit")
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
        
        guard let weight = weight, weight > 0 else {
            alertMessage = "請輸入有效的重量"
            return false
        }
        
        return true
    }
    
    private func saveTrainingSet() {
        guard let equipment = selectedEquipment, let weight = weight else { return }
        
        let weightInKg: Double
        if weightUnit == .lb {
            weightInKg = weight * 0.453592 // 將磅轉換為公斤
        } else {
            weightInKg = weight
        }
        
        let newSet = TrainingSet(id: UUID(), equipment: equipment, reps: reps, weight: weightInKg, time: time)
        
        if let index = dataManager.trainingLogs.firstIndex(where: { Calendar.current.isDate($0.date, inSameDayAs: date) }) {
            dataManager.trainingLogs[index].sets.append(newSet)
        } else {
            let newLog = TrainingLog(id: UUID(), date: date, sets: [newSet])
            dataManager.trainingLogs.append(newLog)
        }
        
        presentationMode.wrappedValue.dismiss()
    }
}
