import SwiftUI

struct ManageMusclesView: View {
    @Binding var muscles: [Muscle]
    @State private var newMuscleName = ""
    @State private var newMuscleColor = ""
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("新增部位")) {
                    TextField("部位名稱", text: $newMuscleName)
                    TextField("顏色", text: $newMuscleColor)
                    Button("新增") {
                        if !newMuscleName.isEmpty && !newMuscleColor.isEmpty {
                            muscles.append(Muscle(id: UUID(), name: newMuscleName, color: newMuscleColor, subMuscles: []))
                            newMuscleName = ""
                            newMuscleColor = ""
                        }
                    }
                }
                
                Section(header: Text("現有部位")) {
                    ForEach(muscles) { muscle in
                        HStack {
                            Text(muscle.name)
                            Spacer()
                            Text(muscle.color)
                                .foregroundColor(Color(muscle.color))
                        }
                    }
                    .onDelete(perform: deleteMuscle)
                }
            }
            .navigationBarTitle("管理部位", displayMode: .inline)
            .navigationBarItems(trailing: EditButton())
        }
    }
    
    func deleteMuscle(at offsets: IndexSet) {
        muscles.remove(atOffsets: offsets)
    }
}
