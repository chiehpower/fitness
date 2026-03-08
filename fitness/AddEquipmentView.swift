import SwiftUI
import UIKit
import CoreNFC

final class NFCScanner: NSObject, ObservableObject, NFCNDEFReaderSessionDelegate {
    private var session: NFCNDEFReaderSession?
    private var onResult: ((String) -> Void)?
    private var onError: ((String) -> Void)?

    func beginScanning(onResult: @escaping (String) -> Void, onError: @escaping (String) -> Void) {
        guard NFCNDEFReaderSession.readingAvailable else {
            onError("此裝置不支援 NFC")
            return
        }

        self.onResult = onResult
        self.onError = onError

        let session = NFCNDEFReaderSession(delegate: self, queue: nil, invalidateAfterFirstRead: true)
        session.alertMessage = "請將 iPhone 靠近 NFC Tag"
        session.begin()
        self.session = session
    }

    func readerSession(_ session: NFCNDEFReaderSession, didInvalidateWithError error: Error) {
        if let nfcError = error as? NFCReaderError, nfcError.code == .readerSessionInvalidationErrorUserCanceled {
            return
        }
        onError?("NFC 讀取失敗，請再試一次")
    }

    func readerSession(_ session: NFCNDEFReaderSession, didDetectNDEFs messages: [NFCNDEFMessage]) {
        guard let tagId = extractTagId(from: messages) else {
            onError?("無法讀取有效的 Tag ID")
            return
        }
        onResult?(tagId)
    }

    private func extractTagId(from messages: [NFCNDEFMessage]) -> String? {
        for message in messages {
            for record in message.records {
                if let id = parseRecord(record) {
                    return id
                }
            }
        }
        return nil
    }

    private func parseRecord(_ record: NFCNDEFPayload) -> String? {
        if record.typeNameFormat == .nfcWellKnown {
            if record.type == Data([0x54]) { // "T"
                if let text = parseWellKnownText(record) {
                    return extractUuid(from: text)
                }
            } else if record.type == Data([0x55]) { // "U"
                if let url = parseWellKnownURL(record) {
                    return extractUuid(from: url)
                }
            }
        }

        if let raw = String(data: record.payload, encoding: .utf8) {
            return extractUuid(from: raw)
        }

        return nil
    }

    private func parseWellKnownText(_ record: NFCNDEFPayload) -> String? {
        let payload = [UInt8](record.payload)
        guard payload.count > 1 else {
            return nil
        }
        let status = payload[0]
        let languageCodeLength = Int(status & 0x3F)
        guard payload.count > 1 + languageCodeLength else {
            return nil
        }
        let textData = Data(payload[(1 + languageCodeLength)...])
        return String(data: textData, encoding: .utf8)
    }

    private func parseWellKnownURL(_ record: NFCNDEFPayload) -> String? {
        let payload = [UInt8](record.payload)
        guard let prefixCode = payload.first else {
            return nil
        }
        let prefix = urlPrefix(for: prefixCode)
        let urlData = Data(payload.dropFirst())
        guard let url = String(data: urlData, encoding: .utf8) else {
            return nil
        }
        return prefix + url
    }

    private func urlPrefix(for code: UInt8) -> String {
        switch code {
        case 0x01:
            return "http://www."
        case 0x02:
            return "https://www."
        case 0x03:
            return "http://"
        case 0x04:
            return "https://"
        default:
            return ""
        }
    }

    private func extractUuid(from raw: String) -> String? {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        if UUID(uuidString: trimmed) != nil {
            return trimmed
        }

        let pattern = "[0-9A-Fa-f]{8}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{12}"
        if let regex = try? NSRegularExpression(pattern: pattern),
           let match = regex.firstMatch(in: trimmed, range: NSRange(trimmed.startIndex..., in: trimmed)),
           let range = Range(match.range, in: trimmed) {
            return String(trimmed[range])
        }

        return nil
    }
}

