//
//  FileModel.swift
//  MasterGCD
//
//  Created by Monster on 10/13/19.
//  Copyright © 2019 khoanguyen. All rights reserved.
//

import Foundation

class FileModel: NSObject {
    let name: String
    let index: Int
    let url: URL
    var downloaded = false
    
    init(fileName: String, fileUrl: URL, index: Int) {
        self.name = fileName
        self.url = fileUrl
        self.index = index
    }
}
