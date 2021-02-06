//
//  PhotoStore.swift
//  PhotoramaX
//
//  Created by 杨俊艺 on 2020/5/12.
//  Copyright © 2020 杨俊艺. All rights reserved.
//

import Foundation
import UIKit
import CoreData

enum ImageResult {
    case Success(UIImage)
    case Failure(Error)
}

enum PhotoError: Error {
    case imageCreationError
}

class PhotoStore {
    // 照片缓存仓库
    let imageStore = ImageStore()
    
    // 商店的搬运工
    let session = URLSession(configuration: URLSessionConfiguration.default)
    
    // CoreData栈操作钳
    let presistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "Photorama")
        container.loadPersistentStores { NSEntityDescription, error in
            if let error = error {
                print("设置Core Data失败")
            }
        }
        return container
    }()
    
    func fetchInterestingPhotos(completion: @escaping (PhotosResult) -> Void) {
        // 1.使用URL生成请求订单
        let request = URLRequest(url: FlickrAPI.interestingPhotosURL)
        // 2.使用请求订单让搬运工建立任务并布置完成任务后的工作
        let task = session.dataTask(with:request) { (data, response, error) -> Void in
            var result = self.processPhotosRequest(data: data, error: error)
            if case .success = result {
                do {
                    try self.presistentContainer.viewContext.save() // 2x保存上下文更改
                } catch let error {
                    result = .failure(error)
                }
            }
            
            // 使用主线程进行闭包的操作,可能闭包需要更新UI
            OperationQueue.main.addOperation {
                completion(result)
            }
        }
        // 3.发起任务
        task.resume()
    }
    
    // 处理网络请求带回来的数据
    private func processPhotosRequest(data: Data?, error: Error?) -> PhotosResult {
        // 确保有数据传递给FlickrAPI工具进行处理
        guard let jsonData = data else { return .failure(error!) }
        // 传入CoreData上下文对象让工具处理网络请求返回的数据
        return FlickrAPI.photos(fromJSON: jsonData, into: presistentContainer.viewContext)
    }
    
    func fetchAllPhotos(completion: @escaping (PhotosResult) -> Void) {
        let sortByDateTaken = NSSortDescriptor.init(key: #keyPath(Photo.dateTaken), ascending: true)
        let fetchRequest: NSFetchRequest<Photo> = Photo.fetchRequest() // 必须要有类型声明
        fetchRequest.sortDescriptors = [sortByDateTaken]
        let viewContext = presistentContainer.viewContext
        viewContext.perform {
            do {
                let allPhotos = try viewContext.fetch(fetchRequest) // 通过上下文对象执行请求
                completion(.success(allPhotos))
            } catch {
                completion(.failure(error))
            }
        }
    }
    
    // 传入Photo对象并根据该对象的URL下载图片并用闭包参数处理图片
    func fetchImage(for photo: Photo, completion: @escaping (ImageResult) -> Void) {
        guard let photoKey = photo.photoID else { preconditionFailure("Photo对象无id") }
        // 先在缓存中查找照片
        if let image = imageStore.image(forKey: photoKey) {
            // 使用主线程进行闭包的操作,可能completion需要更新UI
            OperationQueue.main.addOperation {
                completion(.Success(image))
            }
            return
        }
        
        guard let photoURL = photo.remoteURL else { preconditionFailure("Photo对象无URL") }
        let request = URLRequest(url: photoURL as URL)
        let task = session.dataTask(with: request) { (data, response, error) -> Void in
            let result = self.processImageRequest(data: data, error: error)
            // 存入照片缓存
            if case let .Success(image) = result {
                self.imageStore.setImage(image, forKey: photoKey)
            }
            // 使用主线程进行闭包的操作,可能completion需要更新UI
            OperationQueue.main.addOperation {
                completion(result)
            }
        }
        task.resume()
    }
    
    // 将请求到的单个图片原始数据转换成UIImage图片
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
