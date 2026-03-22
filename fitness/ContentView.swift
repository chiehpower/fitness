import SwiftUI
import Combine

class AnalysisViewModel: ObservableObject {
    @Published var selectedRange: AnalysisRange = .week
    @Published var trainingDays: Int = 0
    @Published var totalSets: Int = 0
    @Published var weightTrendPoints: [TrendPoint] = []
    @Published var maxWeight: Double = 0
    @Published var bodyPartSegments: [MuscleSegment] = []
    @Published var muscleGroupSegments: [MuscleSegment] = []
    @Published var insightText: String = ""
    @Published var trainingDaysTrend: TrendLabel? = nil
    @Published var totalSetsTrend: TrendLabel? = nil
    @Published var mostUsedEquipmentName: String? = nil
    @Published var preferredWeightUnitSuffix: String = "kg"

    func update(with dataManager: DataManager) {
        // Run on background queue to avoid stuttering during UI transitions
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            let currentLogs = self.filteredLogs(from: dataManager.trainingLogs)
            let previousLogs = self.previousLogs(from: dataManager.trainingLogs)
            
            let cTrainingDays = self.totalTrainingDays(in: currentLogs)
            let cSets = self.totalSetCount(in: currentLogs)
            let pTrainingDays = self.totalTrainingDays(in: previousLogs)
            let pSets = self.totalSetCount(in: previousLogs)
            
            let trendDays = self.trendLabel(current: cTrainingDays, previous: pTrainingDays)
            let trendSets = self.trendLabel(current: cSets, previous: pSets)
            
            let lastSixLogs = self.lastSixMonthsLogs(from: dataManager.trainingLogs)
            let mostUsedEq = self.mostUsedEquipmentName(in: lastSixLogs)
            
            let points = self.computeWeightTrendPoints(logs: lastSixLogs, equipmentName: mostUsedEq)
            let mw = points.map { $0.value }.max() ?? 0
            
            let bpSegments = self.bodyPartDistributionSegments(logs: currentLogs)
            let mgSegments = self.muscleGroupDistributionSegments(logs: currentLogs)
            
            let insight = self.computeInsightText(currentDays: cTrainingDays, previousDays: pTrainingDays)
            
            let unitSuffix = dataManager.preferredWeightUnit == .kg ? "kg" : "lb"
            
            DispatchQueue.main.async {
                self.trainingDays = cTrainingDays
                self.totalSets = cSets
                self.trainingDaysTrend = trendDays
                self.totalSetsTrend = trendSets
                
                self.weightTrendPoints = points
                self.maxWeight = mw
                self.mostUsedEquipmentName = mostUsedEq
                
                self.bodyPartSegments = bpSegments
                self.muscleGroupSegments = mgSegments
                self.insightText = insight
                self.preferredWeightUnitSuffix = unitSuffix
            }
        }
    }
    
    private func filteredLogs(from logs: [TrainingLog]) -> [TrainingLog] {
        guard let interval = selectedRange.dateInterval() else { return logs }
        return logs.filter { interval.contains($0.date) }
    }

    private func previousLogs(from logs: [TrainingLog]) -> [TrainingLog] {
        guard let interval = selectedRange.previousDateInterval() else { return [] }
        return logs.filter { interval.contains($0.date) }
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
        guard previous > 0 else { return nil }
        let change = (Double(current) - Double(previous)) / Double(previous)
        let percentage = abs(change) * 100
        return TrendLabel(text: String(format: "%.0f%%", percentage), isPositive: change >= 0)
    }

    private func computeWeightTrendPoints(logs: [TrainingLog], equipmentName: String?) -> [TrendPoint] {
        let calendar = Calendar.current
        let now = Date()
        return (0..<6).map { index in
            let monthDate = calendar.date(byAdding: .month, value: -(5 - index), to: now) ?? now
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "zh_TW")
            formatter.dateFormat = "M月"
            let label = formatter.string(from: monthDate)
            
            let value = equipmentName.flatMap { name in
                guard let monthInterval = calendar.dateInterval(of: .month, for: monthDate) else { return 0.0 }
                return logs.filter { monthInterval.contains($0.date) }
                    .flatMap { $0.sets }
                    .filter { $0.equipment.name == name }
                    .flatMap { $0.sets }
                    .map { $0.weight }
                    .max()
            } ?? 0.0
            
            return TrendPoint(label: label, value: value)
        }
    }

    private func lastSixMonthsLogs(from allLogs: [TrainingLog]) -> [TrainingLog] {
        let calendar = Calendar.current
        guard let start = calendar.date(byAdding: .month, value: -5, to: Date()) else { return allLogs }
        return allLogs.filter { $0.date >= start }
    }

    private func mostUsedEquipmentName(in logs: [TrainingLog]) -> String? {
        var counts: [String: Int] = [:]
        for log in logs {
            for set in log.sets { counts[set.equipment.name, default: 0] += set.sets.count }
        }
        return counts.sorted { $0.value > $1.value }.first?.key
    }

    private func bodyPartDistributionSegments(logs: [TrainingLog]) -> [MuscleSegment] {
        var counts: [String: Int] = [:]
        for log in logs {
            for set in log.sets {
                let name = set.mainMuscle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 
                           (set.equipment.mainPart.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "未分類" : set.equipment.mainPart) : 
                           set.mainMuscle
                counts[name, default: 0] += set.sets.count
            }
        }
        return distributionSegments(from: counts)
    }

    private func muscleGroupDistributionSegments(logs: [TrainingLog]) -> [MuscleSegment] {
        var counts: [String: Int] = [:]
        for log in logs {
            for set in log.sets {
                let sm = set.subMuscle?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                let mm = set.mainMuscle.trimmingCharacters(in: .whitespacesAndNewlines)
                let em = set.equipment.mainPart.trimmingCharacters(in: .whitespacesAndNewlines)
                let name = !sm.isEmpty ? sm : (!mm.isEmpty ? mm : (!em.isEmpty ? em : "未分類"))
                counts[name, default: 0] += set.sets.count
            }
        }
        return distributionSegments(from: counts)
    }

    private func distributionSegments(from counts: [String: Int]) -> [MuscleSegment] {
        let total = counts.values.reduce(0, +)
        guard total > 0 else { return [] }
        let sortedCounts = counts.sorted { $0.value > $1.value }
        return sortedCounts.enumerated().map { index, item in
            MuscleSegment(
                name: item.key,
                percentage: Double(item.value) / Double(total) * 100,
                color: distributionColor(for: index)
            )
        }
    }

    private func distributionColor(for index: Int) -> Color {
        let palette: [Color] = [
            Color(red: 0.73, green: 0.59, blue: 0.57), Color(red: 0.61, green: 0.68, blue: 0.78),
            Color(red: 0.77, green: 0.69, blue: 0.52), Color(red: 0.59, green: 0.71, blue: 0.64),
            Color(red: 0.69, green: 0.62, blue: 0.78), Color(red: 0.80, green: 0.63, blue: 0.68),
            Color(red: 0.55, green: 0.63, blue: 0.59), Color(red: 0.84, green: 0.74, blue: 0.60),
            Color(red: 0.63, green: 0.58, blue: 0.54), Color(red: 0.67, green: 0.75, blue: 0.72),
            Color(red: 0.75, green: 0.66, blue: 0.72), Color(red: 0.57, green: 0.60, blue: 0.72)
        ]
        return palette[index % palette.count]
    }

    private func computeInsightText(currentDays: Int, previousDays: Int) -> String {
        guard previousDays > 0 else {
            return NSLocalizedString("目前的訓練資料還不多，持續紀錄就能看到更完整的趨勢。", comment: "")
        }
        let change = (Double(currentDays) - Double(previousDays)) / Double(previousDays)
        let percentage = abs(change) * 100
        let currentLabel = selectedRange.title
        let previousLabel = selectedRange.previousTitle
        if change >= 0 {
            return String(format: NSLocalizedString("你%@的訓練頻率比%@提升了 %.0f%%。目前節奏不錯，記得把恢復和強度一起安排好。", comment: ""), currentLabel, previousLabel, percentage)
        }
        return String(format: NSLocalizedString("你%@的訓練頻率比%@下降了 %.0f%%。可以先固定每週幾天開練，慢慢把節奏拉回來。", comment: ""), currentLabel, previousLabel, percentage)
    }
}

