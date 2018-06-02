# A Swift library for the HC-SR04 (US-015 and similar) ultrasonic ranging sensors.

<p align="center">
<a href="https://raw.githubusercontent.com/uraimo/SwiftyGPIO/master/LICENSE"><img src="http://img.shields.io/badge/License-MIT-blue.svg?style=flat"/></a>
<a href="#"><img src="https://img.shields.io/badge/OS-linux-green.svg?style=flat"/></a> 
<a href="https://developer.apple.com/swift"><img src="https://img.shields.io/badge/Swift-3.x-orange.svg?style=flat"/></a> 
<a href="https://github.com/apple/swift-package-manager"><img src="https://img.shields.io/badge/Swift%20Package%20Manager-compatible-brightgreen.svg"/></a>
</p>

The project is based on [SwiftyGPIO](https://github.com/uraimo/SwiftyGPIO)



<p align="center">
<a href="https://github.com/konifer44/HCSR04.swift/raw/master/Images/HC-SR04.jpg"  target="_blank">
<img src="https://github.com/konifer44/HCSR04.swift/raw/master/Images/HC-SR04.jpg" height=400 width=400></a>
</p>


## Summary 

This is library for HC-SR04 (US-015 and similar) ultrasonic ranging sensor which provide 3cm up to 500cm(depends on the used sensor) of non-contact measurement functionality with a ranging accuracy that can reach up to 3mm. Library allows to make a single or multiple sample measurment, detect timeout, hardware and measurment errors.

## Supported Boards
Every board supported by [SwiftyGPIO](https://github.com/uraimo/SwiftyGPIO)

##

## Hardware details
The HC-SR04 (US-015 and similar) ultrasonic range sensor is very simple to use, **however the signal it outputs needs to be converted from 5V to 3.3V so as not to damage your Raspberry Pi!**

There are only  four pins that you need to connect:
<ul>
<li>VCC (Power) - 5v</li>
<li> Trig (Trigger) - 3,3v signal from Raspberry is enough to trigger impulse</li>
<li>Echo (Receive) - signal need to be converted from 5V to 3.3V via voltage divder or logic level converter !!!</li>
<li>GND (Ground)</li>
</ul>


[Voltage divider](https://learn.sparkfun.com/tutorials/voltage-dividers/all?print=1) - look for *Level Shifting section*. </br>
[Logic level converter](https://www.sparkfun.com/products/12009) - simple to use and cheap level converter.

For more details read datasheet of your sensor.

## Wiring
<p align="center">

<table style="width:100%">
  <tr>
    <th><a href="https://github.com/konifer44/HCSR04.swift/raw/master/Images/Schematic.jpg"  target="_blank">
    <img src="https://github.com/konifer44/HCSR04.swift/raw/master/Images/Schematic.jpg" height=300 width=390></a></th>
     <th><a href="https://github.com/konifer44/HCSR04.swift/raw/master/Images/Breadboard.jpg"  target="_blank">
    <img src="https://github.com/konifer44/HCSR04.swift/raw/master/Images/Breadboard.jpg" height=300 width=300></a></th>
  </tr>
  </table>

</p>

## Instalation

Add the following dependency to your Package.swift

     .Package(url: "https://github.com/konifer44/HCSR04.swift.git", majorVersion: 1)

## Usage
First you need to import necessary libraries.
```
import HCSR04
import SwiftyGPIO
```
Next step is initialization. Sensor is initialized by creating instance of class HCSR04 and providing: 
<ul>
<li>Used Raspberry name.</li>
<li>GPIO which the ECHO pin is conntected to.</li>
<li>GPIO which the TRIGGER pin is conntected to.</li>
<li>Maximum range of your sensor in cm - check datasheet typically is 400cm.</li>
</ul>


``` 
var sensor = HCSR04.init(usedRaspberry: .RaspberryPiPlusZero, echoConnectedPin: .P21, triggerConnectedPin: .P20, maximumSensorRange: 400)
```
### Single sample  distnace measurment:
You can start **single sample measurment** by calling method with no arguments ``` measureDistance()```  Because the ``` measureDistance()``` method propagates any errors it throws, any code that calls this method must either handle the errors—using a do-catch statement, try?, or try!. In single sample measurment method
``` measureDistance()``` takes sample immediately after calling it. If You want make next measurment You need to remember that producer of ultrasonic sensor suggest to use over 60ms measurement cycle, in order to prevent trigger signal to the echo signal, so You need to wait 60ms before You call single measurment again.</br> </br>
More about: [Swift Error Handling](https://developer.apple.com/library/content/documentation/Swift/Conceptual/Swift_Programming_Language/ErrorHandling.html)

```
do {
  let distance = try sensor.measureDistance()
  print(distance)
} catch {
  print("Unexpected error: \(error)")   
}
```
### Multiple samples  distnace measurment:
You can start **multiple sample measurment** which return average distance by calling method with optional argument ``` measureDistance(numberOfSamples: Int? = nil)``` </br>Depending on producer suggest to use over 60ms measurement cycle ``` measureDistance(numberOfSamples: Int? = nil)``` method takes first sample immediately after calling it but **every next sample is taken after 60ms.** </br>In below example as You expected time of 5 sample measurment will take around 240ms and return average distance.
```
do {
  let distance = try sensor.measureDistance(numberOfSamples: 5)
  print(distance)
} catch {
  print("Error: \(error)")   
}
```

### User provided timeout and errors:

In normal measurment, method ``` measureDistance()``` using default timeout value to throw errors in three cases
<ul>
<li>echoSignalError //Disconnected echo, trigger pin or too fast measurments.</li>
<li>measuredDistanceIsOutSensorRange //Measured distance is out of sensor range.</li>
<li>userTimeout //User timeout interrupt.</li>
</ul>


Default value of timeout depends on your maximum sensor range, it's twice longer than maximum echo signal because it should't interrupt distnace measuremnt. If You provide 400cm maximum sensor range the default timeout value will be around 45ms and after this time You can expect throwing an error. If You need change timeout value for some reasons You can provide it by calling method with optional argument ``` measureDistance(providedTimeout: Int? = nil)``` </br>For example 40ms provided timeout:

```
do {
  let distance = try sensor.measureDistance(providedTimeout: 40)
  print(distance)
} catch {
  print("Error: \(error)")   
}
```
Remember that if You provide timeout shorter than maximum echo signal it will interrupt measurment and throw error.

If You need handle error separately, You can access enum ```ErrorList``` insde of class ```HCSR04```
```
do {
  let distance = try sensor.measureDistance()
  print(distance)
} catch HCSR04.ErrorList.echoSignalError {
  //user error handling procedure
}catch HCSR04.ErrorList.measuredDistanceIsOutSensorRange {
  //user error handling procedure
}catch HCSR04.ErrorList.userTimeout {
  //user error handling procedure
}

```

More about: [Swift Error Handling](https://developer.apple.com/library/content/documentation/Swift/Conceptual/Swift_Programming_Language/ErrorHandling.html)
