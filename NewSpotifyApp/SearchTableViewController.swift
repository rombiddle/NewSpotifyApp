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
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        searchController = UISearchController(searchResultsController: nil)
        // A Boolean indicating whether the underlying content is dimmed during a search.
        searchController.dimsBackgroundDuringPresentation = true
        // A Boolean indicating whether the navigation bar should be hidden when searching.
        searchController.hidesNavigationBarDuringPresentation = false
        
        searchController.searchBar.delegate = self
        
        tableView.tableHeaderView = searchController.searchBar
        tableView.reloadData()
        
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
                        let songURL = item["href"] as! String
                        print("songURL = \(songURL)")
                        let name = item["name"] as! String
                        if let album = item["album"] as? JSONStandard{
                            if let images = album["images"] as? [JSONStandard] {
                                var artistName = ""
                                if let artists = album["artists"] as? [JSONStandard] {
                                    if let artist = artists[0] as? JSONStandard {
                                        artistName = artist["name"] as! String
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

    // MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let destinationvc = segue.destination as! MusicPlayerViewController
        if let indexPath = tableView.indexPathForSelectedRow?.row {
            destinationvc.albumIm = songs[indexPath].albumImage
            destinationvc.songTitle = songs[indexPath].titleSong
            destinationvc.artist = songs[indexPath].artist
            destinationvc.song = songs[indexPath].song
        }
    }
}
