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
                    .gesture(
                        TapGesture(count: 2)
                            .onEnded { _ in
                                showingAddSet = true
                            }
                    )
                List {
                    ForEach(dataManager.trainingLogs.filter { Calendar.current.isDate($0.date, inSameDayAs: selectedDate) }) { log in
                        Section(header: Text(formatDate(log.date))) {
                            ForEach(log.sets) { set in
                                VStack(alignment: .leading, spacing: 5) {
                                    HStack {
                                        Text(set.equipment.name)
                                            .font(.headline)
                                        Spacer()
                                        Text("\(set.reps) 次")
                                        Text("\(set.weight, specifier: "%.1f") kg")
                                    }
                                    HStack {
                                        Text(set.equipment.mainMuscle)
                                            .font(.subheadline)
                                            .padding(3)
                                            .background(Color.blue.opacity(0.2))
                                            .cornerRadius(5)
                                        Text(set.equipment.subMuscle)
                                            .font(.subheadline)
                                            .padding(3)
                                            .background(Color.green.opacity(0.2))
                                            .cornerRadius(5)
                                        Spacer()
                                        Text(formatTime(set.time))
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                    }
                                }
                            }
                            .onDelete { indices in
                                deleteTrainingSet(for: log, at: indices)
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
            .navigationBarItems(trailing: EditButton())
            .sheet(isPresented: $showingAddSet) {
                AddTrainingSetView(dataManager: dataManager, date: selectedDate)
            }
        }
    }
    private func deleteTrainingSet(for log: TrainingLog, at offsets: IndexSet) {
        if let index = dataManager.trainingLogs.firstIndex(where: { $0.id == log.id }) {
            dataManager.trainingLogs[index].sets.remove(atOffsets: offsets)
            
            // 如果刪除後該日誌沒有任何訓練組，則刪除整個日誌
            if dataManager.trainingLogs[index].sets.isEmpty {
                dataManager.trainingLogs.remove(at: index)
            }
        }
    }
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM月dd日 EEEE"
        formatter.locale = Locale(identifier: "zh_TW")
        return formatter.string(from: date)
    }
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
}
