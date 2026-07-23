//
//  PTTAudioStateMachine.swift
//  NoLet
//
//  Pure state/effect model for every PTT audio path. AVFoundation objects stay
//  in their managers; this reducer only decides which ordered effects run.
//

import Foundation

struct PTTLocalPlaybackContext: Equatable {
    let id: UUID
    let generation: UInt64
    let message: AudioMessage
}

struct PTTRemotePlaybackContext: Equatable {
    let sessionID: String
    let channel: String
    let speakerID: String
    let speakerName: String?
}

enum PTTPlaybackRef: Equatable {
    case local(PTTLocalPlaybackContext)
    case remote(PTTRemotePlaybackContext)
}

enum PTTRecordingOrigin: Equatable {
    case user
    case developer
    case handsfree
    case unknown
}

struct PTTRecordingContext: Equatable {
    let id: UUID
    let origin: PTTRecordingOrigin
    let activity: Bool
    let saveLocalCopy: Bool
}

enum PTTSuspensionBlocker: Hashable {
    case interruption
    case audioSessionInactive
}

struct PTTSuspensionContext: Equatable {
    let playback: PTTPlaybackRef?
    let recording: PTTRecordingContext?
}

enum PTTAudioState: Equatable {
    case idle
    case preparingPlayback(PTTPlaybackRef)
    case playing(PTTPlaybackRef)
    case preparingRecording(PTTRecordingContext)
    case recording(PTTRecordingContext)
    case finishingRecording(PTTRecordingContext)
    case suspended(PTTSuspensionContext)
}

struct PTTRemotePushMetadata: Equatable {
    let host: String
    let channel: String
    let sessionID: String
    let speakerID: String
    let speakerName: String?
}

enum PTTAudioEvent: Equatable {
    case localPlayRequested(AudioMessage)
    case playNextRequested
    case stopPlaybackRequested
    case recordRequested(origin: PTTRecordingOrigin, activity: Bool, saveLocalCopy: Bool)
    case recordStopRequested(cancelled: Bool)

    case localPlaybackStarted(id: UUID, generation: UInt64)
    case localPlaybackProgress(id: UUID, generation: UInt64, elapsed: TimeInterval, duration: TimeInterval)
    case localPlaybackFinished(id: UUID, generation: UInt64)
    case localPlaybackFailed(id: UUID, generation: UInt64, reason: String)

    case remoteStreamBegan(PTTRemotePlaybackContext)
    case remoteActivated(sessionID: String)
    case remoteInputEnded(sessionID: String)
    case remoteProgress(sessionID: String, elapsed: TimeInterval, level: Double)
    case remotePlaybackDrained(sessionID: String)
    case remoteFailed(sessionID: String, reason: String)

    case recorderStarted(id: UUID)
    case recorderStopped(id: UUID, data: Data?)
    case recorderFailed(id: UUID, reason: String)

    case remotePushReceived(PTTRemotePushMetadata)
    case transmitBegan(origin: PTTRecordingOrigin)
    case transmitEnded(origin: PTTRecordingOrigin)
    case audioSessionActivated
    case audioSessionDeactivated
    case interruptionBegan
    case interruptionEnded(shouldResume: Bool)
    case explicitResume

    case powerOffRequested
}

enum PTTAudioEffect: Equatable {
    case prepareLocal(PTTLocalPlaybackContext)
    case pauseLocal(UUID)
    case resumeLocal(UUID)
    case stopLocal(UUID)

    case queueRemote(PTTRemotePlaybackContext)
    case activateRemote(String)
    case pauseRemote(String)
    case resumeRemote(String)
    case releaseRemote(String)

    case warmSender
    case startRecording(PTTRecordingContext)
    case stopRecording(PTTRecordingContext, cancelled: Bool)
    case startSender(PTTRecordingContext)
    case endSender(cancelled: Bool)

    case wakeRemote(PTTRemotePushMetadata)
    case configureAudioSessionForPlayback
    case sendLeaveAndTeardown
    case resetTelemetry
    case setActiveRemoteParticipant(Bool)
}

