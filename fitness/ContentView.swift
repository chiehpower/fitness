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
    @EnvironmentObject private var appState: AppState
    @StateObject private var dataManager = DataManager()
    @State private var isWelcomeActive = true
    @State private var selection = 0

    var body: some View {
        Group {
            if isWelcomeActive {
                WelcomeView(isWelcomeActive: $isWelcomeActive)
            } else {
                TabView(selection: $selection) {
                    NavigationView {
                        TrainingLogView(dataManager: dataManager)
                    }
                    .tabItem {
                        Image(systemName: "calendar")
                        Text("運動")
                    }
                    .tag(0)
                    
                    NavigationView {
                        EquipmentListView(dataManager: dataManager)
                    }
                    .tabItem {
                        Image(systemName: "dumbbell.fill")
                        Text("器材")
                    }
                    .tag(1)

                    NavigationView {
                        AnalysisView(dataManager: dataManager)
                    }
                    .tabItem {
                        Image(systemName: "chart.bar.xaxis")
                        Text("分析")
                    }
                    .tag(2)

                    SettingsView(dataManager: dataManager)
                    .tabItem {
                        Image(systemName: "gearshape.fill")
                        Text("設定")
                    }
                    .tag(3)
                }
            }
        }
        .animation(.easeInOut, value: isWelcomeActive)
        .accentColor(.customAccent)
        .onChange(of: appState.shouldShowAddTrainingSet) { _, newValue in
            if newValue {
                isWelcomeActive = false
                selection = 0
            }
        }
    }
}


// 預覽
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

struct AnalysisView: View {
    @ObservedObject var dataManager: DataManager
    @State private var selectedRange: AnalysisRange = .week

    private let cardCornerRadius: CGFloat = 16

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                rangePicker

