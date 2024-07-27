import SwiftUI

// 主視圖
struct ContentView: View {
    @StateObject private var dataManager = DataManager()
    @State private var selection = 0
    @State private var showingAddEquipment = false
    @State private var showingManageMuscles = false
    @State private var showingManageSubMuscles = false
    
    var body: some View {
        TabView(selection: $selection) {
            NavigationView {
                EquipmentListView(equipments: $dataManager.equipments)
                    .navigationTitle("健身器材")
                    .navigationBarItems(trailing: Menu {
                        Button("新增器材") {
                            showingAddEquipment = true
                        }
                        Button("管理部位") {
                            showingManageMuscles = true
                        }
                        Button("管理細部位") {
                            showingManageSubMuscles = true
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    })
            }
            .tabItem {
                Image(systemName: "dumbbell.fill")
                Text("器材")
            }
            .tag(0)
            
            TrainingLogView(dataManager: dataManager)
                .tabItem {
                    Image(systemName: "book.fill")
                    Text("紀錄")
                }
                .tag(1)
            
            Text("設定").tabItem {
                Image(systemName: "gearshape.fill")
                Text("設定")
            }.tag(2)
            
            Text("計時").tabItem {
                Image(systemName: "timer")
                Text("計時")
            }.tag(3)
        }
        .sheet(isPresented: $showingAddEquipment) {
            AddEquipmentView(equipments: $dataManager.equipments, muscles: dataManager.muscles)
        }
        .sheet(isPresented: $showingManageMuscles) {
            ManageMusclesView(muscles: $dataManager.muscles)
        }
        .sheet(isPresented: $showingManageSubMuscles) {
            ManageSubMusclesView(muscles: $dataManager.muscles)
        }
    }
}

// 預覽
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
