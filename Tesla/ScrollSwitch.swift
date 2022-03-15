//
//  ScrollSwitch.swift
//  Tesla
//
//  Created by Kuan Lu on 2021/9/30.
//

import UIKit


protocol ScrollSwitchDelegate {
    func onIsOnUpdate(_ sender:ScrollSwitch)
}
class ScrollSwitch: UIView {

    /*
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
    }
    */
    var delegate:ScrollSwitchDelegate?
    lazy var button:UIView = {
        let b = UIView()
        b.layer.cornerRadius = 10
        //b.layer.borderColor = UIColor.green.cgColor
        b.backgroundColor = .white
        b.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(b)
        b.topAnchor.constraint(equalTo: self.topAnchor).isActive = true
        b.bottomAnchor.constraint(equalTo: self.bottomAnchor).isActive = true
        self.buttonLeadingConstraint = b.leadingAnchor.constraint(equalTo: self.leadingAnchor)
        self.buttonLeadingConstraint.isActive = true
        b.widthAnchor.constraint(equalTo: self.widthAnchor, multiplier: 0.35).isActive = true
        b.addGestureRecognizer(self.panGesture)
        return b
    }()
    lazy var label:UILabel = {
        let L = UILabel()
        L.translatesAutoresizingMaskIntoConstraints = false
        self.button.addSubview(L)
        L.centerYAnchor.constraint(equalTo: self.button.centerYAnchor).isActive = true
        L.centerXAnchor.constraint(equalTo: self.button.centerXAnchor).isActive = true
        return L
    }()
    var isOn:Bool = false {
        didSet {
            self.label.text = (self.isOn) ? "On" : "Off"
            self.buttonLeadingConstraint.constant = self.isOn ? self.frame.width - self.button.frame.width : 0
            self.label.textColor = (self.isOn) ? .green : .black
           
        }
    } //設定初始值是關
    weak var buttonLeadingConstraint:NSLayoutConstraint!
    lazy var panGesture:UIPanGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(onPan(_:)))
    override func awakeFromNib() {
        super.awakeFromNib()
        self.layer.cornerRadius = 10
        
        self.layer.borderWidth = 2
        self.layer.borderColor = UIColor.lightGray.cgColor
        self.backgroundColor = .black
        
        self.isOn = false
    
    }
    @objc func onPan(_ sender:UIPanGestureRecognizer) {
        let translation = sender.translation(in: self)
        let maxX = self.frame.width - self.button.frame.width
        let startX = (self.isOn) ? maxX : 0
// 問號得意思       if self.isOn {
//            startX = maX
//        }
//        else {
//            startX = 0
//        }
        let offsetX = translation.x + startX
        self.buttonLeadingConstraint.constant = min(max(offsetX,0),maxX)
        if sender.state == .ended {
            let oldValue = self.isOn
            UIView.animate(withDuration: 0.1, animations: {
                self.isOn = abs(self.buttonLeadingConstraint.constant - maxX) < 20
                self.layoutIfNeeded()

            },completion: {
                finished in
                if self.isOn != oldValue {
                    self.delegate?.onIsOnUpdate(self)
                }
            })
            
        }
        
    }
}



