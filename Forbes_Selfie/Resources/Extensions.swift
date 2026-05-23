import SwiftUI

// MARK: - Color from Hex
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:  (a,r,g,b) = (255,(int>>8)*17,(int>>4&0xF)*17,(int&0xF)*17)
        case 6:  (a,r,g,b) = (255, int>>16, int>>8&0xFF, int&0xFF)
        case 8:  (a,r,g,b) = (int>>24, int>>16&0xFF, int>>8&0xFF, int&0xFF)
        default: (a,r,g,b) = (255, 0, 0, 0)
        }
        self.init(.sRGB,
                  red:   Double(r)/255,
                  green: Double(g)/255,
                  blue:  Double(b)/255,
                  opacity: Double(a)/255)
    }
}

// MARK: - Gradient Divider
struct GlowDivider: View {
    var body: some View {
        LinearGradient(
            colors: [.clear, Color(hex: "#0EA5E9"), .clear],
            startPoint: .leading, endPoint: .trailing
        )
        .frame(height: 1.5)
    }
}

// MARK: - Corner Bracket
enum BracketPosition { case topLeft, topRight, bottomLeft, bottomRight }

struct CornerBracket: View {
    let position: BracketPosition
    var size: CGFloat = 16
    var color: Color = Color(hex: "#F59E0B")
    var lineWidth: CGFloat = 2.2

    var body: some View {
        Canvas { ctx, sz in
            let s = sz.width
            var path = Path()
            switch position {
            case .topLeft:
                path.move(to: CGPoint(x: 0, y: s))
                path.addLine(to: CGPoint(x: 0, y: 0))
                path.addLine(to: CGPoint(x: s, y: 0))
            case .topRight:
                path.move(to: CGPoint(x: 0, y: 0))
                path.addLine(to: CGPoint(x: s, y: 0))
                path.addLine(to: CGPoint(x: s, y: s))
            case .bottomLeft:
                path.move(to: CGPoint(x: 0, y: 0))
                path.addLine(to: CGPoint(x: 0, y: s))
                path.addLine(to: CGPoint(x: s, y: s))
            case .bottomRight:
                path.move(to: CGPoint(x: 0, y: s))
                path.addLine(to: CGPoint(x: s, y: s))
                path.addLine(to: CGPoint(x: s, y: 0))
            }
            ctx.stroke(path, with: .color(color),
                       style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round))
        }
        .frame(width: size, height: size)
    }
}

// MARK: - Card with corner brackets overlay
struct CardBrackets: ViewModifier {
    var padding: CGFloat = 14
    func body(content: Content) -> some View {
        content.overlay(
            ZStack {
                VStack {
                    HStack {
                        CornerBracket(position: .topLeft).padding(padding)
                        Spacer()
                        CornerBracket(position: .topRight).padding(padding)
                    }
                    Spacer()
                    HStack {
                        CornerBracket(position: .bottomLeft).padding(padding)
                        Spacer()
                        CornerBracket(position: .bottomRight).padding(padding)
                    }
                }
            }
        )
    }
}
extension View {
    func cardBrackets(padding: CGFloat = 14) -> some View {
        modifier(CardBrackets(padding: padding))
    }
}
