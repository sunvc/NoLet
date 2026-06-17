//
//  TouchCaptureView.swift
//  NoLet
//
//  Created by lynn on 2025/7/30.
//
import AVFoundation
import Defaults
import SwiftUI

extension View {
    func pbutton(
        _ hasMoveTopRight: Binding<Bool>,
        _ isPress: Binding<Bool>,
        onBegan: @escaping () -> Void,
        onEnded: @escaping () -> Void,
        onCancelled: (() -> Void)? = nil
    ) -> some View {
        self
            .overlay {
                TouchCaptureView(
                    hasMoveTopRight: hasMoveTopRight,
                    isPressing: isPress,
                    onBegan: onBegan,
                    onEnded: onEnded,
                    onCancelled: onCancelled
                )
            }
    }
}

struct TouchCaptureView: UIViewRepresentable {
    @Binding var hasMoveTopRight: Bool
    @Binding var isPressing: Bool
    var onBegan: () -> Void
    var onEnded: () -> Void
    var onCancelled: (() -> Void)? = nil

    func makeUIView(context: Context) -> UIView {
        let view = TouchUIView()
        view.coordinator = context.coordinator
        view.onBegan = onBegan
        view.onEnded = onEnded
        view.onCancelled = onCancelled
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(hasMoveTopRight: $hasMoveTopRight, isPressing: $isPressing)
    }

    class Coordinator {
        var hasMoveTopRight: Binding<Bool>
        var isPressing: Binding<Bool>
        var lastTouchTime: Date? // ⏱ 记录上次点击时间

        init(hasMoveTopRight: Binding<Bool>, isPressing: Binding<Bool>) {
            self.hasMoveTopRight = hasMoveTopRight
            self.isPressing = isPressing
        }
    }

    class TouchUIView: UIView {
        var coordinator: Coordinator?
        var onBegan: (() -> Void)?
        var onEnded: (() -> Void)?
        var onCancelled: (() -> Void)?
        private var touchStartTime: Date?

        override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
            guard let coord = coordinator else { return }

            let now = Date()
            if let last = coord.lastTouchTime,
               now.timeIntervalSince(last) < 0.5
            {
                return
            }
            coord.lastTouchTime = now

            coord.hasMoveTopRight.wrappedValue = false
            coord.isPressing.wrappedValue = true
            touchStartTime = now
            self.onBegan?()
        }

        override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
            coordinator?.isPressing.wrappedValue = false

            guard let start = touchStartTime else { return }
            let elapsed = Date().timeIntervalSince(start)

            touchStartTime = nil

            if elapsed < 0.3 || coordinator?.hasMoveTopRight.wrappedValue == true {
                coordinator?.hasMoveTopRight.wrappedValue = true
                onCancelled?()
            } else {
                onEnded?()
            }
        }

        override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
            coordinator?.isPressing.wrappedValue = false
            onCancelled?()
        }

        override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
            guard let touch = touches.first else { return }
            let location = touch.location(in: self)
            let center = CGPoint(x: bounds.midX, y: bounds.midY)
            let radius = bounds.width / 2 - 15
            let distance = hypot(location.x - center.x, location.y - center.y)
            let isInsideCircle = distance <= radius
            if coordinator?.hasMoveTopRight.wrappedValue != !isInsideCircle {
                coordinator?.hasMoveTopRight.wrappedValue = !isInsideCircle
            }
        }

        override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
            let center = CGPoint(x: bounds.midX, y: bounds.midY)
            let radius = min(bounds.width, bounds.height) / 2 - 15
            let distance = hypot(point.x - center.x, point.y - center.y)
            return distance <= radius
        }
    }
}

nonisolated struct LineShape: Shape {
    var values: [Double]

    var animatableData: AnimatableLine {
        get { AnimatableLine(values: values) }
        set { values = newValue.values }
    }

    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.size.width / 12, y: values.first ?? 0))
        for index in 1..<values.count {
            let x = positionForDragPoint(at: index, size: rect.size)
            let y = values[index]
            path.addLine(to: CGPoint(x: x, y: y))
        }
        return path
    }

    func positionForDragPoint(at index: Int, size: CGSize) -> CGFloat {
        size.width / 12 * CGFloat(index * 2 + 1)
    }
}

