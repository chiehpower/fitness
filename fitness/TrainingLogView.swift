import SwiftUI

// 訓練記錄視圖
struct TrainingLogView: View {
    @ObservedObject var dataManager: DataManager
    @State private var selectedDate = Date()
    @State private var showingAddSet = false
    
    var body: some View {
        VStack(spacing: 0) {
            CustomDatePicker(
                selectedDate: $selectedDate,
                dataManager: dataManager,
                onDateDoubleTapped: { date in
                    selectedDate = date
                    showingAddSet = true
                }
            )
            .padding(.top)
            
            List {
                ForEach(dataManager.trainingLogs.filter { Calendar.current.isDate($0.date, inSameDayAs: selectedDate) }) { log in
                    Section(header: Text(formatDate(log.date))) {
                        ForEach(log.sets) { trainingSet in
                            VStack(alignment: .leading, spacing: 5) {
                                Text(trainingSet.equipment.name)
                                    .font(.headline)
                                ForEach(trainingSet.sets.indices, id: \.self) { index in
                                    let set = trainingSet.sets[index]
                                    HStack {
                                        Text("組數 \(index + 1)")
                                            .font(.subheadline)
                                        Spacer()
                                        Text("\(set.reps) 次")
                                        Text("\(formatWeight(set.weight)) \(set.weightUnit)")
                                        if set.time > 0 {
                                            Text("\(set.time) \(set.timeUnit)")
                                        }
                                    }
                                }
                                HStack {
                                    Text(trainingSet.equipment.mainMuscle)
                                        .font(.caption)
                                        .padding(3)
                                        .background(Color.blue.opacity(0.2))
                                        .cornerRadius(5)
                                    Text(trainingSet.equipment.subMuscle)
                                        .font(.caption)
                                        .padding(3)
                                        .background(Color.green.opacity(0.2))
                                        .cornerRadius(5)
                                    Spacer()
                                    Text(trainingSet.equipment.location)
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

    private func deleteTrainingSet(for log: TrainingLog, at offsets: IndexSet) {
        if let index = dataManager.trainingLogs.firstIndex(where: { $0.id == log.id }) {
            dataManager.trainingLogs[index].sets.remove(atOffsets: offsets)
            
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

    private func formatWeight(_ weight: Double) -> String {
        return String(format: "%.1f", weight)
    }
}

struct CustomDatePicker: View {
    @Binding var selectedDate: Date
    @ObservedObject var dataManager: DataManager
    var onDateDoubleTapped: (Date) -> Void
    
    @State private var currentMonth: Date = Date()
    @State private var showYearPicker = false
    
    let days: [String] = ["日", "一", "二", "三", "四", "五", "六"]
    let columns = Array(repeating: GridItem(.flexible()), count: 7)
    
    var body: some View {
        VStack(spacing: 20) {
            HStack {
                Button(action: { currentMonth = getPreviousMonth() }) {
                    Image(systemName: "chevron.left")
                }
                Spacer()
                
                Button(action: { showYearPicker = true }) {
                    Text(extractYearMonth())
                        .font(.title2.bold())
                }
                .sheet(isPresented: $showYearPicker) {
                    YearPickerView(currentDate: $currentMonth, showYearPicker: $showYearPicker)
                }
                
                Spacer()
                Button(action: { currentMonth = getNextMonth() }) {
                    Image(systemName: "chevron.right")
                }
            }
            .padding(.horizontal)
            
            HStack {
                ForEach(days, id: \.self) { day in
                    Text(day)
                        .font(.callout)
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                }
            }
            
            LazyVGrid(columns: columns, spacing: 0) {
                ForEach(extractDates()) { dateValue in
                    DayCell(dateValue: dateValue, 
                            selectedDate: $selectedDate, 
                            dataManager: dataManager,
                            onDateDoubleTapped: onDateDoubleTapped)
                        .frame(height: 40)
                }
            }
        }
    }
    
    func extractDates() -> [DateValue] {
        let calendar = Calendar.current
        
        guard let currentMonth = calendar.dateInterval(of: .month, for: self.currentMonth) else {
            return []
        }
        
        let monthStart = currentMonth.start
        let monthEnd = currentMonth.end
        
        let numberOfDays = calendar.dateComponents([.day], from: monthStart, to: monthEnd).day ?? 0
        
        let firstWeekday = calendar.component(.weekday, from: monthStart)
        
        var days: [DateValue] = []
        
        // Add empty cells for days before the first of the month
        for _ in 1..<firstWeekday {
            days.append(DateValue(day: -1, date: Date()))
        }
        
        // Add cells for each day of the month
        for day in 1...numberOfDays {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: monthStart) {
                days.append(DateValue(day: day, date: date))
            }
        }
        
        // Add empty cells to complete the last week if needed
        while days.count % 7 != 0 {
            days.append(DateValue(day: -1, date: Date()))
        }
        
        return days
    }
    
    func extractYearMonth() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "YYYY年MM月"
        return formatter.string(from: currentMonth)
    }
    
    func getPreviousMonth() -> Date {
        let calendar = Calendar.current
        return calendar.date(byAdding: .month, value: -1, to: currentMonth)!
    }
    
    func getNextMonth() -> Date {
        let calendar = Calendar.current
        return calendar.date(byAdding: .month, value: 1, to: currentMonth)!
    }
}

struct YearPickerView: View {
    @Binding var currentDate: Date
    @Binding var showYearPicker: Bool
    
    @State private var selectedYear: Int
    @State private var selectedMonth: Int
    
    init(currentDate: Binding<Date>, showYearPicker: Binding<Bool>) {
        _currentDate = currentDate
        _showYearPicker = showYearPicker
        
        let calendar = Calendar.current
        _selectedYear = State(initialValue: calendar.component(.year, from: currentDate.wrappedValue))
        _selectedMonth = State(initialValue: calendar.component(.month, from: currentDate.wrappedValue))
    }
    
    var body: some View {
        NavigationView {
            Form {
                Picker("年份", selection: $selectedYear) {
                    ForEach((1970...2070), id: \.self) { year in
                        Text(String(year)).tag(year)
                    }
                }
                
                Picker("月份", selection: $selectedMonth) {
                    ForEach(1...12, id: \.self) { month in
                        Text(String(format: "%02d", month)).tag(month)
                    }
                }
            }
            .navigationTitle("選擇年月")
            .navigationBarItems(trailing: Button("確定") {
                if let newDate = Calendar.current.date(from: DateComponents(year: selectedYear, month: selectedMonth, day: 1)) {
                    currentDate = newDate
                }
                showYearPicker = false
            })
        }
    }
}

struct DayCell: View {
    let dateValue: DateValue
    @Binding var selectedDate: Date
    @ObservedObject var dataManager: DataManager
    var onDateDoubleTapped: (Date) -> Void
    
    @State private var lastTapTime: Date?
    @State private var lastTappedDate: Date?
    
    var body: some View {
        VStack {
            if dateValue.day != -1 {
                Text("\(dateValue.day)")
                    .font(isSelectedDate() ? .body.bold() : .body)
                    .foregroundColor(getCellColor())
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(
                        Circle()
                            .fill(isSelectedDate() ? Color.blue.opacity(0.3) : Color.clear)
                            .frame(width: 32, height: 32)
                    )
            } else {
                Color.clear
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            let now = Date()
            
            if let lastTap = lastTapTime,
               let lastDate = lastTappedDate,
               now.timeIntervalSince(lastTap) < 0.5 &&
               Calendar.current.isDate(lastDate, inSameDayAs: dateValue.date) {
                // Double tap detected on the same date
                onDateDoubleTapped(dateValue.date)
                lastTapTime = nil
                lastTappedDate = nil
            } else {
                // Single tap or first tap of a potential double tap
                selectedDate = dateValue.date
                lastTapTime = now
                lastTappedDate = dateValue.date
            }
        }
    }
    
    private func isSelectedDate() -> Bool {
        return Calendar.current.isDate(dateValue.date, inSameDayAs: selectedDate)
    }
    
    private func hasTrainingLog() -> Bool {
        return dataManager.trainingLogs.contains { log in
            Calendar.current.isDate(log.date, inSameDayAs: dateValue.date)
        }
    }
    
    private func getCellColor() -> Color {
        if isSelectedDate() {
            return .primary
        } else if hasTrainingLog() {
            return .orange
        } else {
            return .primary
        }
    }
}

struct DateValue: Identifiable {
    var id = UUID()
    var day: Int
    var date: Date
}


