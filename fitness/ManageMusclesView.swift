import SwiftUI

// 管理部位視圖
struct ManageMusclesView: View {
    @Binding var muscles: [Muscle]
    @State private var newMuscleName = ""
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("新增部位")) {
                    HStack {
                        TextField("部位名稱", text: $newMuscleName)
                        Button("新增") {
                            if !newMuscleName.isEmpty {
                                muscles.append(Muscle(id: UUID(), name: newMuscleName, subMuscles: []))
                                newMuscleName = ""
                            }
                        }
                    }
                }
                
                Section(header: Text("現有部位")) {
                    ForEach(muscles) { muscle in
                        Text(muscle.name)
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