                summaryCardsSection
                weightTrendSection
                muscleDistributionSection
                insightSection
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 32)
        }
        .background(Color(UIColor.systemGroupedBackground))
        .navigationTitle("數據分析")
    }

    private var rangePicker: some View {
        Picker("區間", selection: $selectedRange) {
            ForEach(AnalysisRange.allCases, id: \.self) { range in
                Text(range.title).tag(range)
            }
        }
        .pickerStyle(SegmentedPickerStyle())
    }

    private var summaryCardsSection: some View {
        let currentLogs = filteredLogs()
        let currentTrainingDays = totalTrainingDays(in: currentLogs)
        let currentSets = totalSetCount(in: currentLogs)
        let previousLogs = previousLogs()
        let previousTrainingDays = totalTrainingDays(in: previousLogs)
        let previousSets = totalSetCount(in: previousLogs)

        return LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
            summaryCard(
                title: "\(selectedRange.title)訓練天數",
                iconName: "calendar",
                value: "\(currentTrainingDays)",
                unit: "天",
                trend: trendLabel(current: currentTrainingDays, previous: previousTrainingDays)
            )

            summaryCard(
                title: "總組數",
                iconName: "figure.strengthtraining.traditional",
                value: "\(currentSets)",
                unit: "組",
                trend: trendLabel(current: currentSets, previous: previousSets)
            )
        }
    }

    private var weightTrendSection: some View {
        let points = weightTrendPoints()
        let maxWeight = points.map { $0.value }.max() ?? 0
        return VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("重量成長趨勢")
                        .font(.headline)
                    Text(weightTrendSubtitle())
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    Text(weightHighlightText(maxWeight))
                        .font(.title3.bold())
                        .foregroundColor(.customAccent)
                    Text(maxWeight > 0 ? "PR 突破" : "尚無數據")
                        .font(.caption2.bold())
                        .foregroundColor(maxWeight > 0 ? .green : .secondary)
                }
            }

            WeightTrendChart(points: points, accentColor: .customAccent)
                .frame(height: 160)

            HStack {
                ForEach(points) { point in
                    Text(point.label)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    if point.id != points.last?.id {
                        Spacer()
                    }
                }
            }
        }
        .padding(16)
        .background(Color(UIColor.systemBackground))
        .cornerRadius(cardCornerRadius)
        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 6)
    }

    private var muscleDistributionSection: some View {
        let segments = muscleDistributionSegments()
        let totalPercentage = segments.reduce(0.0) { $0 + $1.percentage }
        return VStack(alignment: .leading, spacing: 16) {
            Text("部位訓練分佈")
                .font(.headline)

            HStack(spacing: 20) {
                DonutChartView(segments: segments, accentColor: .customAccent)
                    .frame(width: 120, height: 120)
                    .overlay {
                        VStack(spacing: 4) {
                            Text("總計")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            Text(totalPercentage == 0 ? "0%" : "100%")
                                .font(.headline)
                        }
                    }

                VStack(alignment: .leading, spacing: 10) {
                    if segments.isEmpty {
                        Text("尚無訓練紀錄")
                            .foregroundColor(.secondary)
                            .font(.caption)
                    } else {
                        ForEach(segments) { segment in
                            HStack {
                                HStack(spacing: 8) {
                                    Circle()
                                        .fill(segment.color)
                                        .frame(width: 8, height: 8)
                                    Text(segment.name)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                                Text(String(format: "%.0f%%", segment.percentage))
                                    .font(.caption.bold())
                            }
                        }
                    }
                }
            }
        }
        .padding(16)
        .background(Color(UIColor.systemBackground))
        .cornerRadius(cardCornerRadius)
        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 6)
    }

    private var insightSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: "lightbulb")
                    .foregroundColor(.customAccent)
                VStack(alignment: .leading, spacing: 6) {
                    Text("訓練洞察")
                        .font(.subheadline.bold())
                        .foregroundColor(.customAccent)
                    Text(insightText())
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .padding(16)
        .background(Color.customAccent.opacity(0.12))
        .cornerRadius(cardCornerRadius)
        .overlay(
            RoundedRectangle(cornerRadius: cardCornerRadius)
                .stroke(Color.customAccent.opacity(0.2), lineWidth: 1)
        )
    }

    private func summaryCard(title: String, iconName: String, value: String, unit: String, trend: TrendLabel?) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: iconName)
                    .font(.caption)
                    .foregroundColor(.customAccent)
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(value)
                    .font(.title2.bold())
                Text(unit)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            if let trend = trend {
                HStack(spacing: 4) {
                    Image(systemName: trend.isPositive ? "arrow.up" : "arrow.down")
                    Text(trend.text)
                }
                .font(.caption2.bold())
                .foregroundColor(trend.isPositive ? .green : .orange)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background((trend.isPositive ? Color.green : Color.orange).opacity(0.12))
                .cornerRadius(12)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(UIColor.systemBackground))
        .cornerRadius(cardCornerRadius)
        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 6)
    }

    private func filteredLogs() -> [TrainingLog] {
        guard let interval = selectedRange.dateInterval() else {
            return dataManager.trainingLogs
        }
        return dataManager.trainingLogs.filter { interval.contains($0.date) }
    }

    private func previousLogs() -> [TrainingLog] {
        guard let interval = selectedRange.previousDateInterval() else {
            return []
        }
        return dataManager.trainingLogs.filter { interval.contains($0.date) }
    }

    private func totalTrainingDays(in logs: [TrainingLog]) -> Int {
        logs.filter { !$0.sets.isEmpty }.count
    }

    private func totalSetCount(in logs: [TrainingLog]) -> Int {
        logs.reduce(0) { partial, log in
            partial + log.sets.reduce(0) { $0 + $1.sets.count }
        }
    }

    private func trendLabel(current: Int, previous: Int) -> TrendLabel? {
        guard previous > 0 else {
            return nil
        }
        let change = (Double(current) - Double(previous)) / Double(previous)
        let percentage = abs(change) * 100
        return TrendLabel(text: String(format: "%.0f%%", percentage), isPositive: change >= 0)
    }

    private func weightTrendPoints() -> [TrendPoint] {
        let calendar = Calendar.current
        let now = Date()
        let logs = lastSixMonthsLogs()
        let equipmentName = mostUsedEquipmentName(in: logs)

        return (0..<6).map { index in
            let monthDate = calendar.date(byAdding: .month, value: -(5 - index), to: now) ?? now
            let label = monthLabel(for: monthDate)
            let value = maxWeight(for: monthDate, equipmentName: equipmentName, in: logs)
            return TrendPoint(label: label, value: value)
        }
    }

    private func lastSixMonthsLogs() -> [TrainingLog] {
        let calendar = Calendar.current
        guard let start = calendar.date(byAdding: .month, value: -5, to: Date()) else {
            return dataManager.trainingLogs
        }
        return dataManager.trainingLogs.filter { $0.date >= start }
    }

    private func mostUsedEquipmentName(in logs: [TrainingLog]) -> String? {
        var counts: [String: Int] = [:]
        for log in logs {
            for set in log.sets {
                counts[set.equipment.name, default: 0] += set.sets.count
            }
        }
        return counts.sorted { $0.value > $1.value }.first?.key
    }

    private func maxWeight(for monthDate: Date, equipmentName: String?, in logs: [TrainingLog]) -> Double {
        guard let equipmentName = equipmentName else {
            return 0
        }
        let calendar = Calendar.current
        guard let monthInterval = calendar.dateInterval(of: .month, for: monthDate) else {
            return 0
        }
        let weights = logs
            .filter { monthInterval.contains($0.date) }
            .flatMap { $0.sets }
            .filter { $0.equipment.name == equipmentName }
            .flatMap { $0.sets }
            .map { $0.weight }
        return weights.max() ?? 0
    }

    private func monthLabel(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_TW")
        formatter.dateFormat = "M月"
        return formatter.string(from: date)
    }

    private func weightTrendSubtitle() -> String {
        if let name = mostUsedEquipmentName(in: lastSixMonthsLogs()) {
            return "\(name) · 過去 6 個月"
        }
        return "尚無器材資料"
    }

    private func weightHighlightText(_ value: Double) -> String {
        if value > 0 {
            return String(format: "%.0fkg", value)
        }
        return "--"
    }

    private func muscleDistributionSegments() -> [MuscleSegment] {
        var counts: [String: Int] = [:]
        for log in filteredLogs() {
            for set in log.sets {
                counts[muscleDistributionName(for: set), default: 0] += set.sets.count
            }
        }

        let total = counts.values.reduce(0, +)
        guard total > 0 else {
            return []
        }

        let colors: [Color] = [
            .customAccent,
            Color(UIColor.systemIndigo),
            Color(UIColor.systemOrange),
            Color(UIColor.systemPink)
        ]

        return counts
            .sorted { $0.value > $1.value }
            .prefix(4)
            .enumerated()
            .map { index, item in
                let percentage = Double(item.value) / Double(total) * 100
                return MuscleSegment(name: item.key, percentage: percentage, color: colors[index % colors.count])
            }
    }

    private func muscleDistributionName(for trainingSet: TrainingSet) -> String {
        if let subMuscle = trainingSet.subMuscle?.trimmingCharacters(in: .whitespacesAndNewlines),
           !subMuscle.isEmpty {
            return subMuscle
        }

        let mainMuscle = trainingSet.mainMuscle.trimmingCharacters(in: .whitespacesAndNewlines)
        if !mainMuscle.isEmpty {
            return mainMuscle
        }

        let equipmentMainPart = trainingSet.equipment.mainPart.trimmingCharacters(in: .whitespacesAndNewlines)
        if !equipmentMainPart.isEmpty {
            return equipmentMainPart
        }

        return "未分類"
    }

    private func insightText() -> String {
        let current = totalTrainingDays(in: filteredLogs())
        let previous = totalTrainingDays(in: previousLogs())
        guard previous > 0 else {
            return "目前的訓練資料還不多，持續紀錄就能看到更完整的趨勢。"
        }
        let change = (Double(current) - Double(previous)) / Double(previous)
        let percentage = abs(change) * 100
        let currentLabel = selectedRange.title
        let previousLabel = selectedRange.previousTitle
        if change >= 0 {
            return String(format: "你%@的訓練頻率比%@提升了 %.0f%%。目前節奏不錯，記得把恢復和強度一起安排好。", currentLabel, previousLabel, percentage)
        }
        return String(format: "你%@的訓練頻率比%@下降了 %.0f%%。可以先固定每週幾天開練，慢慢把節奏拉回來。", currentLabel, previousLabel, percentage)
    }
}