nonisolated struct AnimatableLine: VectorArithmetic {
    var values: [Double]

    var magnitudeSquared: Double {
        return values.map { $0 * $0 }.reduce(0, +)
    }

    mutating func scale(by rhs: Double) {
        values = values.map { $0 * rhs }
    }

    static var zero: AnimatableLine {
        return AnimatableLine(values: [0.0])
    }

    static func - (lhs: AnimatableLine, rhs: AnimatableLine) -> AnimatableLine {
        return AnimatableLine(values: zip(lhs.values, rhs.values).map(-))
    }

    static func -= (lhs: inout AnimatableLine, rhs: AnimatableLine) {
        lhs = lhs - rhs
    }

    static func + (lhs: AnimatableLine, rhs: AnimatableLine) -> AnimatableLine {
        return AnimatableLine(values: zip(lhs.values, rhs.values).map(+))
    }

    static func += (lhs: inout AnimatableLine, rhs: AnimatableLine) {
        lhs = lhs + rhs
    }
}

struct CustomSlider: View {
    @Binding var isPress: Bool
    @Binding var sliderProgress: CGFloat
    /// Configuration
    var symbol: Symbol?
    var axis: SliderAxis
    var tint: Color
    /// View Properties
    @State private var progress: CGFloat = .zero
    @State private var dragOffset: CGFloat = .zero
    @State private var lastDragOffset: CGFloat = .zero
    var body: some View {
        GeometryReader {
            let size = $0.size
            let orientationSize = axis == .horizontal ? size.width : size.height
            let progressValue = max(progress, .zero) * orientationSize

            ZStack(alignment: axis == .horizontal ? .leading : .bottom) {
                Rectangle()
                    .fill(.ultraThinMaterial)
                    .shadow(radius: 1)
                Rectangle()
                    .fill(tint.gradient)
                    .frame(
                        width: axis == .horizontal ? progressValue : nil,
                        height: axis == .vertical ? progressValue : nil
                    )

                if let symbol, symbol.display {
                    Image(systemName: symbol.icon)
                        .font(symbol.font)
                        .foregroundStyle(symbol.tint)
                        .padding(symbol.padding)
                        .frame(width: size.width, height: size.height, alignment: symbol.alignment)
                        .transition(.opacity)
                }
            }
            .clipShape(.rect(cornerRadius: 15))
            .contentShape(.rect(cornerRadius: 15))
            .optionalSizingModifiers(
                axis: axis,
                size: size,
                progress: progress,
                orientationSize: orientationSize
            )
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged {
                        let translation = $0.translation
                        let movement = (axis == .horizontal ? translation.width : -translation
                            .height) + lastDragOffset
                        dragOffset = movement
                        calculateProgress(orientationSize: orientationSize)
                        self.isPress = true
                    }
                    .onEnded { _ in
                        withAnimation(.smooth) {
                            dragOffset = dragOffset > orientationSize ? orientationSize :
                                (dragOffset < 0 ? 0 : dragOffset)
                            calculateProgress(orientationSize: orientationSize)
                        }
                        self.isPress = false
                        lastDragOffset = dragOffset
                    }
            )
            .frame(
                maxWidth: size.width,
                maxHeight: size.height,
                alignment: axis == .vertical ? (progress < 0 ? .top : .bottom) :
                    (progress < 0 ? .trailing : .leading)
            )
            .onChange(of: sliderProgress) { newValue in
                /// Initial Progress Settings
                guard newValue != progress else { return }
                progress = max(min(newValue, 1.0), .zero)
                dragOffset = progress * orientationSize
                lastDragOffset = dragOffset
            }
            .onChange(of: axis) { _ in
                dragOffset = progress * orientationSize
                lastDragOffset = dragOffset
            }
            .onAppear {
                progress = max(min(sliderProgress, 1.0), .zero)
                dragOffset = progress * orientationSize
                lastDragOffset = dragOffset
            }
        }
        .onChange(of: progress) { newValue in
            let clampedValue = max(min(newValue, 1.0), .zero)
            if clampedValue != sliderProgress {
                sliderProgress = clampedValue
            }
        }
    }

    /// Calculating Progress
    private func calculateProgress(orientationSize: CGFloat) {
        let topAndTrailingExcessOffset = orientationSize + (dragOffset - orientationSize) * 0.1
        let bottomAndLeadingExcessOffset = dragOffset < 0 ? (dragOffset * 0.1) : dragOffset

        let progress =
            (dragOffset > orientationSize ? topAndTrailingExcessOffset :
                bottomAndLeadingExcessOffset) / orientationSize

        // 防止 NaN 和无限值
        if progress.isFinite, !progress.isNaN {
            self.progress = progress
        }
    }

    /// Symbol Configuration
    struct Symbol {
        var icon: String
        var tint: Color
        var font: Font
        var padding: CGFloat
        var display: Bool = true
        var alignment: Alignment = .center
    }

    /// Slider Axis
    enum SliderAxis {
        case vertical
        case horizontal
    }
}

