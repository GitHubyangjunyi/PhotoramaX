//
//  TagsViewController.swift
//  PhotoramaX
//
//  Created by 杨俊艺 on 2021/2/6.
//  Copyright © 2021 杨俊艺. All rights reserved.
//

import UIKit
import CoreData

class TagsViewController: UITableViewController {
    var store: PhotoStore!
    var photo: Photo!
    let tagDataSource = TagDataSource()
    
    var selectedIndexPaths = [IndexPath]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.dataSource = tagDataSource
        tableView.delegate = self
        updateTags()
    }
    
    func updateTags() {
        store.fetchAllTags { (tagsResult) in
            switch tagsResult {
                case let .success(tags):
                    self.tagDataSource.tags = tags
                    guard let photoTags = self.photo.tags as? Set<Tag> else { return }
                    
                    for tag in photoTags {
                        if let index = self.tagDataSource.tags.firstIndex(of: tag) {
                            let indexPath = IndexPath(row: index, section: 0)
                            self.selectedIndexPaths.append(indexPath)
                        }
                    }
                case let .failure(error):   print("获取标签失败\(error)")
            }
            self.tableView.reloadSections(IndexSet(integer: 0),
                                          with: .automatic)
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let tag = tagDataSource.tags[indexPath.row]
        if let index = selectedIndexPaths.firstIndex(of: indexPath) {
            selectedIndexPaths.remove(at: index)
            photo.removeFromTags(tag)
        } else {
            selectedIndexPaths.append(indexPath)
            photo.addToTags(tag)
        }
        
        do {
            try store.presistentContainer.viewContext.save()
        } catch {
            print("标签保存失败")
        }
        tableView.reloadRows(at: [indexPath], with: .automatic)
    }
    
    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if selectedIndexPaths.firstIndex(of: indexPath) != nil {
            cell.accessoryType = .checkmark
        } else {
            cell.accessoryType = .none
        }
    }
    
    @IBAction func done(_ sender: UIBarButtonItem) {
        presentingViewController?.dismiss(animated: true, completion: {
            
        })
    }
    
    @IBAction func addNewTag(_ sender: UIBarButtonItem) {
        let alertController = UIAlertController.init(title: "添加标签", message: nil, preferredStyle: .alert)
        alertController.addTextField { (textField) in
            textField.placeholder = "请输入标签......"
            textField.autocapitalizationType = .words
        }
        
        let okAction = UIAlertAction.init(title: "完成", style: .default) { (action) in
            if let tagName = alertController.textFields?.first?.text {
                let viewContext = self.store.presistentContainer.viewContext
                let newTag = NSEntityDescription.insertNewObject(forEntityName: "Tag", into: viewContext)
                newTag.setValue(tagName, forKey: "name")
                
                do {
                    try self.store.presistentContainer.viewContext.save()
                } catch {
                    print("标签保存失败\(error)")
                }
                self.updateTags()
            }
        }
        let cancelAction = UIAlertAction.init(title: "取消", style: .cancel, handler: nil)
        alertController.addAction(okAction)
        alertController.addAction(cancelAction)
        present(alertController, animated: true, completion: nil)
    }
    
}