private struct TrendLabel {
    let text: String
    let isPositive: Bool
}

private struct TrendPoint: Identifiable {
    let id = UUID()
    let label: String
    let value: Double
}

private struct MuscleSegment: Identifiable {
    let id = UUID()
    let name: String
    let percentage: Double
    let color: Color
}

private struct WeightTrendChart: View {
    let points: [TrendPoint]
    let accentColor: Color

    var body: some View {
        GeometryReader { geometry in
            let maxValue = points.map { $0.value }.max() ?? 0
            let height = geometry.size.height
            let width = geometry.size.width
            let step = points.count > 1 ? width / CGFloat(points.count - 1) : 0

            let mappedPoints = points.enumerated().map { index, point in
                CGPoint(
                    x: CGFloat(index) * step,
                    y: yPosition(for: point.value, maxValue: maxValue, height: height)
                )
            }

            ZStack {
                if mappedPoints.count > 1 {
                    Path { path in
                        path.move(to: CGPoint(x: mappedPoints.first?.x ?? 0, y: height))
                        for point in mappedPoints {
                            path.addLine(to: point)
                        }
                        path.addLine(to: CGPoint(x: mappedPoints.last?.x ?? 0, y: height))
                        path.closeSubpath()
                    }
                    .fill(
                        LinearGradient(
                            colors: [accentColor.opacity(0.2), accentColor.opacity(0.0)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )

                    Path { path in
                        guard let first = mappedPoints.first else {
                            return
                        }
                        path.move(to: first)
                        for point in mappedPoints.dropFirst() {
                            path.addLine(to: point)
                        }
                    }
                    .stroke(accentColor, style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))

                    ForEach(mappedPoints.indices, id: \.self) { index in
                        let point = mappedPoints[index]
                        Circle()
                            .fill(accentColor)
                            .frame(width: index == mappedPoints.count - 1 ? 9 : 6, height: index == mappedPoints.count - 1 ? 9 : 6)
                            .overlay(Circle().stroke(Color.white, lineWidth: 2))
                            .position(point)
                    }
                } else {
                    Rectangle()
                        .fill(Color(UIColor.systemGray5))
                }
            }
        }
    }

    private func yPosition(for value: Double, maxValue: Double, height: CGFloat) -> CGFloat {
        guard maxValue > 0 else {
            return height * 0.75
        }
        let normalized = value / maxValue
        return height * (0.15 + (1 - normalized) * 0.7)
    }
}

private struct DonutChartView: View {
    let segments: [MuscleSegment]
    let accentColor: Color

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color(UIColor.systemGray5), lineWidth: 10)

