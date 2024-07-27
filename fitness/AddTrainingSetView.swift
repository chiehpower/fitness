import SwiftUI

struct AddTrainingSetView: View {
    @ObservedObject var dataManager: DataManager
    @State private var selectedEquipment: Equipment?
    @State private var reps: Int
    @State private var weight: Double?
    @State private var time = Date()
    @State private var showAlert = false
    @State private var alertMessage = ""
    let date: Date
    @Environment(\.presentationMode) var presentationMode
    
    init(dataManager: DataManager, date: Date) {
        self.dataManager = dataManager
        self.date = date
        
        let savedReps = UserDefaults.standard.integer(forKey: "lastEditedReps")
        _reps = State(initialValue: savedReps > 0 ? savedReps : 12)
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
        
        guard let weight = weight, weight > 0 else {
            alertMessage = "請輸入有效的重量"
            return false
        }
        
        return true
    }
    
    private func saveTrainingSet() {
        guard let equipment = selectedEquipment, let weight = weight else { return }
        
        let newSet = TrainingSet(id: UUID(), equipment: equipment, reps: reps, weight: weight, time: time)
        
        if let index = dataManager.trainingLogs.firstIndex(where: { Calendar.current.isDate($0.date, inSameDayAs: date) }) {
            dataManager.trainingLogs[index].sets.append(newSet)
        } else {
            let newLog = TrainingLog(id: UUID(), date: date, sets: [newSet])
            dataManager.trainingLogs.append(newLog)
        }
        
        presentationMode.wrappedValue.dismiss()
    }
}
