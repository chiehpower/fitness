import SwiftUI

// 器材列表視圖
public struct EquipmentListView: View {
    @Binding var equipments: [Equipment]
    @State private var selectedImage: UIImage?
    @State private var isShowingEnlargedImage = false
    
    public var body: some View {
        List {
            ForEach(equipments) { equipment in
                HStack {
                    if let imageName = equipment.imageName, let uiImage = loadImage(named: imageName) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 50, height: 50)
                            .cornerRadius(5)
                            .onTapGesture {
                                self.selectedImage = uiImage
                                self.isShowingEnlargedImage = true
                            }
                    } else {
                        Image(systemName: "photo")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 50, height: 50)
                            .foregroundColor(.gray)
                    }
                    
                    VStack(alignment: .leading) {
                        Text(equipment.name)
                            .font(.headline)
                        HStack {
                            Text(equipment.mainMuscle)
                                .font(.subheadline)
                                .padding(5)
                                .background(colorForMuscle(equipment.mainMuscle))
                                .cornerRadius(5)
                            Text(equipment.subMuscle)
                                .font(.subheadline)
                                .padding(5)
                                .background(colorForMuscle(equipment.mainMuscle).opacity(0.5))
                                .cornerRadius(5)
                        }
                    }
                }
                .padding(.vertical, 5)
            }
            .onDelete(perform: deleteEquipment)
        }
        .sheet(isPresented: $isShowingEnlargedImage) {
            if let image = selectedImage {
                EnlargedImageView(image: image)
            }
        }
    }
    
    func deleteEquipment(at offsets: IndexSet) {
        equipments.remove(atOffsets: offsets)
    }
    
    func loadImage(named: String) -> UIImage? {
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
        guard let filePath = documentsDirectory?.appendingPathComponent(named).path else {
            return nil
        }
        return UIImage(contentsOfFile: filePath)
    }
    
    func colorForMuscle(_ muscle: String) -> Color {
        switch muscle {
        case "胸": return .red
        case "背": return .blue
        case "腿": return .green
        case "肩": return .orange
        case "手臂": return .purple
        default: return .gray
        }
    }
}
