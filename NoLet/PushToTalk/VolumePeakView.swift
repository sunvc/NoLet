//
//  VolumePeakView.swift
//  pushme
//
//  Created by lynn on 2025/7/27.
//


import SwiftUI


struct VolumePeakView: View {
    var progress: CGFloat
    var activeTint: Color = .primary
    var inActiveTint: Color = .gray.opacity(0.7)
    
    var anchor: UnitPoint = .trailing
    var body: some View {
        GeometryReader {
            let size = $0.size
            ZStack {
             
                VoiceformShape(width: Float(size.width))
                    .fill(inActiveTint)
                if anchor == .leading{
                    VoiceformShape(width: Float(size.width))
                        .fill(activeTint)
                        .mask {
                            Rectangle()
                                .scale(x: progress, anchor: .leading)
                        }
                        .animation(.linear, value: progress)
                }else{
                    
                    VoiceformShape(width: Float(size.width))
                        .fill(activeTint)
                        .mask {
                            Rectangle()
                                .scale(x: progress, anchor: .trailing)
                        }
                        .animation(.linear, value: progress)
                }
                
                   
            }
        }
    }
    
    /// Custom WaveFrom Shape
    fileprivate struct VoiceformShape: Shape {

        var spacing: Float = 2
        var height: CGFloat = 12
        var width: Float
        var count:Float = 50
        private var oneW:Float{
            (width - count * spacing) / count
        }
        nonisolated func path(in rect: CGRect) -> Path {
            Path { path in
                var x: CGFloat = 0
                for _ in Array(1...Int(count)) {
                    path.addRect(CGRect(
                        origin: .init(x: x + CGFloat(oneW), y: -height / 2),
                        size: .init(width: CGFloat(oneW), height: height)
                    ))
                    
                    x += CGFloat(spacing + oneW)
                }
            }
            .offsetBy(dx: 0, dy: rect.height / 2)
        }
    }

}

#Preview {
    VolumePeakView(progress:  30, anchor: .leading)
}
