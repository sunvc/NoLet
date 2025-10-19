//
//  AnimatedBlob.swift
//  NoLet
//
//  Created by lynn on 2025/6/25.
//  https://github.com/constzz/Animated-Voice-Blob
import UIKit
import SwiftUI

///  VoiceBlobViewRepresentable(
///    maxLevel: 1.0,
///    smallBlobRange: (min: 0.5, max: 1.0),
///    mediumBlobRange: (min: 0.4, max: 0.8),
///    bigBlobRange: (min: 0.3, max: 0.6),
///    audioLevel: $audioLevel,
///    isAnimating: $isAnimating,
///    color: .systemBlue
///    )
///    .frame(width: 200, height: 200)


struct VoiceBlobViewRepresentable: UIViewRepresentable {
    typealias UIViewType = VoiceBlobView
    
    let maxLevel: CGFloat
    let smallBlobRange: VoiceBlobView.BlobRange
    let mediumBlobRange: VoiceBlobView.BlobRange
    let bigBlobRange: VoiceBlobView.BlobRange
    
    @Binding var audioLevel: CGFloat
    @Binding var isAnimating: Bool
    var color: UIColor

    func makeUIView(context: Context) -> VoiceBlobView {
        let view = VoiceBlobView(
            frame: .zero,
            maxLevel: maxLevel,
            smallBlobRange: smallBlobRange,
            mediumBlobRange: mediumBlobRange,
            bigBlobRange: bigBlobRange
        )
        view.setColor(color, animated: false)
        return view
    }

    func updateUIView(_ uiView: VoiceBlobView, context: Context) {
        // 动态更新颜色
        uiView.setColor(color, animated: true)
        
        // 更新音量等级
        uiView.updateLevel(audioLevel)
        
        // 控制动画状态
        if isAnimating {
            uiView.startAnimating()
        } else {
            uiView.stopAnimating()
        }
    }
}


@MainActor
final class VoiceBlobView: UIView {
    private var smallBlob: BlobNode
    private var mediumBlob: BlobNode
    private var bigBlob: BlobNode
    
    private let maxLevel: CGFloat
    
    private var displayLinkAnimator: ConstantDisplayLinkAnimator?
    
    private var audioLevel: CGFloat = 0
    public var presentationAudioLevel: CGFloat = 0
    
    private(set) var isAnimating = false
    
    public typealias BlobRange = (min: CGFloat, max: CGFloat)
    
