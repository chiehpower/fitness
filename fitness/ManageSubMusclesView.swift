import SwiftUI

struct ManageSubMusclesView: View {
    @Binding var muscles: [Muscle]
    @State private var selectedMuscle = ""
    @State private var newSubMuscleName = ""
    @State private var newSubMuscleColor = ""
    
    var body: some View {
        NavigationView {
            Form {
                Picker("選擇部位", selection: $selectedMuscle) {
                    ForEach(muscles) { muscle in
                        Text(muscle.name).tag(muscle.name)
                    }
                }
                
                if let muscleIndex = muscles.firstIndex(where: { $0.name == selectedMuscle }) {
                    Section(header: Text("新增細部位")) {
                        TextField("細部位名稱", text: $newSubMuscleName)
                        TextField("顏色", text: $newSubMuscleColor)
                        Button("新增") {
                            if !newSubMuscleName.isEmpty && !newSubMuscleColor.isEmpty {
                                let newSubMuscle = SubMuscle(name: newSubMuscleName, color: newSubMuscleColor)
                                muscles[muscleIndex].subMuscles.append(newSubMuscle)
                                newSubMuscleName = ""
                                newSubMuscleColor = ""
                            }
                        }
                    }
                    
                    Section(header: Text("現有細部位")) {
                        ForEach(muscles[muscleIndex].subMuscles, id: \.name) { subMuscle in
                            HStack {
                                Text(subMuscle.name)
                                Spacer()
                                Text(subMuscle.color)
                                    .foregroundColor(Color(subMuscle.color))
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
    }
}
