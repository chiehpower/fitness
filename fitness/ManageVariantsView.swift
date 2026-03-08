import SwiftUI

struct ManageVariantsView: View {
    @ObservedObject var dataManager: DataManager
    @State private var newVariantName = ""

    var body: some View {
        List {
            Section(header: Text("新增姿勢/變體")) {
                TextField("姿勢/變體名稱", text: $newVariantName)
                Button("新增") {
                    let trimmed = newVariantName.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !trimmed.isEmpty else {
                        return
                    }
                    dataManager.addVariant(trimmed)
                    newVariantName = ""
                }
            }

            Section(header: Text("現有姿勢/變體")) {
                ForEach(dataManager.variants, id: \.self) { variant in
                    Text(variant)
                }
                .onDelete(perform: deleteVariants)
            }
        }
        .navigationBarTitle("管理姿勢/變體", displayMode: .inline)
        .navigationBarItems(trailing: EditButton())
    }

    private func deleteVariants(at offsets: IndexSet) {
        offsets.sorted(by: >).forEach { index in
            dataManager.deleteVariant(at: index)
        }
    }
}
