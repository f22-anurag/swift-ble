//
//  PeripheralConnectedViewController.swift
//  BLEScanner
//
//  Created by Harry Goodwin on 18/07/2016.
//  Copyright © 2016 GG. All rights reserved.
//
import UIKit
import CoreBluetooth

class PeripheralConnectedViewController: UIViewController {
    @IBOutlet private weak var tableView: UITableView!
    @IBOutlet private weak var rssiLabel: UILabel!
    
    var peripheral: CBPeripheral!
    var centralManager: CBCentralManager!
    var sentData:Bool = false
    
    private var rssiReloadTimer: Timer?
    private var services: [CBService] = []
    let stringToSend = "9999"
    var writeWOResponse:CBCharacteristic!
    var writeWithResponse:CBCharacteristic!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        peripheral.delegate = self
        title = peripheral.name
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 80.0
        tableView.contentInset.top = 5
        
        rssiReloadTimer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(refreshRSSI), userInfo: nil, repeats: true)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        rssiReloadTimer?.invalidate()
        centralManager.cancelPeripheralConnection(peripheral)
    }
    
    func setup(with centralManager: CBCentralManager, peripheral: CBPeripheral) {
        self.centralManager = centralManager
        self.peripheral = peripheral
        self.peripheral.delegate = self // Set the delegate here
    }
    
    @objc private func refreshRSSI() {
        peripheral.readRSSI()
    }
}

extension PeripheralConnectedViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return services.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ServiceCell", for: indexPath) as! ServiceTableViewCell
        cell.serviceNameLabel.text = "\(services[indexPath.row].uuid)"
//        print(services[indexPath.row])
//        print(services[indexPath.row].characteristics)
        print(services)
        print("character")
        if let characteristics = services[indexPath.row].characteristics {
            // Access the characteristics array here
            for characteristic in characteristics {
                print(characteristic)
                // Do something with each characteristic
            }}
        // Call function to set MTU value to 23
//        setMTUValue(to: 23)
        
        return cell
    }
    
//    func setMTUValue(to mtu: Int) {
//        peripheral.requestMtu(mtu)
//        print("MTU Value set to: \(mtu)")
//    }
}


extension PeripheralConnectedViewController: CBPeripheralDelegate {
    func centralManager(_ central: CBCentralManager, didFailToConnectPeripheral peripheral: CBPeripheral, error: Error?) {
        if let error = error {
            print("Error connecting peripheral: \(error.localizedDescription)")
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: (any Error)?) {
        print("\ndidUpdateValueFor\nCharacteristic UUID: \(characteristic.uuid)")
        
    }
    
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: (any Error)?) {
        print("\ndidWriteValueFor\nCharacteristic UUID: \(characteristic.uuid)")
        print(error);
        print(characteristic.value)
        
    }
    
