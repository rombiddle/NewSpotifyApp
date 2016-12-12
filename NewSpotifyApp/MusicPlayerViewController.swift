//
//  MusicPlayerViewController.swift
//  NewSpotifyApp
//
//  Created by Romain Brunie on 12/11/16.
//  Copyright © 2016 Romain Brunie. All rights reserved.
//

import UIKit
import AVFoundation
import AudioToolbox

// HELP
// SPTAudioStreamingDelegate = Defines events relating to the connection to the Spotify service.
// SPTAudioStreamingPlaybackDelegate = Defines events relating to audio playback
// SPTAudioStreamingController = This class manages audio streaming from Spotify

class MusicPlayerViewController: UIViewController, SPTAudioStreamingDelegate, SPTAudioStreamingPlaybackDelegate {

    var songTitle = String()
    var albumIm = UIImage()
    var artist = String()
    var song = String()
    
    let audioSession = AVAudioSession.sharedInstance()
    
    @IBOutlet var albumImage: UIImageView!
    @IBOutlet var artistLabel: UILabel!
    @IBOutlet var songTitleLabel: UILabel!
    @IBOutlet var musicSlider: UISlider!
    @IBAction func playerButton(_ sender: UIButton) {
        if sender.titleLabel?.text == "Prev" {
            SPTAudioStreamingController.sharedInstance().skipPrevious(nil)
        } else if sender.titleLabel?.text == "Next"{
            SPTAudioStreamingController.sharedInstance().skipNext(nil)
        } else {
            SPTAudioStreamingController.sharedInstance().setIsPlaying(!SPTAudioStreamingController.sharedInstance().playbackState.isPlaying, callback: nil)
        }
    }
    
    func updateUI() {
        // SPTAuth = This class provides helper methods for authenticating users against the Spotify OAuth authentication service.
        let auth = SPTAuth.defaultInstance()
        if SPTAudioStreamingController.sharedInstance().metadata == nil || SPTAudioStreamingController.sharedInstance().metadata.currentTrack == nil {
            self.albumImage.image = nil
            return
        }
        //self.spinner.startAnimating()
        //self.nextButton.isEnabled = SPTAudioStreamingController.sharedInstance().metadata.nextTrack != nil
        //self.prevButton.isEnabled = SPTAudioStreamingController.sharedInstance().metadata.prevTrack != nil
        self.songTitleLabel.text = SPTAudioStreamingController.sharedInstance().metadata.currentTrack?.name
        self.artistLabel.text = SPTAudioStreamingController.sharedInstance().metadata.currentTrack?.artistName
        //self.playbackSourceTitle.text = SPTAudioStreamingController.sharedInstance().metadata.currentTrack?.playbackSourceName
        
        print("metadata = \(SPTAudioStreamingController.sharedInstance().metadata.currentTrack!)")
        
        // SPTTrack = This class represents a track on the Spotify service
        // track = Request the track at the given Spotify URI.
        // This method takes Spotify URIs in the form `spotify:*`, NOT HTTP URLs.
        SPTTrack.track(withURI: URL(string: SPTAudioStreamingController.sharedInstance().metadata.currentTrack!.uri)!, accessToken: auth!.session.accessToken, market: nil) { error, result in
            
            if let track = result as? SPTTrack {
                let imageURL = track.album.largestCover.imageURL
                if imageURL == nil {
                    print("Album \(track.album) doesn't have any images!")
                    self.albumImage.image = nil
                    return
                }
                
                // Pop over to a background queue to load the image over the network.
                DispatchQueue.global().async {
                    do {
                        let imageData = try Data(contentsOf: imageURL!, options: [])
                        let image = UIImage(data: imageData)
                        // …and back to the main queue to display the image.
                        DispatchQueue.main.async {
                            //self.spinner.stopAnimating()
                            self.albumImage.image = image
                            if image == nil {
                                print("Couldn't load cover image with error: \(error)")
                                return
                            }
                        }
                    } catch let error {
                        print(error.localizedDescription)
                    }
                }
            }
        }
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.handleNewSession()
        print("session: \(SPTAuth.defaultInstance().session.accessToken!)")
    }
    
