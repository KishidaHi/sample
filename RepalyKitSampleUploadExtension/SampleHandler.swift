//
//  SampleHandler.swift
//  RepalyKitSampleUploadExtension
//
//  Created by shima on 2020/08/13.

//  Copyright © 2020 jun shima. All rights reserved.
//

import TwilioVideo
import ReplayKit

class SampleHandler: RPBroadcastSampleHandler {

    // Video SDK components
    public var room: Room?
    var audioTrack: LocalAudioTrack?
    var videoSource: ReplayKitVideoSource?
    var screenTrack: LocalVideoTrack?
    var disconnectSemaphore: DispatchSemaphore?

    var accessToken: String = "TWILIO_ACCESS_TOKEN"
    let tokenUrl = "https://crimson-locust-6040.twil.io/screen-token"
    
    var statsTimer: Timer?
    static let kBroadcastSetupInfoRoomNameKey = "roomName"
        
    static let kVideoCodec = H264Codec()!
    
    override func broadcastStarted(withSetupInfo setupInfo: [String : NSObject]?) {
        // User has requested to start the broadcast. Setup info from the UI extension can be supplied but optional.
        print("started")

        // User has requested to start the broadcast. Setup info from the UI extension can be supplied but is optional.
        if (accessToken == "TWILIO_ACCESS_TOKEN" || accessToken.isEmpty) {
            do {
                accessToken = try TokenUtils.fetchToken(url: self.tokenUrl)
            } catch {
                let message = "Failed to fetch access token."
                print(message)
            }
        }

        // This source will attempt to produce smaller buffers with fluid motion.
        let options = ReplayKitVideoSource.TelecineOptions.p30to24or25
        let (encodingParams, outputFormat) = ReplayKitVideoSource.getParametersForUseCase(codec: SampleHandler.kVideoCodec,
                                                                                                  isScreencast: false,
                                                                                            telecineOptions: options)

        videoSource = ReplayKitVideoSource(isScreencast: false, telecineOptions: options)
        screenTrack = LocalVideoTrack(source: videoSource!,
                                              enabled: true,
                                              name: "Screen")

        videoSource!.requestOutputFormat(outputFormat)

        audioTrack = LocalAudioTrack()

        let connectOptions = ConnectOptions(token: accessToken) { (builder) in

            // Use the local media that we prepared earlier.
            builder.audioTracks = [self.audioTrack!]
            builder.videoTracks = [self.screenTrack!]

            // We have observed that downscaling the input and using H.264 results in the lowest memory usage.
            builder.preferredVideoCodecs = [SampleHandler.kVideoCodec]

            /*
            * Constrain the bitrate to improve QoS for subscribers when simulcast is not used, and to reduce overall
            * bandwidth usage for the broadcaster.
            */
            builder.encodingParameters = encodingParams

            /*
            * A broadcast extension has no need to subscribe to Tracks, and connects as a publish-only
            * Participant. In a Group Room, this options saves memory and bandwidth since decoders and receivers are
             * no longer needed. Note that subscription events will not be raised for remote publications.
             */
            //            builder.isAutomaticSubscriptionEnabled = false
            //            builder.isAutomaticSubscriptionEnabled = true

            // The name of the Room where the Client will attempt to connect to. Please note that if you pass an empty
            // Room `name`, the Client will create one for you. You can get the name or sid from any connected Room.
            if #available(iOS 12.0, *) {
                builder.roomName = "Broadcast"
            } else {
                builder.roomName = setupInfo?[SampleHandler.kBroadcastSetupInfoRoomNameKey] as? String
            }
        //hk start
            if let preferredAudioCodec = Settings.shared.audioCodec {
                        builder.preferredAudioCodecs = [preferredAudioCodec]
            }
            if let signalingRegion = Settings.shared.signalingRegion {
                        builder.region = signalingRegion
            }
        //hk end
        }

        // Connect to the Room using the options we provided.
        room = TwilioVideoSDK.connect(options: connectOptions, delegate: self)

        // The user has requested to start the broadcast. Setup info from the UI extension can be supplied but is optional.
        print("broadcastStartedWithSetupInfo: ", setupInfo as Any)

//        updateServiceInfo(["state": (0) as NSCoding & NSObjectProtocol])
    }
    
    override func broadcastPaused() {
        // User has requested to pause the broadcast. Samples will stop being delivered.
        print("paused")
    }
    
    override func broadcastResumed() {
        // User has requested to resume the broadcast. Samples delivery will resume.
        print("resumed")
    }
    
    override func broadcastFinished() {
        // User has requested to finish the broadcast.
        print("finished")
        updateServiceInfo(["state": (1) as NSCoding & NSObjectProtocol])
    }
    
    override func processSampleBuffer(_ sampleBuffer: CMSampleBuffer, with sampleBufferType: RPSampleBufferType) {
        switch sampleBufferType {
        case RPSampleBufferType.video:
            // Handle video sample buffer
            print("video sample")
            break
        case RPSampleBufferType.audioApp:
            // Handle audio sample buffer for app audio
            break
        case RPSampleBufferType.audioMic:
            // Handle audio sample buffer for mic audio
            break
        @unknown default:
            // Handle other sample buffer types
            fatalError("Unknown type of sample buffer")
        }
        
    }
}

// MARK:- RoomDelegate
extension SampleHandler : RoomDelegate {
    func roomDidConnect(room: Room) {
        print("didConnectToRoom: ", room)

        disconnectSemaphore = DispatchSemaphore(value: 0)

        #if DEBUG
        statsTimer = Timer(fire: Date(timeIntervalSinceNow: 1), interval: 10, repeats: true, block: { (Timer) in
            room.getStats({ (reports: [StatsReport]) in
                for report in reports {
                    let videoStats = report.localVideoTrackStats.first!
                    print("Capture \(videoStats.captureDimensions) @ \(videoStats.captureFrameRate) fps.")
                    print("Send \(videoStats.dimensions) @ \(videoStats.frameRate) fps. RTT = \(videoStats.roundTripTime) ms")
                }
            })
        })

        if let theTimer = statsTimer {
            RunLoop.main.add(theTimer, forMode: .common)
        }
        #endif
    }

    func roomDidFailToConnect(room: Room, error: Error) {
        print("room: ", room, " didFailToConnectWithError: ", error)
        finishBroadcastWithError(error)
    }

    func roomDidDisconnect(room: Room, error: Error?) {
        statsTimer?.invalidate()
        if let semaphore = self.disconnectSemaphore {
            semaphore.signal()
        }
        if let theError = error {
            print("room: ", room, "didDisconnectWithError: ", theError)
            finishBroadcastWithError(theError)
        }
    }

    func roomIsReconnecting(room: Room, error: Error) {
        print("Reconnecting to room \(room.name), error = \(String(describing: error))")
    }

    func roomDidReconnect(room: Room) {
        print("Reconnected to room \(room.name)")
    }

    func participantDidConnect(room: Room, participant: RemoteParticipant) {
        print("participant: ", participant.identity, " didConnect")
    }

    func participantDidDisconnect(room: Room, participant: RemoteParticipant) {
        print("participant: ", participant.identity, " didDisconnect")
    }
}
