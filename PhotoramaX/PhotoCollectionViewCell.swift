//
//  PhotoCollectionViewCell.swift
//  PhotoramaX
//
//  Created by 杨俊艺 on 2020/5/12.
//  Copyright © 2020 杨俊艺. All rights reserved.
//

import UIKit
import Gemini

class PhotoCollectionViewCell: GeminiCell {
    @IBOutlet var imageView: UIImageView!
    @IBOutlet var spinner: UIActivityIndicatorView! //旋转的转子
    
    func update(with image: UIImage?) {
        if let imageToDisplay = image {
            spinner.stopAnimating()
            imageView.image = imageToDisplay
        } else {
            spinner.startAnimating()
            imageView.image = nil
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        update(with: nil)
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        update(with: nil)
    }
    
    
}
