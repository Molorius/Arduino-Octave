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
## @deftypefn  {Loadable Function} {@var{voltage} = } readVoltage(@var{ard},@var{pin})
##
## Reads the analog voltage of a connected Arduino. If the pin's mode is not
## 'AnalogInput', it will be changed to that.
##
## @var{ard} - Arduino class.@*
## @var{pin} - Analog pin, such as 'A1'. It does not accept digital pins. 
##
## @end deftypefn

function volt = readVoltage(ard,pin)
  try
    volt = ard._readVoltage(pin);
  catch
    print_usage();
  end_try_catch
endfunction