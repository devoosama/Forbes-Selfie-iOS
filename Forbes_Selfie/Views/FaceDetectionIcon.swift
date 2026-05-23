import SwiftUI

// MARK: - Forbes Face Detection Vector Icon
struct FaceDetectionIcon: View {
    var body: some View {
        Canvas { ctx, size in
            let w = size.width, h = size.height
            let cx = w / 2, cy = h / 2

            // ── Face oval ──
            let faceRect = CGRect(x: cx - w*0.28, y: cy - h*0.36, width: w*0.56, height: h*0.72)
            ctx.stroke(Path(ellipseIn: faceRect),
                       with: .color(.white),
                       style: StrokeStyle(lineWidth: w*0.04, lineCap: .round))

            // ── Eyes ──
            let er = w * 0.055
            let eyeY = cy - h * 0.04
            ctx.fill(Path(ellipseIn: CGRect(x: cx - w*0.18 - er, y: eyeY - er, width: er*2, height: er*2)),
                     with: .color(Color(hex: "#0EA5E9")))
            ctx.fill(Path(ellipseIn: CGRect(x: cx + w*0.08 - er, y: eyeY - er, width: er*2, height: er*2)),
                     with: .color(Color(hex: "#0EA5E9")))

            // ── Smile ──
            var smile = Path()
            smile.move(to: CGPoint(x: cx - w*0.18, y: cy + h*0.18))
            smile.addQuadCurve(to: CGPoint(x: cx + w*0.18, y: cy + h*0.18),
                               control: CGPoint(x: cx, y: cy + h*0.30))
            ctx.stroke(smile, with: .color(.white),
                       style: StrokeStyle(lineWidth: w*0.037, lineCap: .round))

            // ── Scan line ──
            var scan = Path()
            scan.move(to: CGPoint(x: cx - w*0.28, y: cy))
            scan.addLine(to: CGPoint(x: cx + w*0.28, y: cy))
            ctx.stroke(scan, with: .color(Color(hex: "#0EA5E9").opacity(0.5)),
                       style: StrokeStyle(lineWidth: w*0.018))

            // ── Corner brackets (gold) ──
            let bSize = w * 0.18
            let margin = w * 0.04
            let positions: [(CGPoint, BracketPosition)] = [
                (CGPoint(x: margin, y: margin), .topLeft),
                (CGPoint(x: w - margin - bSize, y: margin), .topRight),
                (CGPoint(x: margin, y: h - margin - bSize), .bottomLeft),
                (CGPoint(x: w - margin - bSize, y: h - margin - bSize), .bottomRight),
            ]
            for (origin, pos) in positions {
                var b = Path()
                switch pos {
                case .topLeft:
                    b.move(to: CGPoint(x: origin.x, y: origin.y + bSize))
                    b.addLine(to: origin)
                    b.addLine(to: CGPoint(x: origin.x + bSize, y: origin.y))
                case .topRight:
                    b.move(to: CGPoint(x: origin.x, y: origin.y))
                    b.addLine(to: CGPoint(x: origin.x + bSize, y: origin.y))
                    b.addLine(to: CGPoint(x: origin.x + bSize, y: origin.y + bSize))
                case .bottomLeft:
                    b.move(to: CGPoint(x: origin.x, y: origin.y))
                    b.addLine(to: CGPoint(x: origin.x, y: origin.y + bSize))
                    b.addLine(to: CGPoint(x: origin.x + bSize, y: origin.y + bSize))
                case .bottomRight:
                    b.move(to: CGPoint(x: origin.x, y: origin.y + bSize))
                    b.addLine(to: CGPoint(x: origin.x + bSize, y: origin.y + bSize))
                    b.addLine(to: CGPoint(x: origin.x + bSize, y: origin.y))
                }
                ctx.stroke(b, with: .color(Color(hex: "#F59E0B")),
                           style: StrokeStyle(lineWidth: w*0.055, lineCap: .round, lineJoin: .round))
            }
        }
    }
}
