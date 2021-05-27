//
//  InputBarRecordView.swift
//  EEChatUI
//
//  Created by Snow on 2021/5/12.
//

import UIKit
import AVFoundation

public protocol InputBarRecordViewDelegate: AnyObject {
    func inputBarRecordView(_ inputBarRecordView: InputBarRecordView, finish url: URL)
}

public class InputBarRecordView: UIView {
    
    enum State {
        case begin
        case preCancel
        case preDone
        case cancel
        case done
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }
    
    public weak var delegate: InputBarRecordViewDelegate?
    
    lazy var label: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        label.textColor = UIColor(red: 0.11, green: 0.45, blue: 0.93, alpha: 1)
        
        addSubview(label)
        let centerX = label.centerXAnchor.constraint(equalTo: centerXAnchor)
        let centerY = label.centerYAnchor.constraint(equalTo: centerYAnchor)
        NSLayoutConstraint.activate([centerX, centerY])
        
        return label
    }()
    
    lazy var recordView: InputBarRecordAnimationView = {
        var vc: UIViewController?
        var superview = self.superview
        while superview != nil, vc == nil {
            vc = superview?.next as? UIViewController
            superview = superview?.superview
        }
        
        guard let vc = vc else {
            fatalError()
        }
        
        let view = InputBarRecordAnimationView()
        vc.view.addSubview(view)
        view.translatesAutoresizingMaskIntoConstraints = false
        
        let centerX = view.centerXAnchor.constraint(equalTo: vc.view.centerXAnchor)
        let centerY = view.centerYAnchor.constraint(equalTo: vc.view.centerYAnchor, constant: -50)
        NSLayoutConstraint.activate([centerX, centerY])
        return view
    }()
    
    private func setupView() {
        layer.cornerRadius = 4
        translatesAutoresizingMaskIntoConstraints = false
        
        backgroundColor = .white
        label.text = LocalizedString("Hold to Talk")
    }
    
    var state = State.done {
        didSet {
            if state == oldValue {
                return
            }
            
            switch state {
            case .begin:
                record()
                backgroundColor = UIColor(red: 0xE3 / 255, green: 0xE3 / 255, blue: 0xE3 / 255, alpha: 1)
                label.text = LocalizedString("Release to send")
                recordView.isHidden = false
                recordView.label.text = LocalizedString("Swipe up cancel")
                recordView.waverView.setWaverLevel { [weak self] (waverView) in
                    guard let recorder = self?.recorder else {
                        return
                    }
                    recorder.updateMeters()
                    let normalizedValue = pow(10, recorder.averagePower(forChannel: 0) / 40)
                    waverView.level = CGFloat(normalizedValue)
                }
            case .preCancel:
                label.text = LocalizedString("Release to cancel")
                recordView.label.text = LocalizedString("Swipe down to send")
            case .preDone:
                label.text = LocalizedString("Release to send")
                recordView.label.text = LocalizedString("Swipe up cancel")
            case .cancel, .done:
                backgroundColor = .white
                label.text = LocalizedString("Hold to Talk")
                recorder?.stop()
                recordView.isHidden = true
                recordView.waverView.invalidate()
            }
        }
    }
    
    // MARK: - Override
    public override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        state = .begin
    }
    
    public override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        if state == .cancel || state == .done {
            return
        }
        
        if touches.count == 1, let touch = touches.first {
            let point = touch.location(in: self)
            if point.y < -50 {
                state = .preCancel
            } else {
                state = .preDone
            }
        }
    }
    
    public override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        state = .done
    }
    
    public override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        state = .cancel
    }
    
    // MARK: - Recorder
    private var recorder: AVAudioRecorder?
    public var maxDuration: TimeInterval? = 60
}

extension InputBarRecordView {
    func record() {
        AVAudioSession.sharedInstance().requestRecordPermission { (granted) in
            if granted {
                self._record()
            } else {
                self.state = .cancel
            }
        }
    }
    
    private func _record() {
        let filePath = NSTemporaryDirectory().appending("/eechat/record/" + NSUUID().uuidString + ".wav")
        let url = URL(fileURLWithPath: filePath)

        let fileManager = FileManager.default
        let dir = url.deletingLastPathComponent().path
        if !fileManager.fileExists(atPath: dir) {
            try? fileManager.createDirectory(atPath: dir, withIntermediateDirectories: true, attributes: nil)
        }

        let session = AVAudioSession.sharedInstance()
        // 设置session类型
        do {
            try session.setCategory(.playAndRecord)
        } catch {
            
        }

        // 设置session动作
        do {
            try session.setActive(true)
        } catch {
            
        }

        // 录音设置，注意，后面需要转换成NSNumber，是因为底层还是用OC写的原因
        let setting: [String: Any] = [
            AVSampleRateKey: NSNumber(value: 8000), // 设置录音采样率，8000是电话采样率，对于一般录音已经够了
            AVFormatIDKey: NSNumber(value: kAudioFormatLinearPCM), // 设置录音格式
            AVLinearPCMBitDepthKey: NSNumber(value: 16), // 每个采样点位数,分为8、16、24、32
            AVNumberOfChannelsKey: NSNumber(value: 1), // 设置通道,这里采用单声道
            AVEncoderAudioQualityKey: NSNumber(value: AVAudioQuality.min.rawValue), // 录音质量
        ]

        // 开始录音
        do {
            let recorder = try AVAudioRecorder(url: url, settings: setting)
            recorder.delegate = self
            // 如果要监控声波则必须设置为YES
            recorder.isMeteringEnabled = true
            recorder.prepareToRecord()
            if let duration = maxDuration {
                recorder.record(forDuration: duration)
            } else {
                recorder.record()
            }
            self.recorder = recorder
        } catch {
            
        }
    }
}

extension InputBarRecordView: AVAudioRecorderDelegate {
    public func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        switch state {
        case .preCancel:
            state = .cancel
        case .preDone:
            state = .done
            fallthrough
        case .done:
            if flag {
                delegate?.inputBarRecordView(self, finish: recorder.url)
            }
        default:
            break
        }
    }

    public func audioRecorderEncodeErrorDidOccur(_: AVAudioRecorder, error: Error?) {
        
    }
}