extension View {
    @ViewBuilder
    fileprivate func optionalSizingModifiers(
        axis: CustomSlider.SliderAxis,
        size: CGSize,
        progress: CGFloat,
        orientationSize: CGFloat
    ) -> some View {
        let topAndTrailingScale = 1 - (progress - 1) * 0.15
        let bottomAndLeadingScale = 1 + progress * 0.15

        self
            .frame(
                width: axis == .horizontal && progress < 0 ? size
                    .width + (-progress * size.width) : nil,
                height: axis == .vertical && progress < 0 ? size
                    .height + (-progress * size.height) : nil
            )
            .scaleEffect(
                x: axis == .vertical ?
                    (progress > 1 ? topAndTrailingScale :
                        (progress < 0 ? bottomAndLeadingScale : 1)) : 1,
                y: axis == .horizontal ?
                    (progress > 1 ? topAndTrailingScale :
                        (progress < 0 ? bottomAndLeadingScale : 1)) :
                    1,
                anchor: axis == .horizontal ? (progress < 0 ? .trailing : .leading) :
                    (progress < 0 ? .top : .bottom)
            )
    }
}

struct EQSliderView: View {
    @State private var dragPointYLocations: [CGFloat] = Array(repeating: .zero, count: 6)
    @State private var resetPoints: [Double] = Array(repeating: .zero, count: 6)

    @State private var eqViewFrame: CGRect = .zero

    @Default(.eqBands) var eqBands
    @Default(.eqPreset) var eqPreset

