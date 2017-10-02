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
## @deftypefn  {Loadable Function} writeDigitalPin(@var{ard},@var{pin},@var{val})
##
## Write a digital value to a pin. If the pin's mode is not 'DigitalOutput',
## it will be changed to that.
##
## @var{ard} - Arduino class.@*
## @var{pin} - Pin, such as 'A1' or 'D13'.@*
## @var{val} - Value. 1 or 0. 
##
## @end deftypefn

function writeDigitalPin(ard,pin,val)
  try
   ard._writeDigitalPin(pin,val);
  catch
    print_usage();
  end_try_catch
endfunction