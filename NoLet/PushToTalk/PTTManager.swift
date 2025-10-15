//
//  PTTManager.swift
//  pushme
//
//  Created by lynn on 2025/8/24.
//


import Foundation
import Combine
import GRDB

protocol PTTManager: ObservableObject{
    
    var active: Bool{ set get }
    var micLevel: Double{  set get }
    var elapsedTime: TimeInterval{  set get }
    var state:TalkieState{  set get }
    var hasMicrophonePermission:Bool {  set get }
    var channelUsers:Int{  set get }
    
    
    func Join(channel: PTTChannel)
    func Level(channel: PTTChannel)
    
    func record()
    func endRecord(isCancel: Bool)
    
    func play(file: PttMessageModel)
    func stopPlay()
}


final class PushTalkManager: PTTManager{
    
    static let shared  = PushTalkManager()
    
    @Published  var active: Bool = false
    @Published  var micLevel: Double = .zero
    @Published  var elapsedTime: TimeInterval = 0
    @Published  var state:TalkieState = .idle
    @Published  var hasMicrophonePermission:Bool  = false
    @Published  var channelUsers:Int = 0
    @Published  var lastFile:PttMessageModel? = nil
    @Published  var waitPlayList:[PttMessageModel] = []
    @Published  var messages:[PttMessageModel] = []
    
    @Published var currentPlay:PttMessageModel? = nil
    
    private let audio = PttAudioManager.shared
    private let queue: Queue
    private var timer: Timer?
    private let interval: TimeInterval = 20
    private var throttler = Throttler(delay: 0.02)
    
    private let database = DatabaseManager.shared
    private var network = Network()
    
    private var observationCancellable: AnyDatabaseCancellable?
    
    private init() {
        self.queue = Queue(name: "PushTalkManager")
        audio.setCallback(callback: self.setData)
        audio.setInterrupted(callback: self.handlerInterrupt)
        startObservingUnreadCount()
    }
    
    deinit{
        observationCancellable?.cancel()
    }
    
    private func startObservingUnreadCount() {
        let observation = ValueObservation.tracking { db -> [PttMessageModel] in
           
            return try PttMessageModel
                .order(PttMessageModel.Columns.timestamp.desc)
                .limit(50)
                .fetchAll(db)
        }
        
        observationCancellable = observation.start(
            in: database.dbQueue,
            scheduling: .async(onQueue: .global()),
            onError: { error in
                NLog.error("Failed to observe unread count:", error)
            },
            onChange: { [weak self] newMessages in
                guard let self = self else { return }
                Queue.mainQueue().async {
                    self.messages = newMessages
                }
                
            }
        )
    }
    
    
    func Join(channel: PTTChannel) {
        NLog.log("进入频道")
        Task{
            let success = await self.network.JoinOrLeval(channel: channel, api: .join)
            
            await MainActor.run{
                self.active = success
                Defaults[.pttHisChannel].set(channel)
                if success{
                    Defaults[.pttHisChannel].setActive(channel)
                }
                
            }
            
        }
        
    }
    
    func Level(channel: PTTChannel) {
        NLog.log("离开频道")
        Task{
            let success = await self.network.JoinOrLeval(channel: channel, api: .leave)
            await MainActor.run{
                self.active = !success
            }
        }
    }
    
    func setData( _ micLevel: Double,_ duration: Double){
        Queue.mainQueue().async {
            self.micLevel = micLevel
            self.elapsedTime = duration
        }
    }
    
    func record() {
        switch state {
        case .idle:
            break
        case .playing:
            self.stopPlay()
        default:
            return
        }
        queue.async {
            Queue.mainQueue().async {
                self.state = .ready
            }
            self.audio.setCategory(true, .playAndRecord)
            try? self.audio.record()
            Queue.mainQueue().async {
                self.state = .recording
            }
        }
    }
    
