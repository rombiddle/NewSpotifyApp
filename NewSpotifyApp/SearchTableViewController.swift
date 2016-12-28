//
//  SearchTableViewController.swift
//  NewSpotifyApp
//
//  Created by Romain Brunie on 12/7/16.
//  Copyright © 2016 Romain Brunie. All rights reserved.
//
//  This table view is used to make searches through the spotify api.
//  In the search bar, you search for any track you want and it returns the results in the table view cells.
//  Then you can either play the songs, save them in CoreData with a swipe left or get wikipedia information about the artist when you click on the detail disclosure accessory.

import UIKit
import Alamofire
import AVFoundation
import CoreData

// struct of the song object displayed in the tableview
struct song {
    let titleSong : String
    let artist : String
    let albumImage : UIImage
    let song : String
}

class SearchTableViewController: UITableViewController, UISearchBarDelegate {
    
    //  search controller
    var searchController : UISearchController!
    var songs = [song]()
    typealias JSONStandard = [String : AnyObject]
    let managedContext = DataManager().objectContext
    //  activity indicator view
    weak var activityIndicatorView: UIActivityIndicatorView!
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        print("viewDidLoad search")
        
        //  creating activity indicator view
        let activityIndicatorView = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.gray)
        tableView.backgroundView = activityIndicatorView
        self.activityIndicatorView = activityIndicatorView
        
        //  creating the search controller
        searchController = UISearchController(searchResultsController: nil)
        //  A Boolean indicating whether the underlying content is dimmed during a search.
        searchController.dimsBackgroundDuringPresentation = true
        //  A Boolean indicating whether the navigation bar should be hidden when searching.
        searchController.hidesNavigationBarDuringPresentation = false
        searchController.searchBar.delegate = self
        
        tableView.tableHeaderView = searchController.searchBar
        tableView.reloadData()
        
    }
    
    //  Starting the activity indicator view
    func startAnimation() {
        //  I display none the cell separators in order to get a better look at the activity indicator
        tableView.separatorStyle = UITableViewCellSeparatorStyle.none
        activityIndicatorView.startAnimating()
    }
    
    //  Stopping the activity indicator view
    func stopAnimation() {
        tableView.separatorStyle = UITableViewCellSeparatorStyle.singleLine
        activityIndicatorView.stopAnimating()
    }
    
    //  function to save a song to CoreData
    func saveSong(_ song: song) {
        let entity =  NSEntityDescription.entity(forEntityName: "Song", in:managedContext!)
        let songCD = NSManagedObject(entity: entity!, insertInto: managedContext)

        songCD.setValue(song.titleSong, forKey: "titleSong")
        songCD.setValue(song.artist, forKey: "artist")
        songCD.setValue(song.song, forKey: "song")
        //  saving jpeg image to type 'Data'
        let imageData = UIImageJPEGRepresentation(song.albumImage, 1)
        songCD.setValue(imageData, forKey: "albumImage")
        
        do {
            try managedContext?.save()
            print("saved")
        } catch let error as NSError  {
            print("Could not save \(error), \(error.userInfo)")
        }
        
    }
    
    //  Alamofire makes an url request to spotify api
    func callAlamo(url: String) {
        print(url)
        Alamofire.request(url).responseJSON { (response) in
            self.parseData(JSONData: response.data!)
        }
    }
    
    //  parsing JSON data from spotify api
    func parseData(JSONData: Data) {
        do {
            var readableJSON = try JSONSerialization.jsonObject(with: JSONData, options: .mutableContainers) as! JSONStandard
            //  I do this async because it takes time and does not freeze the UI
            DispatchQueue.global(qos: .userInteractive).async {
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
                                        self.songs.append(song.init(titleSong: name, artist: artistName, albumImage: image!, song: songURL))
                                    } else {
                                        self.songs.append(song.init(titleSong: name, artist: artistName, albumImage: UIImage(), song: songURL))
                                    }
                                
                                }
                            }
                        }
                    }
                }
                //  I go back to the main queue in order to update the UI
                DispatchQueue.main.async {
                    //  stop activity indicator view because the search and parsing is now done
                    self.stopAnimation()
                    //  I reload the data of the tableView for updating
                    self.tableView.reloadData()
                }
            }
        }
        catch {
            print(error)
        }
    }
    
    //  When I start to write in Search Bar, I delete all the content of the table view
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        songs.removeAll()
        tableView.reloadData()
    }
    
    //  When I click on the search button in the keyboard...
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        
        //  The search to the spotify api starts here, so I display the activity indicator
        startAnimation()
        
        //  I build the search request to the spotify api
        if let urlCreate = try? SPTSearch.createRequestForSearch(withQuery: searchController.searchBar.text!.lowercased(), queryType: .queryTypeTrack, accessToken: SPTAuth.defaultInstance().session.accessToken!) {
            //  Once the search request is built, I call callAlamo to make the request to the spotify api
            callAlamo(url: String(describing: urlCreate))
        }
        searchController.isActive = false
    }

    //  MARK: - Table view data source
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return songs.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "reuseIdentifier", for: indexPath)

        // Configure the cell...
        // tag 1 is the album image of the song in the table view cell
        let imageView = cell.viewWithTag(1) as! UIImageView
        imageView.image = songs[indexPath.row].albumImage
        // tag 2 is the title of the song in the table view cell
        let songLabel = cell.viewWithTag(2) as! UILabel
        songLabel.text = songs[indexPath.row].titleSong
        // tag 3 is the artist name of the song in the table view cell
        let artistLabel = cell.viewWithTag(3) as! UILabel
        artistLabel.text = songs[indexPath.row].artist
        
        return cell
    }
    
    //  Swipe left enabled and show a green save button
    override func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        //  I create a save action for the table view cells when I swipe
        let save = UITableViewRowAction(style: .normal, title: "Save") { action, indexPath in
            //  Here i call the function saveSong in order to save it to CoreData
            self.saveSong(self.songs[indexPath.row])
            // swipe back when save button is clicked
            tableView.setEditing(false, animated: true)
        }
        //  I set the background color of the save button to a green spotify
        save.backgroundColor = UIColor(colorLiteralRed: (30/255), green: (215/255), blue: (96/255), alpha: 1.0)

        return [save]
    }

    //  MARK: - Navigation
    //  I set up the table view cell to segue information to other views
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        print("prepare")
        //  sender is a UITableViewCell
        //  The musicPlayer identifier goes to the MusicPlayerViewController (it is where the audio player is in order to play the song)
        if segue.identifier == "musicPlayer" {
            print("musicPlayer")
            if let indexPath = tableView.indexPathForSelectedRow {
                let destinationvc = segue.destination as! MusicPlayerViewController
                destinationvc.albumIm = songs[indexPath.row].albumImage
                destinationvc.songTitle = songs[indexPath.row].titleSong
                destinationvc.artist = songs[indexPath.row].artist
                destinationvc.song = songs[indexPath.row].song
            }
        }
        //  the searchWeb identifier goes to the SearchWebViewController (it search the artist name on wikipedia in a web view)
        if segue.identifier == "searchWeb" {
            print("searchWeb")
            let destinationvc = segue.destination as! SearchWebViewController
            let cell = self.tableView.indexPath(for: sender as! UITableViewCell)
            print("cell = \(cell?[1])")
            //  I only search on wikipedia for the artist name
            destinationvc.artist = songs[(cell?[1])!].artist
        }
    }
}
