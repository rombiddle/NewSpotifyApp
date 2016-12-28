//
//  SavedTableViewController.swift
//  NewSpotifyApp
//
//  Created by Romain Brunie on 12/7/16.
//  Copyright © 2016 Romain Brunie. All rights reserved.
//
// This table view shows all the songs saved through the search table view.
// CoreData is used to save all the songs.

import UIKit
import CoreData

class SavedTableViewController: UITableViewController {
    
    // Array to display songs from CoreData
    var Song = [NSManagedObject]()
    
    let managedContext = DataManager().objectContext
    
    override func viewWillAppear(_ animated: Bool) {
        
        super.viewWillAppear(animated)
        
        // fetching all the songs from CoreData
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
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return Song.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "songID", for: indexPath)

        // Configure the cell...
        // tag 1 is the album image
        let imageView = cell.viewWithTag(1) as! UIImageView
        // album image is saved as Binary Data in the CoreData, so I have to get it as an UIImage to display it
        if let imageData = Song[indexPath.row].value(forKey: "albumImage") as? Data{
            imageView.image = UIImage(data: imageData, scale: 1)
        }
        // tag 2 is the title of the song
        let songLabel = cell.viewWithTag(2) as! UILabel
        songLabel.text = Song[indexPath.row].value(forKey: "titleSong") as? String
        // tag 3 is the name of the artist
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
            // remove from table view cells
            Song.remove(at: indexPath.row)
            // remove from CoreData
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

    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return false
    }

}