struct WelcomeView: View {
    @Binding var isWelcomeActive: Bool
    @State private var appearAnimation: Double = 0
    
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
                .shadow(color: .black.opacity(0.1), radius: 16, x: 0, y: 8)
                .overlay(
                    RoundedRectangle(cornerRadius: 40)
                        .stroke(Color.gray.opacity(0.15), lineWidth: 0.5)
                )
                .scaleEffect(0.8 + (appearAnimation * 0.2))
                .opacity(appearAnimation)

                Text("Your Personal Fitness Recorder")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .padding(.top, 50)
                    .opacity(appearAnimation)
                    .offset(y: 20 - (appearAnimation * 20))

                
                Text("Enjoy your fitness journey")
                    .font(.subheadline)
                    .padding(.top, 5)
                    .opacity(appearAnimation)
                    .offset(y: 20 - (appearAnimation * 20))

                Spacer()

                Text("© 2024 Chieh All Rights Reserved")
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
                    .padding(.bottom, 20)
                    .opacity(appearAnimation)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.7, dampingFraction: 0.6)) {
                self.appearAnimation = 1.0
            }
            
            // 3秒后自动跳转到主页面
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
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
    @StateObject private var viewModel = AnalysisViewModel()

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
        .onAppear {
            viewModel.update(with: dataManager)
        }
        .onChange(of: dataManager.trainingLogs.count) { _ in
            viewModel.update(with: dataManager)
        }
    }

    private var rangePicker: some View {
        Picker("區間", selection: $viewModel.selectedRange) {
            ForEach(AnalysisRange.allCases, id: \.self) { range in
                Text(range.title).tag(range)
            }
        }
        .pickerStyle(SegmentedPickerStyle())
        .onChange(of: viewModel.selectedRange) { _ in
            viewModel.update(with: dataManager)
        }
    }

    private var summaryCardsSection: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
            summaryCard(
                title: "\(viewModel.selectedRange.title)訓練天數",
                iconName: "calendar",
                value: "\(viewModel.trainingDays)",
                unit: "天",
                trend: viewModel.trainingDaysTrend
            )

            summaryCard(
                title: "總組數",
                iconName: "figure.strengthtraining.traditional",
                value: "\(viewModel.totalSets)",
                unit: "組",
                trend: viewModel.totalSetsTrend
            )
        }
    }

    private var weightTrendSection: some View {
        let maxWeight = viewModel.maxWeight
        return VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("重量成長趨勢")
                        .font(.headline)
                    Text(weightTrendSubtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    Text(weightHighlightText)
                        .font(.title3.bold())
                        .foregroundColor(.customAccent)
                    Text(maxWeight > 0 ? "PR 突破" : "尚無數據")
                        .font(.caption2.bold())
                        .foregroundColor(maxWeight > 0 ? .green : .secondary)
                }
            }

            WeightTrendChart(points: viewModel.weightTrendPoints, accentColor: .customAccent)
                .frame(height: 160)

            HStack {
                ForEach(viewModel.weightTrendPoints) { point in
                    Text(point.label)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    if point.id != viewModel.weightTrendPoints.last?.id {
                        Spacer()
                    }
                }
            }
        }
        .padding(16)
        .background(Color(UIColor.systemBackground))
        .cornerRadius(cardCornerRadius)
        .shadow(color: Color.black.opacity(0.03), radius: 8, x: 0, y: 4)
    }

    private var muscleDistributionSection: some View {
        return VStack(alignment: .leading, spacing: 16) {
            Text("部位訓練分佈")
                .font(.headline)

            distributionCard(
                title: "Body Part",
                subtitle: "主部位分佈",
                segments: viewModel.bodyPartSegments
            )

            distributionCard(
                title: "Muscle Group",
                subtitle: "肌群分佈",
                segments: viewModel.muscleGroupSegments
            )
        }
        .padding(16)
        .background(Color(UIColor.systemBackground))
        .cornerRadius(cardCornerRadius)
        .shadow(color: Color.black.opacity(0.03), radius: 8, x: 0, y: 4)
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
                    Text(viewModel.insightText)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .padding(16)
        .background(
            LinearGradient(gradient: Gradient(colors: [Color.customAccent.opacity(0.12), Color.customAccent.opacity(0.05)]), startPoint: .topLeading, endPoint: .bottomTrailing)
        )
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
                    .font(.system(size: 24, weight: .bold, design: .rounded))
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
        .shadow(color: Color.black.opacity(0.03), radius: 8, x: 0, y: 4)
    }


    private var weightTrendSubtitle: String {
        if let name = viewModel.mostUsedEquipmentName {
            let format = NSLocalizedString("%@ · 過去 6 個月", comment: "")
            return String(format: format, name)
        }
        return NSLocalizedString("尚無器材資料", comment: "")
    }

    private var weightHighlightText: String {
        let value = viewModel.maxWeight
        if value > 0 {
            let displayWeight = dataManager.convertWeight(value, to: dataManager.preferredWeightUnit)
            return String(format: "%.0f%@", displayWeight, viewModel.preferredWeightUnitSuffix)
        }
        return NSLocalizedString("--", comment: "")
    }

    private func distributionCard(title: String, subtitle: String, segments: [MuscleSegment]) -> some View {
        let totalPercentage = segments.reduce(0.0) { $0 + $1.percentage }
        return VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline.bold())
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            HStack(alignment: .top, spacing: 20) {
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
                            HStack(alignment: .top) {
                                HStack(spacing: 8) {
                                    Circle()
                                        .fill(segment.color)
                                        .frame(width: 8, height: 8)
                                        .padding(.top, 4)
                                    Text(segment.name)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .fixedSize(horizontal: false, vertical: true)
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
    }


}

struct TrendLabel {
    let text: String
    let isPositive: Bool
}

struct TrendPoint: Identifiable {
    let id = UUID()
    let label: String
    let value: Double
}

struct MuscleSegment: Identifiable {
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
            return NSLocalizedString("本週", comment: "")
        case .month:
            return NSLocalizedString("本月", comment: "")
        }
    }

    var previousTitle: String {
        switch self {
        case .week:
            return NSLocalizedString("上週", comment: "")
        case .month:
            return NSLocalizedString("上月", comment: "")
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
