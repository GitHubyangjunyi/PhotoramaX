//
//  PhotoStore.swift
//  PhotoramaX
//
//  Created by 杨俊艺 on 2020/5/12.
//  Copyright © 2020 杨俊艺. All rights reserved.
//

import Foundation
import UIKit

enum ImageResult {
    case Success(UIImage)
    case Failure(Error)
}

enum PhotoError: Error {
    case imageCreationError
}

class PhotoStore {
    //照片缓存
    let imageStore = ImageStore()
    
    //1.商店的搬运工
    let session: URLSession = {
        return URLSession(configuration: URLSessionConfiguration.default)
    }()
    
    func fetchInterestingPhotos(completion: @escaping (PhotoResult) -> Void) {
        //2.使用URL生成请求订单
        let request = URLRequest(url: FlickrAPI.interestingPhotosURL)
        //3.使用请求订单让搬运工建立任务并布置完成任务后的工作
        let task = session.dataTask(with:request) { (data, response, error) -> Void in
            let result = self.processPhotosRequest(data: data, error: error)
            //使用主线程进行闭包的操作,可能闭包需要更新UI
            OperationQueue.main.addOperation {
                completion(result)
            }
        }
        //4.发起任务
        task.resume()
    }
    
    //处理搬运工带回来的数据
    private func processPhotosRequest(data: Data?, error: Error?) -> PhotoResult {
        guard let jsonData = data else { return .failure(error!) }
        //使用工具返回Photo模型数组
        return FlickrAPI.photos(fromJSON: jsonData)
    }
    
    //传入Photo对象并根据该对象的URL下载图片并用闭包参数处理图片
    func fetchImage(for photo: Photo, completion: @escaping (ImageResult) -> Void) {
        //先在缓存中查找照片
        let photoKey = photo.photoID
        if let image = imageStore.image(forKey: photoKey) {
            OperationQueue.main.addOperation {
                completion(.Success(image))
            }
        }
        
        let request = URLRequest(url: photo.remoteURL)
        let task = session.dataTask(with: request) { (data, response, error) -> Void in
            let result = self.processImageRequest(data: data, error: error)
            
            //存入照片缓存
            if case let .Success(image) = result {
                self.imageStore.setImage(image, forKey: photoKey)
            }
            
            //使用主线程进行闭包的操作,可能闭包需要更新UI
            OperationQueue.main.addOperation {
                completion(result)
            }
        }
        task.resume()
    }
    
    //将请求到的单个图片数据转换成UIImage图片
    private func processImageRequest(data: Data?, error: Error?) -> ImageResult {
        guard let imageData = data, let image = UIImage(data: imageData) else {
            if data == nil {
                return .Failure(error!)
            }
            else {
                return .Failure(PhotoError.imageCreationError)
            }
        }
        return .Success(image)
    }
}