    private var maxGain = EqualizerPreset.maxGain
    private var minGain = EqualizerPreset.minGain

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                // Draw labels for gain values
                VStack {
                    Text(verbatim: "\(Int(maxGain))db")
                        .font(.caption2)
                        .foregroundColor(.black)
                    Spacer()
                    Text(verbatim: "0dB")
                        .font(.caption2)
                        .foregroundColor(.black)
                    Spacer()
                    Text(verbatim: "\(Int(minGain))db")
                        .font(.caption2)
                        .foregroundColor(.black)
                }
                GeometryReader { innerGeo in
                    ZStack {
                        LineShape(values: dragPointYLocations.map { Double($0) })
                            .stroke(Color.mint, lineWidth: 2)
                            .animation(.easeInOut(duration: 0.2), value: eqPreset)
                            .onAppear {
                                resetPoints = resetPoints.map { _ in Double(gainToYPosition(
                                    at: 0,
                                    in: innerGeo.size
                                )) }
                            }

                        Path { path in
                            for index in 0..<dragPointYLocations.count {
                                let x = positionForDragPoint(at: index, size: innerGeo.size)
                                path.move(to: CGPoint(x: x, y: 0))
                                path.addLine(to: CGPoint(x: x, y: innerGeo.size.height))
                            }
                            path.move(to: CGPoint(x: 0, y: innerGeo.size.height / 2))
                            path.addLine(to: CGPoint(
                                x: innerGeo.size.width,
                                y: innerGeo.size.height / 2
                            ))
                        }
                        .stroke(Color.gray.opacity(0.5), lineWidth: 1)

                        ForEach(eqBands) { band in
                            Circle()
                                .fill(Color.mint)
                                .frame(width: 20, height: 20)
                                .position(
                                    x: positionForDragPoint(at: band.index, size: innerGeo.size),
                                    y: dragPointYLocations[band.index]
                                )
                                .gesture(
                                    DragGesture()
                                        .onChanged { value in
                                            let newY = min(
                                                max(value.location.y, 0),
                                                innerGeo.size.height
                                            )
                                            dragPointYLocations[band.index] = newY
                                            updateGainValue(at: band.index, in: innerGeo.size)
                                        }
                                )
                                .onAppear {
                                    dragPointYLocations[band.index] = gainToYPosition(
                                        at: band.value,
                                        in: innerGeo.size
                                    )
                                }
                        }
                    }
                    .onChange(of: eqPreset) { value in
                        if value != .custom {
                            self.eqBands = value.bands
                            resetPositions(in: innerGeo.size)
                        }
                    }
                    .onChange(of: eqBands) { datas in
                        let values = datas.map { $0.value }
                        var ok = false
                        for item in EqualizerPreset.allCases {
                            if item.gains == values {
                                self.eqPreset = item
                                ok = true
                            }
                        }
                        if !ok {
                            self.eqPreset = EqualizerPreset.custom
                        }
                    }

                    ForEach(eqBands) { band in
                        Text(band.frequency)
                            .position(
                                x: positionForDragPoint(at: band.index, size: innerGeo.size),
                                y: innerGeo.size.height + 8
                            )
                            .font(.caption)
                            .foregroundColor(.black)
                    }
                }
            }
        }
    }

    func positionForDragPoint(at index: Int, size: CGSize) -> CGFloat {
        size.width / 12 * CGFloat(index * 2 + 1)
    }

    func updateGainValue(at index: Int, in size: CGSize) {
        let percentage = dragPointYLocations[index] / size.height
        let gain = (1 - Float(percentage)) * (maxGain - minGain) + minGain
        eqBands[index].value = gain
    }

    func gainToYPosition(at gain: Float, in size: CGSize) -> CGFloat {
        let percentage = 1 - (gain - minGain) / (maxGain - minGain)
        return CGFloat(percentage) * size.height
    }

    func resetPositions(in size: CGSize) {
        let values = eqBands.map { gainToYPosition(at: $0.value, in: size) }
        withAnimation(.easeInOut(duration: 0.2)) {
            dragPointYLocations = values
        }
    }
}

struct EQGlobalGainSlider: View {
    @Default(.globalGain) var globalGain

    @State private var gain: Double = 0

    @ObservedObject private var pttManager = PushTalkManager.shared
    // 配置常量
    private let minGain: Double = -24.0
    private let maxGain: Double = 24.0
    private let alertGain: Double = 12.0 // 超过 12dB 变红

