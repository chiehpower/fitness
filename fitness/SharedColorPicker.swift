import SwiftUI

struct SharedColorPicker: UIViewRepresentable {
    @Binding var selectedColor: Color
    
    func makeUIView(context: Context) -> UIColorWell {
        let colorWell = UIColorWell()
        colorWell.supportsAlpha = false
        colorWell.selectedColor = UIColor(selectedColor)
        colorWell.addTarget(context.coordinator, action: #selector(Coordinator.colorChanged(_:)), for: .valueChanged)
        return colorWell
    }
    
    func updateUIView(_ uiView: UIColorWell, context: Context) {
        uiView.selectedColor = UIColor(selectedColor)
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject {
        var parent: SharedColorPicker
        
        init(_ parent: SharedColorPicker) {
            self.parent = parent
        }
        
        @objc func colorChanged(_ sender: UIColorWell) {
            if let color = sender.selectedColor {
                parent.selectedColor = Color(color)
            }
        }
    }
}
