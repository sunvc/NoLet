//
//  VolumePeakView.swift
//  NoLet
//
//  Created by lynn on 2025/7/27.
//
//
import SwiftUI

struct VolumePeakView: View {
    var progress: CGFloat
    var activeTint: Color = .primary
    var inActiveTint: Color = .gray.opacity(0.7)
    var anchor: UnitPoint = .trailing

    var barCount: Int = 50
    var barSpacing: CGFloat = 2
    var barHeight: CGFloat = 12

    var body: some View {
        ZStack {
            // 底色：未激活状态的波形
            VoiceformShape(count: barCount, spacing: barSpacing, height: barHeight)
                .fill(inActiveTint)

            // 上色：激活状态的波形 + 动态遮罩
            VoiceformShape(count: barCount, spacing: barSpacing, height: barHeight)
                .fill(activeTint)
                .mask {
                    Rectangle()
                        .scale(x: max(0, min(progress, 1)), anchor: anchor)
                }
                .animation(.linear(duration: 0.2), value: progress)
        }
    }
}

private struct VoiceformShape: Shape {
    var count: Int
    var spacing: CGFloat
    var height: CGFloat

    func path(in rect: CGRect) -> Path {
        var path = Path()

        let totalSpacing = CGFloat(count - 1) * spacing
        let barWidth = (rect.width - totalSpacing) / CGFloat(count)

        guard barWidth > 0 else { return path }

        for i in 0..<count {
            let xPosition = CGFloat(i) * (barWidth + spacing)

            let barRect = CGRect(
                x: xPosition,
                y: (rect.height - height) / 2, // 居中对齐
                width: barWidth,
                height: height
            )
            path.addRect(barRect)
        }

        return path
    }
}

#Preview {

    VolumePeakView(progress: 0.6, anchor: .leading)
        .frame(height: 40)
        .padding()
}