    var body: some View {
        VStack(spacing: 20) {
            // 头部数据读数
            HStack(alignment: .lastTextBaseline) {
                Text("音量增益")
                    .font(.headline)
                    .foregroundColor(.secondary)
                Spacer()
                Text(verbatim: String(format: "%.1f", gain))
                    .font(.system(.title, design: .rounded))
                    .bold()
                    .foregroundColor(gain > alertGain ? .red : (gain < 0 ? .yellow : .green))
                    .contentTransition(.numericText())
                    .animation(.smooth(duration: 0.2), value: gain)
                Text(verbatim: "dB")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 5)

            // 自定义滑块核心组件
            GeometryReader { geometry in
                let width = geometry.size.width
                let height = geometry.size.height
                let centerPoint = width / 2

                let currentX = CGFloat((gain - minGain) / (maxGain - minGain)) * width

                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color(.systemGray5))
                        .frame(height: height)

                    if gain < 0 {
                        Capsule()
                            .fill(Color.yellow)
                            .frame(width: centerPoint - currentX, height: height)
                            .offset(x: currentX)
                    } else if gain > 0 {
                        if gain <= alertGain {
                            Capsule()
                                .fill(Color.green)
                                .frame(width: currentX - centerPoint, height: height)
                                .offset(x: centerPoint)
                        } else {
                            let alertX = CGFloat((alertGain - minGain) / (maxGain - minGain)) *
                                width

                            Capsule()
                                .fill(Color.green)
                                .frame(width: alertX - centerPoint, height: height)
                                .offset(x: centerPoint)

                            Capsule()
                                .fill(Color.red)
                                .frame(width: currentX - alertX, height: height)
                                .offset(x: alertX)
                        }
                    }

                    Rectangle()
                        .fill(Color(.systemBackground).opacity(0.8))
                        .frame(width: 3, height: height + 6)
                        .position(x: centerPoint, y: height / 2)

                    let alertLineX = CGFloat((alertGain - minGain) / (maxGain - minGain)) * width
                    Rectangle()
                        .fill(Color.red.opacity(0.4))
                        .frame(width: 2, height: height + 2)
                        .position(x: alertLineX, y: height / 2)

                    Circle()
                        .fill(Color.white)
                        .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
                        .frame(width: height * 2.5, height: height * 2.5)
                        .position(x: currentX, y: height / 2)
                        .gesture(
                            DragGesture(minimumDistance: 0)
                                .onChanged { value in
                                    let boundedX = min(max(0, value.location.x), width)
                                    let percentage = Double(boundedX / width)
                                    let calculatedGain = minGain + percentage * (maxGain - minGain)
                                    self.gain = (calculatedGain * 10).rounded() / 10
                                }
                                .onEnded { _ in
                                    self.globalGain = gain
                                    pttManager.changeEQ()
                                }
                        )
                }
            }
            .frame(height: 12)
            .padding(.vertical, 10)

            HStack {
                HStack {
                    Text(verbatim: "\(Int(minGain))dB")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .onTapGesture { quickSet(minGain) }
                    Spacer()
                }
                Spacer()
                HStack {
                    Text(verbatim: "0dB")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .offset(x: -15)
                        .onTapGesture { quickSet(0.0) }
                    Spacer()
                    Text(verbatim: "12dB")
                        .font(.caption)
                        .foregroundColor(.red.opacity(0.7))
                        .onTapGesture { quickSet(12.0) }
                    Spacer()
                    Text(verbatim: "\(Int(maxGain))dB")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .onTapGesture { quickSet(maxGain) }
                }
            }
        }
        .padding(10)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
        .onAppear {
            self.gain = globalGain
        }
    }

    func quickSet(_ value: Double) {
        self.globalGain = value
        self.gain = value
        pttManager.changeEQ()
    }
}

/// RotateButtonView
///
///
struct RotateButtonView: View {
    var geometry: GeometryProxy
    // 旋转角度
    @State private var angle: Double = 0
    // 记录上一次的手势绝对角度
    @State private var lastAngle: Double = 0
    // 标记是否是手势的第一帧（防止点下时突变）
    @State private var isDragging: Bool = false

    @State private var lastRotatedValue: Int = 0

    var rotate: (Int) -> Void
    
    var width: CGFloat{
        geometry.size.width
    }


