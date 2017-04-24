//
//  MainViewController.swift
//  OpenLive
//
//  Created by GongYuhua on 2/20/16.
//  Copyright © 2016 Agora. All rights reserved.
//

import Cocoa

class MainViewController: NSViewController {
    
    @IBOutlet weak var roomInputTextField: NSTextField!
    @IBOutlet weak var appIdInputTestField: NSTextField!
    @IBOutlet weak var appCertificateInputTextField: NSTextField!
    @IBOutlet weak var joinInfoInputTextField: NSTextField!
    
    var videoProfile = AgoraRtcVideoProfile._VideoProfile_360P
    fileprivate var agoraKit: AgoraRtcEngineKit!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.wantsLayer = true
        view.layer?.backgroundColor = NSColor.white.cgColor
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()
        let lastAppId = UserDefaults.standard.string(forKey: "appID")
        let lastAppCertificate = UserDefaults.standard.string(forKey: "appCertificate")
        let lastJoinInfo = UserDefaults.standard.string(forKey: "joinInfo")
        
        roomInputTextField.becomeFirstResponder()
        appIdInputTestField.stringValue = lastAppId == nil ? "" : lastAppId!
        appCertificateInputTextField.stringValue = lastAppCertificate == nil ? "" : lastAppCertificate!
        joinInfoInputTextField.stringValue = lastJoinInfo == nil ? "" : lastJoinInfo!
    }
    
    override func prepare(for segue: NSStoryboardSegue, sender: Any?) {
        guard let segueId = segue.identifier , !segueId.isEmpty else {
            return
        }
        
        if segueId == "mainToSettings" {
            let settingsVC = segue.destinationController as! SettingsViewController
            settingsVC.videoProfile = videoProfile
            settingsVC.delegate = self
        } else if segueId == "mainToLive" {
            let liveVC = segue.destinationController as! LiveRoomViewController
            liveVC.roomName = roomInputTextField.stringValue
            liveVC.appId = appIdInputTestField.stringValue
            liveVC.appCertificate = appCertificateInputTextField.stringValue
            liveVC.joinInfo = joinInfoInputTextField.stringValue
            liveVC.videoProfile = videoProfile
            
            UserDefaults.standard.set(liveVC.appId, forKey: "appID")
            UserDefaults.standard.set(liveVC.appCertificate, forKey: "appCertificate")
            UserDefaults.standard.set(liveVC.joinInfo, forKey: "joinInfo")
            UserDefaults.standard.synchronize()
            
            if let value = sender as? NSNumber, let role = AgoraRtcClientRole(rawValue: value.intValue) {
                liveVC.clientRole = role
            }
            liveVC.delegate = self
        }
    }
    
    //MARK: - user actions
    @IBAction func doJoinAsAudienceClicked(_ sender: NSButton) {
        guard let roomName = roomInputTextField?.stringValue , !roomName.isEmpty else {
            return
        }
        
        join(withRole: .clientRole_Audience)
    }
    
    @IBAction func doJoinAsBroadcasterClicked(_ sender: NSButton) {
        guard let roomName = roomInputTextField?.stringValue , !roomName.isEmpty else {
            return
        }
        join(withRole: .clientRole_Broadcaster)
    }
    
    @IBAction func doSettingsClicked(_ sender: NSButton) {
        performSegue(withIdentifier: "mainToSettings", sender: nil)
    }
}

private extension MainViewController {
    func join(withRole role: AgoraRtcClientRole) {
        performSegue(withIdentifier: "mainToLive", sender: NSNumber(value: role.rawValue as Int))
    }
}

extension MainViewController: SettingsVCDelegate {
    func settingsVC(_ settingsVC: SettingsViewController, closeWithProfile profile: AgoraRtcVideoProfile) {
        videoProfile = profile
        settingsVC.view.window?.contentViewController = self
    }
}

extension MainViewController: LiveRoomVCDelegate {
    func liveRoomVCNeedClose(_ liveVC: LiveRoomViewController) {
        guard let window = liveVC.view.window else {
            return
        }
        
        window.delegate = nil
        window.contentViewController = self
    }
}
