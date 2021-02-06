//
//  Photo+CoreDataClass.swift
//  
//
//  Created by 杨俊艺 on 2021/2/5.
//
//

import Foundation
import CoreData

@objc(Photo)
public class Photo: NSManagedObject {

}

// 删除的内容
//class Photo {
//    let title: String
//    var photoID: String
//    let remoteURL: URL
//    let dateTaken: Date
//
//    init(title: String, photoID: String, remoteURL: URL, dateTaken: Date) {
//        self.title = title
//        self.photoID = photoID
//        self.remoteURL = remoteURL
//        self.dateTaken = dateTaken
//    }
//}
//
//extension Photo: Equatable {
//    static func == (lhs: Photo, rhs: Photo) -> Bool {
//        return lhs.photoID == rhs.photoID
//    }
//}
