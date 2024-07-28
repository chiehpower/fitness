import SwiftUI

struct AddTrainingSetView: View {
    @ObservedObject var dataManager: DataManager
    @State private var selectedEquipment: Equipment?
    @State private var reps: Int
    @State private var weight: String = "0"
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
            VStack(spacing: 0) {
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
                    
                    Picker("重量單位", selection: $weightUnit) {
                        ForEach(WeightUnit.allCases, id: \.self) { unit in
                            Text(unit.rawValue).tag(unit)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .onChange(of: weightUnit) { _, newValue in
                        UserDefaults.standard.set(newValue.rawValue, forKey: "lastUsedWeightUnit")
                    }
                }
                
                VStack(spacing: 0) {
                    Text("重量")
                        .font(.headline)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal)
                        .padding(.top, 10)
                    
                    Text("\(weight) \(weightUnit.rawValue)")
                        .font(.system(size: 40, weight: .medium))
                        .frame(maxWidth: .infinity, alignment: .trailing)
                        .padding(.horizontal)
                        .padding(.bottom, 10)
                    
                    CustomNumberPad(value: $weight)
                }
                .background(Color(UIColor.secondarySystemBackground))
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
        .accentColor(.customAccent) // 應用到整個 NavigationView

    }
    
    private func validateInput() -> Bool {
        guard selectedEquipment != nil else {
            alertMessage = "請選擇一個器材"
            return false
        }
        
        guard let weightValue = Double(weight), weightValue > 0 else {
            alertMessage = "請輸入有效的重量"
            return false
        }
        
        return true
    }
    
    private func saveTrainingSet() {
        guard let equipment = selectedEquipment, let weightValue = Double(weight) else { return }
        
        let weightInKg: Double
        if weightUnit == .lb {
            weightInKg = weightValue * 0.453592 // 將磅轉換為公斤
        } else {
            weightInKg = weightValue
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

struct CustomNumberPad: View {
    @Binding var value: String
    
    let buttons: [[String]] = [
        ["7", "8", "9"],
        ["4", "5", "6"],
        ["1", "2", "3"],
        ["C", "0", "."]
    ]
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 1) {
                ForEach(buttons, id: \.self) { row in
                    HStack(spacing: 1) {
                        ForEach(row, id: \.self) { button in
                            Button(action: {
                                self.buttonTapped(button)
                            }) {
                                Text(button)
                                    .font(.system(size: 30, weight: .medium))
                                    .frame(width: (geometry.size.width / 3) - 0.67, height: (geometry.size.height / 4) - 0.75)
                                    .background(buttonColor(for: button))
                                    .foregroundColor(buttonTextColor(for: button))
                            }
                        }
                    }
                }
            }
        }
        .frame(height: UIScreen.main.bounds.height / 3)  // 設置鍵盤高度為螢幕高度的1/3
    }
    
    private func buttonColor(for button: String) -> Color {
        switch button {
        case "C":
            return Color(UIColor.systemOrange)
        case "0", "1", "2", "3", "4", "5", "6", "7", "8", "9", ".":
            return Color(UIColor.systemGray6)
        default:
            return Color(UIColor.systemGray4)
        }
    }
    
    private func buttonTextColor(for button: String) -> Color {
        switch button {
        case "C":
            return .white
        default:
            return .primary
        }
    }
    
    private func buttonTapped(_ button: String) {
        switch button {
        case "C":
            value = "0"
        case ".":
            if !value.contains(".") {
                value += "."
            }
        default:
            if value == "0" {
                value = button
            } else {
                value += button
            }
        }
        
        // 限制小數點後兩位
        if value.contains(".") {
            let parts = value.split(separator: ".")
            if parts.count > 1 && parts[1].count > 2 {
                value = String(value.prefix(value.count - 1))
            }
        }
        
        // 限制整數部分為3位數
        if !value.contains(".") && value.count > 3 {
            value = String(value.prefix(3))
        }
    }
}
