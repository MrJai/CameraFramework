//
//  Camera.swift
//  CameraFramework
//
//  Created by Junaid Rehmat on 28/04/2020.
//  Copyright © 2020 Junaid Rehmat. All rights reserved.
//

import UIKit
import AVFoundation

protocol CameraDelegate {
    func stillImageCaptured(camera: Camera, image: UIImage)
}

class Camera: NSObject {
    
    var delegate: CameraDelegate?
    
    var position : CameraPosition = .back {
        didSet {
            if self.session.isRunning {
                self.session.stopRunning()
                update()
            }
        }
    }
    
    required override init() {
    }
    
    fileprivate var session = AVCaptureSession()
    fileprivate var discoverySession: AVCaptureDevice.DiscoverySession? {
        return AVCaptureDevice.DiscoverySession(deviceTypes: [AVCaptureDevice.DeviceType.builtInWideAngleCamera], mediaType: AVMediaType.video, position: AVCaptureDevice.Position.unspecified)
    }
    
    var videoInput: AVCaptureDeviceInput?
    var videoOutput = AVCaptureVideoDataOutput()
    var photoOutput = AVCapturePhotoOutput()
    
    func getPreviewLayer() -> AVCaptureVideoPreviewLayer? {
        let previewLayer = AVCaptureVideoPreviewLayer(session: self.session)
        previewLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
        return previewLayer
    }
    
    func captureStillImage() {
        let settings = AVCapturePhotoSettings()
        self.photoOutput.capturePhoto(with: settings, delegate: self)
    }
    
    func update() {
        recycleDeviceIO()
        guard let input = getNewInputDevice() else {
            return
        }
        
        guard self.session.canAddInput(input) else {
            return
        }
        
        guard self.session.canAddOutput(self.videoOutput) else {
            return
        }
        
        guard self.session.canAddOutput(self.photoOutput) else {
            return
        }
        
        self.videoInput = input
        self.session.addInput(input)
        self.session.addOutput(self.videoOutput)
        self.session.addOutput(self.photoOutput)
        self.session.commitConfiguration()
        self.session.startRunning()
    }
}

// MARK: Capture Device Handling

private extension Camera {
    func getNewInputDevice() -> AVCaptureDeviceInput? {
        do {
            guard let device = getDevice(with: (self.position == .back) ? AVCaptureDevice.Position.back : AVCaptureDevice.Position.front) else {
                return nil
            }
            let input = try AVCaptureDeviceInput(device: device)
            return input
        } catch {
            return nil
        }
    }
    
    func recycleDeviceIO() {
        for oldInput in self.session.inputs {
            self.session.removeInput(oldInput)
        }
        
        for oldOutput in self.session.outputs {
            self.session.removeOutput(oldOutput)
        }
        
    }
    
    private func getDevice(with position: AVCaptureDevice.Position) -> AVCaptureDevice? {
        guard let discoverySession = self.discoverySession else {
            return nil
        }
        
        for device in discoverySession.devices {
            if device.position == position {
                return device
            }
        }
        return nil
    }
}

// MARK: Still Photo Capture
extension Camera : AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        guard let image = photo.normalizedPhoto(forCameraPosition: self.position) else {
            return
        }
        if let delegate = self.delegate {
            delegate.stillImageCaptured(camera: self, image: image)
        }
    }
}

// MARK: Extend AVCapturePhoto

extension AVCapturePhoto {
    func normalizedPhoto(forCameraPosition position: CameraPosition) -> UIImage? {
        guard let cgImage = self.cgImageRepresentation() else {
            return nil
        }
        return UIImage(cgImage: cgImage.takeUnretainedValue(), scale: 1.0, orientation: getImageOrientation(forCamera: position))
    }
    
    private func getImageOrientation(forCamera: CameraPosition) -> UIImage.Orientation {
        if let orientation = UIApplication.shared.windows.first?.windowScene?.interfaceOrientation {
            switch orientation {
            case .landscapeLeft:
                return (forCamera == .back) ? .down : .upMirrored
            case .unknown:
                return (forCamera == .back) ? .right : .leftMirrored
            case .portrait:
                return (forCamera == .back) ? .right : .leftMirrored
            case .portraitUpsideDown:
                return (forCamera == .back) ? .left : .rightMirrored
            case .landscapeRight:
                return (forCamera == .back) ? .up : .downMirrored
            @unknown default:
                return (forCamera == .back) ? .left : .rightMirrored
            }
        }
        return (forCamera == .back) ? .left : .rightMirrored
    }
}
