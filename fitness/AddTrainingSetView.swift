import SwiftUI

struct AddTrainingSetView: View {
    @ObservedObject var dataManager: DataManager
    @State private var selectedEquipment: Equipment?
    @State private var selectedMainMuscle = ""
    @State private var selectedSubMuscle = ""
    @State private var selectedVariant = ""
    @State private var reps: Int
    @State private var weight: String = "0"
    @State private var time = Date()
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var weightUnit: WeightUnit
    @State private var lastSelectedEquipmentId: String?
    let date: Date
    private let preselectedNfcTagId: String?
    @Environment(\.presentationMode) var presentationMode
    
    init(dataManager: DataManager, date: Date, preselectedNfcTagId: String? = nil) {
        self.dataManager = dataManager
        self.date = date
        self.preselectedNfcTagId = preselectedNfcTagId
        
        let savedReps = UserDefaults.standard.integer(forKey: "lastEditedReps")
        _reps = State(initialValue: savedReps > 0 ? savedReps : 12)
        
        let savedUnit = UserDefaults.standard.string(forKey: "lastUsedWeightUnit") ?? WeightUnit.kg.rawValue
        _weightUnit = State(initialValue: WeightUnit(rawValue: savedUnit) ?? .kg)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 8) {
                selectionGrid
                    .onChange(of: reps) { _, newValue in
                        UserDefaults.standard.set(newValue, forKey: "lastEditedReps")
                    }

                postureRow
            }
            .padding(.horizontal, 16)
            .padding(.top, 6)

            weightCard
                .padding(.top, 4)

            CustomNumberPad(value: $weight, height: numberPadHeight())
                .padding(.top, 2)
        }
        .navigationTitle(timeTitle())
        .navigationBarTitleDisplayMode(.inline)
        .alert(isPresented: $showAlert) {
            Alert(title: Text("錯誤"), message: Text(alertMessage), dismissButton: .default(Text("確定")))
        }
        .accentColor(.customAccent)
        .safeAreaInset(edge: .bottom) {
            Button("SAVE SET") {
                if validateInput() {
                    saveTrainingSet()
                } else {
                    showAlert = true
                }
            }
            .font(.system(size: 16, weight: .bold))
            .foregroundColor(.white)
            .frame(maxWidth: .infinity, minHeight: 52)
            .background(Color.blue)
            .cornerRadius(16)
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .background(Color(UIColor.systemBackground))
        }
        .onAppear {
            prefillEquipmentIfNeeded()
        }
    }
    private func customRow<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        HStack {
            Text(title)
                .font(.headline)
                .foregroundColor(.primary)
            Spacer()
            content()
        }
        .padding(.horizontal)
    }


    private func prefillEquipmentIfNeeded() {
        if let tagId = preselectedNfcTagId, selectedEquipment == nil {
            if let equipment = dataManager.equipment(forNfcTagId: tagId) {
                selectedEquipment = equipment
                return
            } else {
                alertMessage = "找不到對應的器材，請手動選擇"
                showAlert = true
            }
        }

        if selectedEquipment == nil {
            let savedId = UserDefaults.standard.string(forKey: "lastSelectedEquipmentId")
            if let savedId = savedId, let uuid = UUID(uuidString: savedId) {
                selectedEquipment = dataManager.equipments.first { $0.id == uuid }
            }
        }
    }

    private func numberPadHeight() -> CGFloat {
        let screenHeight = UIScreen.main.bounds.height
        return max(210, min(300, screenHeight * 0.30))
    }

    private var selectionGrid: some View {
        let subMuscles = dataManager.muscles.first(where: { $0.name == selectedMainMuscle })?.subMuscles ?? []
        return VStack(spacing: 12) {
            HStack(spacing: 12) {
                labeledMenu(title: "EQUIPMENT", value: selectedEquipment?.name ?? "選擇") {
                    ForEach(dataManager.equipments) { equipment in
                        Button(equipment.name) {
                            selectedEquipment = equipment
                            UserDefaults.standard.set(equipment.id.uuidString, forKey: "lastSelectedEquipmentId")
                        }
                    }
                }
                labeledMenu(title: "BODY PART", value: selectedMainMuscle.isEmpty ? "選擇" : selectedMainMuscle) {
                    ForEach(dataManager.muscles) { muscle in
                        Button(muscle.name) {
                            selectedMainMuscle = muscle.name
                            selectedSubMuscle = ""
                        }
                    }
                }
            }

            HStack(spacing: 12) {
                labeledMenu(
                    title: "MUSCLE GROUP",
                    value: selectedSubMuscle.isEmpty ? "不指定" : selectedSubMuscle,
                    isEnabled: !selectedMainMuscle.isEmpty && !subMuscles.isEmpty
                ) {
                    Button("不指定") { selectedSubMuscle = "" }
                    ForEach(subMuscles, id: \.name) { subMuscle in
                        Button(subMuscle.name) {
                            selectedSubMuscle = subMuscle.name
                        }
                    }
                }

                repsPicker
            }
        }
    }

    private var postureRow: some View {
        labeledMenu(
            title: "FORM / POSTURE",
            value: selectedVariant.isEmpty ? "不指定" : selectedVariant,
            isEnabled: !dataManager.variants.isEmpty
        ) {
            Button("不指定") { selectedVariant = "" }
            ForEach(dataManager.variants, id: \.self) { variant in
                Button(variant) {
                    selectedVariant = variant
                }
            }
        }
    }

    private var weightCard: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("重量")
                    .font(.headline)
                Text("WEIGHT")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
            HStack(alignment: .lastTextBaseline, spacing: 6) {
                Text("\(weight)")
                    .font(.system(size: 52, weight: .bold))
                    .foregroundColor(Color.blue)
                Menu {
                    ForEach(WeightUnit.allCases, id: \.self) { unit in
                        Button(unit.rawValue) {
                            weightUnit = unit
                            UserDefaults.standard.set(unit.rawValue, forKey: "lastUsedWeightUnit")
                        }
                    }
                } label: {
                    Text(weightUnit.rawValue)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 14)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.08), radius: 10, x: 0, y: 4)
        .padding(.horizontal, 20)
        .padding(.top, 8)
        .padding(.bottom, 6)
    }

    private func timeTitle() -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "hh:mm a"
        return formatter.string(from: time)
    }

    private func labeledMenu<MenuContent: View>(
        title: String,
        value: String,
        isEnabled: Bool = true,
        @ViewBuilder menuContent: () -> MenuContent
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            Menu {
                menuContent()
            } label: {
                HStack {
                    Text(value)
                        .foregroundColor(isEnabled ? .primary : .secondary)
                        .lineLimit(1)
                    Spacer()
                    Image(systemName: "chevron.down")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 10)
                .padding(.horizontal, 12)
                .background(Color.white)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                )
                .cornerRadius(12)
            }
            .disabled(!isEnabled)
        }
        .frame(maxWidth: .infinity)
    }

    private var repsPicker: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("REPS")
                .font(.caption)
                .foregroundColor(.secondary)
            HStack {
                Spacer()
                Text("\(reps)")
                    .font(.system(size: 18, weight: .semibold))
                Spacer()
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 12)
            .background(Color.white)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
            )
            .cornerRadius(12)
        }
        .frame(maxWidth: .infinity)
        .contextMenu {
            Button("1") { reps = 1 }
            Button("5") { reps = 5 }
            Button("8") { reps = 8 }
            Button("10") { reps = 10 }
            Button("12") { reps = 12 }
            Button("15") { reps = 15 }
            Button("20") { reps = 20 }
            Button("自訂 +1") { reps += 1 }
            Button("自訂 -1") { reps = max(1, reps - 1) }
        }
    }

    // selectionRow removed in favor of two-row selection layout

    private func validateInput() -> Bool {
        guard selectedEquipment != nil else {
            alertMessage = "請選擇一個器材"
            return false
        }

        guard !selectedMainMuscle.isEmpty else {
            alertMessage = "請選擇一個主部位"
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
        
        let timeComponents = Calendar.current.dateComponents([.hour, .minute], from: time)
        let totalMinutes = (timeComponents.hour ?? 0) * 60 + (timeComponents.minute ?? 0)
        
        let newSet = SetInfo(
            reps: reps,
            weight: weightInKg,
            weightUnit: weightUnit.rawValue,
            time: totalMinutes,
            timeUnit: "分鐘"
        )
        
        let newTrainingSet = TrainingSet(
            id: UUID(),
            equipment: equipment,
            mainMuscle: selectedMainMuscle,
            subMuscle: selectedSubMuscle.isEmpty ? nil : selectedSubMuscle,
            variant: selectedVariant.isEmpty ? nil : selectedVariant,
            sets: [newSet]
        )
        
        if let index = dataManager.trainingLogs.firstIndex(where: { Calendar.current.isDate($0.date, inSameDayAs: date) }) {
            dataManager.trainingLogs[index].sets.append(newTrainingSet)
            dataManager.updateTrainingLog(dataManager.trainingLogs[index])
        } else {
            let newLog = TrainingLog(id: UUID(), date: date, sets: [newTrainingSet])
            dataManager.addTrainingLog(newLog)
        }
                
        UserDefaults.standard.set(reps, forKey: "lastEditedReps")
        UserDefaults.standard.set(weightUnit.rawValue, forKey: "lastUsedWeightUnit")
        UserDefaults.standard.set(equipment.id.uuidString, forKey: "lastSelectedEquipmentId")
        
        presentationMode.wrappedValue.dismiss()
    }
}

