//
//  ViewController.swift
//  demoML
//
//  Created by iOS Development on 6/11/18.
//  Copyright © 2018 Smartivity. All rights reserved.
//

import UIKit
import ARKit
import Vision


public class DynamicType<T> {
    public typealias Listener = (T) -> Void
    public var listener:Listener?
    public var value:T { didSet { listener?(value) } }
    public init(_ value:T) { self.value = value }
    public func bind(listner:Listener?) { self.listener = listner ; listener?(value) }
}





class ViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {

    var labelString:DynamicType<String?> = DynamicType("")
    
    override func viewDidLoad() {
        super.viewDidLoad()
       
        
        let captureSession = AVCaptureSession()
        guard let captureDevice = AVCaptureDevice.default(for: .video) else {return}
        let input = try! AVCaptureDeviceInput(device: captureDevice)
        captureSession.addInput(input)
        captureSession.startRunning()
        
        let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        view.layer.addSublayer(previewLayer)
        previewLayer.frame = view.bounds
        
        
        let dataOutput = AVCaptureVideoDataOutput()
        dataOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "cameraQueue"))
        captureSession.addOutput(dataOutput)
      
        view.addSubview(label)
        label.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        label.bottomAnchor.constraint(equalTo: view.bottomAnchor,constant: -100).isActive = true
        label.widthAnchor.constraint(equalTo: view.widthAnchor,constant: -50).isActive = true
        label.heightAnchor.constraint(equalTo: label.heightAnchor).isActive = true
        
        
        DispatchQueue.main.async {
            self.labelString.bind(listner: {
                self.label.text = $0
            })
        }
        
    }
    
    var label : UILabel = {
       let instance = UILabel()
        instance.translatesAutoresizingMaskIntoConstraints = false
        instance.font = UIFont.preferredFont(forTextStyle: UIFontTextStyle.headline)
        instance.textColor = UIColor.green
        instance.textAlignment = .center
        return instance
    }()

    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        
        guard let pixelBuffer : CVPixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {return}
        //MARK: Change model name for different model
        guard let model = try? VNCoreMLModel(for: hand().model) else {return}
        
        let request = VNCoreMLRequest(model: model) { (finishedReq, error) in
          
            guard let results = finishedReq.results as? [VNClassificationObservation] else {return}
            guard let firstObservation = results.first else {return}
            
            print(firstObservation.identifier)
            DispatchQueue.main.async {
                self.labelString.value = firstObservation.identifier
            }
            
            
        }
       try? VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:]).perform([request])
        
    }


}

