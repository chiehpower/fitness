import SwiftUI

// 訓練記錄視圖
struct TrainingLogView: View {
    @ObservedObject var dataManager: DataManager
    @State private var selectedDate = Date()
    @State private var showingAddSet = false
    
    var body: some View {
        NavigationView {
            VStack {
                DatePicker("選擇日期", selection: $selectedDate, displayedComponents: .date)
                    .datePickerStyle(GraphicalDatePickerStyle())
                    .padding()
                
                List {
                    ForEach(dataManager.trainingLogs.filter { Calendar.current.isDate($0.date, inSameDayAs: selectedDate) }) { log in
                        ForEach(log.sets) { set in
                            HStack {
                                Text(set.equipment.name)
                                Spacer()
                                Text("\(set.reps) 次")
                                Text("\(set.weight, specifier: "%.1f") kg")
                            }
                        }
                    }
                }
                
                Button("新增訓練組") {
                    showingAddSet = true
                }
                .padding()
            }
            .navigationTitle("訓練記錄")
            .sheet(isPresented: $showingAddSet) {
                AddTrainingSetView(dataManager: dataManager, date: selectedDate)
            }
        }
    }
}
