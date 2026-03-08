import SwiftUI
import Foundation
import UniformTypeIdentifiers

struct SettingsView: View {
    @ObservedObject var dataManager: DataManager
    @State private var backupDocument: BackupDocument?
    @State private var showingExporter = false
    @State private var showingImporter = false
    @State private var pendingImportURL: URL?
    @State private var showingImportConfirm = false
    @State private var showAlert = false
    @State private var alertMessage = ""

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("重量單位偏好")) {
                    HStack {
                        Text("顯示重量單位")
                        Spacer()
                        Picker("", selection: $dataManager.preferredWeightUnit) {
                            Text("公斤").tag(WeightUnit.kg)
                            Text("磅").tag(WeightUnit.lb)
                        }
                        .pickerStyle(MenuPickerStyle())
                    }
                }

                Section(header: Text("備份")) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("匯出備份(JSON)")
                            Text("產生 JSON 檔，可手動上傳到 Google Drive。")
                                .font(.footnote)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Button("匯出") {
                            guard let data = dataManager.exportBackupData() else {
                                alertMessage = "匯出失敗，請稍後再試"
                                showAlert = true
                                return
                            }
                            backupDocument = BackupDocument(data: data)
                            showingExporter = true
                        }
                    }

                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("匯入備份(JSON)")
                            Text("會覆蓋目前所有資料。")
                                .font(.footnote)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Button("匯入") {
                            showingImporter = true
                        }
                    }
                }
            }
            .navigationTitle("設定")
            .fileExporter(
                isPresented: $showingExporter,
                document: backupDocument,
                contentType: .json,
                defaultFilename: backupFileName()
            ) { result in
                if case .failure = result {
                    alertMessage = "匯出失敗，請稍後再試"
                    showAlert = true
                }
            }
            .fileImporter(
                isPresented: $showingImporter,
                allowedContentTypes: [.json]
            ) { result in
                switch result {
                case .success(let url):
                    pendingImportURL = url
                    showingImportConfirm = true
                case .failure:
                    alertMessage = "匯入失敗，請稍後再試"
                    showAlert = true
                }
            }
            .alert("匯入備份", isPresented: $showingImportConfirm) {
                Button("取消", role: .cancel) {
                    pendingImportURL = nil
                }
                Button("確定匯入", role: .destructive) {
                    if let url = pendingImportURL {
                        importBackup(from: url)
                    }
                    pendingImportURL = nil
                }
            } message: {
                Text("匯入會覆蓋目前所有資料，確定要繼續嗎？")
            }
            .alert(isPresented: $showAlert) {
                Alert(title: Text("錯誤"), message: Text(alertMessage), dismissButton: .default(Text("確定")))
            }
        }
    }

    private func backupFileName() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd-HHmm"
        return "fitness-backup-\(formatter.string(from: Date()))"
    }

    private func importBackup(from url: URL) {
        let shouldAccess = url.startAccessingSecurityScopedResource()
        defer {
            if shouldAccess {
                url.stopAccessingSecurityScopedResource()
            }
        }

        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let payload = try decoder.decode(BackupPayload.self, from: data)
            dataManager.applyBackup(payload)
        } catch {
            alertMessage = "匯入失敗，檔案格式不正確"
            showAlert = true
        }
    }
}

struct BackupDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.json] }
    var data: Data

    init(data: Data) {
        self.data = data
    }

    init(configuration: ReadConfiguration) throws {
        self.data = configuration.file.regularFileContents ?? Data()
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: data)
    }
}

enum WeightUnit: String, Codable, CaseIterable {
    case kg = "公斤"
    case lb = "磅"
}
