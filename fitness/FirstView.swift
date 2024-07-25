struct FirstView: View {
    @EnvironmentObject var equipmentData: EquipmentData
    @State private var showingSheet = false
    @State private var selectedSheet: SheetType?

    enum SheetType {
        case addEquipment
        case manageParts
        case manageSubParts
    }

    var body: some View {
        NavigationView {
            VStack {
                TableView()
                    .navigationTitle("器材管理")
                    .navigationBarItems(trailing: Menu {
                        Button("新增器材") {
                            selectedSheet = .addEquipment
                            showingSheet = true
                        }
                        Button("管理部位") {
                            selectedSheet = .manageParts
                            showingSheet = true
                        }
                        Button("管理細部位") {
                            selectedSheet = .manageSubParts
                            showingSheet = true
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    })
            }
            .sheet(isPresented: $showingSheet) {
                switch selectedSheet {
                case .addEquipment:
                    AddEquipmentView()
                        .environmentObject(equipmentData)
                case .manageParts:
                    ManagePartsView()
                        .environmentObject(equipmentData)
                case .manageSubParts:
                    ManageSubPartsView()
                        .environmentObject(equipmentData)
                case .none:
                    EmptyView()
                }
            }
        }
    }
}
