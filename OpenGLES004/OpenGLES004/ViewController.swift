//
//  ViewController.swift
//  OpenGLES004
//
//  Created by 于洪礼 on 2019/1/12.
//  Copyright © 2019 yuhongli. All rights reserved.
//

import UIKit

let kBrightness:CGFloat = 1.0
let kSaturation:CGFloat = 0.45
let kPaletteHeight:CGFloat = 30
let kPaletteSize:CGFloat = 5
let kMinEraseInterval:CGFloat = 0.5

let kLeftMargin:CGFloat = 10
let kTopMargin:CGFloat = 10
let kRightMargin:CGFloat = 10
let kBottomMargin:CGFloat = 20
class ViewController: UIViewController {
    
    lazy var erasingSound:SoundEffect = {
        let path = Bundle.main.path(forResource: "Erase", ofType: "caf")
        return SoundEffect(path!)
    }()
    lazy var selectSound:SoundEffect = {
        let path = Bundle.main.path(forResource: "Select", ofType: "caf")
        return SoundEffect(path!)
    }()
    var lastTime:CFTimeInterval = 0
    override func viewDidLoad() {
        super.viewDidLoad()
        setUI()
    }
    
    func setUI()  {
        let redImage = UIImage(named: "Red")?.withRenderingMode(.alwaysOriginal)
        let yellowImage = UIImage(named: "Yellow")?.withRenderingMode(.alwaysOriginal)
        let greenImage = UIImage(named: "Green")?.withRenderingMode(.alwaysOriginal)
        let blueImage = UIImage(named: "Blue")?.withRenderingMode(.alwaysOriginal)
        let imageArrays = [redImage,yellowImage,greenImage,blueImage].compactMap {$0}
        
        let segmentedControl = UISegmentedControl(items: imageArrays)
        
        let rect = CGRect(x: kLeftMargin, y: UIScreen.main.bounds.height-kPaletteHeight-kBottomMargin, width: UIScreen.main.bounds.width-kLeftMargin-kRightMargin, height: kPaletteHeight)
        segmentedControl.frame = rect
        segmentedControl.addTarget(self, action: #selector(changBrushColor(_:)), for: .valueChanged)
        segmentedControl.tintColor = UIColor.darkGray
        segmentedControl.selectedSegmentIndex = 2
        self.view.addSubview(segmentedControl)
        let color = UIColor(hue: 2.0/kPaletteSize, saturation: kSaturation, brightness: kBrightness, alpha: 1).cgColor
        changeColor(color)
        
        
    }
    
    @objc func changBrushColor(_ sender:UISegmentedControl) {
        selectSound.play()
        let color = UIColor(hue: CGFloat(sender.selectedSegmentIndex)/kPaletteSize, saturation: kSaturation, brightness: kBrightness, alpha: 1.0).cgColor
        changeColor(color)
    }
    
    func changeColor(_ color:CGColor)  {
        
        if let arr = color.components,arr.count>3{
            (self.view as! HLView).setBrushColor(arr[0], arr[1], arr[2])
        }
    }


}

