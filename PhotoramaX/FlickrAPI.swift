//
//  FlickrAPI.swift
//  PhotoramaX
//
//  Created by 杨俊艺 on 2020/5/12.
//  Copyright © 2020 杨俊艺. All rights reserved.
//

import Foundation

//方法枚举
enum Method: String {
    case interestingPhotos = "flickr.interestingness.getList"
}

//结果枚举
enum PhotoResult {
    case success([Photo])   //如果成功则枚举关联结果
    case failure(Error)
}

enum FlickrError: Error {
    case invalidJSONData    //无效的json数据
}

struct FlickrAPI {
    private static let baseURLString = "https://api.flickr.com/services/rest"
    private static let APIKey = "a6d819499131071f158fd740860a5a88"  //APIKey
    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return formatter
    }()
    
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
        if let additionalParams = parameters{
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
    
    static var interestingPhotosURL: URL {
        return flickrURL(method: .interestingPhotos, parameters: ["extras" : "url_h,date_taken"])
    }
    
    //根据返回的JSON数据创建一个Photo对象数组
    static func photos(fromJSON data: Data) -> PhotoResult {
        do {
            let jsonObject = try JSONSerialization.jsonObject(with: data, options: [])
            guard let jsonDictionary = jsonObject as? [AnyHashable : Any],
                let photos = jsonDictionary["photos"] as? [String : Any],
                let photosArray = photos["photo"] as? [[String : Any]] else {
                    return .failure(FlickrError.invalidJSONData)
            }
            var finalPhotos = [Photo]()
            for photoJSON in photosArray {
                if let photo = photo(fromJSON: photoJSON) {
                    finalPhotos.append(photo)
                }
            }
            if finalPhotos.isEmpty && !photosArray.isEmpty {
                return .failure(FlickrError.invalidJSONData)
            }
            return .success(finalPhotos)
        } catch let error {
            return .failure(error)
        }
    }
    
    //使用Photo字典创建一个Photo对象
    private static func photo(fromJSON json: [String : Any]) -> Photo? {
        guard let photoID = json["id"] as? String,
            let title = json["title"] as? String,
            let dateString = json["datetaken"] as? String,
            let photoURLString = json["url_h"] as? String,
            let url = NSURL(string: photoURLString),
            let dateTaken = dateFormatter.date(from: dateString)
        else {
            return nil
        }
        return Photo(title: title, photoID: photoID, remoteURL: url as URL, dateTaken: dateTaken)
    }
}
