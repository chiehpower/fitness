import SwiftUI

struct WelcomeView: View {
    @Binding var isWelcomeActive: Bool
    @State private var opacity: Double = 0
    
    var body: some View {
        ZStack {
            Color.white.edgesIgnoringSafeArea(.all)
            VStack {
                Spacer()

                // 嘗試加載自定義 logo
                Group {
                    if let uiImage = UIImage(named: "WelcomeIcon") ?? UIImage(named: "Assets/WelcomeIcon") {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFit()
                    } else {
                        // 後備圖像
                        Image(systemName: "dumbbell.fill")
                            .resizable()
                            .scaledToFit()
                            .foregroundColor(.blue)
                    }
                }
                .frame(width: 180, height: 180)
                .clipShape(RoundedRectangle(cornerRadius: 40))
                .shadow(color: .gray, radius: 10, x: 0, y: 5)
                .overlay(
                    RoundedRectangle(cornerRadius: 40)
                        .stroke(Color.gray, lineWidth: 0.5)
                )

                Text("Your Personal Fitness Recorder")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .padding(.top, 50)

                
                Text("Enjoy your fitness journey")
                    .font(.subheadline)
                    .padding(.top, 5)

                Spacer()

                Text("© 2024 Chieh All Rights Reserved")
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
                    .padding(.bottom, 20)
            }
        }
        .opacity(opacity)
        .onAppear {
            withAnimation(.easeIn(duration: 1.0)) {
                self.opacity = 1.0
            }
            
            // 3秒后自动跳转到主页面
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                withAnimation {
                    self.isWelcomeActive = false
                }
            }
        }
    }
}
struct ContentView: View {
    @StateObject private var dataManager = DataManager()
    @State private var isWelcomeActive = true
    @State private var selection = 0
    @State private var showingAddEquipment = false
    @State private var showingManageMuscles = false
    @State private var showingManageSubMuscles = false

    var body: some View {
        Group {
            if isWelcomeActive {
                WelcomeView(isWelcomeActive: $isWelcomeActive)
            } else {
                TabView(selection: $selection) {
                    TrainingLogView(dataManager: dataManager)
                    .tabItem {
                        Image(systemName: "calendar")
                        Text("運動")
                    }
                    .tag(0)
                    
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
                    .tag(1)

                    SettingsView(dataManager: dataManager)
                    .tabItem { 
                        Image(systemName: "gearshape.fill") 
                        Text("設定") 
                    }.tag(2)
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
        .animation(.easeInOut, value: isWelcomeActive)
    }
}

// 預覽
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
