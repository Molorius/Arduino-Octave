Arduino Octave
==============
A class to control an Arduino board using the Firmata protocol.

Note that any time a pin is specified, it must be of the form 'D#' or
'A#'. For example, to use digital pin 11 you must type 'D11'. 

The standard Firmata functionality must be uploaded to use this.
If you're unsure what needs to be there, just upload StandardFirmata
for serial and StandardFirmataWifi (with wifi credential set) for TCP/IP.

To install, download the latest release from the release page.
Start Octave, and move to the folder the file is saved in.
Type `pkg install arduino.tar.gz` into Octave's command window.
It requires instrument-control package to run from Forge. 
To install that, type `pkg install -forge instrument-control`.

version 1.1.0
To do: add I2C interface

Table of Contents
=================
* [Initialization](#initialization)
  * [arduino](#arduino)
* [General Commands](#general-commands)
  * [configurePin](#configurepinard-pin-mode)
  * [readDigitalPin](#readdigitalpinard-pin)
  * [writeDigitalPin](#writedigitalpinard-pin-val)
  * [readVoltage](#readvoltageard-pin)
  * [writePWMDutyCycle](#writepwmdutycycleard-pin-duty)
  * [writePWMVoltage](#writepwmvoltageard-pin-volt)
* [Version History](#version-history)

Initialization
==============

arduino()
-----------------------------
or:
#### arduino(port)
#### arduino('',board)
#### arduino(port,board)
#### arduino(ip_address)
#### arduino(ip_address,board)
#### arduino(ip_address,board,tcpipport)
#### arduino(ip_address,'',tcpipport)

Open connection with a microcontroller using the Firmata protocol over serial or TCP/IP (internet).

`port` - the serial port, string.
`board` - the name of the microcontroller, string.
`ip_address` - the ip address, string.
`tcpipport` - the tcp/ip port, int.

If `port` is left out or an empty string, this will attempt to use the first available serial port.
If `board` is left out or an empty string, this will try to guess the board using the pins.
If the mapping doesn't match any known board, it will default to 'Generic 5V'.
If `tcpipport` is left out, it will default to the Firmata default of 3030.

Note that the Firmata protocol does not specify the maximum voltage that boards read.
If the correct voltage is not found automatically, use 'Generic 5V', 'Generic 3.3V', or 'Generic 1.8V' for `board`.

Known `board` names: 'Uno', 'Nano', 'Teensy 2.0', 'Teensy 2.0 3.3V', 'MKR1000', 'ESP8266',
'Generic 5V', 'Generic 3.3V', 'Generic 1.8V'. If an unknown board is specified,
the voltage will default to 5V.

Returns the Arduino object.

General Commands
================

configurePin(ard, pin, mode)
----------------------------
If the `mode` is specified, this will set the desired `pin` to that mode. If not, it simply
returns the mode already on the pin. Note that this does not check that the
pin is compatible with that mode. 

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

readDigitalPin(ard, pin)
------------------------
Reads the value of a digital `pin`. This can also be used on analog pins.
It will automatically set the pin mode if it is not 'DigitalInput' or 'Pullup'.

Returns 1 if high, 0 if low.

writeDigitalPin(ard, pin, val)
------------------------------
Writes a value to a pin. This can also be used on analog pins. 
It will automatically set the pin mode if it is not 'DigitalOutput'.

readVoltage(ard, pin)
---------------------
Reads the voltage on an analog `pin`. It will automatically
set the pin mode if it is not 'AnalogInput'.

The output value will be scaled from 0-1023 to the estimated maximum voltage.
The estimated max voltage is found at the start, see [above](#arduino).

Returns the approximate voltage.

writePWMDutyCycle(ard, pin, duty)
---------------------------------
Sets a PWM duty cycle for the desired `pin`. Note that this does not
check if the pin is PWM compatible. If the pin's mode is not 'PWM', it will
change it to that. 

`duty` is a value between 0 and 1. For example, 0.25 turns on the pin for
25% of the time.

writePWMVoltage(ard, pin, volt)
-------------------------------
Sets a `pin` PWM duty cycle relative to the maximum voltage of the board. For example,
if the board has a 5V max, setting `volt` to 5 will set the duty cycle to max.

Trying to use a duty cycle higher than the board voltage will output the max duty.

Version History
===============

Version 1.1.0
-------------
Tested on Octave 4.0.3, Linux kernel 3.18, Firmata 2.5.7.

Added TCP/IP interface, tested with Espressif ESP8266 and Arduino MKR1000.

Added 'help' features (try typing `help arduino`) for every available function. 

Can now print information about the class object, such as the available pins,
reference voltage, and the name of the sketch running on the board.

Every function is now compatible with Matlab (sorry if this breaks anything).

New functions:
writePWMDutyCycle, writePWMVoltage

Version 1.0.0
-------------
Tested on Octave 4.0.2, Linux kernel 3.18, Firmata 2.5.1. 

First version. Tested with Arduino Uno, Arduino Nano, Teensy 2.0.

Added serial interface. Will scan for first open port if not specified.

Some optional parameters differ from Matlab's.

New functions:
arduino, configurePin, readDigitalPin, writeDigitalPin, readVoltage
