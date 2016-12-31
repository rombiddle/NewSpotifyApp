//
//  MusicPlayerViewController.swift
//  NewSpotifyApp
//
//  Created by Romain Brunie on 12/11/16.
//  Copyright © 2016 Romain Brunie. All rights reserved.
//
//  This view is the music player that manage events relating to the connection to the Spotify service and events relating to audio playback.

import UIKit
import AVFoundation
import AudioToolbox

//  SPTAudioStreamingDelegate = Defines events relating to the connection to the Spotify service.
//  SPTAudioStreamingPlaybackDelegate = Defines events relating to audio playback
class MusicPlayerViewController: UIViewController, SPTAudioStreamingDelegate, SPTAudioStreamingPlaybackDelegate {

    //  song object sent from the SearchTableViewController through the segue
    var songTitle = String()
    var albumIm = UIImage()
    var artist = String()
    var song = String()
    
    let audioSession = AVAudioSession.sharedInstance()
    
    //  for the duration slider to move along the song duration
    var isChangingProgress: Bool = false
    
    //  UI Outlet
    @IBOutlet var albumImage: UIImageView!
    @IBOutlet var artistLabel: UILabel!
    @IBOutlet var songTitleLabel: UILabel!
    @IBOutlet var musicSlider: UISlider!
    @IBOutlet var playPauseOutlet: UIButton!
    
    //  Play / Pause Button
    @IBAction func playPauseButton(_ sender: UIButton) {
        //  I play / pause the song
        //  SPTAudioStreamingController = This class manages audio streaming from Spotify
        SPTAudioStreamingController.sharedInstance().setIsPlaying(!SPTAudioStreamingController.sharedInstance().playbackState.isPlaying, callback: nil)
    }
    
    //  when music duration position change...
    @IBAction func seekValueChanged(_ sender: UISlider) {
        self.isChangingProgress = false
        let dest = SPTAudioStreamingController.sharedInstance().metadata!.currentTrack!.duration * Double(self.musicSlider.value)
        //  Seek playback to a given location in the current track
        SPTAudioStreamingController.sharedInstance().seek(to: dest, callback: nil)
    }
    
    //  when music duration slider is touched
    @IBAction func proggressTouchDown(_ sender: UISlider) {
        self.isChangingProgress = true
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //  The first time I call the MusicPlayerViewController, I set up a new session and then I do not create a new one, I keep the same session and change the URI of the song
        if SPTAudioStreamingController.sharedInstance().loggedIn == false {
            //  I create the new spotify session
            self.handleNewSession()
        } else {
            //  in order to have the audioStreaming delegate to work, I have to logout and close the session everytime I want to play a new song
            SPTAudioStreamingController.sharedInstance().logout()
            closeSession()
        }
        //  Here I set up the UI View from segue data
        songTitleLabel.text = songTitle
        albumImage.image = albumIm
        artistLabel.text = artist
        //  the initial image when I get on this view is the pause button because the song plays automatically
        playPauseOutlet.setImage(UIImage(named: "Circled Pause.png"), for: .normal)
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
            //SPTAuth.defaultInstance().session = nil
            //_ = self.navigationController!.popViewController(animated: true)
        } catch let error {
            let alert = UIAlertController(title: "Error deinit", message: error.localizedDescription, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
            self.present(alert, animated: true, completion: { _ in })
        }
        self.handleNewSession()
    }
        
    // Called when the streaming controller recieved a message for the end user from the Spotify service
    func audioStreaming(_ audioStreaming: SPTAudioStreamingController, didReceiveMessage message: String) {
        let alert = UIAlertController(title: "Message from Spotify", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
        self.present(alert, animated: true, completion: { _ in })
    }
    
    // Called when playback status changes
    func audioStreaming(_ audioStreaming: SPTAudioStreamingController, didChangePlaybackStatus isPlaying: Bool) {
        if isPlaying {
            self.activateAudioSession()
            //  If the track is playing, I set the pause image button
            playPauseOutlet.setImage(UIImage(named: "Circled Pause.png"), for: .normal)
        }
        else {
            self.deactivateAudioSession()
            //  If the track is NOT playing, I set the play image button
            playPauseOutlet.setImage(UIImage(named: "Circled Play.png"), for: .normal)
        }
    }
    
    // Called when metadata for current, previous, or next track is changed.
    // This event occurs when playback starts or changes to a different context,
    // when a track switch occurs, etc. This is an informational event that does
    // not require action, but should be used to keep the UI display updated with
    // the latest metadata information.
    func audioStreaming(_ audioStreaming: SPTAudioStreamingController, didChange metadata: SPTPlaybackMetadata) {
    }
    
    // Called for each received low-level event
    func audioStreaming(_ audioStreaming: SPTAudioStreamingController, didReceive event: SpPlaybackEvent, withName name: String) {
        print("didReceivePlaybackEvent: \(event) \(name)")
        print("isPlaying=\(SPTAudioStreamingController.sharedInstance().playbackState.isPlaying) isRepeating=\(SPTAudioStreamingController.sharedInstance().playbackState.isRepeating) isShufflin/Users/romainbrunie/Downloads/SpotifyDemo/SpotifyDemo/Images.xcassets/loginButton.imageset/log_in-mobile.pngg=\(SPTAudioStreamingController.sharedInstance().playbackState.isShuffling) isActiveDevice=\(SPTAudioStreamingController.sharedInstance().playbackState.isActiveDevice) positionMs=\(SPTAudioStreamingController.sharedInstance().playbackState.position)")
    }
    
    // Called when the streaming controller logs out
    func audioStreamingDidLogout(_ audioStreaming: SPTAudioStreamingController) {
    }
    
    // Called on error
    func audioStreaming(_ audioStreaming: SPTAudioStreamingController, didReceiveError error: Error?) {
        print("didReceiveError: \(error!.localizedDescription)")
    }
    
    // Called when playback has progressed
    func audioStreaming(_ audioStreaming: SPTAudioStreamingController, didChangePosition position: TimeInterval) {
        if self.isChangingProgress {
            return
        }
        let positionDouble = Double(position)
        let durationDouble = Double(SPTAudioStreamingController.sharedInstance().metadata.currentTrack!.duration)
        self.musicSlider.value = Float(positionDouble / durationDouble)
    }
    
    // Called when the streaming controller begins playing a new track.
    func audioStreaming(_ audioStreaming: SPTAudioStreamingController, didStartPlayingTrack trackUri: String) {
        print("Source \(SPTAudioStreamingController.sharedInstance().metadata.currentTrack?.playbackSourceUri)")
        // If context is a single track and the uri of the actual track being played is different
        // than we can assume that relink has happended.
        let isRelinked = SPTAudioStreamingController.sharedInstance().metadata.currentTrack!.playbackSourceUri.contains("spotify:track") && !(SPTAudioStreamingController.sharedInstance().metadata.currentTrack!.playbackSourceUri == trackUri)
        print("Relinked \(isRelinked)")
    }
    
    // Called before the streaming controller begins playing another track.
    func audioStreaming(_ audioStreaming: SPTAudioStreamingController, didStopPlayingTrack trackUri: String) {
    }
    
    // Called when the streaming controller logs in successfully
    func audioStreamingDidLogin(_ audioStreaming: SPTAudioStreamingController) {
        SPTAudioStreamingController.sharedInstance().playSpotifyURI(song, startingWith: 0, startingWithPosition: 0) { error in
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
    
}
