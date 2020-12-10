//
//  ImageViewController.swift
//  HotTakes
//
//  Created by Zach Crews on 12/10/20.
//

import UIKit

class ImageViewController: UIViewController {
    @IBOutlet weak var imageView: UIImageView!
    
    var image: UIImage!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if image == nil {
            image = UIImage()
        }

        imageView.image = image
    }
    
    
}
