//
//  FlickrAPI.swift
//  PhotoramaX
//
//  Created by 杨俊艺 on 2020/5/12.
//  Copyright © 2020 杨俊艺. All rights reserved.
//

import Foundation
import CoreData

//方法枚举
enum Method: String {
    case interestingPhotos = "flickr.interestingness.getList"
}

//结果枚举
enum PhotosResult {
    case success([Photo])   //如果成功则枚举关联结果
    case failure(Error)
}

enum FlickrError: Error {
    case invalidJSONData
}

struct FlickrAPI {
    private static let baseURLString = "https://api.flickr.com/services/rest"
    private static let APIKey = "a6d819499131071f158fd740860a5a88"
    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return formatter
    }()
    
    // 根据传入的要请求的方法枚举和请求参数字典生成一个请求URL
    private static func flickrURL(method: Method, parameters: [String:String]?) -> URL {
        //1.使用基础URL创建一个URLComponents
        var components = URLComponents(string: baseURLString)!
        var queryItems = [URLQueryItem]()
        //2.添加基本查询参数
        let baseParameters = [
            "method" : method.rawValue,
            "format" : "json",
            "nojsoncallback" : "1",
            "api_key" : APIKey]
        
        for (key, value) in baseParameters {
            let item = URLQueryItem(name: key, value: value)
            queryItems.append(item)
        }
        //3.有额外查询参数就进行添加
        if let additionalParams = parameters {
            for (key, value) in additionalParams {
                let item = URLQueryItem(name: key, value: value)
                queryItems.append(item)
            }
        }
        //4.组装查询参数
        components.queryItems = queryItems
        //5.获取组装好的请求URL
        return components.url!
    }
    
    // 生成目前项目需要用到的特殊的请求URL
    static var interestingPhotosURL: URL {
        return flickrURL(method: .interestingPhotos, parameters: ["extras" : "url_h,date_taken"])
    }
    
    // 根据返回的JSON数据创建一个Photo对象数组
    static func photos(fromJSON data: Data, into viewContext: NSManagedObjectContext) -> PhotosResult {
        do {
            let jsonObject = try JSONSerialization.jsonObject(with: data, options: [])
            guard let jsonDictionary = jsonObject as? [AnyHashable : Any],
                let photos = jsonDictionary["photos"] as? [String : Any],
                let photosArray = photos["photo"] as? [[String : Any]] else { return .failure(FlickrError.invalidJSONData) }
            var finalPhotos = [Photo]()
            for photoJSON in photosArray {
                if let photo = photo(fromJSON: photoJSON, into: viewContext) {
                    finalPhotos.append(photo)
                }
            }
            // 如果解析完的json数据不为空且finalPhotos数组没有photo对象则表示json数据是损坏的
            if !photosArray.isEmpty && finalPhotos.isEmpty {
                return .failure(FlickrError.invalidJSONData)
            }
            return .success(finalPhotos)
        } catch let error {
            return .failure(error)
        }
    }
    
    // 结合CoreData上下文对象使用Photo字典创建一个Photo对象
    // 创建数据后需要将数据放入NSManagedObjectContext
    private static func photo(fromJSON json: [String : Any], into viewContext: NSManagedObjectContext) -> Photo? {
        guard let photoID = json["id"] as? String,
            let title = json["title"] as? String,
            let dateString = json["datetaken"] as? String,
            let photoURLString = json["url_h"] as? String,
            let url = NSURL(string: photoURLString),
            let dateTaken = dateFormatter.date(from: dateString) else { return nil }
        // 如果找到相同唯一标识的照片则不插入数据，没有找到才插入新的照片数据
        let predicate = NSPredicate(format: "\(#keyPath(Photo.photoID)) == \(photoID)") // 设置条件后将返回0或者1条数据
        let fetchRequest: NSFetchRequest<Photo> = Photo.fetchRequest()
        fetchRequest.predicate = predicate
        var fetchedPhotos: [Photo]?
        viewContext.performAndWait {
            fetchedPhotos = try? fetchRequest.execute()
        }
        if let existingPhoto = fetchedPhotos?.first {
            return existingPhoto
        }
        
        var photo: Photo!
        // 使用返回的数据进行数据插入所以使用同步操作
        viewContext.performAndWait {
            // 1x在上下文中创建一个Photo对象
            photo = Photo(context: viewContext)
            photo.title = title
            photo.photoID = photoID
            photo.remoteURL = url as NSURL
            photo.dateTaken = dateTaken as Date
        }
        return photo
    }
}
