//
//  SearchTableViewController.swift
//  NewSpotifyApp
//
//  Created by Romain Brunie on 12/7/16.
//  Copyright © 2016 Romain Brunie. All rights reserved.
//

import UIKit
import Alamofire

class SearchTableViewController: UITableViewController, UISearchBarDelegate {
    
    var searchController : UISearchController!
    var names = [String]()
    var searchURL = "https://api.spotify.com/v1/search?type=track&q="
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
        Alamofire.request(url).responseJSON { (response) in
            self.parseData(JSONData: response.data!)
        }
    }
    
    func parseData(JSONData: Data) {
        do {
            var readableJSON = try JSONSerialization.jsonObject(with: JSONData, options: .mutableContainers) as! JSONStandard
            if let tracks = readableJSON["tracks"] as? JSONStandard {
                if let items = tracks["items"] as? NSArray {
                    for itemz in items {
                        let item = itemz as! JSONStandard
                        let name = item["name"] as! String
                        names.append(name)
                    }
                }
            }
        }
        catch {
            print(error)
        }
        tableView.reloadData()
    }
    
    // Search Bar Delegate
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        names.removeAll()
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
        return names.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "reuseIdentifier", for: indexPath)

        // Configure the cell...
        cell.textLabel?.text = names[indexPath.row]

        return cell
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
