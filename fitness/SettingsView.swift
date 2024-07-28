import SwiftUI

struct SettingsView: View {
    @ObservedObject var dataManager: DataManager
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("重量單位偏好")) {
                    HStack {
                        Text("顯示重量單位")
                        Spacer()
                        Picker("", selection: $dataManager.preferredWeightUnit) {
                            Text("公斤").tag(WeightUnit.kg)
                            Text("磅").tag(WeightUnit.lb)
                        }
                        .pickerStyle(MenuPickerStyle())
                    }
                }
            }
            .navigationTitle("設定")
        }
    }
}

enum WeightUnit: String, Codable {
    case kg = "公斤"
    case lb = "磅"
}
