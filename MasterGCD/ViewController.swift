//
//  ViewController.swift
//  MasterGCD
//
//  Created by Monster on 10/13/19.
//  Copyright © 2019 khoanguyen. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    
    var files = [
        FileModel(fileName: "File 1", fileUrl: URL(string: "http://ipv4.download.thinkbroadband.com/50MB.zip")!,  index: 0),
        FileModel(fileName: "File 2", fileUrl: URL(string: "http://ipv4.download.thinkbroadband.com/100MB.zip")!, index: 1),
        FileModel(fileName: "File 3", fileUrl: URL(string: "http://ipv4.download.thinkbroadband.com/200MB.zip")!, index: 2),
        FileModel(fileName: "File 4", fileUrl: URL(string: "http://ipv4.download.thinkbroadband.com/512MB.zip")!, index: 3),
        FileModel(fileName: "File 4", fileUrl: URL(string: "http://ipv4.download.thinkbroadband.com/1GB.zip")!,   index: 4),
    ]
    
    let downloadManager = DownloadManager()
    let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    
    lazy var downloadsSession: URLSession = {
        let configuration = URLSessionConfiguration.background(withIdentifier: "com.khoanguyen.mastergcd")
        return URLSession(configuration: configuration, delegate: self, delegateQueue: nil)
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        downloadManager.downloadsSession = downloadsSession
    }
    
    func reload(_ row: Int) {
        tableView.reloadRows(at: [IndexPath(row: row, section: 0)], with: .none)
    }
    
    func localFilePath(for url: URL) -> URL {
        return documentsPath.appendingPathComponent(url.lastPathComponent)
    }
    
}
// MARK: - UITableViewDataSource
extension ViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return files.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! DownloadTableViewCell
        let fileModel = files[indexPath.row]
        cell.configure(fileModel, download: downloadManager.activeDownloads[fileModel.url])
        cell.selectionStyle = .none
        cell.delegate = self
        return cell
    }
    
}
// MARK: - UITableViewDelegate
extension ViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 80
    }
}
// MARK: - UITableViewDelegate
extension ViewController: DownloadTableViewCellProtocol {
    func didTapCancel(_ cell: DownloadTableViewCell) {
        if let indexPath = tableView.indexPath(for: cell) {
            let file = files[indexPath.row]
            downloadManager.cancelDownload(file)
            reload(indexPath.row)
        }
    }
    
    func didTapDownload(_ cell: DownloadTableViewCell) {
        if let indexPath = tableView.indexPath(for: cell) {
            let file = files[indexPath.row]
            downloadManager.startDownload(file)
            reload(indexPath.row)
        }
    }
    
    func didTapPause(_ cell: DownloadTableViewCell) {
        if let indexPath = tableView.indexPath(for: cell) {
            let file = files[indexPath.row]
            downloadManager.pauseDownload(file)
            reload(indexPath.row)
        }
    }
    
    func didTapResume(_ cell: DownloadTableViewCell) {
        if let indexPath = tableView.indexPath(for: cell) {
          let file = files[indexPath.row]
          downloadManager.resumeDownload(file)
          reload(indexPath.row)
        }
    }
        
    
}
// MARK: - URL Session Delegate
extension ViewController: URLSessionDelegate {
  func urlSessionDidFinishEvents(forBackgroundURLSession session: URLSession) {
    DispatchQueue.main.async {
      if let appDelegate = UIApplication.shared.delegate as? AppDelegate,
        let completionHandler = appDelegate.backgroundSessionCompletionHandler {
        appDelegate.backgroundSessionCompletionHandler = nil
        completionHandler()
      }
    }
  }
}

// MARK: - URLSessionDownloadDelegate
extension ViewController: URLSessionDownloadDelegate {
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        guard let sourceURL = downloadTask.originalRequest?.url else {
            return
        }
        
        let download = downloadManager.activeDownloads[sourceURL]
        downloadManager.activeDownloads[sourceURL] = nil
        
        let destinationURL = localFilePath(for: sourceURL)
        print(destinationURL)
        
        let fileManager = FileManager.default
        try? fileManager.removeItem(at: destinationURL)
        
        do {
            try fileManager.copyItem(at: location, to: destinationURL)
            download?.file.downloaded = true
        } catch let error {
            print("Could not copy file to disk: \(error.localizedDescription)")
        }
        
        if let index = download?.file.index {
            DispatchQueue.main.async { [weak self] in
                self?.tableView.reloadRows(at: [IndexPath(row: index, section: 0)], with: .none)
            }
        }
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        
        guard
            let url = downloadTask.originalRequest?.url,
            let download = downloadManager.activeDownloads[url]  else {
                return
        }
        
        download.progress = Float(totalBytesWritten) / Float(totalBytesExpectedToWrite)
        let totalSize = ByteCountFormatter.string(fromByteCount: totalBytesExpectedToWrite, countStyle: .file)
        let received = ByteCountFormatter.string(fromByteCount: totalBytesWritten, countStyle: .file)
        DispatchQueue.main.async {
            if let downloadCell = self.tableView.cellForRow(at: IndexPath(row: download.file.index, section: 0)) as? DownloadTableViewCell {
                downloadCell.updateDisplay(receivedSize: received, progress: download.progress, totalSize: totalSize)
            }
        }
    }
    
//    func urlSession(_ session: URLSession, task: URLSessionTask, willPerformHTTPRedirection response: HTTPURLResponse, newRequest request: URLRequest, completionHandler: @escaping (URLRequest?) -> Void) {
//
//    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didResumeAtOffset fileOffset: Int64, expectedTotalBytes: Int64) {
        print("resume url: ",downloadTask.originalRequest?.url)
        guard
            let url = downloadTask.originalRequest?.url,
            let download = downloadManager.activeDownloads[url]  else {
                return
        }
        
        download.progress = Float(fileOffset) / Float(expectedTotalBytes)
        let totalSize = ByteCountFormatter.string(fromByteCount: expectedTotalBytes, countStyle: .file)
        let received = ByteCountFormatter.string(fromByteCount: fileOffset, countStyle: .file)
        DispatchQueue.main.async {
            if let downloadCell = self.tableView.cellForRow(at: IndexPath(row: download.file.index, section: 0)) as? DownloadTableViewCell {
                downloadCell.updateDisplay(receivedSize: received, progress: download.progress, totalSize: totalSize)
            }
        }
    }
    
//    func urlSession(_ session: URLSession, task: URLSessionTask, needNewBodyStream completionHandler: @escaping (InputStream?) -> Void) {
//
//    }
//
//
//    func urlSession(_ session: URLSession, task: URLSessionTask, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
//
//    }
//
//    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
//        print(error?.localizedDescription)
//    }
//
//    func urlSession(_ session: URLSession, task: URLSessionTask, willBeginDelayedRequest request: URLRequest, completionHandler: @escaping (URLSession.DelayedRequestDisposition, URLRequest?) -> Void) {
//
//    }
//
//    func urlSession(_ session: URLSession, didBecomeInvalidWithError error: Error?) {
//
//    }
//
//    func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
//
//    }
//
//    func urlSession(_ session: URLSession, task: URLSessionTask, didFinishCollecting metrics: URLSessionTaskMetrics) {
//
//    }
//
    func urlSession(_ session: URLSession, task: URLSessionTask, didSendBodyData bytesSent: Int64, totalBytesSent: Int64, totalBytesExpectedToSend: Int64) {

    }
//
//    func urlSession(_ session: URLSession, taskIsWaitingForConnectivity task: URLSessionTask) {
//
//    }
}
