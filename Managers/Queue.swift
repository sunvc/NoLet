//
//  Queue.swift
//  NoLet
//
//  Author:        Copyright (c) 2024 QingHe. All rights reserved.
//  Document:      https://wiki.wzs.app
//  E-mail:        to@wzs.app
//
//  History:
//    Created by Neo on 2025/7/24.
//
import Foundation

private let QueueSpecificKey = DispatchSpecificKey<NSObject>()

private let globalMainQueue = Queue(queue: DispatchQueue.main, specialIsMainQueue: true)
private let globalDefaultQueue = Queue(
    queue: DispatchQueue.global(qos: .default),
    specialIsMainQueue: false
)
private let globalBackgroundQueue = Queue(
    queue: DispatchQueue.global(qos: .background),
    specialIsMainQueue: false
)

public final class Queue {
    private let nativeQueue: DispatchQueue
    private var specific = NSObject()
    private let specialIsMainQueue: Bool

    public var queue: DispatchQueue {
        return nativeQueue
    }

    public class func mainQueue() -> Queue {
        return globalMainQueue
    }

    public class func concurrentDefaultQueue() -> Queue {
        return globalDefaultQueue
    }

    public class func concurrentBackgroundQueue() -> Queue {
        return globalBackgroundQueue
    }

    public init(queue: DispatchQueue) {
        nativeQueue = queue
        specialIsMainQueue = false
    }

    fileprivate init(queue: DispatchQueue, specialIsMainQueue: Bool) {
        nativeQueue = queue
        self.specialIsMainQueue = specialIsMainQueue
    }

    public init(name: String? = nil, qos: DispatchQoS = .default) {
        nativeQueue = DispatchQueue(label: name ?? "", qos: qos)

        specialIsMainQueue = false

        nativeQueue.setSpecific(key: QueueSpecificKey, value: specific)
    }

    public func isCurrent() -> Bool {
        if DispatchQueue.getSpecific(key: QueueSpecificKey) === specific {
            return true
        } else if specialIsMainQueue && Thread.isMainThread {
            return true
        } else {
            return false
        }
    }

    public func async(_ f: @escaping () -> Void) {
        if isCurrent() {
            f()
        } else {
            nativeQueue.async(execute: f)
        }
    }

    public func sync(_ f: () -> Void) {
        if isCurrent() {
            f()
        } else {
            nativeQueue.sync(execute: f)
        }
    }

    public func justDispatch(_ f: @escaping () -> Void) {
        nativeQueue.async(execute: f)
    }

    public func justDispatchWithQoS(qos: DispatchQoS, _ f: @escaping () -> Void) {
        nativeQueue.async(group: nil, qos: qos, flags: [.enforceQoS], execute: f)
    }

    public func after(_ delay: Double, _ f: @escaping () -> Void) {
        let time = DispatchTime.now() + delay
        nativeQueue.asyncAfter(deadline: time, execute: f)
    }
}
