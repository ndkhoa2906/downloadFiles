//
//  Download.swift
//  MasterGCD
//
//  Created by Monster on 10/14/19.
//  Copyright © 2019 khoanguyen. All rights reserved.
//

import Foundation

class Download {
    
    var file: FileModel
    init(file: FileModel) {
        self.file = file
    }
    
    var task: URLSessionDownloadTask?
    var isDownloading = false
    var resumeData: Data?
    
    var progress: Float = 0
    
}