struct PTTAudioMachine: Equatable {
    var state: PTTAudioState = .idle
    var pausedLocal: PTTLocalPlaybackContext?
    var pausedRemote: PTTRemotePlaybackContext?
    var remoteQueue: [PTTRemotePlaybackContext] = []
    var pendingRemotePush: PTTRemotePushMetadata?
    var queuedLocal: [AudioMessage] = []
    var transmitIntent = false
    var audioSessionActive = false
    var suspensionBlockers: Set<PTTSuspensionBlocker> = []
    var automaticResumeAllowed = true
    var recordingCancelled = false
    var localGeneration: UInt64 = 0
}

struct PTTAudioTransition {
    var machine: PTTAudioMachine
    var effects: [PTTAudioEffect] = []
}

extension PTTPlaybackRef {
    var isRemote: Bool {
        if case .remote = self { return true }
        return false
    }
}

extension PTTAudioState {
    var playback: PTTPlaybackRef? {
        switch self {
        case .preparingPlayback(let pb), .playing(let pb): return pb
        case .suspended(let ctx): return ctx.playback
        default: return nil
        }
    }

    var recordingContext: PTTRecordingContext? {
        switch self {
        case .preparingRecording(let rc), .recording(let rc), .finishingRecording(let rc):
            return rc
        case .suspended(let ctx):
            return ctx.recording
        default:
            return nil
        }
    }

    var isRecordingPhase: Bool { recordingContext != nil }

    var remoteSessionID: String? {
        guard case .remote(let r) = playback else { return nil }
        return r.sessionID
    }

    var localIdentity: (UUID, UInt64)? {
        guard case .local(let l) = playback else { return nil }
        return (l.id, l.generation)
    }
}

