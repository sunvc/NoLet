//
//  DatabaseManager.swift
//  NoLet
//
//  Created by lynn on 2025/5/26.
//
import GRDB
import Foundation

public class DatabaseManager {
    
    public static let shared = try! DatabaseManager()
    
    
    public let dbQueue: DatabaseQueue
    public let localPath:URL
    
    private init() throws {
    
        self.localPath = CONTAINER.appendingPathComponent( NCONFIG.databaseName, conformingTo: .database)
        
        // DatabasePool 只在这里创建一次
        self.dbQueue = try DatabaseQueue(path: self.localPath.path)
    
        try Message.createInit(dbQueue: dbQueue)
        try ChatGroup.createInit(dbQueue: dbQueue)
        try ChatMessage.createInit(dbQueue: dbQueue)
        try ChatPrompt.createInit(dbQueue: dbQueue)
        try PttMessageModel.createInit(dbQueue: dbQueue)
        
    }
    
}