struct AddEquipmentView: View {
    @ObservedObject var dataManager: DataManager
    @State private var name = ""
    @State private var location = ""
    @State private var nfcTagId = ""
    @State private var image: UIImage?
    @State private var showingImagePicker = false
    @StateObject private var nfcScanner = NFCScanner()
    @State private var showingSourceTypeMenu = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var sourceType: UIImagePickerController.SourceType = .photoLibrary
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        NavigationView {
            Form {
                TextField("器材名稱", text: $name)
                
                TextField("位置", text: $location)
                
                Section(header: Text("NFC Tag")) {
                    HStack {
                        Text(nfcTagId.isEmpty ? "未綁定" : nfcTagId)
                            .font(.subheadline)
                            .foregroundColor(nfcTagId.isEmpty ? .secondary : .primary)
                        Spacer()
                        if !nfcTagId.isEmpty {
                            Button("清除") {
                                nfcTagId = ""
                            }
                        }
                    }
                    Button("掃描 NFC Tag") {
                        nfcScanner.beginScanning(
                            onResult: { tagId in
                                if dataManager.equipments.contains(where: { $0.nfcTagId == tagId }) {
                                    alertMessage = "此 NFC Tag 已綁定器材"
                                    showAlert = true
                                    return
                                }
                                nfcTagId = tagId
                            },
                            onError: { message in
                                alertMessage = message
                                showAlert = true
                            }
                        )
                    }
                }
                
                Section(header: Text("圖片")) {
                    if let image = image {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(height: 200)
                    }
                    Button(image == nil ? "上傳圖片" : "更改圖片") {
                        showingSourceTypeMenu = true
                    }
                }
            }
            .navigationBarTitle("新增器材", displayMode: .inline)
            .navigationBarItems(trailing: Button("儲存") {
                if validateInput() {
                    saveEquipment()
                } else {
                    showAlert = true
                }
            })
            .actionSheet(isPresented: $showingSourceTypeMenu) {
                ActionSheet(title: Text("選擇圖片來源"), buttons: [
                    .default(Text("相冊")) {
                        self.sourceType = .photoLibrary
                        self.showingImagePicker = true
                    },
                    .default(Text("相機")) {
                        self.sourceType = .camera
                        self.showingImagePicker = true
                    },
                    .cancel()
                ])
            }
            .sheet(isPresented: $showingImagePicker) {
                ImagePicker(image: $image, sourceType: sourceType)
            }
            .alert(isPresented: $showAlert) {
                Alert(title: Text("錯誤"), message: Text(alertMessage), dismissButton: .default(Text("確定")))
            }
        }
    }

    func validateInput() -> Bool {
        if name.isEmpty {
            alertMessage = "請輸入器材名稱"
            return false
        }
        if location.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            alertMessage = "請輸入位置"
            return false
        }
        if image == nil {
            alertMessage = "請上傳器材圖片"
            return false
        }
        return true
    }
    func saveEquipment() {
        let imageName = saveImage()
        let trimmedLocation = location.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedLocation.isEmpty, !dataManager.locations.contains(trimmedLocation) {
            dataManager.addLocation(trimmedLocation)
        }

        let newEquipment = Equipment(
            id: UUID(),
            name: name,
            imageName: imageName,
            nfcTagId: nfcTagId.isEmpty ? nil : nfcTagId,
            location: trimmedLocation,
            pr: nil
        )
        dataManager.addEquipment(newEquipment)
        presentationMode.wrappedValue.dismiss()
    }

    func saveImage() -> String? {
        guard let image = image else { return nil }
        let imageName = UUID().uuidString + ".jpg"
        if let data = image.jpegData(compressionQuality: 0.8) {
            let fileManager = FileManager.default
            do {
                let documentsDirectory = try fileManager.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
                let fileURL = documentsDirectory.appendingPathComponent(imageName)
                try data.write(to: fileURL)
                print("Image saved successfully: \(fileURL.path)")
                return imageName
            } catch {
                print("Error saving image: \(error)")
            }
        }
        return nil
    }

}
