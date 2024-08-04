import SwiftUI

struct ManageMusclesView: View {
    @ObservedObject var dataManager: DataManager
    @State private var newMuscleName = ""
    @State private var newMuscleColor = Color.blue
    
    var body: some View {
        List {
            Section(header: Text("新增部位")) {
                TextField("部位名稱", text: $newMuscleName)
                
                ColorPicker("選擇顏色", selection: $newMuscleColor)
                
                Button("新增") {
                    if !newMuscleName.isEmpty {
                        let newMuscle = Muscle(id: UUID(), name: newMuscleName, color: newMuscleColor.toHex(), subMuscles: [])
                        dataManager.addMuscle(newMuscle)
                        resetNewMuscleInputs()
                    }
                }
            }
            
            Section(header: Text("現有部位")) {
                ForEach(dataManager.muscles) { muscle in
                    HStack {
                        Text(muscle.name)
                        Spacer()
                        ColorIndicator(color: Color(hex: muscle.color) ?? .gray)
                    }
                }
                .onDelete(perform: deleteMuscle)
            }
        }
        .navigationBarTitle("管理部位", displayMode: .inline)
        .navigationBarItems(trailing: EditButton())
    }
    
    private func resetNewMuscleInputs() {
        newMuscleName = ""
        newMuscleColor = .blue
    }
    
    func deleteMuscle(at offsets: IndexSet) {
        offsets.forEach { index in
            let muscleToDelete = dataManager.muscles[index]
            dataManager.deleteMuscle(muscleToDelete)
        }
    }
}