    public init(
        frame: CGRect,
        maxLevel: CGFloat,
        smallBlobRange: BlobRange,
        mediumBlobRange: BlobRange,
        bigBlobRange: BlobRange
    ) {
        self.maxLevel = maxLevel
        
        self.smallBlob = BlobNode(
            pointsCount: 8,
            minRandomness: 0.1,
            maxRandomness: 0.5,
            minSpeed: 0.2,
            maxSpeed: 0.6,
            minScale: smallBlobRange.min,
            maxScale: smallBlobRange.max,
            scaleSpeed: 0.2,
            isCircle: true
        )
        self.mediumBlob = BlobNode(
            pointsCount: 8,
            minRandomness: 1,
            maxRandomness: 1,
            minSpeed: 0.9,
            maxSpeed: 4,
            minScale: mediumBlobRange.min,
            maxScale: mediumBlobRange.max,
            scaleSpeed: 0.2,
            isCircle: false
        )
        self.bigBlob = BlobNode(
            pointsCount: 8,
            minRandomness: 1,
            maxRandomness: 1,
            minSpeed: 0.9,
            maxSpeed: 4,
            minScale: bigBlobRange.min,
            maxScale: bigBlobRange.max,
            scaleSpeed: 0.2,
            isCircle: false
        )
        
        super.init(frame: .zero)
        
        addSubview(bigBlob)
        addSubview(mediumBlob)
        addSubview(smallBlob)
        
        self.displayLinkAnimator = ConstantDisplayLinkAnimator { [weak self] in
            guard let self = self else { return }
            
            self.presentationAudioLevel = self.presentationAudioLevel * 0.9 + self.audioLevel * 0.1
            
            self.smallBlob.level = self.presentationAudioLevel
            self.mediumBlob.level = self.presentationAudioLevel
            self.bigBlob.level = self.presentationAudioLevel
        }
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public func setColor(_ color: UIColor) {
        setColor(color, animated: false)
    }
    
    public func setColor(_ color: UIColor, animated: Bool) {
        smallBlob.setColor(color, animated: animated)
        mediumBlob.setColor(color.withAlphaComponent(0.3), animated: animated)
        bigBlob.setColor(color.withAlphaComponent(0.15), animated: animated)
    }
    
    public func updateLevel(_ level: CGFloat) {
        updateLevel(level, immediately: false)
    }
    
    public func updateLevel(_ level: CGFloat, immediately: Bool = false) {
        let normalizedLevel = min(1, max(level / maxLevel, 0))
        
        smallBlob.updateSpeedLevel(to: normalizedLevel)
        mediumBlob.updateSpeedLevel(to: normalizedLevel)
        bigBlob.updateSpeedLevel(to: normalizedLevel)
        
        audioLevel = normalizedLevel
        if immediately {
            presentationAudioLevel = normalizedLevel
        }
    }
    
    public func startAnimating() {
        startAnimating(immediately: false)
    }
    
    public func startAnimating(immediately: Bool = false) {
        guard !isAnimating else { return }
        isAnimating = true
        
        if !immediately {
            mediumBlob.layer.animateScale(from: 0.75, to: 1, duration: 0.35, removeOnCompletion: false)
            bigBlob.layer.animateScale(from: 0.75, to: 1, duration: 0.35, removeOnCompletion: false)
        } else {
            mediumBlob.layer.removeAllAnimations()
            bigBlob.layer.removeAllAnimations()
        }
        
        updateBlobsState()
        
        displayLinkAnimator?.isPaused = false
    }
    
    public func stopAnimating() {
        stopAnimating(duration: 0.15)
    }
    
    public func stopAnimating(duration: Double) {
        guard isAnimating else { return }
        isAnimating = false
        
        mediumBlob.layer.animateScale(from: 1.0, to: 0.75, duration: duration, removeOnCompletion: false)
        bigBlob.layer.animateScale(from: 1.0, to: 0.75, duration: duration, removeOnCompletion: false)
        
        updateBlobsState()
        
        displayLinkAnimator?.isPaused = true
    }
    
    public func updateSmallBlob(_ updateBlob: (any BlobNodeProtocol) -> Void) {
        updateBlob(smallBlob)
    }
    
    public func updateMediumBlob(_ updateBlob: (any BlobNodeProtocol) -> Void) {
        updateBlob(mediumBlob)
    }
    
    public func updateBigBlob(_ updateBlob: (any BlobNodeProtocol) -> Void) {
        updateBlob(bigBlob)
    }
    
    private func updateBlobsState() {
        if isAnimating {
            if smallBlob.frame.size != .zero {
                smallBlob.startAnimating()
                mediumBlob.startAnimating()
                bigBlob.startAnimating()
            }
        } else {
            smallBlob.stopAnimating()
            mediumBlob.stopAnimating()
            bigBlob.stopAnimating()
        }
    }
    
    override public func layoutSubviews() {
        super.layoutSubviews()
        
        smallBlob.frame = bounds
        mediumBlob.frame = bounds
        bigBlob.frame = bounds
        
        updateBlobsState()
    }
}






@MainActor
public protocol BlobNodeProtocol: AnyObject {
    var pointsCount: Int { get set }
    var isCircle: Bool { get set }
    var color: UIColor? { get }
    var level: CGFloat { get set }
}

fileprivate extension CALayer {
    @discardableResult
    func animateScale(from fromValue: CGFloat, to toValue: CGFloat, duration: Double, removeOnCompletion: Bool) -> CABasicAnimation {
        let scaleAnimation = CABasicAnimation(keyPath: "transform.scale")
        scaleAnimation.fromValue = fromValue
        scaleAnimation.toValue = toValue
        scaleAnimation.duration = duration
        scaleAnimation.repeatCount = .infinity
        scaleAnimation.isRemovedOnCompletion = removeOnCompletion
        scaleAnimation.timingFunction = CAMediaTimingFunction(name: .linear)
        return scaleAnimation
    }
}

fileprivate final class DisplayLinkTarget: NSObject {
    private let f: () -> Void
    
    public init(_ f: @escaping () -> Void) {
        self.f = f
    }
    
    @objc public func event() {
        self.f()
    }
}

fileprivate final class ConstantDisplayLinkAnimator {
    private var displayLink: CADisplayLink?
    private let update: () -> Void
    private var completed = false
    
    public var frameInterval: Int = 1 {
        didSet {
            self.updateDisplayLink()
        }
    }
    
    private func updateDisplayLink() {
        guard let displayLink = self.displayLink else {
            return
        }
        if self.frameInterval == 1 {
            if #available(iOS 15.0, *) {
                self.displayLink?.preferredFrameRateRange = CAFrameRateRange(minimum: 60.0, maximum: 120.0, preferred: 120.0)
            }
        } else {
            displayLink.preferredFramesPerSecond = 30
        }
    }
    