    func peripheralIsReady(toSendWriteWithoutResponse peripheral: CBPeripheral) {
        if let dataToSend = stringToSend.data(using: .utf8) {
            print("Device ready to allow writes data")
            print("Can send write without response?:",peripheral.canSendWriteWithoutResponse)
            if(peripheral.canSendWriteWithoutResponse && !sentData){
                peripheral.writeValue(dataToSend, for: writeWOResponse, type: .withoutResponse)
//                peripheral.writeValue(dataToSend, for: writeWithResponse, type: .withResponse)
                sentData = true
                print("\ninside the write if.")
            }
//            print("Can send write without response?:",peripheral.canSendWriteWithoutResponse)
        }
    }
    
    
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: (any Error)?) {
        print("\ndidUpdateNotificationStateFor\nCharacteristic UUID: \(characteristic.uuid)")
        print("isNotifying: \(characteristic.isNotifying)")
//        print("isNotifying: \(characteristic)")
        print("characteristic.uuid == CBUUID(string: C306) && characteristic.isNotifying",characteristic.uuid == CBUUID(string: "C306"), characteristic.isNotifying)
        if(characteristic.uuid == CBUUID(string: "C306") && characteristic.isNotifying) {

            if let dataToSend = stringToSend.data(using: .utf8) {
                // Assuming characteristic is the target characteristic
//                peripheral.writeValue(dataToSend, for: writeWOResponse, type: .withoutResponse)
//                peripheral.writeValue(dataToSend, for: writeWOResponse.descriptors![0])
                print("Can send write without response?:",peripheral.canSendWriteWithoutResponse)
//                peripheral.writeValue(dataToSend, for: writeWithResponse, type: .withResponse)
//                peripheralIsReady?(toSendWriteWithoutResponse: peripheral)
            }

            
        }
        
        
        
    }
    
    

    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if let error = error {
            print("Error discovering services: \(error.localizedDescription)")
            return
        }
        
        guard let discoveredServices = peripheral.services else {
            print("No services discovered")
            return
        }
        
        print("Discovered services:")
           for service in discoveredServices {
               print("- Service UUID: \(service.uuid)")
           }
        
        // Clear existing services
        services.removeAll()
        
        // Add discovered services to the array
        services.append(contentsOf: discoveredServices)
        
        // Reload table view data
        tableView?.reloadData()
        for service in discoveredServices {
                peripheral.discoverCharacteristics(nil, for: service)
            }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if let error = error {
            print("Error discovering service characteristics: \(error.localizedDescription)")
        }
        
        guard let characteristics = service.characteristics else {
            print("No characteristics discovered for the service: \(service.uuid)")
            return
        }
        
       
        
        print("Characteristics discovered for service: \(service.uuid)")
        for characteristic in characteristics {
            if characteristic.uuid == CBUUID(string: "C303") || characteristic.uuid == CBUUID(string: "C306") {
                        // Convert the received data to a string
                        if let value = characteristic.value,
                           let responseString = String(data: value, encoding: .utf8) {
                            print("Received response: \(responseString)")
                        }
                    }
        }
        for characteristic in characteristics {
            if characteristic.uuid == CBUUID(string: "C303") {
                writeWOResponse = characteristic
            }
            if characteristic.uuid == CBUUID(string: "C304") {
                writeWithResponse = characteristic
            }
                print("\nCharacteristic UUID: \(characteristic.uuid)")
                print("isNotifying: \(characteristic.isNotifying)")
                
                
                // Check characteristic properties
                print("Properties: \(characteristic.properties)")
                
                
                // Check if the characteristic supports indicate operation
                if characteristic.properties.contains(.indicate) {
                    print("Characteristic supports indicate operation")
                    // You can enable indications here
                    peripheral.setNotifyValue(true, for: characteristic)
                }
//                if characteristic.properties.contains(.notify) {
//                    print("Characteristic supports notify operation")
//                    // You can enable indications here
//                    peripheral.setNotifyValue(true, for: characteristic)
//                }
                print(characteristic.descriptors, characteristic)
                // Print descriptors if available
            
                if let descriptors = characteristic.descriptors {
                    print("Descriptors: \(descriptors)")
                } else {
                    print("No descriptors found")
                }
//            }
        }
        
//        let mtuValue = peripheral.maximumWriteValueLength(for: .withoutResponse)
//        print("MTU Value: \(mtuValue)")

//        for characteristic in characteristics {
//            if characteristic.uuid == CBUUID(string: "C303") ||  characteristic.uuid == CBUUID(string: "C304") {
//                print("Characteristic UUID: \(characteristic.uuid)")
//                
//                // Check characteristic properties
//                print("Properties: \(characteristic.properties)")
//                
//                // Check if the characteristic supports write operation
//                if characteristic.properties.contains(.writeWithoutResponse) {
//                    print("Characteristic supports write without response operation")
//                    if let dataToSend = stringToSend.data(using: .utf8) {
//                        // Assuming characteristic is the target characteristic
//                        peripheral.writeValue(dataToSend, for: characteristic, type: .withoutResponse)
//                    }
//                    // You can perform write operation here
//                }
//              
//            
//            if characteristic.properties.contains(.write) {
//                print("Characteristic supports write operation")
//                if let dataToSend = stringToSend.data(using: .utf8) {
//                    // Assuming characteristic is the target characteristic
//                    peripheral.writeValue(dataToSend, for: characteristic, type: .withResponse)
//                }
//                // You can perform write operation here
//            }
//            
//          
//                
//                // Check if the characteristic supports indicate operation
//               
//                // Print descriptors if available
//                if let descriptors = characteristic.descriptors {
//                    print("Descriptors: \(descriptors)")
//                } else {
//                    print("No descriptors found")
//                }
//            }
//        }

    }
    
    func peripheral(_ peripheral: CBPeripheral, didReadRSSI RSSI: NSNumber, error: Error?) {
        switch RSSI.intValue {
        case -90 ... -60:
            rssiLabel.textColor = .orange
        case -200 ... -90:
            rssiLabel.textColor = .red
        default:
            rssiLabel.textColor = .green
        }
        
        rssiLabel.text = "\(RSSI)dB"
    }
}
