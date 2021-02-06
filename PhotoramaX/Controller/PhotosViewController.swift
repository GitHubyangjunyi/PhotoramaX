//
//  PhotosViewController.swift
//  PhotoramaX
//
//  Created by 杨俊艺 on 2020/5/12.
//  Copyright © 2020 杨俊艺. All rights reserved.
//

import UIKit
import Gemini

//精选图片视图控制器
class PhotosViewController: UIViewController {

    @IBOutlet var collectionView: GeminiCollectionView!
    @IBOutlet weak var effect: UIBarButtonItem!
    
    var store: PhotoStore!
    let photoDataSource = PhotoDataSource()
    var animationEffect = AnimationEffect.cubeAnimation
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.store = PhotoStore()
        
        // 先加载本地的旧照片避免网络情况较差时白屏
        updateDataSource()
        
        collectionView.dataSource = photoDataSource
        collectionView.delegate = self // 联系更紧密的操作可以交给视图控制器而将数据源分离出去
        collectionView.gemini.cubeAnimation().cubeDegree(90).cornerRadius(75)
        
        store.fetchInterestingPhotos { (PhotosResult) -> Void in
            self.updateDataSource()
        }

        showPrivacyAlert()
    }
    
    func updateDataSource() {
        store.fetchAllPhotos { (photoResult) in
            switch photoResult {
                case let .success(photos):
                    self.photoDataSource.photos = photos
                case .failure:
                    self.photoDataSource.photos.removeAll()
            }
            self.collectionView.reloadSections(IndexSet(integer: 0))
        }
    }
    
    // 相册权限弹窗逻辑
    func showPrivacyAlert() {
        // 第一次进入App时没有弹过窗所以进行弹窗
        let angent = UserDefaults.standard.bool(forKey: "ACCESS")
        if !angent {
            let privacyAlert = UIAlertController.init(title: "AI Recognition", message: "Our app will read your photos or use the camera to take photos for image recognition, please allow!", preferredStyle: .alert)

            privacyAlert.addAction(UIAlertAction(title: "Allow", style: .default) { _ in
                UserDefaults.standard.set(true, forKey: "ACCESS")
            })
            
            privacyAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel) { _ in
                UserDefaults.standard.set(false, forKey: "ACCESS")
            })
            present(privacyAlert, animated: false)
        }
        //a little logic problem
        UserDefaults.standard.set(true, forKey: "ACCESS")
        UserDefaults.standard.synchronize()
    }

    @IBAction func changeEffect(_ sender: UIBarButtonItem) {
        switch self.animationEffect {
        case .cubeAnimation:
            collectionView.gemini.circleRotationAnimation().radius(400).rotateDirection(.clockwise)
            self.animationEffect.toggle()
        case .circleRotationAnimation:
            collectionView.gemini.scaleAnimation().scale(0.75).scaleEffect(.scaleUp)
            self.animationEffect.toggle()
        case .scaleAnimation:
            collectionView.gemini.customAnimation().backgroundColor(startColor: UIColor.gray, endColor: UIColor.blue).ease(.easeOutSine).cornerRadius(75)
            self.animationEffect.toggle()
        case .customAnimation:
            collectionView.gemini.cubeAnimation().cubeDegree(90).cornerRadius(75)
            self.animationEffect.toggle()
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segue.identifier {
        case "showPhoto"?:
            if let selectedIndexPath = collectionView.indexPathsForSelectedItems?.first {
                let photo = photoDataSource.photos[selectedIndexPath.row]
                let destinationVC = segue.destination as! PhotoInfoViewController
                destinationVC.photo = photo
                destinationVC.store = store
            }
        default:
            preconditionFailure("exception")
        }
    }
}

extension PhotosViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 5
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "TestCell", for: indexPath) as! GeminiCell
        self.collectionView.animateCell(cell)
        return cell
    }
}

extension PhotosViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize.init(width: 325, height: 325)
    }
}

extension PhotosViewController: UICollectionViewDelegate {
    // 在即将展示某个Cell时再去下载照片数据
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        let photo = photoDataSource.photos[indexPath.row]
        // 根据photo模型的URL去下载对应的照片
        store.fetchImage(for: photo) { (result) -> Void in
            // 照片的indexPath可能会在请求前后发生变化,因此需要获取最新的indexPath
            guard let photoIndex = self.photoDataSource.photos.firstIndex(of: photo),
                case let .Success(image) = result else {
                    return
            }
            let photoindexPath = IndexPath(item: photoIndex, section: 0)
            //请求完成后之后cell依旧可见时才更新cell
            if let cell = self.collectionView.cellForItem(at: photoindexPath) as? PhotoCollectionViewCell {
                cell.update(with: image)
                self.collectionView.animateCell(cell)
            }
        }
        // 当UICollectionViewCell显示到屏幕上时照片数据会重新加载所以实现了照片缓存,如果缓存中有就不用再次发起网络请求
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        self.collectionView.animateVisibleCells()
    }
    
    // 自动切换到下一个Cell
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.scrollToItem(at: IndexPath.init(item: indexPath.item + 1, section: indexPath.section), at: .centeredVertically, animated: true)
    }
}

enum AnimationEffect {
    case cubeAnimation
    case circleRotationAnimation
    case scaleAnimation
    case customAnimation
    
    mutating func toggle() {
        switch self {
            case .cubeAnimation:
                self = .circleRotationAnimation
            case .circleRotationAnimation:
                self = .scaleAnimation
            case .scaleAnimation:
                self = .customAnimation
            case .customAnimation:
                self = .cubeAnimation
        }
    }
}
