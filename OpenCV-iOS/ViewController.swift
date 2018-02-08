//
//  ViewController.swift
//  OpenCV-iOS
//
//  Created by TerryLiu on 2/2/18.
//  Copyright © 2018 TerryLiu. All rights reserved.
//

import UIKit
import AVFoundation

class ViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate{

    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var versionLabel: UILabel!
    
    var input:AVCaptureDeviceInput!
    var output:AVCaptureVideoDataOutput!
    var session:AVCaptureSession!
    var camera:AVCaptureDevice!
    var processing:Bool!
    let quality = AVCaptureSession.Preset.hd1280x720
    
    override func viewDidLoad() {
        super.viewDidLoad()
        processing = false
        versionLabel.text = OpenCVWrapper.openCVVString()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    override func viewWillAppear(_ animated: Bool) {
        
        session = AVCaptureSession()
        session.sessionPreset = quality
    
        let camera = AVCaptureDevice.default(for: AVMediaType.video)
        // Fetch video
        do {
            input = try AVCaptureDeviceInput(device: camera!) as AVCaptureDeviceInput
        } catch let error as NSError {
            print(error)
        }
        
        if( session.canAddInput(input)) {
            session.addInput(input)
        }
        
        // Send image to processing
        output = AVCaptureVideoDataOutput()
        output.videoSettings = [kCVPixelBufferPixelFormatTypeKey as AnyHashable as! String : Int(kCVPixelFormatType_32BGRA)]
        
        // Delegate
        let queue: DispatchQueue = DispatchQueue(label: "videoqueue" , attributes: [])
        output.setSampleBufferDelegate(self, queue: queue)
        
        // Discard frames which have too long delay
        output.alwaysDiscardsLateVideoFrames = true
        
        // Put the output to session
        if session.canAddOutput(output) {
            session.addOutput(output)
        }
        
        // Fix the camera rotation
        guard let conn = output.connection(with: AVFoundation.AVMediaType.video) else {return}
        
        if conn.isVideoOrientationSupported {
            conn.videoOrientation = AVCaptureVideoOrientation.portrait
        }
        
        
        // Show on the display
        //let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        //previewLayer.frame = imageView.bounds
        //previewLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
        
        session.startRunning()
    }
    
    // Update view
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        
        let image:UIImage = self.captureImage(sampleBuffer)
        
        DispatchQueue.main.async {[unowned self] in
            self.imageView.image = image
        }
    }
    
    // Create UIImage from sampleBuffer
    func captureImage(_ sampleBuffer:CMSampleBuffer) -> UIImage {
        
        // Fetch an image
        let imageBuffer: CVImageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)!
        
        //　Lock the page address
        CVPixelBufferLockBaseAddress(imageBuffer, CVPixelBufferLockFlags(rawValue: 0) )
        
        // Image data information
        let baseAddress: UnsafeMutableRawPointer = CVPixelBufferGetBaseAddressOfPlane(imageBuffer, 0)!
        let bytesPerRow: Int = CVPixelBufferGetBytesPerRow(imageBuffer)
        let width: Int = CVPixelBufferGetWidth(imageBuffer)
        let height: Int = CVPixelBufferGetHeight(imageBuffer)
        let bitmapInfo = CGImageAlphaInfo.premultipliedFirst.rawValue|CGBitmapInfo.byteOrder32Little.rawValue as UInt32
        
        //RGB color space
        let colorSpace: CGColorSpace = CGColorSpaceCreateDeviceRGB()
        let newContext: CGContext = CGContext(data: baseAddress, width: width, height: height, bitsPerComponent: 8, bytesPerRow: bytesPerRow, space: colorSpace, bitmapInfo: bitmapInfo)!
        // Quartz Image
        let imageRef: CGImage = newContext.makeImage()!
        
        // UIImage
        let cameraImage: UIImage = UIImage(cgImage: imageRef)
        
        if(processing) {
        // Apply OpenCV fileter
        let resultImage: UIImage = OpenCVWrapper.detectFeatures(cameraImage)
        return resultImage
        }
        
        return cameraImage
        
    }
    
    @IBAction func ButtonClicked(_ sender: Any) {
        processing = !processing
    }

}