    func handleNewSession() {
        do {
            // Start the `SPAudioStreamingController` thread with a custom audio controller
            try SPTAudioStreamingController.sharedInstance().start(withClientId: SPTAuth.defaultInstance().clientID, audioController: nil, allowCaching: true)
            SPTAudioStreamingController.sharedInstance().delegate = self
            SPTAudioStreamingController.sharedInstance().playbackDelegate = self
            SPTAudioStreamingController.sharedInstance().diskCache = SPTDiskCache() /* capacity: 1024 * 1024 * 64 */
            // Log into the Spotify service for audio playback
            SPTAudioStreamingController.sharedInstance().login(withAccessToken: SPTAuth.defaultInstance().session.accessToken!)
        } catch let error {
            let alert = UIAlertController(title: "Error init", message: error.localizedDescription, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
            self.present(alert, animated: true, completion: { _ in })
            self.closeSession()
        }
    }
    
    func closeSession() {
        do {
            // Shut down the `SPTAudioStreamingController` thread
            try SPTAudioStreamingController.sharedInstance().stop()
            SPTAuth.defaultInstance().session = nil
            _ = self.navigationController!.popViewController(animated: true)
        } catch let error {
            let alert = UIAlertController(title: "Error deinit", message: error.localizedDescription, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
            self.present(alert, animated: true, completion: { _ in })
        }
    }
    
    // Called when the streaming controller recieved a message for the end user from the Spotify service
    func audioStreaming(_ audioStreaming: SPTAudioStreamingController, didReceiveMessage message: String) {
        let alert = UIAlertController(title: "Message from Spotify", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
        self.present(alert, animated: true, completion: { _ in })
    }
    
    // Called when playback status changes
    func audioStreaming(_ audioStreaming: SPTAudioStreamingController, didChangePlaybackStatus isPlaying: Bool) {
        print("is playing = \(isPlaying)")
        if isPlaying {
            self.activateAudioSession()
        }
        else {
            self.deactivateAudioSession()
        }
    }
    
    // Called when metadata for current, previous, or next track is changed.
    // This event occurs when playback starts or changes to a different context,
    // when a track switch occurs, etc. This is an informational event that does
    // not require action, but should be used to keep the UI display updated with
    // the latest metadata information.
    func audioStreaming(_ audioStreaming: SPTAudioStreamingController, didChange metadata: SPTPlaybackMetadata) {
        self.updateUI()
    }
    
    // Called for each received low-level event
    func audioStreaming(_ audioStreaming: SPTAudioStreamingController, didReceive event: SpPlaybackEvent, withName name: String) {
        print("didReceivePlaybackEvent: \(event) \(name)")
        print("isPlaying=\(SPTAudioStreamingController.sharedInstance().playbackState.isPlaying) isRepeating=\(SPTAudioStreamingController.sharedInstance().playbackState.isRepeating) isShufflin/Users/romainbrunie/Downloads/SpotifyDemo/SpotifyDemo/Images.xcassets/loginButton.imageset/log_in-mobile.pngg=\(SPTAudioStreamingController.sharedInstance().playbackState.isShuffling) isActiveDevice=\(SPTAudioStreamingController.sharedInstance().playbackState.isActiveDevice) positionMs=\(SPTAudioStreamingController.sharedInstance().playbackState.position)")
    }
    
    // Called when the streaming controller logs out
    func audioStreamingDidLogout(_ audioStreaming: SPTAudioStreamingController) {
        self.closeSession()
    }
    
    // Called on error
    func audioStreaming(_ audioStreaming: SPTAudioStreamingController, didReceiveError error: Error?) {
        print("didReceiveError: \(error!.localizedDescription)")
    }
    
    // Called when playback has progressed
    func audioStreaming(_ audioStreaming: SPTAudioStreamingController, didChangePosition position: TimeInterval) {
//        if self.isChangingProgress {
//            return
//        }
//        let positionDouble = Double(position)
//        let durationDouble = Double(SPTAudioStreamingController.sharedInstance().metadata.currentTrack!.duration)
        //self.progressSlider.value = Float(positionDouble / durationDouble)
    }
    
    // Called when the streaming controller begins playing a new track.
    func audioStreaming(_ audioStreaming: SPTAudioStreamingController, didStartPlayingTrack trackUri: String) {
        print("Starting \(trackUri)")
        print("Source \(SPTAudioStreamingController.sharedInstance().metadata.currentTrack?.playbackSourceUri)")
        // If context is a single track and the uri of the actual track being played is different
        // than we can assume that relink has happended.
        let isRelinked = SPTAudioStreamingController.sharedInstance().metadata.currentTrack!.playbackSourceUri.contains("spotify:track") && !(SPTAudioStreamingController.sharedInstance().metadata.currentTrack!.playbackSourceUri == trackUri)
        print("Relinked \(isRelinked)")
    }
    
    // Called before the streaming controller begins playing another track.
    func audioStreaming(_ audioStreaming: SPTAudioStreamingController, didStopPlayingTrack trackUri: String) {
        print("Finishing: \(trackUri)")
    }
    
    // Called when the streaming controller logs in successfully
    func audioStreamingDidLogin(_ audioStreaming: SPTAudioStreamingController) {
        self.updateUI()
        SPTAudioStreamingController.sharedInstance().playSpotifyURI("spotify:user:spotify:playlist:2yLXxKhhziG2xzy7eyD4TD", startingWith: 0, startingWithPosition: 10) { error in
            if error != nil {
                print("*** failed to play: \(error)")
                return
            }
        }
    }
    
    func activateAudioSession() {
        do {
            try audioSession.setCategory(AVAudioSessionCategoryPlayback)
            try audioSession.setActive(true)
        }
        catch let error {
            print(error.localizedDescription)
        }
    }
    
    func deactivateAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setActive(false)
        }
        catch let error {
            print(error.localizedDescription)
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        songTitleLabel.text = songTitle
        albumImage.image = albumIm
        artistLabel.text = artist
    }
}