@MainActor
enum PTTAudioReducer {
    static func reduce(_ current: PTTAudioMachine, event: PTTAudioEvent) -> PTTAudioTransition {
        var machine = current
        var effects: [PTTAudioEffect] = []

        func makeLocal(_ msg: AudioMessage) -> PTTLocalPlaybackContext {
            machine.localGeneration &+= 1
            return PTTLocalPlaybackContext(id: UUID(), generation: machine.localGeneration, message: msg)
        }

        func enqueueRemote(_ remote: PTTRemotePlaybackContext) {
            let known = machine.remoteQueue.contains { $0.sessionID == remote.sessionID }
                || machine.state.remoteSessionID == remote.sessionID
            if !known {
                machine.remoteQueue.append(remote)
                effects.append(.queueRemote(remote))
            }
        }

        func selectNextPlayback() {
            if machine.remoteQueue.isEmpty, machine.pausedRemote == nil,
               machine.pausedLocal == nil, machine.queuedLocal.isEmpty {
                machine.state = .idle
                effects += [.resetTelemetry, .setActiveRemoteParticipant(false)]
                return
            }
            if let remote = machine.remoteQueue.first {
                machine.remoteQueue.removeFirst()
                machine.state = .preparingPlayback(.remote(remote))
                effects += [.activateRemote(remote.sessionID), .setActiveRemoteParticipant(true)]
                return
            }
            if let remote = machine.pausedRemote {
                machine.pausedRemote = nil
                machine.state = .playing(.remote(remote))
                effects += [.resumeRemote(remote.sessionID), .setActiveRemoteParticipant(true)]
                return
            }
            if let local = machine.pausedLocal {
                machine.pausedLocal = nil
                machine.state = .playing(.local(local))
                effects.append(.resumeLocal(local.id))
                return
            }
            if let message = machine.queuedLocal.first {
                machine.queuedLocal.removeFirst()
                let local = makeLocal(message)
                machine.state = .preparingPlayback(.local(local))
                effects.append(.prepareLocal(local))
                return
            }
            machine.state = .idle
            effects += [.resetTelemetry, .setActiveRemoteParticipant(false)]
        }

        func resumeIfPossible(_ machine: inout PTTAudioMachine, effects: inout [PTTAudioEffect],
                              explicit: Bool = false) {
            guard case .suspended(let ctx) = machine.state,
                  machine.suspensionBlockers.isEmpty,
                  explicit || machine.automaticResumeAllowed else { return }
            if machine.transmitIntent, let old = ctx.recording {
                let rc = PTTRecordingContext(id: UUID(), origin: old.origin, activity: old.activity,
                                              saveLocalCopy: old.saveLocalCopy)
                machine.state = .preparingRecording(rc)
                effects += [.warmSender, .startSender(rc), .startRecording(rc)]
                return
            }
            if let playback = ctx.playback {
                machine.state = .playing(playback)
                switch playback {
                case .local(let local): effects.append(.resumeLocal(local.id))
                case .remote(let remote): effects.append(.resumeRemote(remote.sessionID))
                }
            } else {
                machine.state = .idle
            }
        }

        // ── main event dispatcher ──────────────────────────────────────
        switch event {
        case .localPlayRequested(let message):
            switch machine.state {
            case .idle:
                let local = makeLocal(message)
                machine.state = .preparingPlayback(.local(local))
                effects.append(.prepareLocal(local))
            case .preparingRecording, .recording, .finishingRecording:
                machine.queuedLocal.append(message)
            case .playing(.remote), .preparingPlayback(.remote), .suspended:
                machine.queuedLocal.append(message)
            case .playing(.local(let cur)), .preparingPlayback(.local(let cur)):
                effects.append(.stopLocal(cur.id))
                let local = makeLocal(message)
                machine.state = .preparingPlayback(.local(local))
                effects.append(.prepareLocal(local))
            }

        case .playNextRequested:
            if case .playing(let pb) = machine.state {
                switch pb {
                case .local(let l): effects.append(.stopLocal(l.id))
                case .remote(let r): effects.append(.releaseRemote(r.sessionID))
                }
            }
            selectNextPlayback()

        case .stopPlaybackRequested:
            switch machine.state {
            case .playing(let pb), .preparingPlayback(let pb):
                switch pb {
                case .local(let l): effects.append(.stopLocal(l.id))
                case .remote(let r): effects.append(.releaseRemote(r.sessionID))
                }
                machine.pausedLocal = nil
                machine.remoteQueue.removeAll()
                machine.state = .idle
                effects.append(.resetTelemetry)
            case .suspended(let ctx):
                if let pb = ctx.playback {
                    switch pb {
                    case .local(let l): effects.append(.stopLocal(l.id))
                    case .remote(let r): effects.append(.releaseRemote(r.sessionID))
                    }
                }
                machine.pausedLocal = nil
                machine.remoteQueue.removeAll()
                machine.state = .idle
                effects.append(.resetTelemetry)
            default: break
            }

        case .recordRequested(let origin, let activity, let save):
            guard !machine.state.isRecordingPhase else { break }
            if let pb = machine.state.playback {
                switch pb {
                case .local(let l):
                    machine.pausedLocal = l
                    effects.append(.pauseLocal(l.id))
                case .remote(let r):
                    machine.pausedRemote = r
                    effects.append(.pauseRemote(r.sessionID))
                }
            }
            let rc = PTTRecordingContext(id: UUID(), origin: origin, activity: activity,
                                         saveLocalCopy: save)
            machine.recordingCancelled = false
            machine.state = .preparingRecording(rc)
            effects += [.warmSender, .startSender(rc), .startRecording(rc)]

        case .recordStopRequested(let cancelled):
            guard let rc = machine.state.recordingContext else { break }
            machine.recordingCancelled = cancelled
            machine.transmitIntent = false
            machine.state = .finishingRecording(rc)
            effects += [.endSender(cancelled: cancelled), .stopRecording(rc, cancelled: cancelled)]

        case .recorderStarted(let id):
            guard case .preparingRecording(let rc) = machine.state, rc.id == id else { break }
            machine.state = .recording(rc)

        case .recorderStopped(let id, _):
            guard case .finishingRecording(let rc) = machine.state, rc.id == id else { break }
            selectNextPlayback()

        case .recorderFailed(let id, _):
            guard let rc = machine.state.recordingContext, rc.id == id else { break }
            effects.append(.endSender(cancelled: true))
            selectNextPlayback()

        case .remoteStreamBegan(let remote):
            switch machine.state {
            case .idle:
                // If the audio session isn't active yet (e.g. second+
                // calls over an already-open WS — no push this time),
                // queue the remote and nudge PushToTalk with the speaker
                // name so it activates the session. audioSessionActivated
                // will then dequeue and activate this remote.
                if !machine.audioSessionActive {
                    machine.remoteQueue.insert(remote, at: 0)
                    effects.append(.queueRemote(remote))
                    effects.append(.setActiveRemoteParticipant(true))
                    break
                }
                machine.state = .preparingPlayback(.remote(remote))
                effects.append(.activateRemote(remote.sessionID))
            case .playing(.local(let l)), .preparingPlayback(.local(let l)):
                machine.pausedLocal = l
                effects.append(.pauseLocal(l.id))
                if machine.audioSessionActive {
                    machine.state = .preparingPlayback(.remote(remote))
                    effects.append(.activateRemote(remote.sessionID))
                } else {
                    machine.remoteQueue.insert(remote, at: 0)
                    effects.append(.queueRemote(remote))
                    effects.append(.setActiveRemoteParticipant(true))
                }
            case .preparingRecording, .recording, .finishingRecording:
                enqueueRemote(remote)
            case .playing(.remote), .preparingPlayback(.remote), .suspended:
                enqueueRemote(remote)
            }

        case .remoteInputEnded:
            break

        case .remotePlaybackDrained(let sessionID):
            guard machine.state.remoteSessionID == sessionID else {
                machine.remoteQueue.removeAll { $0.sessionID == sessionID }
                break
            }
            effects.append(.releaseRemote(sessionID))
            selectNextPlayback()

        case .remoteFailed(let sessionID, _):
            machine.remoteQueue.removeAll { $0.sessionID == sessionID }
            if machine.state.remoteSessionID == sessionID {
                effects.append(.releaseRemote(sessionID))
                selectNextPlayback()
            }

        case .localPlaybackStarted(let id, let gen):
            guard case .preparingPlayback(.local(let l)) = machine.state,
                  l.id == id, l.generation == gen else { break }
            machine.state = .playing(.local(l))

        case .localPlaybackFinished(let id, let gen),
             .localPlaybackFailed(let id, let gen, _):
            guard let ident = machine.state.localIdentity,
                  ident.0 == id, ident.1 == gen else { break }
            selectNextPlayback()

        case .remoteProgress, .localPlaybackProgress:
            break

        case .remoteActivated(let sessionID):
            guard case .preparingPlayback(.remote(let r)) = machine.state,
                  r.sessionID == sessionID else { break }
            machine.state = .playing(.remote(r))

        case .transmitBegan(let origin):
            machine.transmitIntent = true
            if !machine.state.isRecordingPhase {
                if machine.state.recordingContext != nil { break }
                let rc = PTTRecordingContext(id: UUID(), origin: origin, activity: false,
                                              saveLocalCopy: true)
                if let pb = machine.state.playback {
                    switch pb {
                    case .local(let l):
                        machine.pausedLocal = l
                        effects.append(.pauseLocal(l.id))
                    case .remote(let r):
                        machine.pausedRemote = r
                        effects.append(.pauseRemote(r.sessionID))
                    }
                }
                machine.state = .preparingRecording(rc)
                effects += [.warmSender, .startSender(rc), .startRecording(rc)]
            }

        case .transmitEnded:
            machine.transmitIntent = false
            if let rc = machine.state.recordingContext {
                machine.state = .finishingRecording(rc)
                effects += [.endSender(cancelled: false), .stopRecording(rc, cancelled: false)]
            }

        case .interruptionBegan:
            machine.suspensionBlockers.insert(.interruption)
            machine.automaticResumeAllowed = true
            if let pb = machine.state.playback {
                switch pb {
                case .local(let l):
                    machine.pausedLocal = l
                    effects.append(.pauseLocal(l.id))
                case .remote(let r):
                    machine.pausedRemote = r
                    effects.append(.pauseRemote(r.sessionID))
                }
                machine.state = .suspended(.init(playback: pb, recording: nil))
            } else if let rc = machine.state.recordingContext {
                machine.state = .suspended(.init(playback: nil, recording: rc))
                effects += [.endSender(cancelled: false), .stopRecording(rc, cancelled: false)]
            }

        case .audioSessionDeactivated:
            machine.audioSessionActive = false
            if machine.state.playback?.isRemote == true || !machine.remoteQueue.isEmpty {
                effects.append(.configureAudioSessionForPlayback)
                break
            }
            if !machine.state.isRecordingPhase, let pb = machine.state.playback {
                switch pb {
                case .local(let l):
                    machine.pausedLocal = l
                    effects.append(.pauseLocal(l.id))
                case .remote(let r):
                    machine.pausedRemote = r
                    effects.append(.pauseRemote(r.sessionID))
                }
                machine.state = .suspended(.init(playback: pb, recording: nil))
            }
            machine.suspensionBlockers.insert(.audioSessionInactive)

        case .interruptionEnded(let shouldResume):
            machine.suspensionBlockers.remove(.interruption)
            machine.automaticResumeAllowed = shouldResume
            resumeIfPossible(&machine, effects: &effects)

        case .audioSessionActivated:
            machine.audioSessionActive = true
            machine.suspensionBlockers.remove(.audioSessionInactive)
            // If the receiver has a queued remote session that arrived
            // while `audioSessionActive` was false, activate it now. This
            // is the only safe time to start playback — PushToTalk
            // framework has just granted us the audio session.
            if let first = machine.remoteQueue.first {
                machine.remoteQueue.removeFirst()
                machine.state = .preparingPlayback(.remote(first))
                effects += [.activateRemote(first.sessionID), .setActiveRemoteParticipant(true)]
                break
            }
            if let meta = machine.pendingRemotePush {
                machine.pendingRemotePush = nil
                effects.append(.wakeRemote(meta))
            }
            if machine.transmitIntent, !machine.state.isRecordingPhase {
                let rc = PTTRecordingContext(id: UUID(), origin: .user, activity: false,
                                              saveLocalCopy: true)
                if let pb = machine.state.playback {
                    switch pb {
                    case .local(let l):
                        machine.pausedLocal = l
                        effects.append(.pauseLocal(l.id))
                    case .remote(let r):
                        machine.pausedRemote = r
                        effects.append(.pauseRemote(r.sessionID))
                    }
                }
                machine.state = .preparingRecording(rc)
                effects += [.warmSender, .startSender(rc), .startRecording(rc)]
                break
            }
            resumeIfPossible(&machine, effects: &effects)

        case .explicitResume:
            machine.automaticResumeAllowed = true
            resumeIfPossible(&machine, effects: &effects, explicit: true)

        case .remotePushReceived(let metadata):
            machine.pendingRemotePush = metadata

        case .powerOffRequested:
            switch machine.state {
            case .playing(.local(let l)), .preparingPlayback(.local(let l)):
                effects.append(.stopLocal(l.id))
            case .playing(.remote(let r)), .preparingPlayback(.remote(let r)):
                effects.append(.releaseRemote(r.sessionID))
            case .preparingRecording(let rc), .recording(let rc), .finishingRecording(let rc):
                effects += [.endSender(cancelled: true), .stopRecording(rc, cancelled: true)]
            case .suspended(let ctx):
                if case .local(let l)? = ctx.playback { effects.append(.stopLocal(l.id)) }
                if case .remote(let r)? = ctx.playback { effects.append(.releaseRemote(r.sessionID)) }
                if let rc = ctx.recording {
                    effects += [.endSender(cancelled: true), .stopRecording(rc, cancelled: true)]
                }
            case .idle: break
            }
            machine = PTTAudioMachine()
            effects += [.sendLeaveAndTeardown, .resetTelemetry]
        }
        return PTTAudioTransition(machine: machine, effects: effects)
    }
}
