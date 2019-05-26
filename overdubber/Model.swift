//
//  Model.swift
//  overdubber
//
//  Created by THORBJOERN THRONDSEN BONVIK on 26/5/19.
//  Copyright © 2019 THORBJOERN THRONDSEN BONVIK. All rights reserved.
//

import Foundation

class Model{
    static let shared = Model.init()
    let LIB_NAME = "OverdubberLibrary"
    let LIB_URL:URL
    
    init() {
        let fileManager = FileManager.default
        if let tDocumentDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first {
            LIB_URL =  tDocumentDirectory.appendingPathComponent("\(LIB_NAME)")
            if !fileManager.fileExists(atPath: LIB_URL.path) {
                do {
                    try fileManager.createDirectory(atPath: LIB_URL.path, withIntermediateDirectories: true, attributes: nil)
                } catch {
                    NSLog("Couldn't create document directory")
                }
            }
            NSLog("Document directory is \(LIB_URL)")
            
            addFakeFiles(path:LIB_URL)
        }
        else{
            LIB_URL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0] // THis is bull. TODO better error handling, what to do if above fails?
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
        var records:[URL]?
        do {
            let urls = try FileManager.default.contentsOfDirectory(at: LIB_URL, includingPropertiesForKeys: nil, options: FileManager.DirectoryEnumerationOptions.skipsHiddenFiles)
            records = urls.filter( { (name: URL) -> Bool in
                return name.lastPathComponent.hasSuffix("m4a")
            })
            
        } catch let error as NSError {
            print(error.localizedDescription)
        } catch {
            print("something went wrong when listing recordings")
        }
        return records
    }
}
