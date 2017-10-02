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
## @deftypefn  {Loadable Function} writePWMDutyCycle(@var{ard},@var{pin},@var{duty})
##
## Writes a PWM duty cycle to the specified pin. Max=1, half=0.5.
##
## @var{ard} - Arduino class.@*
## @var{pin} - Desired pin.@*
## @var{duty} - Desired PWM duty.
##
## @end deftypefn

function writePWMDutyCycle(ard,pin,duty)
  try
    ard._writePWMDutyCycle(pin,duty);
  catch
    print_usage();
  end_try_catch
endfunction