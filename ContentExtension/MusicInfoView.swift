//
//  MusicInfoView.swift
//  NoLet
//
//  Created by lynn on 2025/5/14.
//

import UIKit
import AVFoundation
import Defaults

class MusicInfoView: UIView, AVAudioPlayerDelegate {

    private let progressSlider = UISlider()
    private let playPauseButton = UIButton(type: .system)
    private let stopButton = UIButton(type: .system)
    
    private var timer: CADisplayLink?
    private var isUserSeeking = false
    private var waitingTime:Int = 0
    private var lastWaitingUpdate: CFTimeInterval = .zero


    var audioPlayer: AVAudioPlayer? {
        didSet {
            if let player = audioPlayer {
                playPauseButton.isEnabled = true
                stopButton.isEnabled = true
                
                stopButton.setTitle(formatTime(player.duration), for: .normal)
                progressSlider.value = 0
                playPauseButton.setTitle("0:00", for: .normal)

                if Defaults[.voicesAutoSpeak]{
                    startTimer()
                    self.playStatue = !player.isPlaying
                }
            }
        }
    }
    
    var text: String? {
        didSet {
            startTimer()
            Task.detached(priority: .userInitiated) {[weak self] in
                guard let self = self, let text = await text else { return }
                let client = try VoiceManager()
                let filePath = try await client.createVoice(text: text)
                let player = try AVAudioPlayer(contentsOf: filePath)
                await MainActor.run {
                    self.audioPlayer = player
                    self.audioPlayer!.delegate = self
                }
               
            }
        }
    }
    
    var playStatue:Bool = false{
        didSet{
            if playStatue {
                isUserSeeking = false
                startTimer()
                audioPlayer?.play()
            }else{
                timer?.invalidate()
                audioPlayer?.pause()
            }
            Haptic.impact()
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }
    

    private func setupUI() {
        playPauseButton.setTitle("0.00", for: .disabled)
        stopButton.setTitle("-.--", for: .disabled)
        playPauseButton.isEnabled = false
        stopButton.isEnabled = false
        stopButton.setTitleColor(UIColor.red, for: .disabled)
        playPauseButton.setTitleColor(UIColor.red, for: .disabled)
        // 播放进度滑块
        progressSlider.minimumValue = 0
        progressSlider.maximumValue = 1
        progressSlider.value = 0
        progressSlider.minimumTrackTintColor = .systemBlue
        progressSlider.maximumTrackTintColor = UIColor.systemGray5
        
        
    
        if let originalImage = UIImage(named: "logo") {
            // 1. 调整图片大小
            let size = CGSize(width: 30, height: 30)
            UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
            originalImage.draw(in: CGRect(origin: .zero, size: size))
            let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            
            // 2. 设置渲染模式并应用颜色
            if let resizedImage = resizedImage {
//                let tintedImage = resizedImage
////                    .withRenderingMode(.alwaysTemplate)
////                    .withTintColor(.systemBlue)
                // 3. 将处理后的图片应用到滑块
                progressSlider.tintColor = .systemBlue
                progressSlider.setThumbImage(resizedImage, for: .normal)
            
            }
        }
        
        progressSlider.addTarget(self, action: #selector(handleSliderChange), for: .valueChanged)
        progressSlider.addTarget(self, action: #selector(beginSeeking), for: .touchDown)
        progressSlider.addTarget(self, action: #selector(endSeeking), for: [.touchUpInside, .touchUpOutside])
        progressSlider.isUserInteractionEnabled = true
        
        // 播放暂停按钮
        playPauseButton.addTarget(self, action: #selector(playPauseTapped), for: .touchUpInside)

        // 停止按钮
        stopButton.addTarget(self, action: #selector(stopTapped), for: .touchUpInside)
        
    
        // 布局
        let hStack = UIStackView(arrangedSubviews: [playPauseButton, progressSlider, stopButton])
        hStack.axis = .horizontal
        hStack.spacing = 8
        hStack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(hStack)

        NSLayoutConstraint.activate([
            hStack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            hStack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            hStack.topAnchor.constraint(equalTo: topAnchor, constant: 8),
            hStack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -8)
        ])
    }

    @objc private func playPauseTapped(_ gesture: UITapGestureRecognizer) {
        guard let player = audioPlayer else { return }
        self.playStatue = !player.isPlaying
    }

    @objc private func stopTapped() {
        
        timer?.invalidate()
        audioPlayer?.stop()
        audioPlayer?.currentTime = 0
        progressSlider.value = 0
        playPauseButton.setTitle("0:00", for: .normal)
        Haptic.impact()
    }
    
    private func startTimer() {
        timer?.invalidate()
        // 使用 CADisplayLink 替代 Timer（与屏幕刷新率同步，默认 60FPS）
        timer = CADisplayLink(target: self, selector: #selector(updateUI))
        timer?.add(to: .main, forMode: .common) // 确保在滚动等操作时仍能更新
    }
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        timer?.invalidate()
        progressSlider.value = 0
        playPauseButton.setTitle("0:00", for: .normal)
        
    }

    @objc private func updateUI() {
        guard let player = audioPlayer, !isUserSeeking else {
            let now = CACurrentMediaTime()
            // 每 1 秒更新一次 title
            if now - lastWaitingUpdate >= 1 {
                lastWaitingUpdate = now
                waitingTime += 1
                stopButton.setTitle(formatTime(TimeInterval(waitingTime)), for: .disabled)
            }
            return
        }
        playPauseButton.setTitle(formatTime(player.currentTime), for: .normal)
        
        self.progressSlider.value = Float(player.currentTime / player.duration)
        
    }
    
    
    @objc private func beginSeeking() {
        Haptic.impact()
        isUserSeeking = true
        audioPlayer?.pause()
        timer?.invalidate()
    }
    
    @objc private func endSeeking() {
        isUserSeeking = false
        guard let player = audioPlayer else { return }
        
        let seekTime = TimeInterval(progressSlider.value) * player.duration
        player.currentTime = seekTime
        playPauseButton.setTitle(formatTime(seekTime), for: .normal)
        
        startTimer()
        player.play()
        Haptic.impact()
    }
    
    @objc private func handleSliderChange() {
        guard let player = audioPlayer else { return }
        playPauseButton.setTitle(formatTime(TimeInterval(progressSlider.value) * player.duration), for: .normal)
        Haptic.selection(limitFrequency: true)
    }

    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

extension UIFont {
    class func preferredFont(ofSize size: CGFloat, weight: Weight = .regular) -> UIFont {
        return UIFontMetrics.default.scaledFont(for: UIFont.systemFont(ofSize: size, weight: weight))
    }
}
