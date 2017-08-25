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

## arduino class
## Allows the usage of arduinos with GNU Octave.
## Upload StandardFirmata.ino to your board.
## For more information, view the README
## 
## Public Functions
## ----------------
## arduino(port,Board='Uno',Voltage=5)
## configurePin(obj,pin,mode)
## readDigitalPin(obj,pin)
## writeDigitalPin(obj,pin,val)
## * writePWMVoltage(obj,pin,volt)
## * writePWMDutyCycle(obj,pin,duty)
## readVoltage(obj,pin)
## display(obj)
## 
## * = not implemented yet

classdef arduino < handle % use the class as a handle
  properties(Access=private, Hidden=true) % unchanging properties
    BAUD = 57600;
    SERIAL_TIMEOUT = 10; % timeout for the serial class, tenths of a second
    TIMEOUT = 8; % timeout for the serial connection, seconds
    MAJOR_VERSION = 2;
    MINOR_VERSION = 5;
    VERSION = 2.5;
    FIRMWARE = "StandardFirmata.ino";
    ANALOG_MAX = 1023; % maximum analog value
    
    % Firmata Protocol
    ANALOG_MSG              = 0xE0;
    DIGITAL_MSG             = 0x90;
    REPORT_ANALOG           = 0xC0;
    REPORT_DIGITAL          = 0xD0;
    START_SYSEX             = 0xF0;
    SET_PIN_MODE            = 0xF4;
    SET_DIGITAL_PIN_VAL     = 0xF5;
    END_SYSEX               = 0xF7;
    PROTOCOL_VERSION        = 0xF9;
    SYSTEM_RESET            = 0xFF;
    
    EXTENDED_ID             = 0x00;
    ANALOG_MAPPING_QUERY    = 0x69;
    ANALOG_MAPPING_RESPONSE = 0x6A;
    CAPABILITY_QUERY        = 0x6B;
    CAPABILITY_RESPONSE     = 0x6C;
    PIN_STATE_QUERY         = 0x6D;
    PIN_STATE_RESPONSE      = 0x6E;
    EXTENDED_ANALOG         = 0x6F;
    STRING_DATA             = 0x71;
    REPORT_FIRMWARE         = 0x79;
    SAMPLING_INTERVAL       = 0x7A;
    SYSEX_NON_REALTIME      = 0x7E;
    SYSEX_REALTIME          = 0x7F;
    
  endproperties % read-only property
  properties(SetAccess=private)
    serial;
    Port;
    Board;
    Voltage;
    AvailablePins;
    analog_map; % a map of the analog pins to their digital counterparts
    digital_max; % the highest pin value
    pin_modes; % saves all pin modes
  endproperties
  methods
    function obj = arduino(Port,Board='Uno',Voltage)
      try
        pkg load instrument-control;
      catch
        error('Unable to load arduino functionality, is instrument-control installed?\n"pkg install -forge instrument-control"');
      end
      if nargin < 1 % if no port is specified, find an open one
        tmp = instrhwinfo("serial"); % find all serial devices
        if length(tmp) < 1
          error("no port specified and no serial device found");
        endif
        tmp = char(tmp(1)); % save the first device that appears
        if isunix() % if Linux/Mac
          tmp = strcat("/dev/",tmp); % put the beginning on
        endif
        Port = tmp;
      endif
      if ~ischar(Port)
        error("port must be specified as a string!");
      endif
      
      obj.serial = serial(Port,obj.BAUD,obj.SERIAL_TIMEOUT); % open connection
      
      % find protocol version
      strt = time();
      count = 0;
      while count==0
        srl_flush(obj.serial,1); % flush pending input
        [data,count]=srl_read(obj.serial,1); % try to read 
        if (time()-strt) > obj.TIMEOUT % if it took too long
          error("Could not connect to board, is Firmata uploaded?");
        endif
      endwhile
      if data ~= obj.PROTOCOL_VERSION
        error("Board misbehaving, is Firmata uploaded?");
      endif
      [data,count]=srl_read(obj.serial,2);
      if data(1) < obj.MAJOR_VERSION
        error("Firmata protocol needs to be %f or greater",obj.VERSION);
      elseif data(1) == obj.MAJOR_VERSION && data(2) < obj.MINOR_VERSION
        error("Firmata protocol needs to be %f or greater",obj.VERSION);
      endif
      
      % find the uploaded firmware name
      [data,count] = srl_read(obj.serial,80); % read the remaining string
      data = data(5:(end-1)); % remove the leading and trailing values
      
      % get the fluff out of the firmware string
      i = 1;
      firmware = [];
      for x = data
        if x > 0
          firmware(i) = x;
          i++;
        endif
      endfor
      firmware = char(firmware); % turn to a char
      if ~strcmp(firmware,obj.FIRMWARE) % see if the correct firmware is loaded
        error("the %s firmware must be loaded",obj.FIRMWARE);
      endif
      
      % find the analog pin map and the maximum digital pin
      analog_mapping_query(obj);
      
      % specify that all pins are output by default, save it
      for i = 1:obj.digital_max
        obj.pin_modes{i} = 'DigitalOutput';
      endfor
      
      % save the port, board name, and voltage
      obj.Port = Port;
      obj.Board = Board;
      if nargin>2 % if voltage is specified
        obj.Voltage = Voltage;
      elseif strcmp(Board,'ESP32') ...
          || strcmp(Board,'ESP8266') ...
          || strcmp(Board,'MKR1000')...
          || strcmp(Board,'Zero')
        obj.Voltage = 3.3;
      else
        obj.Voltage = 5;
      endif
      
      %obj.AvailablePins = sprintf("{ D0-D%i",obj.digital_max);
      
      % finally, the board is set up!
    endfunction
    function mode = configurePin(obj,pin,mode)
      pin = obj.pinNumber(pin); % get the pin number
      if nargin > 2 % if the mode is read in
        if ~strcmp(obj.pin_modes{pin},mode) % if it's a new mode
          m = 0;
          switch mode
            case 'AnalogInput'
              m = 2;
            case 'DigitalInput'
              m = 0;
            case 'DigitalOutput'
              m = 1;
            case 'I2C'
              m = 6;
            case 'Pullup'
              m = 11;
            case 'PWM'
              m = 3;
            case 'Servo'
              m = 4;
            case 'SPI'
              m = 10;
            case 'OneWire'
              m = 7;
            case 'Stepper'
              m = 8;
            case 'Encoder'
              m = 9;
            case 'Unset'
              m = 1;
            otherwise
              error('unknown pin mode');
          endswitch
          obj.pin_modes{pin} = mode;
          msg = [obj.SET_PIN_MODE,pin,m];
          n = srl_write(obj.serial,char(msg)); % write the actual message
        endif % only run if it was a new mode
      else % if the mode is not read in, return it
        mode = obj.pin_modes{pin};
      endif
    endfunction
    function [val,err] = readDigitalPin(obj,pin)
      old_mode = obj.configurePin(pin);
      %disp(old_mode);
      if (~strcmp(old_mode,'DigitalInput')) && (~strcmp(old_mode,'Pullup'))
        %disp('mode not valid, changing to DigitalInput');
        obj.configurePin(pin,'DigitalInput');
      endif
      p = obj.pinNumber(pin);
      port = floor(p / 7); % find the port
      bit = mod(p,7); % find the bit
      msg1 = char([bitor(obj.REPORT_DIGITAL,port),1]); % turn on reporting
      msg2 = char([bitor(obj.REPORT_DIGITAL,port),0]); % immediately turn it off
      srl_flush(obj.serial);
      srl_write(obj.serial,msg1);
      srl_write(obj.serial,msg2);
      %srl_flush(obj.serial); % send it all!
      
      data = 0;
      strt = time();
      while data ~= bitor(obj.DIGITAL_MSG,port)
        [data,count] = srl_read(obj.serial,1); % read in the info, while trying to get rid of more
        if (time()-strt) > obj.TIMEOUT
          disp('timed out');
          err = 1;
          return;
        endif
      endwhile
      %srl_flush(obj.serial);
      [data,count] = srl_read(obj.serial,2);
      port_map = bitor(data(1), bitshift(bitand(data(2),1),7)); % make a port map
      val = ~(0==bitand(port_map,bitshift(1,bit))); % return the value of that bit
      pause(0); % useful, trust me
    endfunction
    function writeDigitalPin(obj,pin,val)
      p = obj.pinNumber(pin);
      msg = [obj.SET_DIGITAL_PIN_VAL,p,~(val==0)];
      obj.configurePin(pin,'DigitalOutput');
      n = srl_write(obj.serial,char(msg));
      srl_flush(obj.serial,0); % flush output
    endfunction
    function writePWMVoltage(obj,pin,volt)
      error('not implemented yet');
    endfunction
    function writePWMDutyCycle(obj,pin,duty)
      error('not implemented yet');
    endfunction
    function [volt,value,err] = readVoltage(obj,pin)
      volt = 0;
      value = 0;
      err = 0;
      [p,a] = obj.pinNumber(pin); % get the pin number and the analog
      if a<0 % if the pin isn't analog
        error("readVoltage can only be used on analog pins ('A0','A6')");
      endif
      obj.configurePin(pin,'AnalogInput');
      msg1 = char([bitor(obj.REPORT_ANALOG,a), 1]);
      msg2 = char([bitor(obj.REPORT_ANALOG,a), 0]);
      srl_flush(obj.serial);
      srl_write(obj.serial,msg1);
      srl_write(obj.serial,msg2);
      
      data = 0;
      strt = time();
      while data~=bitor(obj.ANALOG_MSG,a)
        [data,count] = srl_read(obj.serial,1);
        if (time()-strt>obj.TIMEOUT)
          disp('timed out');
          err = 1;
          return
        endif
      endwhile
      [data,count] = srl_read(obj.serial,2);
      lsb = double(data(1));
      msb = bitshift(double(data(2)),7);
      value = bitor(lsb,msb);
      volt =  double(value*obj.Voltage) / double(obj.ANALOG_MAX);
      pause(0); % useful, trust me
    endfunction
    function display(obj)
      printf("   arduino with properties:\n\n");
      printf("                     Port: '");printf(obj.Port);printf("'\n");
      printf("                    Board: '");printf(obj.Board);printf("'\n");
      printf("            AvailablePins: ");printf(obj.AvailablePins);printf("\n");
      printf("                  Voltage: ");printf(num2str(obj.Voltage));printf("\n");
    endfunction
  endmethods
  methods(Access=private,Hidden=true)
    function [p,analog] = pinNumber(obj,pin)
      if ~ischar(pin)
        error("pin must be a string ('D3', 'A10')");
      endif
      if (pin(1)~='D') && (pin(1)~='A')
        error("pin must be labeled as digital or analog ('D2', 'A5')");
      endif
      
      if pin(1)=='A'
        p = obj.analog_map.(pin);
        analog = str2num(pin(2:end));
      else
        p = str2num(pin(2:end));
        analog = -1;
      endif
    endfunction
    function obj = analog_mapping_query(obj)
      msg = char([obj.START_SYSEX,obj.ANALOG_MAPPING_QUERY,obj.END_SYSEX]);
      srl_flush(obj.serial) % flush the serial line
      n = srl_write(obj.serial,msg); % send the query
      
      % get sysex response
      [cmd,msg] = obj.read_sysex();
      if cmd ~= obj.ANALOG_MAPPING_RESPONSE
        error("problem with reading analog map, try again");
      endif
      % disp(msg);
      % get max pin number
      obj.digital_max = length(msg)-1; % the highest pin available 
      %disp(obj.digital_max);
      
      % start saving the available pins in a string
      obj.AvailablePins = sprintf("{'D0-D%i', ",obj.digital_max);
      
      % parse analog map
      obj.analog_map = struct();
      analog_min = -1;
      analog_prev = -1;
      for i = 1:obj.digital_max+1
        if msg(i) ~= 127 % 127 means the pin doesn't support analog
          obj.analog_map.(sprintf("A%i",msg(i))) = i-1; % save the analog to digital conversion
          %obj.AvailablePins = [obj.AvailablePins, sprintf("A%i ",msg(i))];
          if analog_min < 0 % if it's the first time
            obj.AvailablePins = [obj.AvailablePins, sprintf("'A%i",msg(i))];
            analog_min = msg(i);
          elseif msg(i)-analog_prev > 1 % if it skipped
            obj.AvailablePins = [obj.AvailablePins, sprintf("-A%i', 'A%i",analog_prev,msg(i))];
            analog_min = msg(i);
          endif
          analog_prev = msg(i);
        endif
      endfor
      
      if analog_prev ~= analog_min
        obj.AvailablePins = [obj.AvailablePins,sprintf("-A%i",analog_prev)];
      endif
      obj.AvailablePins = [obj.AvailablePins,"'}"];
    endfunction
    function [cmd,msg] = read_sysex(obj,max_size=100)
      msg = []; % a buffer to hold the message
      data = 0;
      % check for sysex start message
      strt = time();
      while data ~= obj.START_SYSEX
        [data,count] = srl_read(obj.serial,1);
        if (time()-strt) > obj.TIMEOUT
          error("reading sysex timed out");
        endif
      endwhile
      [cmd,count] = srl_read(obj.serial,1); % read the command
      while true
        [data,count] = srl_read(obj.serial,1); % read each value
        if data==obj.END_SYSEX
          return % return the completed message
        endif
        msg = [msg data]; % append the new data to the whole message
      endwhile
    endfunction
  endmethods

end
