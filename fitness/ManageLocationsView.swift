import SwiftUI

struct ManageLocationsView: View {
    @ObservedObject var dataManager: DataManager
    @State private var newLocation = ""
    @State private var editingLocation: (Int, String)? = nil

    var body: some View {
        List {
            Section(header: Text("新增地點")) {
                HStack {
                    TextField("輸入新地點", text: $newLocation)
                    Button(action: addLocation) {
                        Image(systemName: "plus.circle.fill")
                    }
                    .disabled(newLocation.isEmpty)
                }
            }

            Section(header: Text("現有地點")) {
                ForEach(dataManager.locations.indices, id: \.self) { index in
                    if let (editingIndex, editingName) = editingLocation, editingIndex == index {
                        HStack {
                            TextField("", text: Binding(
                                get: { editingName },
                                set: { self.editingLocation = (index, $0) }
                            ))
                            Button("儲存") {
                                dataManager.updateLocation(at: index, with: editingName)
                                editingLocation = nil
                            }
                        }
                    } else {
                        Text(dataManager.locations[index])
                            .onTapGesture {
                                editingLocation = (index, dataManager.locations[index])
                            }
                    }
                }
                .onDelete(perform: deleteLocation)
            }
        }
        .navigationTitle("管理地點")
        .navigationBarItems(trailing: EditButton())
    }

    private func addLocation() {
        dataManager.addLocation(newLocation)
        newLocation = ""
    }

    private func deleteLocation(at offsets: IndexSet) {
        offsets.forEach { dataManager.deleteLocation(at: $0) }
    }
}
