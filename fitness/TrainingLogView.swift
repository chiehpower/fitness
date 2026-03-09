import SwiftUI
import UIKit

// 訓練記錄視圖
struct TrainingLogView: View {
    @EnvironmentObject private var appState: AppState
    @ObservedObject var dataManager: DataManager
    @State private var selectedDate = Date()
    @State private var showingAddSet = false
    @State private var showingCalendar = false
    
    var body: some View {
        VStack(spacing: 0) {
            headerView
                .simultaneousGesture(
                    DragGesture(minimumDistance: 20)
                        .onEnded { value in
                            handleWeekSwipe(value)
                        }
                )

            ScrollView {
                VStack(spacing: 16) {
                    daySummaryHeader

                    let groups = equipmentGroups(for: selectedDate)
                    if groups.isEmpty {
                        emptyStateCard
                    } else {
                        ForEach(groups) { group in
                            workoutCard(for: group)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 20)
            }

            NavigationLink(isActive: $showingAddSet) {
                AddTrainingSetView(
                    dataManager: dataManager,
                    date: selectedDate,
                    preselectedNfcTagId: appState.pendingNfcTagId
                )
            } label: {
                EmptyView()
            }
        }
        .background(Color(UIColor.systemGroupedBackground))
        .navigationBarHidden(true)
        .safeAreaInset(edge: .bottom) {
            Button(action: {
                showingAddSet = true
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "figure.strengthtraining.traditional")
                    Text("開始新動作")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color.customAccent)
                .foregroundColor(.white)
                .cornerRadius(16)
                .shadow(color: Color.customAccent.opacity(0.2), radius: 8, x: 0, y: 4)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Color(UIColor.systemGroupedBackground).opacity(0.95))
        }
        .sheet(isPresented: $showingCalendar) {
            CalendarSheetView(
                selectedDate: $selectedDate,
                dataManager: dataManager,
                isPresented: $showingCalendar
            )
        }
        .onChange(of: appState.shouldShowAddTrainingSet) { _, newValue in
            if newValue {
                selectedDate = Date()
                showingAddSet = true
            }
        }
    }

    private var headerView: some View {
        VStack(spacing: 12) {
            HStack {
                Button(action: {
                    showingCalendar = true
                }) {
                    Image(systemName: "calendar")
                        .foregroundColor(.customAccent)
                }

                Spacer()

                Text("訓練記錄")
                    .font(.headline)

                Spacer()

                Button(action: {
                    selectedDate = Date()
                }) {
                    Text("今天")
                        .font(.subheadline.bold())
                        .foregroundColor(Calendar.current.isDateInToday(selectedDate) ? .secondary : .customAccent)
                }
                .disabled(Calendar.current.isDateInToday(selectedDate))

                Button(action: {
                    showingAddSet = true
                }) {
                    Image(systemName: "calendar.badge.plus")
                        .foregroundColor(.customAccent)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)

            weekStrip
        }
        .background(Color.white.opacity(0.9))
    }

    private var weekStrip: some View {
        GeometryReader { geometry in
            let totalSpacing: CGFloat = 8 * 6
            let totalPadding: CGFloat = 32
            let cellWidth = max(36, (geometry.size.width - totalSpacing - totalPadding) / 7)

            HStack(spacing: 8) {
                ForEach(weekDates(for: selectedDate), id: \.self) { date in
                    let isSelected = Calendar.current.isDate(date, inSameDayAs: selectedDate)
                    VStack(spacing: 4) {
                        Text(weekdayString(for: date))
                            .font(.caption2)
                            .foregroundColor(isSelected ? .white.opacity(0.8) : .secondary)
                        Text("\(Calendar.current.component(.day, from: date))")
                            .font(.subheadline.bold())
                            .foregroundColor(isSelected ? .white : .primary)
                    }
                    .frame(width: cellWidth, height: 60)
                    .background(isSelected ? Color.customAccent : Color.white)
                    .cornerRadius(14)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(Color.gray.opacity(0.15), lineWidth: isSelected ? 0 : 1)
                    )
                    .shadow(color: isSelected ? Color.customAccent.opacity(0.2) : Color.clear, radius: 4, x: 0, y: 2)
                    .onTapGesture {
                        selectedDate = date
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 12)
        }
        .frame(height: 72)
    }

    private var daySummaryHeader: some View {
        HStack {
            Text("今日訓練內容")
                .font(.title3.bold())
            Spacer()
            Text(formatDaySummaryDate(selectedDate))
                .font(.footnote)
                .foregroundColor(.secondary)
        }
    }

    private var emptyStateCard: some View {
        HStack {
            Text("當日尚無訓練記錄")
                .foregroundColor(.secondary)
            Spacer()
        }
        .padding(.vertical, 18)
        .padding(.horizontal, 16)
        .background(Color.white)
        .cornerRadius(18)
        .shadow(color: Color.black.opacity(0.03), radius: 6, x: 0, y: 2)
    }

    private func workoutCard(for group: EquipmentGroup) -> some View {
        let sets = flattenedSets(for: group)
        let primaryMuscle = group.trainingSets.first?.mainMuscle ?? ""
        let secondaryMuscle = group.trainingSets.first?.subMuscle ?? ""
        return VStack(spacing: 0) {
            HStack(spacing: 16) {
                cardThumbnail(for: group.equipment)

                VStack(alignment: .leading, spacing: 6) {
                    Text(group.equipment.name)
                        .font(.headline)
                    HStack(spacing: 6) {
                        if !primaryMuscle.isEmpty {
                            tagView(text: primaryMuscle, color: colorForMuscle(primaryMuscle))
                        }
                        if !secondaryMuscle.isEmpty {
                            tagView(text: secondaryMuscle, color: Color(UIColor.systemGray5))
                        }
                    }
                }

                Spacer()
                Image(systemName: "ellipsis")
                    .foregroundColor(.secondary)
            }
            .padding(16)

            VStack(spacing: 0) {
                HStack {
                    tableHeader("組數")
                    tableHeader("重量 (kg)")
                    tableHeader("次數")
                    tableHeader("時間", alignRight: true)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color(UIColor.systemGray6))

                ForEach(sets.indices, id: \.self) { index in
                    let row = sets[index]
                    HStack {
                        tableCell("\(row.index)")
                        tableCell("\(formatWeight(row.weight))")
                        tableCell("\(row.reps)")
                        tableCell(row.timeString, alignRight: true, isSecondary: true)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(index == sets.count - 1 ? Color.customAccent.opacity(0.04) : Color.white)
                    if index != sets.count - 1 {
                        Divider().padding(.leading, 16)
                    }
                }
            }

            Button(action: {
                showingAddSet = true
            }) {
                HStack(spacing: 6) {
                    Image(systemName: "plus")
                    Text("新增組數")
                        .font(.caption.bold())
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.gray.opacity(0.2), style: StrokeStyle(lineWidth: 1, dash: [4]))
                )
                .foregroundColor(.customAccent)
            }
            .padding(16)
        }
        .background(Color.white)
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 3)
    }

    private func cardThumbnail(for equipment: Equipment) -> some View {
        let image = loadImage(named: equipment.imageName)
        return Group {
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                Image(systemName: "photo")
                    .resizable()
                    .scaledToFit()
                    .padding(12)
                    .foregroundColor(.secondary)
            }
        }
        .frame(width: 72, height: 72)
        .background(Color(UIColor.systemGray5))
        .cornerRadius(12)
        .clipped()
    }

    private func tableHeader(_ text: String, alignRight: Bool = false) -> some View {
        Text(text)
            .font(.caption)
            .foregroundColor(.secondary)
            .frame(maxWidth: .infinity, alignment: alignRight ? .trailing : .leading)
    }

    private func tableCell(_ text: String, alignRight: Bool = false, isSecondary: Bool = false) -> some View {
        Text(text)
            .font(.footnote)
            .foregroundColor(isSecondary ? .secondary : .primary)
            .frame(maxWidth: .infinity, alignment: alignRight ? .trailing : .leading)
    }

    private func tagView(text: String, color: Color) -> some View {
        Text(text)
            .font(.caption2.bold())
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color.opacity(0.12))
            .foregroundColor(color == Color(UIColor.systemGray5) ? .secondary : color)
            .cornerRadius(6)
    }

