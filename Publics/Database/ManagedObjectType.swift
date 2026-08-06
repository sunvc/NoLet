//
//  ManagedObjectType.swift
//  NoLet
//
//  Single source of truth for Core Data entity names, so they are never written
//  as string literals at call sites.
//

import CoreData

protocol ManagedObjectType: NSManagedObject {
    nonisolated static var entityName: String { get }
}

extension MessageEntity: ManagedObjectType {
    nonisolated static let entityName = "MessageEntity"
}

extension ChatGroupEntity: ManagedObjectType {
    nonisolated static let entityName = "ChatGroupEntity"
}

extension ChatMessageEntity: ManagedObjectType {
    nonisolated static let entityName = "ChatMessageEntity"
}

extension AudioMessageEntity: ManagedObjectType {
    nonisolated static let entityName = "AudioMessageEntity"
}
