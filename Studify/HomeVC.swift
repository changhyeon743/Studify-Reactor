//
//  ViewController.swift
//  Studify
//
//  Created by 이창현 on 04/08/2019.
//  Copyright © 2019 이창현. All rights reserved.
//

import UIKit
import AVFoundation

import ReactorKit
import RxCocoa
import RxSwift

class HomeVC: UIViewController,StoryboardView {
    var disposeBag: DisposeBag  = DisposeBag()
    var reactor: HomeReactor?
    
    var session = AVCaptureSession()
    var device : AVCaptureDevice!
    var output : AVCaptureVideoDataOutput!
    var previewLayer:AVCaptureVideoPreviewLayer!
    
    var luminosity:BehaviorSubject<Double> = BehaviorSubject(value: 10)
    
    @IBOutlet weak var currentBtn: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        reactor = HomeReactor()
        
        if let captureDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: AVMediaType.video, position: .front) {
            do {
                let input = try AVCaptureDeviceInput(device: captureDevice)
                session.addInput(input)
            }
            catch {
                print("Error")
            }
            
            
            
            self.navigationController?.navigationBar.isTranslucent = false
            
            output = AVCaptureVideoDataOutput()
            output.alwaysDiscardsLateVideoFrames = true
            output.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32BGRA)]
            output.setSampleBufferDelegate(self, queue: DispatchQueue(label: "studify"))
            if session.canAddOutput(output) {
                session.addOutput(output)
            } else {
                return
            }
//
//            cover.backgroundColor = .black
//            cover.frame = view.frame
//            UIApplication.shared.keyWindow!.addSubview(cover)
//            UIApplication.shared.keyWindow!.bringSubviewToFront(cover)
//            cover.isHidden = true
            session.startRunning()
            
            print("session started")
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        self.tabBarController?.navigationItem.title = "집중"
    }
    
    
    func bind(reactor: HomeReactor) {
        //Action
        currentBtn.rx.tap
            .map {Reactor.Action.currentChanged(self.currentBtn.title(for: .normal) ?? "")}
            .do(onNext: { (_) in
                self.currentBtn.setTitle("숙제", for: .normal)
            })
            .bind(to: reactor.action)
            .disposed(by: disposeBag)
        
        
            //start
        luminosity
            .filter{_ in reactor.currentState.reversed == true}
            .filter{$0 > 4}
            .map{_ in Reactor.Action.phoneReversed}
            .bind(to: reactor.action)
            .disposed(by: disposeBag)
        
            //stop
        luminosity
            .filter{_ in reactor.currentState.reversed == false}
            .filter{$0 < 4}
            .map{_ in Reactor.Action.phoneReversed}
            .bind(to: reactor.action)
            .disposed(by: disposeBag)
        
        //State
        reactor.state.map { $0.current }
            .bind(to: currentBtn.rx.title(for: .normal))
            .disposed(by: disposeBag)
    }
}

extension HomeVC : AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        
        
        
        //Calculating the luminosity ( 인터넷에서 가져온 코드 )
        let rawMetadata = CMCopyDictionaryOfAttachments(allocator: nil, target: sampleBuffer, attachmentMode: CMAttachmentMode(kCMAttachmentMode_ShouldPropagate))
        let metadata = CFDictionaryCreateMutableCopy(nil, 0, rawMetadata) as NSMutableDictionary
        let exifData = metadata.value(forKey: "{Exif}") as? NSMutableDictionary
        
        let FNumber : Double = exifData?["FNumber"] as! Double
        let ExposureTime : Double = exifData?["ExposureTime"] as! Double
        let ISOSpeedRatingsArray = exifData!["ISOSpeedRatings"] as? NSArray
        let ISOSpeedRatings : Double = ISOSpeedRatingsArray![0] as! Double
        let CalibrationConstant : Double = 50
        
        let l : Double = (CalibrationConstant * FNumber * FNumber ) / ( ExposureTime * ISOSpeedRatings )
        //5 보다 낮을 경우 시작
        luminosity.onNext(l)
    }
}
