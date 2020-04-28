//
//  CameraViewController.swift
//  CameraFramework
//
//  Created by Junaid Rehmat on 28/04/2020.
//  Copyright © 2020 Junaid Rehmat. All rights reserved.
//

import UIKit
import AVFoundation

public protocol CameraControllerDelegate {
    func shutterButtonTapped(controller: CameraViewController)
    func cancelButtonTapped(controller: CameraViewController)
    func stillImageCaptured(controller: CameraViewController, image: UIImage)
}

public enum CameraPosition {
    case back
    case front
}

public final class CameraViewController: UIViewController {
    fileprivate var camera: Camera?
    var previewLayer: AVCaptureVideoPreviewLayer?
    
    private var _cancelButton: UIButton?
    var cancelButton: UIButton {
        if let currentButton = _cancelButton {
            return currentButton
        }
        let button = UIButton()
        button.setTitle("Cancel", for: .normal)
        button.addTarget(self, action: #selector(cancelButtonTapped), for: .touchUpInside)
        _cancelButton = button
        return button
    }
    
    private var _shutterButton: UIButton?
    var shutterButton:UIButton {
        if let currentButton = _shutterButton {
            return currentButton
        }
        
        let button = UIButton()
        button.setImage(UIImage(named: "trigger", in:Bundle(for: CameraViewController.self), compatibleWith: nil), for: .normal)
        button.addTarget(self, action: #selector(shutterButtonTapped), for: .touchUpInside)
        _shutterButton = button
        return button
    }
    
    public var delegate: CameraControllerDelegate?
    
    public var position: CameraPosition = .back {
        didSet {
            guard let camera = self.camera else {
                return
            }
            camera.position = position
        }
    }
    
    public init() {
        super.init(nibName: nil, bundle: nil)
        let camera = Camera()
        camera.delegate = self
        self.camera = camera
    }
    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        guard let camera = self.camera else {
            return
        }
        createUI()
        camera.update()
    }
    
    public override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        self.updateUI(orientation: UIApplication.shared.windows.first!.windowScene!.interfaceOrientation)
        self.updateButtonFrames()
    }
    
    public class func getVersion() -> String? {
        let bundle = Bundle(for: CameraViewController.self)
        guard let info = bundle.infoDictionary else {
            return nil
        }
        
        guard  let versionString = info["CFBundleShortVersionString"] as? String else {
            return nil
        }
        
        return versionString
    }
    
    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: User Interface Creation

fileprivate extension CameraViewController {
    func createUI() {
        guard let camera = self.camera else {
            return
        }
        
        guard let previewLayer = camera.getPreviewLayer() else {
            return
        }
        previewLayer.frame = self.view.bounds
        self.previewLayer = previewLayer
        self.view.layer.addSublayer(previewLayer)
        self.view.addSubview(self.cancelButton)
        self.view.addSubview(self.shutterButton)
    }
    
    func updateUI(orientation: UIInterfaceOrientation) {
        guard let previewLayer = self.previewLayer, let connection = previewLayer.connection else {
            return
        }
        previewLayer.frame = self.view.bounds
        switch orientation {
        case .portrait:
            connection.videoOrientation = .portrait
        case .portraitUpsideDown:
            connection.videoOrientation = .portraitUpsideDown
        case .landscapeLeft:
            connection.videoOrientation = .landscapeLeft
        case .landscapeRight:
            connection.videoOrientation = .landscapeRight
        default:
            connection.videoOrientation = .portrait
        }
    }
    
    func updateButtonFrames() {
        self.shutterButton.frame = CGRect(x: self.view.frame.midX-35, y: self.view.frame.maxY-80, width: 70, height: 70)
        self.cancelButton.frame = CGRect(x: self.view.frame.minX+10, y: self.view.frame.maxY-50, width: 70, height: 30)
    }
}

// MARK: UIButton Extension

fileprivate extension CameraViewController {
    @objc func cancelButtonTapped() {
        if let delegate = self.delegate {
            delegate.cancelButtonTapped(controller: self)
        }
    }
    
    @objc func shutterButtonTapped() {
        if let camera = self.camera {
            camera.captureStillImage()
        }
    }
}

// MARK: CameraDelegate

extension CameraViewController: CameraDelegate {
    func stillImageCaptured(camera: Camera, image: UIImage) {
        if let delegate = self.delegate {
            delegate.stillImageCaptured(controller: self, image: image)
        }
    }
}
