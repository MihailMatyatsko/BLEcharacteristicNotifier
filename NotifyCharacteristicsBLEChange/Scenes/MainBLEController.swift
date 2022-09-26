//
//  MainBLEController.swift
//  NotifyCharacteristicsBLEChange
//
//  Created by Mihail Matyatsko on 22.09.2022.
//

import UIKit
import CoreBluetooth
import Combine
import VTMProductLib

final class MainBLEController: UIViewController {
    
    @IBOutlet private weak var contentView: UIView!
    @IBOutlet private weak var bpmRateLabel: UILabel!
    @IBOutlet private weak var amountOfNotifiesLabel: UILabel!
    
    @IBOutlet private weak var startNotifiingButton: UIButton!
    @IBOutlet private weak var stopNotifiingButton: UIButton!
    @IBOutlet private weak var connectDisconnetButton: UIButton!
    
    private var centralManager: CBCentralManager!
    private var fitbitPeripheral: CBPeripheral?
    
    private var heartRateMeasurementCharacteristic: CBCharacteristic?
    private let heartRateMeasurementCharacteristicCBUUID = CBUUID(string: "2A37")
    private let bodySensorLocationCharacteristicCBUUID = CBUUID(string: "2A38")
    private var duoEK2uuidString: String = "0829D646-BE6E-BA8A-B8C1-7B2DF597C46A"
    private var globalNotifiesCounter: Int = 0
    @Published private var isPeripheralConnnected: Bool = false
    
    private var cancelable: Set<AnyCancellable> = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
        setupObservers()
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }
    
    //MARK: - ViewInjected
    static func make() -> Self {
        return loadFromXib()
    }
    
    //MARK: - Private
    private func setupUI() {
        contentView.layer.cornerRadius = 8
        var config: UIButton.Configuration = UIButton.Configuration.tinted()
        config.cornerStyle = .capsule
        config.baseBackgroundColor = isPeripheralConnnected ? UIColor.red : UIColor.green
        connectDisconnetButton.configuration = config
    }
    
    private func setupObservers() {
        $isPeripheralConnnected
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
            .sink { [weak self] isConnected in
                guard let self = self else { return }
                var config: UIButton.Configuration = UIButton.Configuration.tinted()
                config.cornerStyle = .capsule
                config.baseBackgroundColor = isConnected ? UIColor.red : UIColor.green
                config.title = isConnected ? "Disconnect" : "Connect"
                self.connectDisconnetButton.configuration = config
            }
            .store(in: &cancelable)
    }
    
    private func bodyLocation(from characteristic: CBCharacteristic) -> String {
        guard let characteristicData = characteristic.value,
              let byte = characteristicData.first else { return "Error" }
        
        switch byte {
        case 0: return "Other"
        case 1: return "Chest"
        case 2: return "Wrist"
        case 3: return "Finger"
        case 4: return "Hand"
        case 5: return "Ear Lobe"
        case 6: return "Foot"
        default:
            return "Reserved for future use"
        }
    }
    
    private func heartRate(from characteristic: CBCharacteristic) -> Int {
        guard let characteristicData = characteristic.value else { return -1 }
        let byteArray = [UInt8](characteristicData)
        print("DEBUG: Byte array: \(byteArray)")
        print("DEBUG: Byte array[0] \(byteArray[0])")
        
        let firstBitValue = byteArray[0] & 0x01
        if firstBitValue == 0 {
            return Int(byteArray[1])
        } else {
            return (Int(byteArray[1]) << 8) + Int(byteArray[2])
        }
    }
    
    private func setNotifyValueForBPM(_ notify: Bool) {
        guard
            let fitbitPeripheral = self.fitbitPeripheral,
            let heartRateMeasurementCharacteristic = self.heartRateMeasurementCharacteristic
        else {
            return
        }
        if notify {
            startNotifiingButton.isEnabled = false
            stopNotifiingButton.isEnabled = true
        } else {
            startNotifiingButton.isEnabled = true
            stopNotifiingButton.isEnabled = false
        }
        fitbitPeripheral.setNotifyValue(
            notify,
            for: heartRateMeasurementCharacteristic
        )
    }
    
    //MARK: - Actions
    @IBAction private func connectDisconnect(_ sender: UIButton) {
        guard
            let fitbitPeripheral = self.fitbitPeripheral
        else {
            return
        }
        isPeripheralConnnected ? centralManager.cancelPeripheralConnection(fitbitPeripheral) : centralManager.connect(fitbitPeripheral)
        
    }
    
    @IBAction private func stopNotifiing(sender: UIButton) {
        setNotifyValueForBPM(false)
    }
    
    @IBAction private func startNotifiing(_ sender: UIButton) {
        setNotifyValueForBPM(true)
    }
    
}