            ForEach(Array(segments.enumerated()), id: \.element.id) { index, segment in
                Circle()
                    .trim(from: startPoint(for: index), to: endPoint(for: index))
                    .stroke(segment.color, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                    .rotationEffect(.degrees(-90))
            }
        }
    }

    private func startPoint(for index: Int) -> CGFloat {
        let total = segments.reduce(0.0) { $0 + $1.percentage }
        guard total > 0 else {
            return 0
        }
        let previous = segments.prefix(index).reduce(0.0) { $0 + $1.percentage }
        return CGFloat(previous / total)
    }

    private func endPoint(for index: Int) -> CGFloat {
        let total = segments.reduce(0.0) { $0 + $1.percentage }
        guard total > 0 else {
            return 0
        }
        let current = segments.prefix(index + 1).reduce(0.0) { $0 + $1.percentage }
        return CGFloat(current / total)
    }
}

enum AnalysisRange: CaseIterable {
    case week
    case month

    var title: String {
        switch self {
        case .week:
            return "本週"
        case .month:
            return "本月"
        }
    }

    var previousTitle: String {
        switch self {
        case .week:
            return "上週"
        case .month:
            return "上月"
        }
    }

    func dateInterval(reference: Date = Date()) -> DateInterval? {
        let calendar = Calendar.current
        switch self {
        case .week:
            return calendar.dateInterval(of: .weekOfYear, for: reference)
        case .month:
            return calendar.dateInterval(of: .month, for: reference)
        }
    }

    func previousDateInterval(reference: Date = Date()) -> DateInterval? {
        let calendar = Calendar.current
        switch self {
        case .week:
            guard let current = calendar.dateInterval(of: .weekOfYear, for: reference) else {
                return nil
            }
            guard let previousStart = calendar.date(byAdding: .weekOfYear, value: -1, to: current.start) else {
                return nil
            }
            return calendar.dateInterval(of: .weekOfYear, for: previousStart)
        case .month:
            guard let current = calendar.dateInterval(of: .month, for: reference) else {
                return nil
            }
            guard let previousStart = calendar.date(byAdding: .month, value: -1, to: current.start) else {
                return nil
            }
            return calendar.dateInterval(of: .month, for: previousStart)
        }
    }
}
