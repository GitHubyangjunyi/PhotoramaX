//
//  PhotoInfoViewController.swift
//  PhotoramaX
//
//  Created by 杨俊艺 on 2020/5/12.
//  Copyright © 2020 杨俊艺. All rights reserved.
//

import UIKit
import CoreML
import Vision
import ImageIO

class PhotoInfoViewController: UIViewController {
    @IBOutlet var imageView: UIImageView!
    @IBOutlet weak var classificationLabel: UILabel!
    
    lazy var classificationRequest: VNCoreMLRequest = {
        do {
            let model = try VNCoreMLModel(for: MobileNet().model)
            
            let request = VNCoreMLRequest(model: model, completionHandler: { [weak self] request, error in
                self?.processClassifications(for: request, error: error)
            })
            request.imageCropAndScaleOption = .centerCrop
            return request
        } catch {
            fatalError("Failed to load Vision ML model: \(error)")
        }
    }()
    
    func updateClassifications(for image: UIImage) {
        classificationLabel.text = "Classifying..."
        
        let orientation = CGImagePropertyOrientation(image.imageOrientation)
        guard let ciImage = CIImage(image: image) else { fatalError("Unable to create \(CIImage.self) from \(image).") }
        
        DispatchQueue.global(qos: .userInitiated).async {
            let handler = VNImageRequestHandler(ciImage: ciImage, orientation: orientation)
            do {
                try handler.perform([self.classificationRequest])
            } catch {
                print("Failed to perform classification.\n\(error.localizedDescription)")
            }
        }
    }
    
    func processClassifications(for request: VNRequest, error: Error?) {
        DispatchQueue.main.async {
            guard let results = request.results else {
                self.classificationLabel.text = "Unable to classify image.\n\(error!.localizedDescription)"
                return
            }
            let classifications = results as! [VNClassificationObservation]
        
            if classifications.isEmpty {
                self.classificationLabel.text = "Nothing recognized."
            } else {
                let topClassifications = classifications.prefix(2)
                let descriptions = topClassifications.map { classification in
                    // Formats the classification for display; e.g. "(0.37) cliff, drop, drop-off".
                   return String(format: "confidence:  (%.2f) %@", classification.confidence, classification.identifier)
                }
                self.classificationLabel.text = "Possible matching classification results:\n" + descriptions.joined(separator: "\n")
            }
        }
    }
    
    
    
    var photo: Photo! {
        didSet {
            navigationItem.title = photo.title
        }
    }
    var store: PhotoStore!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let longTap = UILongPressGestureRecognizer.init(target: self, action: #selector(self.save))
        self.imageView.addGestureRecognizer(longTap)
        
        
        store.fetchImage(for: photo) { (result) in
            switch result {
            case let .Success(image):
                self.imageView.image = image
                
                self.updateClassifications(for: image)
                
            case let .Failure(error):
                print(error)
            }
        }
    }
    
    @objc func save() {
        
        let title = "Save"
        let message = "Are you sure?"
        let ac = UIAlertController(title: title, message: message, preferredStyle: .actionSheet)
        //取消和删除动作
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        let deleteAction = UIAlertAction(title: "Save", style: .destructive, handler: { (action) -> Void in
            UIImageWriteToSavedPhotosAlbum(((self.imageView.image ?? UIImage.init(named: "ML.png"))!), nil, nil, nil)
        })
        ac.addAction(deleteAction)
        ac.addAction(cancelAction)
        //将提示弹窗显示出来
        self.present(ac, animated: true, completion: nil)
    }
    
}
