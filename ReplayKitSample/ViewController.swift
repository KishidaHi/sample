//
//  ViewController.swift
//  ReplayKitSample
//
//  Created by shima on 2020/08/13.
//  Copyright © 2020 jun shima. All rights reserved.
//

import UIKit
import ReplayKit

@available(iOS 10.0, *)
class ViewController: UIViewController {
    
    // In-App Capture
    @IBOutlet private var recordingButton: UIButton!
    @IBOutlet private var captureButton: UIButton!
    
    // Live Broadcast
    @IBOutlet private var broadcastButton: UIButton!
    @IBOutlet private var pairingButton: UIButton!
    @IBOutlet private var broadcastView: UIView!
    
    private var recorder = RPScreenRecorder.shared()

/*
    private var controller: Any?
    @available(iOS 10.0, *)
    var broadcastController: RPBroadcastController? {
        get {
            return controller as? RPBroadcastController
        }
        set(new) {
            controller = new as Any
        }
    }
 */
    var broadcastController: RPBroadcastController?
    @IBOutlet weak var broadcastPickerView: UIView?
    @IBOutlet weak var spinner: UIActivityIndicatorView!
    
    private var _observers = [NSKeyValueObservation]()
    
//    private let kUploadExtension = "com.jshima.ReplayKitSample.RepalyKitSampleUploadExtension"
    static let kUploadExtension = "com.jshima.ReplayKitSample.RepalyKitSampleUploadExtension"
//    private let kSetupExtension = "com.jshima.ReplayKitSample.RepalyKitSampleUploadExtensionSetupUI"
    static let kSetupExtension = "com.jshima.ReplayKitSample.RepalyKitSampleUploadExtensionSetupUI"

    override func viewDidLoad() {
        super.viewDidLoad()

        print("APP start!")
        print("setupUI start!")
        setupUI()
//        print("setupRecorder start!")
//        setupRecorder()
//        print("setupBroadcastPickerView start!")
//        setupBroadcastPickerView()

/*
        if #available(iOS 11.0, *) {
            NotificationCenter.default.addObserver(forName: UIScreen.capturedDidChangeNotification, object: UIScreen.main, queue: OperationQueue.main) { (notification) in
                if self.broadcastPickerView != nil {
                    let isCaptured = UIScreen.main.isCaptured
//                    let title = isCaptured ? ViewController.kInProgressBroadcastButtonTitle : ViewController.kStartBroadcastButtonTitle
//                    self.broadcastButton.setTitle(title, for: .normal)
//                    self.conferenceButton?.isEnabled = !isCaptured
                    isCaptured ? self.spinner.startAnimating() : self.spinner.stopAnimating()
                }
            }
        } else {
            // Fallback on earlier versions
        }
*/
        
        // Use RPSystemBroadcastPickerView when available (iOS 12+ devices).
        if #available(iOS 12.0, *) {
            print("setupPickerView start!")
            setupPickerView()
        }
//        print("setupKVO start!")
//        setupKVO()

    }
    
    @available(iOS 12.0, *)
    func setupPickerView() {
        print("---------- setupPickerView ------------")
        // Swap the button for an RPSystemBroadcastPickerView.
        #if !targetEnvironment(simulator)
        // iOS 13.0 throws an NSInvalidArgumentException when RPSystemBroadcastPickerView is used to start a broadcast.
        // https://stackoverflow.com/questions/57163212/get-nsinvalidargumentexception-when-trying-to-present-rpsystembroadcastpickervie
        if #available(iOS 13.0, *) {
            // The issue is resolved in iOS 13.1.
            if #available(iOS 13.1, *) {
            } else {
                broadcastButton.addTarget(self, action: #selector(tapBroadcastPickeriOS13(sender:)), for: UIControl.Event.touchUpInside)
                return
            }
        }

        let pickerView = RPSystemBroadcastPickerView(frame: CGRect(x: 0,
                                                                   y: 0,
                                                                   width: view.bounds.width,
                                                                   height: 80))
        pickerView.translatesAutoresizingMaskIntoConstraints = false
