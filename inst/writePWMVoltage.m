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
## @deftypefn  {Loadable Function} writePWMVoltage(@var{ard},@var{pin},@var{volt})
##
## Writes a PWM voltage to a specified pin. This does not verify that the pin
## is capable of PWM. If the pin's mode is not 'PWM', it is changed to that.
## The voltage is based on the maximum that the board is capable of.
##
## @var{ard} - Arduino class.@*
## @var{pin} - Desired pin.@*
## @var{volt} - Desired PWM voltage. Max is the board's voltage.
##
## @end deftypefn

function writePWMVoltage(ard,pin,volt)
  try
    ard._writePWMVoltage(pin,volt);
  catch
    print_usage();
  end_try_catch
endfunction