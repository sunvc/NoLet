//
//  DatabaseManager.swift
//  NoLet
//
//  Author:        Copyright (c) 2024 QingHe. All rights reserved.
//  Document:      https://wiki.wzs.app
//  E-mail:        to@wzs.app
//
//  History:
//    Created by Neo on 2025/5/26.
//
import Foundation
import GRDB

public class DatabaseManager {
    public static let shared = try! DatabaseManager()

    public let dbQueue: DatabaseQueue
    public let localPath: URL

    private init() throws {
        localPath = CONTAINER.appendingPathComponent(NCONFIG.databaseName, conformingTo: .database)

        // DatabasePool 只在这里创建一次
        dbQueue = try DatabaseQueue(path: localPath.path)

        try Message.createInit(dbQueue: dbQueue)
        try ChatGroup.createInit(dbQueue: dbQueue)
        try ChatMessage.createInit(dbQueue: dbQueue)
        try ChatPrompt.createInit(dbQueue: dbQueue)
    }
}