//        pickerView.preferredExtension = ViewController.kBroadcastExtensionBundleId
        pickerView.preferredExtension = ViewController.kUploadExtension

        // Theme the picker view to match the white that we want.
        if let button = pickerView.subviews.first as? UIButton {
//            button.imageView?.tintColor = UIColor.white
            button.imageView?.tintColor = UIColor.red
        }

        view.addSubview(pickerView)

        self.broadcastPickerView = pickerView
        broadcastButton.isEnabled = false
        broadcastButton.titleEdgeInsets = UIEdgeInsets(top: 34, left: 0, bottom: 0, right: 0)

        let centerX = NSLayoutConstraint(item:pickerView,
                                         attribute: NSLayoutConstraint.Attribute.centerX,
                                         relatedBy: NSLayoutConstraint.Relation.equal,
                                         toItem: broadcastButton,
                                         attribute: NSLayoutConstraint.Attribute.centerX,
                                         multiplier: 1,
                                         constant: 0);
        self.view.addConstraint(centerX)
        let centerY = NSLayoutConstraint(item: pickerView,
                                         attribute: NSLayoutConstraint.Attribute.centerY,
                                         relatedBy: NSLayoutConstraint.Relation.equal,
                                         toItem: broadcastButton,
                                         attribute: NSLayoutConstraint.Attribute.centerY,
                                         multiplier: 1,
                                         constant: -10);
        self.view.addConstraint(centerY)
        let width = NSLayoutConstraint(item: pickerView,
                                       attribute: NSLayoutConstraint.Attribute.width,
                                       relatedBy: NSLayoutConstraint.Relation.equal,
                                       toItem: self.broadcastButton,
                                       attribute: NSLayoutConstraint.Attribute.width,
                                       multiplier: 1,
                                       constant: 0);
        self.view.addConstraint(width)
        let height = NSLayoutConstraint(item: pickerView,
                                        attribute: NSLayoutConstraint.Attribute.height,
                                        relatedBy: NSLayoutConstraint.Relation.equal,
                                        toItem: self.broadcastButton,
                                        attribute: NSLayoutConstraint.Attribute.height,
                                        multiplier: 1,
                                        constant: 0);
        self.view.addConstraint(height)
        #endif
    }
    
    @objc func tapBroadcastPickeriOS13(sender: UIButton) {
        let message = "ReplayKit broadcasts can not be started using the broadcast picker on iOS 13.0. Please upgrade to iOS 13.1+, or start a broadcast from the screen recording widget in control center instead."
        let alertController = UIAlertController(title: "Start Broadcast", message: message, preferredStyle: .actionSheet)

        let settingsButton = UIAlertAction(title: "Launch Settings App", style: .default, handler: { (action) -> Void in
            // Launch the settings app, with control center if possible.
            UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!, options: [:]) { (success) in
            }
        })

        alertController.addAction(settingsButton)

        if UIDevice.current.userInterfaceIdiom == .pad {
            alertController.popoverPresentationController?.sourceView = sender
            alertController.popoverPresentationController?.sourceRect = sender.bounds
        } else {
            // Adding the cancel action
            let cancelButton = UIAlertAction(title: "Cancel", style: .cancel, handler: { (action) -> Void in
            })
            alertController.addAction(cancelButton)
        }
        self.navigationController!.present(alertController, animated: true, completion: nil)
    }
    
    func setupUI() {
            recordingButton.isEnabled = false
            broadcastButton.isEnabled = true
        if #available(iOS 11, *) {
            captureButton.isEnabled = false
            pairingButton.isEnabled = false
        }
    }
    
    func setupRecorder() {
        recorder.isMicrophoneEnabled = true
        recorder.delegate = self
    }
    
    func setupKVO() {
            broadcastController = RPBroadcastController()
            broadcastController?.delegate = self
            broadcastController?.addObserver(self, forKeyPath: "serviceInfo", options: .new, context: nil)
//            _observers.append((broadcastController?.observe(\.serviceInfo, options: .new) { (controller, change) in
//                print("\(#function) \(change)")
//                })!)
    }
