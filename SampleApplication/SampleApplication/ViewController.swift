//
//  ViewController.swift
//  SampleApplication
//
//  Created by Junaid Rehmat on 28/04/2020.
//  Copyright © 2020 Junaid Rehmat. All rights reserved.
//

import UIKit
import CameraFramework
class ViewController: UIViewController {

    @IBOutlet weak var imageView: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        print("Framework Version: \(CameraViewController.getVersion()!)")
    }
    
    @IBAction func startButtonTapped() {
        let camera = CameraViewController.init()
        camera.position = .back
        camera.delegate = self
        camera.modalPresentationStyle = .fullScreen
        present(camera, animated: true, completion: nil)
    }
}

// MARK: CameraControllerDelegate

extension ViewController: CameraControllerDelegate {
    func stillImageCaptured(controller: CameraViewController, image: UIImage) {
        self.imageView.image = image
        controller.dismiss(animated: true, completion: nil)
    }
    
    func shutterButtonTapped(controller: CameraViewController) {
        
    }
    
    func cancelButtonTapped(controller: CameraViewController) {
        controller.dismiss(animated: true, completion: nil)
    }
}

