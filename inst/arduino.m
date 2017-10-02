## Copyright (C) 2017 Blake Felt <blake.w.felt@gmail.com>
## 
## This program is free software: you can redistribute it and/or modify
## it under the terms of the GNU General Public License as published by
## the Free Software Foundation, either version 3 of the License, or
## (at your option) any later version.
## 
## This program is distributed in the hope that it will be useful,
## but WITHOUT ANY WARRANTY; without even the implied warranty of
## MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
## GNU General Public License for more details.
## 
## You should have received a copy of the GNU General Public License
## along with this program.  If not, see <http://www.gnu.org/licenses/>.

## -*- texinfo -*-
## @deftypefn  {Loadable Function} {@var{ard} = } arduino()
## @deftypefnx {Loadable Function} {@var{ard} = } arduino(@var{port})
## @deftypefnx {Loadable Function} {@var{ard} = } arduino('',@var{board})
## @deftypefnx {Loadable Function} {@var{ard} = } arduino(@var{port},@var{board})
## @deftypefnx {Loadable Function} {@var{ard} = } arduino(@var{ip_address})
## @deftypefnx {Loadable Function} {@var{ard} = } arduino(@var{ip_address},@var{board})
## @deftypefnx {Loadable Function} {@var{ard} = } arduino(@var{ip_address},@var{board},@var{tcpipport})
## @deftypefnx {Loadable Function} {@var{ard} = } arduino(@var{ip_address},'',@var{tcpipport})
##
## Open connection with a microcontroller using the Firmata protocol over serial or TCP/IP (internet).
##
## @var{port} - the serial port, string.@*
## @var{board} - the name of the microcontroller, string.@*
## @var{ip_address} - the ip address, string.@*
## @var{tcpipport} - the tcp/ip port, int.@*
##
## If @var{port} is left out or an empty string, this will attempt to use the first available serial port @*
## If @var{board} is left out or an empty string, this will try to guess the board using the pins @*
## If the mapping doesn't match any known board, it will default to 'Generic 5V' @*
## If @var{tcpipport} is left out, it will default to the Firmata default of 3030 @*
##
## Note that the Firmata protocol does not specify the maximum voltage that boards read.@*
## If the correct voltage is not found automatically, use 'Generic 5V', 'Generic 3.3V', or 'Generic 1.8V' for @var{board}.
##
## Known @var{board} names: 'Uno', 'Nano', 'Teensy 2.0', 'Teensy 2.0 3.3V', 'MKR1000', 'ESP8266',
## 'Generic 5V', 'Generic 3.3V', 'Generic 1.8V'. If an unknown board is specified,
## the voltage will default to 5V.
##
## Available functions: configurePin, readVoltage, readDigitalPin, writeDigitalPin,
## writePWMDutyCycle, writePWMVoltage
##
## @end deftypefn

function ard = arduino(varargin)
  try
    ard = arduino(varargin{:});
  catch
    print_usage();
  end_try_catch
endfunction