    var body: some View {
        ZStack {
            // 背景大圆
            Circle()
                .fill(Color.gray.opacity(0.15))
                .frame(width: width, height: width)

            ZStack {
                // 内层旋转旋钮主体
                Circle()
                    .fill(Color.black.gradient)
                    .frame(width: width - 60, height: width - 60)
                    .shadow(color: Color.white.opacity(0.2), radius: 5, x: 5, y: 5)
                    .shadow(color: Color.white.opacity(0.2), radius: 5, x: -5, y: -5)
                    .rotationEffect(.init(degrees: angle))

                // 旋钮上的小凹槽点（供手指触摸）
                Circle()
                    .fill(.clear)
                    .overlay(
                        Circle()
                            .stroke(Color.gray.opacity(0.5), lineWidth: 2)
                            .overlay(
                                Circle()
                                    .stroke(Color.gray.opacity(0.3), lineWidth: 6)
                                    .blur(radius: 3)
                                    .offset(x: 0, y: 3)
                                    .mask(Circle().fill(LinearGradient(
                                        gradient: Gradient(colors: [Color.black, Color.clear]),
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )))
                            )
                    )
                    .frame(width: 50, height: 50)
                    .offset(x: (width - 150) / 2)
                    .rotationEffect(.init(degrees: angle))
                    // 初始摆放偏角偏转
                    .rotationEffect(.init(degrees: -210))
            }
            // 【关键改动 1】：将手势挂在整个大容器 ZStack 上，或者利用透明蒙版捕获，
            // 这样无论按钮怎么转，手势判断都在稳定的固定坐标系中进行。
            .background(Circle().fill(Color.clear))
            .gesture(
                DragGesture(minimumDistance: 0, coordinateSpace: .named("knobContainer"))
                    .onChanged { value in
                        onChanged(value: value, center: width / 2)
                    }
                    .onEnded { _ in
                        withAnimation(.bouncy(duration: 0.1, extraBounce: 0.3)) {
                            self.angle = 0
                            self.lastAngle = 0
                        }
                        isDragging = false
                    }
            )

            // 周围的指示灯刻度圈
            ZStack {
                let highlightCount = min(abs(Int(angle) % 360) / 12 + 1, 30)

                ForEach(0...29, id: \.self) { index in
                    ZStack {
                        Capsule()
                            .fill(dotColor(0, Int(angle)))

                        if angle > 0 {
                            Capsule()
                                .fill((Int(angle) % 360 / 12 + 1) > index ? dotColor(
                                    1,
                                    Int(angle)
                                ) : .clear)
                        } else {
                            if index >= 30 - highlightCount {
                                Capsule()
                                    .fill(dotColor(1, Int(angle)))
                            }
                        }
                    }
                    .frame(width: 10, height: 10)
                    .offset(x: -(width + 10) / 2)
                    .rotationEffect(.init(degrees: Double(index) * 12 - 24))
                }
            }
        }
        // 【关键改动 2】：定义稳定的命名坐标空间
        .coordinateSpace(name: "knobContainer")
        .onChange(of: angle) { newValue in
            let roundedValue = Int(newValue)
            if roundedValue != lastRotatedValue {
                rotate(roundedValue)
                lastRotatedValue = roundedValue
            }
        }
    }

    // 动态传入中心点，计算平滑旋转
    private func onChanged(value: DragGesture.Value, center: CGFloat) {
        let touchLocation = value.location

        // 基于精准且固定的外层中轴线建立向量
        let vector = CGVector(dx: touchLocation.x - center, dy: touchLocation.y - center)

        // 防止用户手势完美点在绝对中心导致 atan2 分母为0崩溃或计算异常
        guard vector.dx != 0 || vector.dy != 0 else { return }

        let radians = atan2(vector.dy, vector.dx)

        var currentAngle = radians * 180 / .pi
        if currentAngle < 0 { currentAngle += 360 }

        // 如果是刚触碰的第一帧，初始化角度，不计算增量（避免闪跳）
        if !isDragging {
            lastAngle = currentAngle
            isDragging = true
            return
        }

        // 计算角度增量
        var deltaAngle = currentAngle - lastAngle

        // 处理 0° / 360° 突变边界的平滑过渡
        if deltaAngle > 180 {
            deltaAngle -= 360
        } else if deltaAngle < -180 {
            deltaAngle += 360
        }

        self.angle += deltaAngle
        self.lastAngle = currentAngle
    }

    func dotColor(_ upNumber: Int = 0, _ angle: Int) -> Color {
        let colors: [Color] = [
            .gray.opacity(0.5), .green, .teal, .blue, .yellow, .orange, .purple, .red,
        ] + Array(repeating: Color.red, count: 20)

        let number = abs(Int(angle / 360)) + upNumber
        let index = number % colors.count
        return colors[index]
    }
}

/// VolumePeakView
///

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
    PTTContentView()
}