    func endRecord(isCancel: Bool) {
        
        queue.async {
            
            if let data = self.audio.end(){
                
                if let file = self.saveVoice(data: data){
                    Task{
                        await self.network.sendVoice(message: file)
                    }
                    if !isCancel{
                        
                        Queue.mainQueue().async {
                            self.lastFile = file
                        }
                    }
                }
                
            }
            
            self.resumePlay()
            
        }
    }
    
    func clearWaitList(){
        Queue.mainQueue().async {
            self.waitPlayList = []
            self.stopPlay()
        }
    }
    
    func next(){
        self.audio.stop()
    }
    
    func resumePlay(){
        Queue.mainQueue().async {
            self.state = .idle
            self.setData(0, 0)
            self.audio.stop()
            if self.waitPlayList.count > 0{
                self.play(file: self.waitPlayList.removeLast())
            }
        }
        
    }
    
    func play(file: PttMessageModel) {
        Queue.mainQueue().async {
            self.waitPlayList.append(file)
        }
        
        guard state == .idle else{ return }
      
        queue.async {
            Queue.mainQueue().async {
                self.state = .playing
            }
  
            Task{ @MainActor in
                do{
                    self.audio.setCategory(true, .playback)
            
                    var breakSign:Bool = false
                    while self.waitPlayList.count > 0{
               
                        let current = self.waitPlayList.removeFirst()
                        
                        Queue.mainQueue().async {
                            self.currentPlay = current
                        }
                        
                        if let currentUrl = current.filePath(){
                            try await self.audio.play(filePath: currentUrl)
                        }
                
                        
                        if self.waitPlayList.count > 0{
                            self.audio.stop()
                            try await Task.sleep(for: .seconds(0.1))
                        }
                        
                        if self.state != .playing{
                            breakSign = true
                            break
                        }
                    }
                    if !breakSign{
                        self.stopPlay()
                    }
                    Queue.mainQueue().async {
                        self.currentPlay = nil
                    }
                    
                }catch{
                    NLog.error(error.localizedDescription)
                    self.stopPlay()
                }
                
            }
        }
    }
    
    func stopPlay() {
        Queue.mainQueue().async {
            self.state = .idle
            self.setData(0, 0)
        }
        self.audio.stop()
        
    }
    
    
    

    
    
    func saveVoice(data: Data)-> PttMessageModel? {
        let id = Defaults[.id]
        guard  let channel = Defaults[.pttHisChannel].first(where: {$0.isActive}),
               let filePath = channel.filePath(userID: id)
        else { return nil }
        
        do{
            try data.write(to: filePath)
            let voice = try self.database.dbQueue.write { db in
                let voice = PttMessageModel(channel: channel.hex(), from: id, file: filePath.lastPathComponent, status: .sending)
                try voice.save(db)
                return voice
            }
            return voice
        }catch{
            NLog.error(error.localizedDescription)
            return nil
        }
    }
    
    func saveVoice(remoteFileName: String) async -> PttMessageModel? {
        
        guard let data = await self.network.getVoice(fileName: remoteFileName) else { return  nil}
        
        let names = remoteFileName.split(separator: "-").compactMap({String($0)})
        guard names.count == 5 else { return nil }
        let channel = names[0...2].joined(separator: "-")
        let id = names[4]
        
        guard let channel = Defaults[.pttHisChannel].first(where: {$0.hex() == channel}),
              let filePath = channel.filePath(userID: id) else { return  nil}
        
        do{
            try data.write(to: filePath)
            
            let voice = try await self.database.dbQueue.write { db in
                let voice = PttMessageModel(channel: channel.hex(), from: id, file: filePath.lastPathComponent, status: .unread)
                try voice.save(db)
                return voice
            }
            return voice
        }catch{
            return nil
        }
    }
    
    func setDB(_ value: Float){
        self.audio.setVolume(value)
    }
    
    func playTips(_ fileName: TipsSound, fileExtension:String = "aac", complete:(()->Void)? = nil){
        audio.playTips(fileName, fileExtension: fileExtension, complete: complete)
    }
}

extension PushTalkManager{
    
