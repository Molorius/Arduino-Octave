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
## @deftypefn  {Loadable Function} {@var{val} = } readVoltage(@var{ard},@var{pin})
##
## Read a digital pin. If the pin's mode is not 'DigitalInput' or 'Pullup',
## it will be changed to 'DigitalInput'.
##
## @var{val} - return value, 1 or 0 @*
## @var{ard} - Arduino class @*
## @var{pin} - Pin, such as 'A1' or 'D13'
##
## @end deftypefn

function val = readDigitalPin(ard,pin)
  try
   val = ard._readDigitalPin(pin);
  catch
    print_usage();
  end_try_catch
endfunction