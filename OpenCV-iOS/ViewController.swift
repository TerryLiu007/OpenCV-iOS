//
//  ViewController.swift
//  OpenCV-iOS
//
//  Created by TerryLiu on 2/2/18.
//  Copyright © 2018 TerryLiu. All rights reserved.
//

import UIKit
import AVFoundation

class ViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate{

    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var versionLabel: UILabel!
    
    var input:AVCaptureDeviceInput!
    var output:AVCaptureVideoDataOutput!
    var session:AVCaptureSession!
    var camera:AVCaptureDevice!
    var processing:Bool!
    var redetect:Bool!
    var imagePicker = UIImagePickerController()
    var objectImage:UIImage!
    var cvFunction = CVFunction.FeatureDetect
    var feature = FeatureDetector.ORB
    let quality = AVCaptureSession.Preset.vga640x480
    
    enum CVFunction {
        case FeatureDetect
        case Canny
        case Bilateral
        case ColorRange
    }
    
    enum FeatureDetector {
        case ORB
        case BRISK
        case AKAZE
        case SURF
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        imagePicker.delegate = self
        processing = false
        redetect = false
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
        
        var image:UIImage = self.captureImage(sampleBuffer)
        switch cvFunction {
        case .FeatureDetect:
            break
        case .Canny:
            image = OpenCVWrapper.cannyEdge(image)
        case .Bilateral:
            image = OpenCVWrapper.bilateralFilter(image)
        case .ColorRange:
            image = OpenCVWrapper.detectColor(image)
        }
        
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
        
        if(processing && self.cvFunction == .FeatureDetect) {
        
            var resultImage: UIImage!
            
            // Apply OpenCV fileter
            switch feature {
            case .ORB:
                resultImage = OpenCVWrapper.orb(matching: cameraImage, withTemplate: objectImage, withRedetect: redetect)
            case .BRISK:
                resultImage = OpenCVWrapper.brisk(matching: cameraImage, withTemplate: objectImage, withRedetect: redetect)
            case .AKAZE:
                resultImage = OpenCVWrapper.akaze(matching: cameraImage, withTemplate: objectImage, withRedetect: redetect)
            case .SURF:
                resultImage = OpenCVWrapper.surf(matching: cameraImage, withTemplate: objectImage, withRedetect: redetect)
            }
            
            if(redetect == true) {
                redetect = false
            }
            
            return resultImage
        }
        
        return cameraImage
        
    }
    
    
    @IBAction func DetectObject(_ sender: UIButton) {
        processing = !processing
        redetect = true
    }
    
    @IBAction func CVFunctionSelect(_ sender: UIButton) {
        
        let alert = UIAlertController(title: "Choose other functions", message: nil, preferredStyle: .actionSheet)
        
        alert.addAction(UIAlertAction(title: "Color range", style: .default, handler: { _ in
            self.cvFunction = .ColorRange
            self.processing = false
        }))
        
        alert.addAction(UIAlertAction(title: "Canny edge", style: .default, handler: { _ in
            self.cvFunction = .Canny
            self.processing = false
        }))
        
        alert.addAction(UIAlertAction(title: "Bilateral filter", style: .default, handler: { _ in
            self.cvFunction = .Bilateral
            self.processing = false
        }))
        
        alert.addAction(UIAlertAction(title: "ORB feature", style: .default, handler: { _ in
            self.processing = false
            
            self.cvFunction = .FeatureDetect
            self.feature = .ORB
            
        }))
        
        alert.addAction(UIAlertAction(title: "BRISK feature", style: .default, handler: { _ in
            self.processing = false
            
            self.cvFunction = .FeatureDetect
            self.feature = .BRISK
            
        }))
        
        alert.addAction(UIAlertAction(title: "AKAZE feature", style: .default, handler: { _ in
            self.processing = false
            
            self.cvFunction = .FeatureDetect
            self.feature = .AKAZE
            
        }))
        
        alert.addAction(UIAlertAction(title: "SURF feature", style: .default, handler: { _ in
            self.processing = false
            
            self.cvFunction = .FeatureDetect
            self.feature = .SURF
            
        }))
        
        alert.addAction(UIAlertAction.init(title: "Cancel", style: .cancel, handler: nil))
        
        switch UIDevice.current.userInterfaceIdiom {
        case .pad:
            alert.popoverPresentationController?.sourceView = sender
            alert.popoverPresentationController?.sourceRect = sender.bounds
            alert.popoverPresentationController?.permittedArrowDirections = .up
        default:
            break
        }
        
        self.present(alert, animated: true, completion: nil)
    }
    
    @IBAction func DefineObject(_ sender: UIButton) {
        
        let alert = UIAlertController(title: "Choose Image", message: nil, preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "Camera", style: .default, handler: { _ in
            self.openCamera()
        }))
        
        alert.addAction(UIAlertAction(title: "Gallery", style: .default, handler: { _ in
            self.openGallary()
        }))
        
        alert.addAction(UIAlertAction.init(title: "Cancel", style: .cancel, handler: nil))
        
        /*If you want work actionsheet on ipad
         then you have to use popoverPresentationController to present the actionsheet,
         otherwise app will crash on iPad */
        switch UIDevice.current.userInterfaceIdiom {
        case .pad:
            alert.popoverPresentationController?.sourceView = sender
            alert.popoverPresentationController?.sourceRect = sender.bounds
            alert.popoverPresentationController?.permittedArrowDirections = .up
        default:
            break
        }
        
        self.present(alert, animated: true, completion: nil)
    }
    
    
    func openCamera()
    {
        if(UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.camera))
        {
            imagePicker.sourceType = UIImagePickerControllerSourceType.camera
            imagePicker.allowsEditing = false
            self.present(imagePicker, animated: true, completion: nil)
        }
        else
        {
            let alert  = UIAlertController(title: "Warning", message: "You don't have camera", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    
    func openGallary()
    {
        imagePicker.sourceType = UIImagePickerControllerSourceType.photoLibrary
        imagePicker.allowsEditing = false
        self.present(imagePicker, animated: true, completion: nil)
    }
    
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        
        if let image = info[UIImagePickerControllerOriginalImage] as? UIImage
        {
            objectImage = image
        }
        else
        {
            let alert  = UIAlertController(title: "Warning", message: "Only image can be defined as detect object", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
        redetect = true
        self.dismiss(animated: true, completion: nil)
    }
    
}

extension UIImage {
    
    func resizeImage(targetSize: CGSize) -> UIImage {
        let size = self.size
        let widthRatio  = targetSize.width  / size.width
        let heightRatio = targetSize.height / size.height
        let newSize = widthRatio > heightRatio ?  CGSize(width: size.width * heightRatio, height: size.height * heightRatio) : CGSize(width: size.width * widthRatio,  height: size.height * widthRatio)
        let rect = CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height)
        
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        self.draw(in: rect)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage!
    }
}