    private func handlerInterrupt(_ sign: InterruptedType){
        let stop = {
            switch self.state {
            case .idle:
                break
            case .ready:
                self.endRecord(isCancel: true)
            case .recording:
                self.endRecord(isCancel: true)
            case .playing:
                self.stopPlay()
            }
        }
        switch sign {
        case .begin:
            stop()
           
        case .end:
            break
        case .resume:
            Task{
                
                try await Task.sleep(for: .seconds(1))
                self.resumePlay()
            }
            NLog.error("恢复播放")
        case .other:
            stop()
        }
    }
    
    
    func startPolling() {
        
        DispatchQueue.main.async {
            self.stopPolling()
            // 然后设置定时器
            self.timer = Timer.scheduledTimer(withTimeInterval: self.interval, repeats: true) { [weak self] _ in
                Task.detached(priority: .background) {
                    await self?.network.ping()
                }
            }
        }
        
        
    }
    
    func stopPolling() {
        timer?.invalidate()
        timer = nil
    }
    
    class Network:NetworkManager{
        
        
        enum API: String{
            case join = "/ptt/join"
            case leave = "/ptt/leave"
            case ping = "/ptt/ping"
            case send = "/ptt/send"
            case getVoice = "/ptt/voice"
        }
        
        
        
        func JoinOrLeval(channel: PTTChannel, api:API = .join) async -> Bool {
            
            guard let server = channel.server else { return false }
            let url = server.url + api.rawValue
            
            do{
                NLog.log("channel:", channel.hex())
                
                guard let result:baseResponse<Int> =  try await self.fetch(url: url, method: .POST, params: [
                    "id": server.key, "channel": channel.hex()
                ], headers: [:], timeout: 3)else {
                    throw "请求失败"
                }
                
                if let data = result.data{
                    DispatchQueue.main.async{
                        PushTalkManager.shared.channelUsers = data
                    }
                    NLog.log("频道人数:", data)
                }
                
                return result.code == 0
            }catch{
                NLog.error(error)
                return false
            }
            
        }
        
        func ping() async -> Int {
            guard  let channel =  Defaults[.pttHisChannel].first(where: {$0.isActive}),
                   let server = channel.server else { return -2}
            
            let url = server.url + API.ping.rawValue + "/\(channel.hex())"
            let token = Defaults[.pttToken]
            do{
                let data:baseResponse<Int> = try await self.fetch(url: url, method: .GET, params: [:], headers: [ "X-Q": token ], timeout: 3)
                return data.data ?? 0
                
            }catch{
                NLog.error(error.localizedDescription)
                return -1
            }
            
        }
        
        func sendVoice(message: PttMessageModel) async  -> Bool{
            guard  let channel = Defaults[.pttHisChannel].first(where: {$0.isActive}),
                   let server = channel.server,
                   let filePath = message.filePath() else { return false}
            
            let url =  server.url + API.send.rawValue
            
            do{
                let data = try Data(contentsOf: filePath)
                /// 加密
                
                guard let data = CryptoModelConfig.data.encrypt(inputData: data) else {
                    throw "encrypt error"
                }
                
                let response = try await uploadFile(url: url,
                                                    fileData: data,
                                                    fileName:  message.file,
                                                    mimeType: "audio/ogg")
                
                let result = try JSONDecoder().decode(String.self, from: response)
                NLog.log(result)
                return result == "ok"
            }catch{
                NLog.error(error.localizedDescription)
                return false
            }
        }
        
        func getVoice(fileName: String) async -> Data? {
            guard  let channel =  Defaults[.pttHisChannel].first(where: {$0.isActive}),
                   let server = channel.server else { return nil }
            
            do{
                let url = server.url + API.getVoice.rawValue + "/\(fileName)"
                let data = try await self.fetch(url: url, method: .GET, params: [:], headers: [:])
                /// 解密
                guard let data = CryptoModelConfig.data.decrypt(inputData: data.0) else { throw "decrypt error"}
                
                return data
            }catch{
                NLog.error(error.localizedDescription)
                return nil
            }
            
        }
    }
    
   
    
}