/*
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        print("----- observeValue start -----")
        switch keyPath {
        case "serviceInfo":
            print("\(#function)")
        default:
            print("")
        }
    }
 */
    private func startBroadcast() {
        print("----- startBroadcast -----")
        self.broadcastController?.startBroadcast { [unowned self] error in
            DispatchQueue.main.async {
                if let theError = error {
                    print("Broadcast controller failed to start with error:", theError as Any)
                } else {
                    print("Broadcast controller started.")
                    self.spinner.startAnimating()
//                    self.broadcastButton.setTitle(ViewController.kStopBroadcastButtonTitle, for: .normal)
                }
            }
        }
    }
    
    
    // MARK: - Recording
    @IBAction func recording() {
        if recorder.isRecording {
            stopRecording()
        } else {
            startRecording()
        }
    }
    
    func startRecording() {
            recorder.startRecording { (error) in
                if let error = error {
                    print("\(#function) \(error)")
                    return
                }
            }
    }
    
    func stopRecording() {
        recorder.stopRecording { (preview, error) in
            if let error = error {
                print("\(#function) \(error)")
                return
            }
            if let preview = preview {
                preview.previewControllerDelegate = self
                self.present(preview, animated: true, completion: nil)
            }
        }
    }
    
    // MARK: - Capture
    @IBAction func capture() {
        if recorder.isRecording {
            stopCapture()
        } else {
            startCapture()
        }
    }

    func startCapture() {
        if #available(iOS 11.0, *) {
            recorder.startCapture(handler: { (cmSampleBuffer, sampleBufferType, error) in
                switch sampleBufferType {
                case .audioApp:
                    print("audioApp")
                case .audioMic:
                    print("audioMic")
                case .video:
                    print("video")
                @unknown default:
                    fatalError()
                }
            }) { (error) in
                if let error = error {
                    print("\(#function) \(error)")
                    return
                }
            }
        }
    }
    
    func stopCapture() {
        if #available(iOS 11.0, *) {
            recorder.stopCapture { (error) in
                if let error = error {
                    print("\(#function) \(error)")
                    return
                }
            }
        }
    }

/*
    // MARK: - Broadcast
    @IBAction func broadcast() {
        print("broadcast start!!!!!!!")
        if #available(iOS 10.0, *) {
            if broadcastController?.isBroadcasting ?? false {
                stopBroadcasst()
            } else {
                startBroadcast()
            }
        }
    }

    func startBroadcast() {
        if #available(iOS 10.0, *) {
            RPBroadcastActivityViewController.load { (broadcastAVC, error) in
            if let error = error {
                print("\(#function) \(error)")
                return
            }
            if let broadcastAVC = broadcastAVC {
                broadcastAVC.delegate = self
                self.present(broadcastAVC, animated: true, completion: nil)
            }
            }
        }
    }
    
    func stopBroadcasst() {
        if #available(iOS 10.0, *) {
            broadcastController?.finishBroadcast { (error) in
                if let error = error {
                    print("\(#function) \(error)")
                    return
                }
            }
        }
    }
*/
/*
    // MARK: - Broadcast Pairing
    @IBAction func broadcastPairing() {
        if #available(iOS 10.0, *) {
            if broadcastController?.isBroadcasting ?? false {
                stopBroadcasst()
            } else {
                startBroadcastPairing()
            }
        }
    }
    
    func startBroadcastPairing() {
        if #available(iOS 11.0, *) {
            RPBroadcastActivityViewController.load(withPreferredExtension: ViewController.kSetupExtension) { (broadcastAVC, error) in
                if let error = error {
                    print("\(#function) \(error)")
                    return
                }
                if let broadcastAVC = broadcastAVC {
                    broadcastAVC.delegate = self
                    self.present(broadcastAVC, animated: true, completion: nil)
               }
            }
        }
        return
    }
*/
/*
    // This action is only invoked on iOS 11.x. On iOS 12.0 this is handled by RPSystemBroadcastPickerView.
    @IBAction func startBroadcast2(_ sender: Any) {
        print("----- startBroadcast2 start -----")
        if #available(iOS 10.0, *) {
            if let controller = self.broadcastController {
                print("----- self.broadcastController start -----")
                controller.finishBroadcast { [unowned self] error in
                    DispatchQueue.main.async {
                        self.spinner.stopAnimating()
                        self.broadcastController = nil
//                        self.broadcastButton.setTitle(ViewController.kStartBroadcastButtonTitle, for: .normal)
                    }
                }
            } else {
                // This extension should be the broadcast upload extension UI, not broadcast update extension
                if #available(iOS 11.0, *) {
                    print("----- RPBroadcastActivityViewController.load start -----")
//                    RPBroadcastActivityViewController.load(withPreferredExtension:ViewController.kSetupExtension) {
                        RPBroadcastActivityViewController.load(withPreferredExtension:ViewController.kUploadExtension) {
                        (broadcastActivityViewController, error) in
                        if let broadcastActivityViewController = broadcastActivityViewController {
                            broadcastActivityViewController.delegate = self
                            broadcastActivityViewController.modalPresentationStyle = .popover
                            self.present(broadcastActivityViewController, animated: true)
                            print("----- broadcastActivityViewController start -----")
                        }
                    }
                } else {
                    // Fallback on earlier versions
                }
            }
        } else {
            // Fallback on earlier versions
        }
    }
*/