    private func weekDates(for date: Date) -> [Date] {
        let calendar = Calendar.current
        guard let interval = calendar.dateInterval(of: .weekOfYear, for: date) else {
            return [date]
        }
        return (0..<7).compactMap { day in
            calendar.date(byAdding: .day, value: day, to: interval.start)
        }
    }

    private func handleWeekSwipe(_ value: DragGesture.Value) {
        let horizontal = value.translation.width
        let vertical = value.translation.height
        let threshold: CGFloat = 50

        guard abs(horizontal) > abs(vertical) else {
            return
        }

        if horizontal <= -threshold {
            shiftWeek(by: 1)
        } else if horizontal >= threshold {
            shiftWeek(by: -1)
        }
    }

    private func shiftWeek(by offset: Int) {
        guard let newDate = Calendar.current.date(byAdding: .weekOfYear, value: offset, to: selectedDate) else {
            return
        }
        selectedDate = newDate
    }

    private func weekdayString(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_TW")
        formatter.dateFormat = "EEE"
        return formatter.string(from: date)
    }

    private func formatDaySummaryDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_TW")
        formatter.dateFormat = "yyyy年MM月dd日"
        return formatter.string(from: date)
    }

    private func flattenedSets(for group: EquipmentGroup) -> [SetRow] {
        var rows: [SetRow] = []
        var index = 1
        for trainingSet in group.trainingSets {
            for set in trainingSet.sets {
                rows.append(SetRow(index: index, weight: set.weight, reps: set.reps, timeString: formatTime(set.time)))
                index += 1
            }
        }
        return rows
    }

    private struct SetRow: Identifiable {
        let id = UUID()
        let index: Int
        let weight: Double
        let reps: Int
        let timeString: String
    }

    private func deleteTrainingSets(within sets: [TrainingSet], at offsets: IndexSet) {
        let idsToDelete = offsets.map { sets[$0].id }
        guard let logIndex = dataManager.trainingLogs.firstIndex(where: { Calendar.current.isDate($0.date, inSameDayAs: selectedDate) }) else {
            return
        }

        dataManager.trainingLogs[logIndex].sets.removeAll { idsToDelete.contains($0.id) }

        if dataManager.trainingLogs[logIndex].sets.isEmpty {
            dataManager.trainingLogs.remove(at: logIndex)
        }

        dataManager.saveTrainingLogs()
    }

    private func equipmentGroups(for date: Date) -> [EquipmentGroup] {
        guard let log = dataManager.trainingLogs.first(where: { Calendar.current.isDate($0.date, inSameDayAs: date) }) else {
            return []
        }

        var orderedEquipmentIds: [UUID] = []
        for set in log.sets where !orderedEquipmentIds.contains(set.equipment.id) {
            orderedEquipmentIds.append(set.equipment.id)
        }

        return orderedEquipmentIds.compactMap { equipmentId in
            let sets = log.sets.filter { $0.equipment.id == equipmentId }
            guard let equipment = sets.first?.equipment else {
                return nil
            }
            return EquipmentGroup(id: equipment.id, equipment: equipment, trainingSets: sets)
        }
    }

    private func trainingListView(for date: Date) -> some View {
        List {
            let groups = equipmentGroups(for: date)
            if groups.isEmpty {
                Text("當日尚無訓練記錄")
                    .foregroundColor(.secondary)
                    .listRowInsets(EdgeInsets(top: 16, leading: 16, bottom: 8, trailing: 16))
            }

            ForEach(groups) { group in
                Section(header: equipmentHeader(group.equipment)) {
                    ForEach(group.trainingSets.indices, id: \.self) { trainingSetIndex in
                        let trainingSet = group.trainingSets[trainingSetIndex]
                        let startingIndex = group.trainingSets.prefix(trainingSetIndex).reduce(0) { $0 + $1.sets.count }
                        VStack(alignment: .leading, spacing: 6) {
                            ForEach(trainingSet.sets.indices, id: \.self) { index in
                                let set = trainingSet.sets[index]
                                HStack {
                                    Text("第 \(startingIndex + index + 1) 組")
                                        .font(.subheadline)
                                    Spacer()
                                    Text("\(set.reps) 次")
                                    Text("\(formatWeight(set.weight)) \(set.weightUnit)")
                                    if set.time > 0 {
                                        Text(formatTime(set.time))
                                    }
                                }
                            }
                            HStack(spacing: 6) {
                                Text(trainingSet.mainMuscle)
                                    .font(.caption)
                                    .padding(4)
                                    .background(colorForMuscle(trainingSet.mainMuscle).opacity(0.2))
                                    .cornerRadius(6)
                                if let subMuscle = trainingSet.subMuscle, !subMuscle.isEmpty {
                                    Text(subMuscle)
                                        .font(.caption)
                                        .padding(4)
                                        .background(colorForMuscle(subMuscle).opacity(0.2))
                                        .cornerRadius(6)
                                }
                                if let variant = trainingSet.variant, !variant.isEmpty {
                                    Text(variant)
                                        .font(.caption)
                                        .padding(4)
                                        .background(Color(UIColor.secondarySystemBackground))
                                        .cornerRadius(6)
                                }
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    .onDelete { indexSet in
                        deleteTrainingSets(within: group.trainingSets, at: indexSet)
                    }
                }
            }
        }
    }

    private func equipmentHeader(_ equipment: Equipment) -> some View {
        HStack(alignment: .top, spacing: 10) {
            equipmentThumbnail(for: equipment)

            VStack(alignment: .leading, spacing: 6) {
                Text(equipment.name)
                    .font(.headline)
                Text(equipment.location ?? "未設定")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .textCase(nil)
        .padding(.vertical, 4)
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM月dd日 EEEE"
        formatter.locale = Locale(identifier: "zh_TW")
        return formatter.string(from: date)
    }

    private func equipmentThumbnail(for equipment: Equipment) -> some View {
        let image = loadImage(named: equipment.imageName)
        return Group {
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                Image(systemName: "dumbbell.fill")
                    .resizable()
                    .scaledToFit()
                    .padding(8)
                    .foregroundColor(.secondary)
            }
        }
        .frame(width: 44, height: 44)
        .background(Color(UIColor.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private func loadImage(named imageName: String?) -> UIImage? {
        guard let imageName = imageName else {
            return nil
        }
        guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return nil
        }
        let fileURL = documentsDirectory.appendingPathComponent(imageName)
        return UIImage(contentsOfFile: fileURL.path)
    }

    private func formatWeight(_ weight: Double) -> String {
        return String(format: "%.1f", weight)
    }

    private func formatTime(_ minutes: Int) -> String {
        let normalized = max(0, minutes)
        let hour = normalized / 60
        let minute = normalized % 60
        return String(format: "%02d:%02d", hour, minute)
    }

    private func colorForMuscle(_ muscleName: String) -> Color {
        if let muscle = dataManager.muscles.first(where: { $0.name == muscleName }) {
            return Color(hex: muscle.color) ?? .gray
        } else if let muscle = dataManager.muscles.first(where: { $0.subMuscles.contains(where: { $0.name == muscleName }) }),
                  let subMuscle = muscle.subMuscles.first(where: { $0.name == muscleName }) {
            return Color(hex: subMuscle.color) ?? .gray
        }
        return .gray
    }
}

struct DayDetailView<ListContent: View>: View {
    let date: Date
    let listContent: ListContent
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            listContent
                .navigationTitle(formatDate(date))
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("關閉") {
                            dismiss()
                        }
                    }
                }
        }
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM月dd日 EEEE"
        formatter.locale = Locale(identifier: "zh_TW")
        return formatter.string(from: date)
    }
}

struct EquipmentGroup: Identifiable {
    let id: UUID
    let equipment: Equipment
    let trainingSets: [TrainingSet]
}

struct CalendarSheetView: View {
    @Binding var selectedDate: Date
    @ObservedObject var dataManager: DataManager
    @Binding var isPresented: Bool

    var body: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                HStack {
                    Button("取消") {
                        isPresented = false
                    }
                    .foregroundColor(.customAccent)
                    .font(.system(size: 17, weight: .medium))

                    Spacer()

                    Text("選擇日期")
                        .font(.system(size: 17, weight: .bold))

                    Spacer()

                    Button("完成") {
                        isPresented = false
                    }
                    .foregroundColor(.customAccent)
                    .font(.system(size: 17, weight: .semibold))
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .background(Color(UIColor.systemBackground))
                .overlay(
                    Rectangle()
                        .frame(height: 1)
                        .foregroundColor(Color(UIColor.separator)),
                    alignment: .bottom
                )

                CustomDatePicker(
                    selectedDate: $selectedDate,
                    dataManager: dataManager,
                    onDateDoubleTapped: { date in
                        selectedDate = date
                        isPresented = false
                    }
                )
                .padding(.vertical, 20)
                .padding(.horizontal, 20)
            }
            .background(Color(UIColor.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
            .padding(.horizontal, 16)
            .shadow(color: Color.black.opacity(0.18), radius: 24, x: 0, y: 16)
        }
    }
}

struct CustomDatePicker: View {
    @Binding var selectedDate: Date
    @ObservedObject var dataManager: DataManager
    var onDateDoubleTapped: (Date) -> Void
    
    @State private var currentMonth: Date = Date()
    
    let days: [String] = ["SUN", "MON", "TUE", "WED", "THU", "FRI", "SAT"]
    let columns = Array(repeating: GridItem(.flexible()), count: 7)
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text(extractYearMonth())
                    .font(.system(size: 20, weight: .bold))
                Spacer()
                HStack(spacing: 16) {
                    Button(action: { currentMonth = getPreviousMonth() }) {
                        Image(systemName: "chevron.left")
                            .foregroundColor(.customAccent)
                    }
                    Button(action: { currentMonth = getNextMonth() }) {
                        Image(systemName: "chevron.right")
                            .foregroundColor(.customAccent)
                    }
                }
            }

            HStack {
                ForEach(days, id: \.self) { day in
                    Text(day)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }

            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(extractDates()) { dateValue in
                    DayCell(
                        dateValue: dateValue,
                        selectedDate: $selectedDate,
                        dataManager: dataManager,
                        onDateDoubleTapped: onDateDoubleTapped
                    )
                }
            }
        }
        .onAppear {
            currentMonth = selectedDate
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

        if let previousMonth = calendar.date(byAdding: .month, value: -1, to: monthStart),
           let previousInterval = calendar.dateInterval(of: .month, for: previousMonth) {
            let previousMonthDays = calendar.dateComponents([.day], from: previousInterval.start, to: previousInterval.end).day ?? 0
            let leadingDays = max(0, firstWeekday - 1)
            if leadingDays > 0 {
                let startDay = previousMonthDays - leadingDays + 1
                for day in startDay...previousMonthDays {
                    if let date = calendar.date(byAdding: .day, value: day - 1, to: previousInterval.start) {
                        days.append(DateValue(day: day, date: date, isCurrentMonth: false))
                    }
                }
            }
        }

        for day in 1...numberOfDays {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: monthStart) {
                days.append(DateValue(day: day, date: date, isCurrentMonth: true))
            }
        }

        let remainder = days.count % 7
        if remainder != 0 {
            let needed = 7 - remainder
            for day in 1...needed {
                if let date = calendar.date(byAdding: .day, value: day - 1, to: monthEnd) {
                    days.append(DateValue(day: day, date: date, isCurrentMonth: false))
                }
            }
        }

        return days
    }
    
    func extractYearMonth() -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US")
        formatter.dateFormat = "MMMM yyyy"
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

