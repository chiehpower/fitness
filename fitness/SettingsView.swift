import SwiftUI

struct SettingsView: View {
    @ObservedObject var dataManager: DataManager
    
    var body: some View {
        Form {
            Section(header: Text("重量單位偏好")) {
                Picker("顯示重量單位", selection: $dataManager.preferredWeightUnit) {
                    Text("公斤").tag(WeightUnit.kg)
                    Text("磅").tag(WeightUnit.lb)
                }
                .pickerStyle(SegmentedPickerStyle())
            }
        }
        .navigationTitle("設置")
    }
}

enum WeightUnit: String, Codable {
    case kg = "公斤"
    case lb = "磅"
}
