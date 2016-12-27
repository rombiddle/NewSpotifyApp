//
//  SavedTableViewController.swift
//  NewSpotifyApp
//
//  Created by Romain Brunie on 12/7/16.
//  Copyright © 2016 Romain Brunie. All rights reserved.
//

import UIKit
import CoreData

class SavedTableViewController: UITableViewController {
    
    @IBAction func editActionButton(_ sender: UIBarButtonItem) {
        self.isEditing = !self.isEditing
        if sender.title == "Edit"{
            sender.title = "Done"
        }else{
            sender.title = "Edit"
        }
    }
    
    var Song = [NSManagedObject]()
    let managedContext = DataManager().objectContext

    override func viewDidLoad() {
        super.viewDidLoad()
        print("viewDidLoad")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        print("viewWillAppear")
        super.viewWillAppear(animated)
        // fetching all the songs from core data
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Song")
        do {
            let songs = try managedContext?.fetch(fetchRequest)
            Song = songs as! [NSManagedObject]
        } catch let error as NSError {
            print("Could not fetch \(error), \(error.userInfo)")
        }
        self.tableView.reloadData()
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return Song.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "songID", for: indexPath)

        // Configure the cell...
        let imageView = cell.viewWithTag(1) as! UIImageView
        if let imageData = Song[indexPath.row].value(forKey: "albumImage") as? Data{
            imageView.image = UIImage(data: imageData, scale: 1)
        }
        
        let songLabel = cell.viewWithTag(2) as! UILabel
        songLabel.text = Song[indexPath.row].value(forKey: "titleSong") as? String
        let artistLabel = cell.viewWithTag(3) as! UILabel
        artistLabel.text = Song[indexPath.row].value(forKey: "artist") as? String

        return cell
    }

    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }

    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let songToDelete = Song[indexPath.row]
            // remove from list
            Song.remove(at: indexPath.row)
            // remove from core data
            managedContext?.delete(songToDelete as NSManagedObject)
            do {
                try managedContext?.save()
            } catch let error as NSError {
                print("Could not save \(error), \(error.userInfo)")
            }
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }

    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {
        let item = Song[fromIndexPath.row];
        // remove and insert from table
        Song.remove(at: fromIndexPath.row);
        Song.insert(item, at: to.row)
        // remove and insert from code data
//        managedContext?.delete(Song[fromIndexPath.row] as NSManagedObject)
//        managedContext?.insert(item)
//        managedContext?
    }

    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
