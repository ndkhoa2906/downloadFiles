//
//  DownloadManager.swift
//  MasterGCD
//
//  Created by Monster on 10/13/19.
//  Copyright © 2019 khoanguyen. All rights reserved.
//

import Foundation


class DownloadManager {
    
    var activeDownloads: [URL: Download] = [ : ]
    
    var downloadsSession: URLSession!
    
    //
    // MARK: - Internal Methods
    //
    func cancelDownload(_ file: FileModel) {
        guard let download = activeDownloads[file.url] else {
            return
        }
        download.resumeData = nil
        download.progress = 0
        download.task?.cancel()
        activeDownloads[file.url] = nil
    }
    
    func pauseDownload(_ file: FileModel) {
        guard
            let download = activeDownloads[file.url],
            download.isDownloading
            else {
                return
        }
        
        download.task?.cancel(byProducingResumeData: { data in
            download.resumeData = data
        })
                
        download.isDownloading = false
    }
    
    func resumeDownload(_ file: FileModel) {
        guard let download = activeDownloads[file.url] else {
            return
        }
        
        if let resumeData = download.resumeData {
            download.task = downloadsSession.downloadTask(withResumeData: resumeData)
        } else {
            download.task = downloadsSession.downloadTask(with: download.file.url)
        }
        
        download.task?.resume()
        download.isDownloading = true
    }
    
    func startDownload(_ file: FileModel) {
        let download = Download(file: file)
        download.task = downloadsSession.downloadTask(with: file.url)
        download.task?.resume()
        download.isDownloading = true
        activeDownloads[download.file.url] = download
    }
    
}


