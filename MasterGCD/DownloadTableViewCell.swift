//
//  DownloadTableViewCell.swift
//  MasterGCD
//
//  Created by Monster on 10/13/19.
//  Copyright © 2019 khoanguyen. All rights reserved.
//

import UIKit

protocol DownloadTableViewCellProtocol: class {
    func didTapDownload(_ cell: DownloadTableViewCell)
    func didTapPause(_ cell: DownloadTableViewCell)
    func didTapResume(_ cell: DownloadTableViewCell)
    func didTapCancel(_ cell: DownloadTableViewCell)
}

class DownloadTableViewCell: UITableViewCell {
    static var identifier: String {
        return String(describing: self)
    }
    
    weak var delegate: DownloadTableViewCellProtocol?
    var isResume = false
    @IBOutlet weak var lblPercent: UILabel!
    @IBOutlet weak var lblName: UILabel!
    @IBOutlet weak var btnDownload: UIButton!
    @IBOutlet weak var btnPause: UIButton!
    @IBOutlet weak var progressView: UIProgressView!
    @IBOutlet weak var btnCancel: UIButton!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        // Configure the view for the selected state
    }
    
    func configure(_ fileModel: FileModel, download: Download?) {
        lblName.text = fileModel.name
        
        if let download = download {
            btnDownload.isEnabled = !download.isDownloading
            btnPause.isEnabled = download.isDownloading
            btnCancel.isEnabled = download.isDownloading
            isResume = download.progress == 0 ? false : true
        
            progressView.progress = download.progress
            lblPercent.text = String(format: "%.1f%%", download.progress * 100)

        }
    }
    
    @IBAction func downloadFile(_ sender: Any) {
        if isResume {
            delegate?.didTapResume(self)
        } else {
            delegate?.didTapDownload(self)
        }
    }
    
    @IBAction func pauseDownload(_ sender: Any) {
        delegate?.didTapPause(self)
    }
    
    @IBAction func cancelDownload(_ sender: Any) {
        delegate?.didTapCancel(self)
    }
    
    func updateDisplay(receivedSize: String, progress: Float, totalSize : String) {
        progressView.progress = progress
        lblPercent.text = String(format: "%.1f%%", progress * 100)
        //lblPercent.text = String(format: "%@ of %@ (%.1f%%)", receivedSize, totalSize, progress * 100)
    }
}
