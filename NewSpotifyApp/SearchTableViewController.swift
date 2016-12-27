//
//  SearchTableViewController.swift
//  NewSpotifyApp
//
//  Created by Romain Brunie on 12/7/16.
//  Copyright © 2016 Romain Brunie. All rights reserved.
//

import UIKit
import Alamofire
import AVFoundation
import CoreData

var player = AVAudioPlayer()

struct song {
    let titleSong : String
    let artist : String
    let albumImage : UIImage
    let song : String
}

class SearchTableViewController: UITableViewController, UISearchBarDelegate {
    
    var searchController : UISearchController!
    var songs = [song]()
    typealias JSONStandard = [String : AnyObject]
    let managedContext = DataManager().objectContext
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        //self.tableView.delegate = self
        //self.tableView.dataSource = self
        
        
        
        searchController = UISearchController(searchResultsController: nil)
        // A Boolean indicating whether the underlying content is dimmed during a search.
        searchController.dimsBackgroundDuringPresentation = true
        // A Boolean indicating whether the navigation bar should be hidden when searching.
        searchController.hidesNavigationBarDuringPresentation = false
        
        searchController.searchBar.delegate = self
        
        tableView.tableHeaderView = searchController.searchBar
        tableView.reloadData()
        
    }
    
    // CoreData
    
    func saveSong(_ song: song) {
        
        let entity =  NSEntityDescription.entity(forEntityName: "Song", in:managedContext!)
        
        let songCD = NSManagedObject(entity: entity!, insertInto: managedContext)
        songCD.setValue(song.titleSong, forKey: "titleSong")
        songCD.setValue(song.artist, forKey: "artist")
        songCD.setValue(song.song, forKey: "song")
        let imageData = UIImageJPEGRepresentation(song.albumImage, 1)
        songCD.setValue(imageData, forKey: "albumImage")
        print(songCD)
        do {
            try managedContext?.save()
            print("saved")
        } catch let error as NSError  {
            print("Could not save \(error), \(error.userInfo)")
        }
    }
    
    // Alamo
    
    func callAlamo(url: String) {
        print(url)
        Alamofire.request(url).responseJSON { (response) in
            self.parseData(JSONData: response.data!)
        }
    }
    
    func parseData(JSONData: Data) {
        do {
            var readableJSON = try JSONSerialization.jsonObject(with: JSONData, options: .mutableContainers) as! JSONStandard
            if let tracks = readableJSON["tracks"] as? JSONStandard {
                if let items = tracks["items"] as? [JSONStandard] {
                    for item in items {
                        let songURL = item["uri"] as! String
                        print("songURL = \(songURL)")
                        let name = item["name"] as! String
                        if let album = item["album"] as? JSONStandard{
                            if let images = album["images"] as? [JSONStandard] {
                                var artistName = ""
                                if let artists = album["artists"] as? [JSONStandard] {
                                    if let artist = artists[0] as? JSONStandard {
                                        artistName = artist["name"] as! String
                                        print("artistName = \(artistName)")
                                    }
                                }
                                if let imageObject = images[0] as? JSONStandard {
                                    let imageURL = NSURL(string: imageObject["url"] as! String)
                                    let imageData = NSData(contentsOf: imageURL as! URL)
                                    let image = UIImage(data: imageData as! Data)
                                    songs.append(song.init(titleSong: name, artist: artistName, albumImage: image!, song: songURL))
                                }
                                
                            }
                        }
                    }
                }
            }
            tableView.reloadData()
        }
        catch {
            print(error)
        }
    }
    
    // Search Bar Delegate
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        songs.removeAll()
        tableView.reloadData()
    }
     
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        if let urlCreate = try? SPTSearch.createRequestForSearch(withQuery: searchController.searchBar.text!.lowercased(), queryType: .queryTypeTrack, accessToken: SPTAuth.defaultInstance().session.accessToken!) {
            callAlamo(url: String(describing: urlCreate))
        }
        searchController.isActive = false
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return songs.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "reuseIdentifier", for: indexPath)

        // Configure the cell...
        let imageView = cell.viewWithTag(1) as! UIImageView
        imageView.image = songs[indexPath.row].albumImage
        let songLabel = cell.viewWithTag(2) as! UILabel
        songLabel.text = songs[indexPath.row].titleSong
        let artistLabel = cell.viewWithTag(3) as! UILabel
        artistLabel.text = songs[indexPath.row].artist
        
        return cell
    }
    
    // swipe left enabled and show save button
    override func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        let save = UITableViewRowAction(style: .normal, title: "Save") { action, indexPath in
            print("Save button tapped")
            self.saveSong(self.songs[indexPath.row])
            // swipe back when save button is clicked
            tableView.setEditing(false, animated: true)
        }
        save.backgroundColor = UIColor(colorLiteralRed: (30/255), green: (215/255), blue: (96/255), alpha: 1.0)
        return [save]
    }
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        
    }

    // MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        print("prepare")
        // sender is a UITableViewCell
        if segue.identifier == "musicPlayer" {
            print("musicPlayer")
            if let indexPath = tableView.indexPathForSelectedRow {
                print("musicPlayer = \(indexPath.row)")
                let destinationvc = segue.destination as! MusicPlayerViewController
                destinationvc.albumIm = songs[indexPath.row].albumImage
                destinationvc.songTitle = songs[indexPath.row].titleSong
                destinationvc.artist = songs[indexPath.row].artist
                destinationvc.song = songs[indexPath.row].song
            }
        }
        if segue.identifier == "searchWeb" {
            print("searchWeb")
            print("\(sender)")
            let destinationvc = segue.destination as! SearchWebViewController
            let cell = self.tableView.indexPath(for: sender as! UITableViewCell)
            print("cell = \(cell?[1])")
            destinationvc.artist = songs[(cell?[1])!].artist
        }
    }
}
