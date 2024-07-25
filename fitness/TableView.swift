import SwiftUI

struct TableView: View {
    var body: some View {
        List {
            Section(header: Text("ID  器材名稱  部位  細部位  器材圖片")) {
                // 您的表格內容
                Text("1  器材1  胸  上胸  圖片")
                Text("2  器材2  背  下背  圖片")
            }
        }
    }
}
