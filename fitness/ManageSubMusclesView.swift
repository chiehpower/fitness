import SwiftUI

struct ManageSubMusclesView: View {
    @Binding var muscles: [Muscle]
    @State private var selectedMuscle = ""
    @State private var newSubMuscleName = ""
    @State private var newSubMuscleColor = Color.blue
    
    var body: some View {
        Form {
            Picker("選擇部位", selection: $selectedMuscle) {
                Text("選擇部位").tag("")
                ForEach(muscles) { muscle in
                    Text(muscle.name).tag(muscle.name)
                }
            }
            
            if let muscleIndex = muscles.firstIndex(where: { $0.name == selectedMuscle }) {
                Section(header: Text("新增細部位")) {
                    TextField("細部位名稱", text: $newSubMuscleName)
                    ColorPicker("選擇顏色", selection: $newSubMuscleColor)
                    Button("新增") {
                        if !newSubMuscleName.isEmpty {
                            let newSubMuscle = SubMuscle(name: newSubMuscleName, color: newSubMuscleColor.toHex())
                            muscles[muscleIndex].subMuscles.append(newSubMuscle)
                            resetNewSubMuscleInputs()
                        }
                    }
                }
                
                Section(header: Text("現有細部位")) {
                    ForEach(muscles[muscleIndex].subMuscles.indices, id: \.self) { index in
                        HStack {
                            Text(muscles[muscleIndex].subMuscles[index].name)
                            Spacer()
                            ColorIndicator(color: Color(hex: muscles[muscleIndex].subMuscles[index].color) ?? .gray)
                        }
                    }
                    .onDelete { indexSet in
                        muscles[muscleIndex].subMuscles.remove(atOffsets: indexSet)
                    }
                }
            }
        }
        .navigationBarTitle("管理細部位", displayMode: .inline)
        .navigationBarItems(trailing: EditButton())
    }
    
    private func resetNewSubMuscleInputs() {
        newSubMuscleName = ""
        newSubMuscleColor = .blue
    }
}
