//
//  SearchWebViewController.swift
//  NewSpotifyApp
//
//  Created by Romain Brunie on 12/13/16.
//  Copyright © 2016 Romain Brunie. All rights reserved.
//
//  This web view searches on Wikipedia the name of the artist that we get from the search table view when the detail disclosure accessory is clicked

import UIKit

class SearchWebViewController: UIViewController {

    @IBOutlet var webView: UIWebView!
    // artist name we get from the segue from SearchTableViewController
    var artist = String()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // we build the url with the artist name
        let urlString = "https://fr.wikipedia.org/wiki/" + artist
        // wikipedia does not always understand spaces in the url, so I replace a space with '_'
        let newURL = urlString.replacingOccurrences(of: " ", with: "_")
        
        let url = NSURL(string: newURL)
        let request = NSURLRequest(url: url as! URL)
        webView.loadRequest(request as URLRequest)
    }

}