struct DayCell: View {
    let dateValue: DateValue
    @Binding var selectedDate: Date
    @ObservedObject var dataManager: DataManager
    var onDateDoubleTapped: (Date) -> Void

    @State private var lastTapTime: Date?
    @State private var lastTappedDate: Date?

    var body: some View {
        Button(action: handleTap) {
            Text("\(dateValue.day)")
                .font(.system(size: 14, weight: isSelectedDate() ? .bold : .medium))
                .foregroundColor(textColor())
                .frame(maxWidth: .infinity, minHeight: 36)
                .background(
                    Circle()
                        .fill(isSelectedDate() ? Color.customAccent : Color.clear)
                        .frame(width: 36, height: 36)
                )
                .overlay(alignment: .bottom) {
                    if hasTrainingLog() && !isSelectedDate() {
                        Circle()
                            .fill(Color.customAccent.opacity(0.6))
                            .frame(width: 4, height: 4)
                            .offset(y: 6)
                    }
                }
        }
        .buttonStyle(.plain)
    }

    private func handleTap() {
        let now = Date()

        if let lastTap = lastTapTime,
           let lastDate = lastTappedDate,
           now.timeIntervalSince(lastTap) < 0.5 &&
           Calendar.current.isDate(lastDate, inSameDayAs: dateValue.date) {
            onDateDoubleTapped(dateValue.date)
            lastTapTime = nil
            lastTappedDate = nil
        } else {
            selectedDate = dateValue.date
            lastTapTime = now
            lastTappedDate = dateValue.date
        }
    }

    private func isSelectedDate() -> Bool {
        Calendar.current.isDate(dateValue.date, inSameDayAs: selectedDate)
    }

    private func hasTrainingLog() -> Bool {
        dataManager.trainingLogs.contains { log in
            Calendar.current.isDate(log.date, inSameDayAs: dateValue.date)
        }
    }

    private func textColor() -> Color {
        if isSelectedDate() {
            return .white
        }
        return dateValue.isCurrentMonth ? .primary : .secondary
    }
}

struct DateValue: Identifiable {
    var id = UUID()
    var day: Int
    var date: Date
    var isCurrentMonth: Bool
}
