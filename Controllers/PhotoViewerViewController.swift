//
//  PhotoViewerViewController.swift
//  Messenger
//
//  Created by Алексей Авдейчик on 13.07.21.
//

import UIKit
import SDWebImage

final class PhotoViewerViewController: UIViewController {

    
    
    private let url: URL
    
    init(with url: URL) {
        self.url = url
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private let imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    
    override func viewDidLoad() {
        title = "Photo"
        navigationItem.largeTitleDisplayMode = .never
        super.viewDidLoad()
        view.backgroundColor = .black
        view.addSubview(imageView)
        imageView.sd_setImage(with: url, completed: nil)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        imageView.frame = view.bounds
    }

}
