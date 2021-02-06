//
//  TagDataSource.swift
//  PhotoramaX
//
//  Created by 杨俊艺 on 2021/2/6.
//  Copyright © 2021 杨俊艺. All rights reserved.
//

import UIKit
import CoreData

class TagDataSource: NSObject, UITableViewDataSource {
    var tags: [Tag] = []
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tags.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "UITableViewCell", for: indexPath)
        cell.textLabel?.text = tags[indexPath.row].name
        return cell
    }
    
    
}