/*
    // MARK: - BroadcastPickerView
    func setupBroadcastPickerView() {
        if #available(iOS 12, *) {
            let broadcastPicker = RPSystemBroadcastPickerView(frame: broadcastView.bounds)
            
            broadcastPicker.preferredExtension = ViewController.kUploadExtension
            broadcastPicker.showsMicrophoneButton = true
//            broadcastPicker.showsMicrophoneButton = false
            broadcastPicker.backgroundColor = .clear
            
            for subview  in broadcastPicker.subviews {
                let b = subview as! UIButton
                    b.setImage(nil, for: .normal)
                    b.setTitle("画面共有", for: .normal)
//                    b.setTitleColor(.black, for: .normal)
                    b.setTitleColor(.red, for: .normal)
            }
            self.broadcastView.addSubview(broadcastPicker)
        }
    }
*/
}

// MARK: - RPScreenRecorderDelegate
@available(iOS 10.0, *)
extension ViewController: RPScreenRecorderDelegate {
    func screenRecorderDidChangeAvailability(_ screenRecorder: RPScreenRecorder) {
        print("\(#function) isAvailable:\(screenRecorder.isAvailable)")
        print("\(#function) isRecording:\(screenRecorder.isRecording)")
    }
}

// MARK: - RPPreviewViewControllerDelegate
@available(iOS 10.0, *)
extension ViewController: RPPreviewViewControllerDelegate {
    func previewControllerDidFinish(_ previewController: RPPreviewViewController) {
        DispatchQueue.main.async {
            self.dismiss(animated: true, completion: nil)
        }
    }
}

// MARK: - RPBroadcastActivityViewControllerDelegate
@available(iOS 10.0, *)
extension ViewController: RPBroadcastActivityViewControllerDelegate {
    func broadcastActivityViewController(_ broadcastActivityViewController: RPBroadcastActivityViewController, didFinishWith broadcastController: RPBroadcastController?, error: Error?) {
        if let error = error {
            print("\(#function) \(error)")
            DispatchQueue.main.async {
                self.dismiss(animated: true, completion: nil)
            }
            return
        }
        if let broadcastController = broadcastController {
            self.broadcastController = broadcastController
            self.broadcastController?.delegate = self
            DispatchQueue.main.async {
                self.dismiss(animated: true) {
                    self.broadcastController?.startBroadcast(handler: { (error) in
                        if let error = error {
                            print("\(#function) \(error)")
                            return
                        }
                    })
                }
            }
        }
    }
}

// MARK: - RPBroadcastControllerDelegate
@available(iOS 10.0, *)
extension ViewController: RPBroadcastControllerDelegate {
    func broadcastController(_ broadcastController: RPBroadcastController, didFinishWithError error: Error?) {
        if let error = error {
            print("\(#function) \(error)")
            return
        }
    }
    
    func broadcastController(_ broadcastController: RPBroadcastController, didUpdateServiceInfo serviceInfo: [String : NSCoding & NSObjectProtocol]) {
        print("\(#function) \(serviceInfo)")
    }
}
