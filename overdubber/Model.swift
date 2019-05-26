//
//  Model.swift
//  overdubber
//
//  Created by THORBJOERN THRONDSEN BONVIK on 26/5/19.
//  Copyright © 2019 THORBJOERN THRONDSEN BONVIK. All rights reserved.
//

import Foundation

class Model{
    let LIB_NAME = "OverdubberLibrary"
    
    init() {
        let fileManager = FileManager.default
        if let tDocumentDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first {
            let filePath =  tDocumentDirectory.appendingPathComponent("\(LIB_NAME)")
            if !fileManager.fileExists(atPath: filePath.path) {
                do {
                    try fileManager.createDirectory(atPath: filePath.path, withIntermediateDirectories: true, attributes: nil)
                } catch {
                    NSLog("Couldn't create document directory")
                }
            }
            NSLog("Document directory is \(filePath)")
            addFakeFiles(path:filePath)
        }
        
        
        
        
        
    }
    
    func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }
    
    func addFakeFiles(path:URL){
        let fakeFile1 = Bundle.main.url(forResource: "mp3", withExtension: "m4a")
        let fakeFile2 = Bundle.main.url(forResource: "example", withExtension: "m4a")
        
            let file = "mp3.m4a"
            let fileURL = path.appendingPathComponent(file)
            let filePath = String(fileURL.absoluteString.dropFirst(8))
            
            if FileManager.default.fileExists(atPath: filePath) {
                print("Lib Test Files Exists")
            } else {
                print("Copy Lib Test Files")
                
                let copyFile = path.appendingPathComponent(file)
                do{
                    try FileManager.default.copyItem(at: fakeFile1!, to: copyFile)
                    print("File1 copied to local folder")
                    try FileManager.default.copyItem(at: fakeFile2!, to: path.appendingPathComponent("example.m4a"))
                    print("File2 copied to local folder")
                }catch{
                    print("Copy Failed.")
                }
            }
        }
    
    
    func getLibList() -> [URL]?{
        
        return nil
    }
}