extension MainBLEController: CBCentralManagerDelegate {
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .resetting:
            print("central.state is .resetting")
        case .unsupported:
            print("central.state is .unsupported")
        case .unauthorized:
            print("central.state is .unauthorized")
        case .poweredOff:
            print("central.state is .poweredOff")
        case .poweredOn:
            print("central.state is .poweredOn")
            centralManager.scanForPeripherals(withServices: nil)
        case .unknown:
            print("central.state is .unknown")
        @unknown default:
            print("central.state is .unknown")
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        print("-----------------------------------------")
        print("Peripheral: \(peripheral)")
        print("Peripheral uuid: \(peripheral.identifier)")
        print("Peripheral name: \(peripheral.name != nil ? peripheral.name! : "No device name information")")
        
        //Establish connection
        if peripheral.identifier.uuidString == duoEK2uuidString {
            fitbitPeripheral = peripheral
            guard let _ = self.fitbitPeripheral else { return }
            centralManager.stopScan()
            connectDisconnetButton.isEnabled = true
        }
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("Connected to ble device")
        
//        VTMProductURATUtils.shared.delegate = self
//        VTMProductURATUtils.shared.deviceDelegate = self
//        VTMProductURATUtils.shared.peripheral = peripheral
        
        isPeripheralConnnected = true
        fitbitPeripheral?.delegate = self
        fitbitPeripheral?.discoverServices(nil)
        
        startNotifiingButton.isEnabled = true
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        print("Disconnected from ble device")
        isPeripheralConnnected = false
        fitbitPeripheral?.delegate = nil
        startNotifiingButton.isEnabled = false
        stopNotifiingButton.isEnabled = false
    }
    
}

extension MainBLEController: CBPeripheralDelegate {
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        print("-------------didDiscoverServices--------------")
        guard let services = peripheral.services else { return }
        print("Peripheral services")
        for service in services {
            print("Service: \(service)")
            peripheral.discoverCharacteristics([heartRateMeasurementCharacteristicCBUUID, bodySensorLocationCharacteristicCBUUID], for: service)
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        print("-------------didDiscoverCharacteristicsFor--------------")
        guard let characteristics = service.characteristics else { return }
        characteristics.forEach { characteristic in
            if characteristic.properties.contains(.read) {
                print("\(characteristic.uuid): properties contains .read")
                peripheral.readValue(for: characteristic)
            }
            if characteristic.properties.contains(.notify) {
                print("\(characteristic.uuid): properties contains .notify")
                heartRateMeasurementCharacteristic = characteristic
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        switch characteristic.uuid {
        case bodySensorLocationCharacteristicCBUUID:
            print("-------------didUpdateValueFor--------------")
            let bodySensorLocation = bodyLocation(from: characteristic)
            print("Body sensor characteristic value: \(bodySensorLocation)")
        case heartRateMeasurementCharacteristicCBUUID:
            print("-------------didUpdateValueFor--------------")
            globalNotifiesCounter += 1
            let bpm = heartRate(from: characteristic)
            bpmRateLabel.text = String(describing: bpm)
            amountOfNotifiesLabel.text = String(describing: globalNotifiesCounter)
//            error if call request from here
//            VTMProductURATUtils.shared.requestECGRealData()
            print("BPM: \(bpm)")
        default:
            print("-------------didUpdateValueFor--------------")
            print("Unhandled type character...")
        }
    }
    
}

//extension MainBLEController: VTMURATUtilsDelegate {
//
//    @objc(util: commandCompletion: deviceType: response:)
//    func util(_ util: VTMURATUtils, commandCompletion cmdType: u_char, deviceType: VTMDeviceType, response: Data?) {
//        print("DEBUG: recieve call in \(#function)")
//        switch deviceType {
//        case VTMDeviceTypeECG:
//            if cmdType == VTMECGCmdGetRealData.rawValue {
//                guard let response = response else {
//                    return
//                }
//                let realData = VTMBLEParser.parseRealTime(response)
//                let waveForm = realData.waveform
//                print(waveForm.wave_data)
//            }
//        default:
//            print("Wrong device signature")
//        }
//    }
//
//    @objc(util:commandFailed:deviceType:failedType:)
//    func util(_ util: VTMURATUtils, commandFailed cmdType: u_char, deviceType: VTMDeviceType, failedType type: VTMBLEPkgType) {
//        print("DEBUG: recieve call in \(#function)")
//    }
//
//}
//
//
//extension MainBLEController: VTMURATDeviceDelegate {
//
//
//
//}
