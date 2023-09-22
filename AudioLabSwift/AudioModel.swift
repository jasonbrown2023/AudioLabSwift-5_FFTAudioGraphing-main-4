//
//  AudioModel.swift
//  AudioLabSwift
//
//  Created by Eric Larson 
//  Copyright © 2020 Eric Larson. All rights reserved.
//

import Foundation
import Accelerate

class AudioModel {
    
    // MARK: Properties
    private var BUFFER_SIZE:Int
    // thse properties are for interfaceing with the API
    // the user can access these arrays at any time and plot them if they like
    var timeData:[Float]
    var fftData:[Float]
    var fftData2:[Float]
    var max:[Float]
    
    // MARK: Public Methods
    init(buffer_size:Int) {
        BUFFER_SIZE = buffer_size
        // anything not lazily instatntiated should be allocated here
        timeData = Array.init(repeating: 0.0, count: BUFFER_SIZE)
        fftData = Array.init(repeating: 0.0, count: BUFFER_SIZE/2)
        fftData2 = Array.init(repeating: 0.0, count: BUFFER_SIZE/2)
        max = Array.init(repeating: 0.0, count: 20)
    }
    
    // public function for starting processing of microphone data
    func startMicrophoneProcessing(withFps:Double){
        // setup the microphone to copy to circualr buffer
        if let manager = self.audioManager{
            manager.inputBlock = self.handleMicrophone
            //manager.outputBlock = self.printMax
            
            
            // repeat this fps times per second using the timer class
            //   every time this is called, we update the arrays "timeData" and "fftData"
            Timer.scheduledTimer(withTimeInterval: 1.0/withFps, repeats: true) { _ in
                self.runEveryInterval()
            }
            
        }
    }
    
    
    // You must call this when you want the audio to start being handled by our model
    func play(){
        if let manager = self.audioManager{
            manager.play()
        }
    }
    
    func pause(){
        if let manager = self.audioManager{
            manager.pause()
        }
    }
    
    
    //==========================================
    // MARK: Private Properties
    private lazy var audioManager:Novocaine? = {
        return Novocaine.audioManager()
    }()
    
    private lazy var fftHelper:FFTHelper? = {
        return FFTHelper.init(fftSize: Int32(BUFFER_SIZE))
    }()
    
    
    
    private lazy var inputBuffer:CircularBuffer? = {
        return CircularBuffer.init(numChannels: Int64(self.audioManager!.numInputChannels),
                                   andBufferSize: Int64(BUFFER_SIZE))
    }()
    
    
    //==========================================
    // MARK: Private Methods
    // NONE for this model
    
    //==========================================
    // MARK: Model Callback Methods
    private func runEveryInterval(){
        if inputBuffer != nil {
            // copy time data to swift array
            self.inputBuffer!.fetchFreshData(&timeData,
                                             withNumSamples: Int64(BUFFER_SIZE))
            
            // now take FFT
            fftHelper!.performForwardFFT(withData: &timeData,
                                         andCopydBMagnitudeToBuffer: &fftData)
            
            fftHelper!.performForwardFFT(withData: &timeData,
                                         andCopydBMagnitudeToBuffer: &fftData2)
            
            
            
            
            
            
            
            // at this point, we have saved the data to the arrays:
            //   timeData: the raw audio samples
            //   fftData:  the FFT of those same samples
            // the user can now use these variables however they like
            
        }
    }
    
    //==========================================
    // MARK: Audiocard Callbacks
    // in obj-C it was (^InputBlock)(float *data, UInt32 numFrames, UInt32 numChannels)
    // and in swift this translates to:
    private func handleMicrophone (data:Optional<UnsafeMutablePointer<Float>>, numFrames:UInt32, numChannels: UInt32) {
        // copy samples from the microphone into circular buffer
        self.inputBuffer?.addNewFloatData(data, withNumSamples: Int64(numFrames))
        //printMax(data: Optional<UnsafeMutablePointer<Float>>, numFrames: UInt32, numChannels: UInt32)
        
        if let arrayData = data{
            var max: Float = 0;
            //---------------------------------------
            // just print out the first audio sample
            //print(arrayData[0])
            // 🎙️ -> 📉 grab first element in the buffer
            
            //---------------------------------------
            // bonus: vDSP example (will cover in next lecture)
            // here is an example using iOS accelerate to quickly handle the array
            // Let's use the accelerate framework
            
            vDSP_maxv(arrayData, 1, &max, vDSP_Length(numFrames))
            print(max)
            
            
        }
        
        func printMax (data:Optional<UnsafeMutablePointer<Float>>, numFrames:UInt32, numChannels: UInt32) {
            // copy samples from the microphone into circular buffer
            //self.inputBuffer?.addNewFloatData(data, withNumSamples: Int64(numFrames))
            var max:[Float] =
            Array.init(repeating: 0.0, count: 20)
            
            if let arrayData = data{
                //---------------------------------------
                // just print out the first audio sample
                //print(arrayData[0])
                // 🎙️ -> 📉 grab first element in the buffer
                
                //---------------------------------------
                // bonus: vDSP example (will cover in next lecture)
                // here is an example using iOS accelerate to quickly handle the array
                // Let's use the accelerate framework
                
                vDSP_maxv(arrayData, 1, &max, vDSP_Length(numFrames))
                print(max)
                
                
                
                // 🎙️ -> 📉 get max element in the buffer
            }
            
        }
        
        
    }
}
