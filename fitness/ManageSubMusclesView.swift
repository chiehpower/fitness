import SwiftUI

// 管理細部位視圖
struct ManageSubMusclesView: View {
    @Binding var muscles: [Muscle]
    @State private var selectedMuscle = ""
    @State private var newSubMuscleName = ""
    
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
                        HStack {
                            TextField("細部位名稱", text: $newSubMuscleName)
                            Button("新增") {
                                if !newSubMuscleName.isEmpty {
                                    muscles[muscleIndex].subMuscles.append(newSubMuscleName)
                                    newSubMuscleName = ""
                                }
                            }
                        }
                    }
                    
                    Section(header: Text("現有細部位")) {
                        ForEach(muscles[muscleIndex].subMuscles, id: \.self) { subMuscle in
                            Text(subMuscle)
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