struct CustomNumberPad: View {
    @Binding var value: String
    let height: CGFloat
    
    let buttons: [[String]] = [
        ["1", "2", "3"],
        ["4", "5", "6"],
        ["7", "8", "9"],
        ["C", "0", "."]
    ]
    
    var body: some View {
        GeometryReader { geometry in
            let horizontalPadding: CGFloat = 16
            let columnSpacing: CGFloat = 10
            let rowSpacing: CGFloat = 10
            let availableWidth = max(0, geometry.size.width - (horizontalPadding * 2) - (columnSpacing * 2))
            let itemWidth = availableWidth / 3
            let itemHeight = (geometry.size.height - (rowSpacing * 3)) / 4

            VStack(spacing: rowSpacing) {
                ForEach(buttons, id: \.self) { row in
                    HStack(spacing: columnSpacing) {
                        ForEach(row, id: \.self) { button in
                            Button(action: {
                                self.buttonTapped(button)
                            }) {
                                Text(button)
                                    .font(.system(size: 24, weight: .semibold))
                                    .frame(width: itemWidth, height: itemHeight)
                                    .background(buttonColor(for: button))
                                    .foregroundColor(buttonTextColor(for: button))
                                    .cornerRadius(12)
                                    .shadow(color: Color.black.opacity(0.12), radius: 6, x: 0, y: 4)
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, horizontalPadding)
            .frame(maxWidth: .infinity, alignment: .center)
        }
        .frame(maxWidth: .infinity)
        .frame(height: height)
    }
    
    private func buttonColor(for button: String) -> Color {
        switch button {
        case "C":
            return Color(red: 0.86, green: 0.73, blue: 0.73)
        default:
            return Color.white
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
