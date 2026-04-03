import SwiftUI

// MARK: - PixelSpriteView
// Renders a pixel-art creature using the SwiftUI Canvas API.
// Each species has named PNG assets in the Assets catalog under the "Sprites" folder:
//   <spritePrefix>_0, <spritePrefix>_1, … <spritePrefix>_<frameCount-1>
//
// The view cycles through frames at `fps` frames per second using TimelineView.
struct PixelSpriteView: View {
    let spritePrefix: String
    let frameCount:   Int
    var fps:          Double = 4
    var pixelSize:    CGFloat = 3  // each sprite pixel is rendered at this scale

    // Fallback built-in pixel art for when no image assets exist yet.
    // A simple 16x16 blob creature.
    private static let fallbackFrames: [[[Int]]] = [
        // Frame 0 — eyes open
        [
            [0,0,0,0,0,0,1,1,1,1,0,0,0,0,0,0],
            [0,0,0,0,1,1,1,1,1,1,1,1,0,0,0,0],
            [0,0,0,1,1,1,1,1,1,1,1,1,1,0,0,0],
            [0,0,1,1,1,1,1,1,1,1,1,1,1,1,0,0],
            [0,1,1,1,2,2,1,1,1,1,2,2,1,1,1,0],
            [0,1,1,1,2,2,1,1,1,1,2,2,1,1,1,0],
            [0,1,1,1,1,1,1,1,1,1,1,1,1,1,1,0],
            [0,1,1,1,1,3,3,3,3,3,3,1,1,1,1,0],
            [0,1,1,1,1,1,1,1,1,1,1,1,1,1,1,0],
            [0,0,1,1,1,1,1,1,1,1,1,1,1,1,0,0],
            [0,0,1,1,1,1,1,1,1,1,1,1,1,1,0,0],
            [0,0,0,1,1,1,1,1,1,1,1,1,1,0,0,0],
            [0,0,0,0,1,1,0,0,0,0,1,1,0,0,0,0],
            [0,0,0,0,1,1,0,0,0,0,1,1,0,0,0,0],
            [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0],
            [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0],
        ],
        // Frame 1 — eyes half-closed (blink)
        [
            [0,0,0,0,0,0,1,1,1,1,0,0,0,0,0,0],
            [0,0,0,0,1,1,1,1,1,1,1,1,0,0,0,0],
            [0,0,0,1,1,1,1,1,1,1,1,1,1,0,0,0],
            [0,0,1,1,1,1,1,1,1,1,1,1,1,1,0,0],
            [0,1,1,1,1,1,1,1,1,1,1,1,1,1,1,0],
            [0,1,1,1,2,2,1,1,1,1,2,2,1,1,1,0],
            [0,1,1,1,1,1,1,1,1,1,1,1,1,1,1,0],
            [0,1,1,1,1,3,3,3,3,3,3,1,1,1,1,0],
            [0,1,1,1,1,1,1,1,1,1,1,1,1,1,1,0],
            [0,0,1,1,1,1,1,1,1,1,1,1,1,1,0,0],
            [0,0,1,1,1,1,1,1,1,1,1,1,1,1,0,0],
            [0,0,0,1,1,1,1,1,1,1,1,1,1,0,0,0],
            [0,0,0,0,1,1,0,0,0,0,1,1,0,0,0,0],
            [0,0,0,0,1,1,0,0,0,0,1,1,0,0,0,0],
            [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0],
            [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0],
        ],
    ]

    // Colour palette: 0=transparent, 1=body, 2=eyes, 3=mouth
    private static let palette: [Int: Color] = [
        1: Color(red: 0.4, green: 0.7, blue: 1.0),   // light blue body
        2: Color(red: 0.1, green: 0.1, blue: 0.2),   // dark eyes
        3: Color(red: 0.9, green: 0.2, blue: 0.3),   // red mouth
    ]

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / fps)) { timeline in
            let frame = currentFrame(for: timeline.date)
            spriteCanvas(frame: frame)
        }
    }

    // MARK: Canvas rendering
    @ViewBuilder
    private func spriteCanvas(frame: Int) -> some View {
        if let image = UIImage(named: "\(spritePrefix)_\(frame)") {
            // Use actual PNG asset if available
            Image(uiImage: image)
                .interpolation(.none)
                .resizable()
                .frame(width: CGFloat(image.size.width) * pixelSize,
                       height: CGFloat(image.size.height) * pixelSize)
        } else {
            // Fallback: draw built-in pixel art
            let grid = Self.fallbackFrames[frame % Self.fallbackFrames.count]
            let cols = grid[0].count
            let rows = grid.count
            Canvas { ctx, _ in
                for row in 0..<rows {
                    for col in 0..<cols {
                        let colorIndex = grid[row][col]
                        guard colorIndex != 0, let color = Self.palette[colorIndex] else { continue }
                        let rect = CGRect(
                            x: CGFloat(col) * pixelSize,
                            y: CGFloat(row) * pixelSize,
                            width: pixelSize,
                            height: pixelSize
                        )
                        ctx.fill(Path(rect), with: .color(color))
                    }
                }
            }
            .frame(width:  CGFloat(cols) * pixelSize,
                   height: CGFloat(rows) * pixelSize)
        }
    }

    // MARK: Frame index from wall clock (so all instances stay in sync)
    private func currentFrame(for date: Date) -> Int {
        let interval = date.timeIntervalSinceReferenceDate
        return Int(interval * fps) % max(1, frameCount)
    }
}

// MARK: - Preview
#Preview {
    PixelSpriteView(spritePrefix: "baby_blob", frameCount: 2)
        .padding()
}