    public var isPaused: Bool = true {
        didSet {
            if self.isPaused != oldValue {
                if !self.isPaused, self.displayLink == nil {
                    let displayLink = CADisplayLink(target: DisplayLinkTarget { [weak self] in
                        self?.tick()
                    }, selector: #selector(DisplayLinkTarget.event))
                    displayLink.add(to: RunLoop.main, forMode: .common)
                    self.displayLink = displayLink
                    self.updateDisplayLink()
                }
                
                self.displayLink?.isPaused = self.isPaused
            }
        }
    }
    
    public init(update: @escaping () -> Void) {
        self.update = update
    }
    
    deinit {
        if let displayLink = self.displayLink {
            displayLink.isPaused = true
            displayLink.invalidate()
        }
    }
    
    public func invalidate() {
        if let displayLink = self.displayLink {
            displayLink.isPaused = true
            displayLink.invalidate()
        }
    }
    
    @objc private func tick() {
        if self.completed {
            return
        }
        self.update()
    }
}

fileprivate extension UIBezierPath {
    static func smoothCurve(
        through points: [CGPoint],
        length: CGFloat,
        smoothness: CGFloat
    ) -> UIBezierPath {
        var smoothPoints = [SmoothPoint]()
        for index in 0 ..< points.count {
            let prevIndex = index - 1
            let prev = points[prevIndex >= 0 ? prevIndex : points.count + prevIndex]
            let curr = points[index]
            let next = points[(index + 1) % points.count]
            
            let angle: CGFloat = {
                let dx = next.x - prev.x
                let dy = -next.y + prev.y
                let angle = atan2(dy, dx)
                if angle < 0 {
                    return abs(angle)
                } else {
                    return 2 * .pi - angle
                }
            }()
            
            smoothPoints.append(
                SmoothPoint(
                    point: curr,
                    inAngle: angle + .pi,
                    inLength: smoothness * distance(from: curr, to: prev),
                    outAngle: angle,
                    outLength: smoothness * distance(from: curr, to: next)
                )
            )
        }
        
        let resultPath = UIBezierPath()
        resultPath.move(to: smoothPoints[0].point)
        for index in 0 ..< smoothPoints.count {
            let curr = smoothPoints[index]
            let next = smoothPoints[(index + 1) % points.count]
            let currSmoothOut = curr.smoothOut()
            let nextSmoothIn = next.smoothIn()
            resultPath.addCurve(to: next.point, controlPoint1: currSmoothOut, controlPoint2: nextSmoothIn)
        }
        resultPath.close()
        return resultPath
    }
    
    private static func distance(from fromPoint: CGPoint, to toPoint: CGPoint) -> CGFloat {
        return sqrt((fromPoint.x - toPoint.x) * (fromPoint.x - toPoint.x) + (fromPoint.y - toPoint.y) * (fromPoint.y - toPoint.y))
    }
}

fileprivate extension UIBezierPath {
    struct SmoothPoint {
        let point: CGPoint
        
        let inAngle: CGFloat
        let inLength: CGFloat
        
        let outAngle: CGFloat
        let outLength: CGFloat
        
        func smoothIn() -> CGPoint {
            return smooth(angle: inAngle, length: inLength)
        }
        
        func smoothOut() -> CGPoint {
            return smooth(angle: outAngle, length: outLength)
        }
        
        private func smooth(angle: CGFloat, length: CGFloat) -> CGPoint {
            return CGPoint(
                x: point.x + length * cos(angle),
                y: point.y + length * sin(angle)
            )
        }
    }
}

@MainActor
fileprivate final class BlobNode: UIView, BlobNodeProtocol, @preconcurrency CAAnimationDelegate {
    var pointsCount: Int {
        didSet {
            self.smoothness = Self.smoothnessForPointsCount(pointsCount: self.pointsCount)
        }
    }
    
    private var smoothness: CGFloat = .zero
    
    private let minRandomness: CGFloat
    private let maxRandomness: CGFloat
    
    private let minSpeed: CGFloat
    private let maxSpeed: CGFloat
    
    private let minScale: CGFloat
    private let maxScale: CGFloat
    private let scaleSpeed: CGFloat
    
    var isCircle: Bool {
        didSet { setNeedsDisplay() }
    }
    
    var color: UIColor? {
        if let color = shapeLayer.fillColor {
            return UIColor(cgColor: color)
        }
        
        return nil
    }
    
    var level: CGFloat = 0 {
        didSet {
            if abs(self.level - oldValue) > 0.01 {
                CATransaction.begin()
                CATransaction.setDisableActions(true)
                let lv = self.minScale + (self.maxScale - self.minScale) * self.level
                self.shapeLayer.transform = CATransform3DMakeScale(lv, lv, 1)
                CATransaction.commit()
            }
        }
    }
    
    private var speedLevel: CGFloat = 0
    private var scaleLevel: CGFloat = 0
    
    private var lastSpeedLevel: CGFloat = 0
    private var lastScaleLevel: CGFloat = 0
    
    private let shapeLayer: CAShapeLayer = {
        let layer = CAShapeLayer()
        layer.strokeColor = nil
        return layer
    }()
    
    private var transition: CGFloat = 0 {
        didSet {
            guard let currentPoints = currentPoints else { return }
            
            self.shapeLayer.path = UIBezierPath.smoothCurve(through: currentPoints, length: bounds.width, smoothness: self.smoothness).cgPath
        }
    }
    
    private var fromPoints: [CGPoint]?
    private var toPoints: [CGPoint]?
    
    private var currentPoints: [CGPoint]? {
        guard let fromPoints = fromPoints, let toPoints = toPoints else { return nil }
        
        return fromPoints.enumerated().map { offset, fromPoint in
            let toPoint = toPoints[offset]
            return CGPoint(
                x: fromPoint.x + (toPoint.x - fromPoint.x) * transition,
                y: fromPoint.y + (toPoint.y - fromPoint.y) * transition
            )
        }
    }
    
    init(
        pointsCount: Int,
        minRandomness: CGFloat,
        maxRandomness: CGFloat,
        minSpeed: CGFloat,
        maxSpeed: CGFloat,
        minScale: CGFloat,
        maxScale: CGFloat,
        scaleSpeed: CGFloat,
        isCircle: Bool
    ) {
        self.pointsCount = pointsCount
        self.minRandomness = minRandomness
        self.maxRandomness = maxRandomness
        self.minSpeed = minSpeed
        self.maxSpeed = maxSpeed
        self.minScale = minScale
        self.maxScale = maxScale
        self.scaleSpeed = scaleSpeed
        self.isCircle = isCircle
        
        self.smoothness = Self.smoothnessForPointsCount(pointsCount: pointsCount)
        
        super.init(frame: .zero)
        
        self.layer.addSublayer(self.shapeLayer)
        
        self.shapeLayer.transform = CATransform3DMakeScale(minScale, minScale, 1)
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setColor(_ color: UIColor, animated: Bool) {
        self.shapeLayer.fillColor = color.cgColor
    }
    
    func updateSpeedLevel(to newSpeedLevel: CGFloat) {
        self.speedLevel = max(self.speedLevel, newSpeedLevel)
    }
    
    func startAnimating() {
        self.animateToNewShape()
    }
    
    func stopAnimating() {
        self.shapeLayer.removeAnimation(forKey: "path")
    }
    
    private func animateToNewShape() {
        if self.isCircle { return }
        
        if self.shapeLayer.path == nil {
            let points = self.nextBlob(for: self.bounds.size)
            self.shapeLayer.path = UIBezierPath.smoothCurve(through: points, length: bounds.width, smoothness: self.smoothness).cgPath
        }
        
        let nextPoints = self.nextBlob(for: self.bounds.size)
        let nextPath = UIBezierPath.smoothCurve(through: nextPoints, length: bounds.width, smoothness: self.smoothness).cgPath
        
        let animation = CABasicAnimation(keyPath: "path")
        let previousPath = self.shapeLayer.path
        self.shapeLayer.path = nextPath
        animation.duration = CFTimeInterval(1 / (self.minSpeed + (self.maxSpeed - self.minSpeed) * self.speedLevel))
        animation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        animation.fromValue = previousPath
        animation.toValue = nextPath
        animation.isRemovedOnCompletion = false
        animation.fillMode = .forwards
        animation.delegate = self
        
        self.shapeLayer.add(animation, forKey: "path")
        
        self.lastSpeedLevel = self.speedLevel
        self.speedLevel = 0
    }
    
    func animationDidStop(_ anim: CAAnimation, finished flag: Bool) {
        if flag {
            self.animateToNewShape()
        }
    }
    
    private func nextBlob(for size: CGSize) -> [CGPoint] {
        let randomness = self.minRandomness + (self.maxRandomness - self.minRandomness) * self.speedLevel
        return Self.blob(pointsCount: self.pointsCount, randomness: randomness)
            .map {
                return CGPoint(
                    x: $0.x * CGFloat(size.width),
                    y: $0.y * CGFloat(size.height)
                )
            }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        self.shapeLayer.position = CGPoint(x: bounds.midX, y: bounds.midY)
        if self.isCircle {
            let halfWidth = self.bounds.width * 0.5
            self.shapeLayer.path = UIBezierPath(
                roundedRect: self.bounds.offsetBy(dx: -halfWidth, dy: -halfWidth),
                cornerRadius: halfWidth
            ).cgPath
        }
        CATransaction.commit()
    }
}

fileprivate extension BlobNode {
    static func blob(pointsCount: Int, randomness: CGFloat) -> [CGPoint] {
        let angle = (CGFloat.pi * 2) / CGFloat(pointsCount)
        
        let rgen = { () -> CGFloat in
            let accuracy: UInt32 = 1000
            let random = arc4random_uniform(accuracy)
            return CGFloat(random) / CGFloat(accuracy)
        }
        
        let rangeStart: CGFloat = 1 / (1 + randomness / 10)
        
        let startAngle = angle * CGFloat(arc4random_uniform(100)) / CGFloat(100)
        
        let points = (0 ..< pointsCount).map { i -> CGPoint in
            let randPointOffset = (rangeStart + CGFloat(rgen()) * (1 - rangeStart)) / 2
            let angleRandomness: CGFloat = angle * 0.1
            let randAngle = angle + angle * ((angleRandomness * CGFloat(arc4random_uniform(100)) / CGFloat(100)) - angleRandomness * 0.5)
            let pointX = sin(startAngle + CGFloat(i) * randAngle)
            let pointY = cos(startAngle + CGFloat(i) * randAngle)
            return CGPoint(
                x: pointX * randPointOffset,
                y: pointY * randPointOffset
            )
        }
        
        return points
    }
    
    private static func smoothnessForPointsCount(pointsCount: Int) -> CGFloat {
        let angle = (CGFloat.pi * 2) / CGFloat(pointsCount)
        return ((4 / 3) * tan(angle / 4)) / sin(angle / 2) / 2
    }
}


