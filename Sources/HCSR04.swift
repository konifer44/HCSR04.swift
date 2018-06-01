import SwiftyGPIO
import Foundation
import Dispatch

public class HCSR04 {
    private let currentlyUsedRaspberryGpios: [GPIOName : GPIO]
    public var echoConnectedPin: GPIO
    public var triggerConnectedPin: GPIO
    public  var maximumSensorRange: Double
    public enum ErrorList: Error {
        case echoSignalError //Echo signal error for example disconnected echo, trigger pin or too fast measurments.
        case measuredDistanceIsOutSensorRange //Measured echo signal is out of sensor range.
        case userTimeout //User timeout interrupt.
    }
    
    public init(usedRaspberry: SupportedBoard, echoConnectedPin: GPIOName, triggerConnectedPin: GPIOName, maximumSensorRange: Double) {
        self.currentlyUsedRaspberryGpios = SwiftyGPIO.GPIOs(for: usedRaspberry) // Setting gpios for used Raspberry.
        self.echoConnectedPin = currentlyUsedRaspberryGpios[echoConnectedPin]! //Setting the gpio which the echo pin is conntected to.
        self.echoConnectedPin.direction = .IN //Setting echo gpio pin direction, always .IN.
        self.triggerConnectedPin = currentlyUsedRaspberryGpios[triggerConnectedPin]! //Setting the gpio which the trigger pin is conntected to.
        self.triggerConnectedPin.direction = .OUT //Setting trigger gpio pin direction, always .OUT.
        self.maximumSensorRange = maximumSensorRange //Setting maximum ultrasonic sensor rage in cm.
    }
    
    public func measureDistance(numberOfSamples: Int? = nil,providedTimeout: Int? = nil) throws -> Double {
        var beginningTimeOfEchoSignal: DispatchTime //The beginning of echo signal.
        var endTimeOfEchoSignal: DispatchTime //The end of echo signal.
        var echoSignalTime = Double.init() //Calculated echo signal time.
        var distance = Double.init() //Calculated distance.
        var enterTimeIntoWhile: DispatchTime //Used for timeout and error detection.
        let maximumEchoSignalTime = (maximumSensorRange/0.0000343) * 2 //Time of maximum echo signal for provided sensor range - used for error detection and default timeout.
        let defaultTimeout = maximumEchoSignalTime * 2  //Calculate timeout = (maximumEchoSignalTime)*(safety margin).
        let usedTimeout: Double //Finally used timeout - default or provided by user.
        
        if (providedTimeout == nil) {
            usedTimeout = defaultTimeout
        } else {
            usedTimeout = Double(providedTimeout! * 1000000) //convert miliseconds to nanoseconds, user provide timeout in miliseconds.
        }
        
        for _ in 0..<(numberOfSamples ?? 1) { //Default number of samples is 1, user can provide another number of samples by optional argument while calling method measureDistance
            
            //Start distance measure.
            generateTriggerImpulse() //Generate trigger impuls 10 microseconds long.
            
            enterTimeIntoWhile = DispatchTime.now() //Save enter time into while loop for error detection.
            while (echoConnectedPin.value == 0) {
                if (calculateTimeInterval(from: enterTimeIntoWhile, to: DispatchTime.now()) > usedTimeout){
                    throw ErrorList.echoSignalError //Throw error
                }
            }
            beginningTimeOfEchoSignal = DispatchTime.now() //Save time of  beginning echo signal.
            
            enterTimeIntoWhile = DispatchTime.now() //Save enter time into while loop for error detection.
            while (echoConnectedPin.value == 1){ //Wait for end of echo signal.
                let timeInLoop = calculateTimeInterval(from: enterTimeIntoWhile, to: DispatchTime.now())
                if timeInLoop >= maximumEchoSignalTime {
                    throw ErrorList.measuredDistanceIsOutSensorRange //Throw error.
                } else if (providedTimeout != nil) && (timeInLoop > usedTimeout) {
                    throw ErrorList.userTimeout //Throw error - user timeout interrupt.
                }
            }
            endTimeOfEchoSignal = DispatchTime.now() //Save time of the end echo signal.
            
            echoSignalTime = calculateTimeInterval(from: beginningTimeOfEchoSignal, to: endTimeOfEchoSignal) //Calculate time of echo signal.
            distance = distance + (echoSignalTime * 0.0000343)/2 //Calculate distance: ((echo signal time in nanosecodns)*(speed of the sound cm per nanoseconds))/(distance divided by 2, echo signal round trip)).
            if numberOfSamples != nil {
                usleep(60000) //Wait 60ms before next sample measurement.
            }
        }
        distance = distance/Double(numberOfSamples ?? 1) //Calculate average distance.
        
        if distance <= maximumSensorRange {
            return distance
        } else {
            throw ErrorList.measuredDistanceIsOutSensorRange
        }
    }
    
    private func generateTriggerImpulse() {
        triggerConnectedPin.value = 1 //Set trigger pin High level.
        usleep(10)//Wait 10 microsecodns.
        triggerConnectedPin.value = 0 //Set trigger pin Low level.
    }
    private func calculateTimeInterval(from startTime: DispatchTime, to endTime: DispatchTime) -> Double {
        return Double(endTime.uptimeNanoseconds - startTime.uptimeNanoseconds)
    }
}

