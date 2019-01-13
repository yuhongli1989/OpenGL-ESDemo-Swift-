//
//  SoundEffect.swift
//  OpenGLES004
//
//  Created by 于洪礼 on 2019/1/12.
//  Copyright © 2019 yuhongli. All rights reserved.
//

import UIKit
import AudioToolbox

class SoundEffect {

    var soundId:SystemSoundID = 0
    init(_ file:String) {
        let url = URL(fileURLWithPath: file)
        var asoundId:SystemSoundID = 0
        let status =  AudioServicesCreateSystemSoundID(url as CFURL, &asoundId)
        if status == kAudioServicesNoError {
            soundId = asoundId
        }else{
            fatalError("build error")
        }
    }
    
    deinit {
        AudioServicesDisposeSystemSoundID(soundId)
    }
    
    func play()  {
        AudioServicesPlaySystemSound(soundId)
    }
    
}
