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

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                rangePicker
                summarySection
                topEquipmentSection
                topMuscleSection
            }
            .padding()
        }
        .navigationTitle("分析")
    }

    private var rangePicker: some View {
        Picker("區間", selection: $selectedRange) {
            ForEach(AnalysisRange.allCases, id: \.self) { range in
                Text(range.title).tag(range)
            }
        }
        .pickerStyle(SegmentedPickerStyle())
    }

    private var summarySection: some View {
        let metrics = summaryMetrics()
        return VStack(alignment: .leading, spacing: 10) {
            Text("摘要")
                .font(.headline)
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(metrics) { metric in
                    VStack(alignment: .leading, spacing: 6) {
                        Text(metric.title)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(metric.value)
                            .font(.title3.bold())
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(12)
                    .background(Color(UIColor.secondarySystemBackground))
                    .cornerRadius(12)
                }
            }
        }
    }

    private var topEquipmentSection: some View {
        let items = topEquipments()
        return VStack(alignment: .leading, spacing: 10) {
            Text("器材使用排行")
                .font(.headline)
            if items.isEmpty {
                Text("尚無訓練紀錄")
                    .foregroundColor(.secondary)
            } else {
                ForEach(items) { item in
                    barRow(title: item.name, value: item.count, maxValue: items.first?.count ?? 1)
                }
            }
        }
    }

    private var topMuscleSection: some View {
        let items = topMuscles()
        return VStack(alignment: .leading, spacing: 10) {
            Text("主肌群分布")
                .font(.headline)
            if items.isEmpty {
                Text("尚無訓練紀錄")
                    .foregroundColor(.secondary)
            } else {
                ForEach(items) { item in
                    barRow(title: item.name, value: item.count, maxValue: items.first?.count ?? 1)
                }
            }
        }
    }

    private func barRow(title: String, value: Int, maxValue: Int) -> some View {
        let ratio = maxValue > 0 ? CGFloat(value) / CGFloat(maxValue) : 0
        return VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(title)
                Spacer()
                Text("\(value) 組")
                    .foregroundColor(.secondary)
            }
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color(UIColor.systemGray5))
                        .frame(height: 8)
                    Capsule()
                        .fill(Color.customAccent)
                        .frame(width: geometry.size.width * ratio, height: 8)
                }
            }
            .frame(height: 8)
        }
        .padding(.vertical, 4)
    }

    private func summaryMetrics() -> [AnalysisMetric] {
        let logs = filteredLogs()
        let totalDays = Set(logs.map { Calendar.current.startOfDay(for: $0.date) }).count
        let totalTrainingSets = logs.reduce(0) { $0 + $1.sets.count }
        let totalSets = logs.reduce(0) { partial, log in
            partial + log.sets.reduce(0) { $0 + $1.sets.count }
        }
        let totalWeight = logs.reduce(0.0) { partial, log in
            partial + log.sets.reduce(0.0) { sum, trainingSet in
                sum + trainingSet.sets.reduce(0.0) { $0 + $1.weight }
            }
        }

        return [
            AnalysisMetric(title: "訓練天數", value: "\(totalDays)"),
            AnalysisMetric(title: "訓練組數", value: "\(totalTrainingSets)"),
            AnalysisMetric(title: "總次數(子組)", value: "\(totalSets)"),
            AnalysisMetric(title: "總重量(kg)", value: String(format: "%.1f", totalWeight))
        ]
    }

    private func topEquipments(limit: Int = 5) -> [CountItem] {
        var counts: [String: Int] = [:]
        for log in filteredLogs() {
            for set in log.sets {
                counts[set.equipment.name, default: 0] += set.sets.count
            }
        }
        return counts
            .map { CountItem(name: $0.key, count: $0.value) }
            .sorted { $0.count > $1.count }
            .prefix(limit)
            .map { $0 }
    }

    private func topMuscles(limit: Int = 5) -> [CountItem] {
        var counts: [String: Int] = [:]
        for log in filteredLogs() {
            for set in log.sets {
                counts[set.mainMuscle, default: 0] += set.sets.count
            }
        }
        return counts
            .map { CountItem(name: $0.key, count: $0.value) }
            .sorted { $0.count > $1.count }
            .prefix(limit)
            .map { $0 }
    }

    private func filteredLogs() -> [TrainingLog] {
        guard let interval = selectedRange.dateInterval() else {
            return dataManager.trainingLogs
        }
        return dataManager.trainingLogs.filter { interval.contains($0.date) }
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

    func dateInterval(reference: Date = Date()) -> DateInterval? {
        let calendar = Calendar.current
        switch self {
        case .week:
            return calendar.dateInterval(of: .weekOfYear, for: reference)
        case .month:
            return calendar.dateInterval(of: .month, for: reference)
        }
    }
}

struct AnalysisMetric: Identifiable {
    let id = UUID()
    let title: String
    let value: String
}

struct CountItem: Identifiable {
    let id = UUID()
    let name: String
    let count: Int
}
