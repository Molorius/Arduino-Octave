Arduino Octave
==============
A class to control an Arduino board using the Firmata protocol.
I kept most functions identical to Matlab's version for compatibility.

The StandardFirmata.ino firmware needs to be loaded to your development board. 
Serial communication is the only form possible right now.

To install, download the latest release from the release page.
Start Octave, and move to the folder it the file is saved in.
Type `pkg install arduino.tar.gz`
It requires instrument-control package to run from Forge. 
To install that, type `pkg install -forge instrument-control`

Additional features will be added later.
version 1.0.0

Table of Contents
=================
* [Initialization](#initialization)
  * [arduino](#arduinoport-board-voltage "arduino(Port, Board, Voltage)")
* [General Commands](#general-commands)
  * [configurePin](#configurepinobj-pin-mode "configurePin(obj, pin, mode)")
  * [readDigitalPin](#readdigitalpinobj-pin "readDigitalPin(obj, pin)")
  * [writeDigitalPin](#writedigitalpinobj-pin-val "writeDigitalPin(obj, pin, val)")
  * [readVoltage](#readvoltageobj-pin "readVoltage(obj, pin)")

Initialization
==============

arduino(Port, Board, Voltage)
-----------------------------
Starts the class. All parameters are optional, the serial port should be automatically found
(only tested on Linux). Board is to keep compatibility with Matlab and to help determine the
maximum voltage. Voltage is a way to manually set the maximum voltage (5V on Uno, 3.3 on ESP32, etc).
Note that Voltage is not compatible with Matlab. 

Returns the arduino object (used for every other function).

If this is run without a parenthese (;) at the end, it will display the 
serial port, board name (defaults to 'Uno'), all available digital and analog pins, 
and the max voltage value being used with voltage functions.

General Commands
================

configurePin(obj, pin, mode)
----------------------------
If the `mode` is specified, this will set the desired pin to that mode. If not, it simply
returns the mode already on the pin. 

|      `Mode`      |
|------------------|
| 'AnalogInput'    |
|'DigitalInput'    |
|'DigitalOutput'   |
|    'I2C'         |
|    'PWM'         |
|   'Servo'        |
|    'SPI'         |
|  'OneWire'       |
|  'Stepper'       |
|  'Encoder'       |
|   'Unset'        |

readDigitalPin(obj, pin)
------------------------
Reads the value of a digital pin. This can also be used on analog pins.
It will automatically set the pin mode if it is not 'DigitalInput' or 'Pullup'.

Returns `[val,err]` where val is 1 or 0, err is 1 if an error occured during the process. 
Note that err is not compatible with Matlab. 

writeDigitalPin(obj, pin, val)
------------------------------
Writes a value to a pin. This can also be used on analog pins. 
It will automatically set the pin mode if it is not 'DigitalOutput'.


readVoltage(obj, pin)
---------------------
Reads the voltage on an analog pin. It will automatically
set the pin mode if it is not 'AnalogInput'.

The output value will be scaled from 0-1023 to 0-5V. Note that this is an
approximation, and the actual maximum voltage will not be 5V without a good
power supply.

Returns `[volt,value,err]` where volt is the approximate voltage, value is the 
raw value (0-1023), and err is 1 if an error occured during the process.
Note that only volt is compatible with Matlab. 
