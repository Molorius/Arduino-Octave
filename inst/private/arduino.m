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

% this is a private function, so there can be the fancy
% help functions for each of the desired functions

classdef arduino < handle % use the class as a handle
  properties (Access=private, Hidden=true) % unchanging properties
    BAUD = 57600; % serial baud
    SERIAL_TIMEOUT = 10; % timeout for the serial class, tenths of a second
    TCP_TIMEOUT = 100; % timeout for the tcp class, tenths of a second
    TIMEOUT = 8; % timeout for receiving data, such as after a reboot, seconds
    MAJOR_VERSION = 2;
    MINOR_VERSION = 5;
    VERSION = 2.5;
    %ANALOG_MAX = 1023; % maximum analog value
    
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
    
    % pin mappings of various boards
    %                AvailablePins,     Board, Voltage
    BOARD_MAPS = {"{'D0-D19', 'A0-A5'}","Uno",5;... % Arduino Uno
                  "{'D0-D21', 'A0-A7'}","Nano",5;... % Arduino Nano
                  "{'D0-D24', 'A0-A11'}","Teensy 2.0",5;... % Teensy 2.0
                  "{'D0-D24', 'A0-A11'}","Teensy 2.0 3.3V",3.3;... % Teensy 2.0 w/ 3.3V regulator
                  "{'D0-D21', 'A0-A6'}","MKR1000",3.3;... % Arduino MKR1000
                  "{'D0-D17', 'A0'}","ESP8266",3.3;... % ESP8266, tested with NodeMCU
                  "{}","Generic 5V",5;... % generic, a 5V board
                  "{}","Generic 3.3V",3.3;... % generic, a 3.3V board
                  "{}","Generic 1.8V",1.8;... % generic, a 1.8V board
                  };
  endproperties % read-only property
  properties (SetAccess=private)
    connection_type; % 'serial' or 'tcp'
    connection; % the connection object, either 
    DeviceAddress; % IP Address
    Port; % serial or tcp port
    Board;
    AvailablePins;
    
    % holds the read and write functions
    ard_read;
    ard_write;
    
    analog_map; % a map of the analog pins to their digital counterparts
    digital_max; % the highest pin value
    pin_modes; % saves all pin modes
    firmware;
    FirmataVersion;
  endproperties
  properties (SetAccess=private)
    Voltage;
    ANALOG_MAX = 1023; % maximum analog value
  endproperties
  methods
    function obj = arduino(address,Board,port)
      try % load the necessary packages
        pkg unload instrument-control; % helps suppress warnings
        pkg load instrument-control;
      catch
        disp('Unable to load arduino functionality, is instrument-control installed?\n"pkg install -forge instrument-control"\n');
        error();
      end
      
      if (nargin<1) || (length(address)==0) % if no port/address is specified or it's: ''
        tmp = instrhwinfo("serial"); % find all serial devices
        if length(tmp) < 1
          disp("No port specified and no serial device found\n");
          error();
        endif
        tmp = char(tmp(1)); % save the first device that appears
        if isunix() % if Unix based (Linux, Mac, etc.)
          tmp = strcat("/dev/",tmp); % put the beginning on
        endif
        obj.Port = tmp;
        address = tmp;
        obj.connection_type = 'serial';
      endif
      if ~ischar(address) % if the address is not a string
        disp("port/address must be specified as a string!\n");
        error();
      endif
      
      if (nargin>0) % if a port/address is specified 
        [val,obj.DeviceAddress,tmp_port] = obj.ifIP(address); % check if the address is an IP
        if val
          obj.connection_type = 'tcp';
          %obj.Port = sprintf("%i",tmp_port);
          obj.Port = tmp_port;
        else
          obj.connection_type = 'serial';
          obj.Port = address;
        endif
      endif
      
      % Finally, done determining input parameter!
      % Setup connections, save read/write functions
      if strcmp(obj.connection_type,'tcp')
        obj.connection = tcp(obj.DeviceAddress, obj.Port, obj.TCP_TIMEOUT);
        obj.ard_read = @tcp_read;
        obj.ard_write = @tcp_write;
      elseif strcmp(obj.connection_type,'serial');
        obj.connection = serial(obj.Port,obj.BAUD,obj.SERIAL_TIMEOUT);
        srl_flush(obj.connection);
        obj.ard_read = @srl_read;
        obj.ard_write = @srl_write;
      else
        disp("invalid connection type\n");
        error();
      endif
      pause(0.1);
      
      % reset pins, request firmware name and version, for boards that don't reset (teensy, leonardo, etc.)
      obj.ard_write(obj.connection,char([obj.SYSTEM_RESET]));
      obj.ard_write(obj.connection,char([obj.PROTOCOL_VERSION]));
      msg = char([obj.START_SYSEX,obj.REPORT_FIRMWARE,obj.END_SYSEX]);
      obj.ard_write(obj.connection,msg);
      % pause(0.1); % wait before flushing
      % srl_flush(obj.connection,0);
      
      % find protocol version
      strt = time();
      count = 0;
      while count==0
        [data,count]=obj.ard_read(obj.connection,1); % try to read
        if (time()-strt) > obj.TIMEOUT % if it took too long
          disp("Could not connect to board, is Firmata uploaded?\n");
          error();
        endif
      endwhile
      if data ~= obj.PROTOCOL_VERSION
        disp("Board misbehaving, is Firmata uploaded?\n");
        error();
      endif
      [data,count]=obj.ard_read(obj.connection,2);
      if data(1) < obj.MAJOR_VERSION
        disp("Firmata protocol needs to be %f or greater\n",obj.VERSION);
        error();
      elseif data(1) == obj.MAJOR_VERSION && data(2) < obj.MINOR_VERSION
        disp("Firmata protocol needs to be %f or greater\n",obj.VERSION);
        error();
      endif
      obj.FirmataVersion = sprintf("%i.%i",data(1),data(2));
      
      
      % find the uploaded firmware name
      [data,count] = obj.ard_read(obj.connection,80); % read the remaining string
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
      obj.firmware = firmware;
      
      % find the analog pin map and the maximum digital pin
      analog_mapping_query(obj);
      
      % specify that all pins are output by default, save it
      for i = 1:obj.digital_max
        obj.pin_modes{i} = 'DigitalOutput';
      endfor
      
      % save the port, board name, and voltage
      
      
      found_board = 0;
      % check for board, if not specified, based on pin maps
      if nargin<2 % if no board was specified
        for i = 1:size(obj.BOARD_MAPS)(1) % check every mapping
          if strcmp(obj.AvailablePins,obj.BOARD_MAPS{i,1}) % if the board map matches
            obj.Board  = obj.BOARD_MAPS{i,2}; % save it
            found_board = 1;
            break; % exit after the first available mapping
          endif
        endfor
        if ~found_board % if no board was found
          obj.Board = 'Generic 5V'; % default to Unknown
        endif
      else
        obj.Board = Board;
      endif
      
      
      found_voltage = 0; % flag to check if a voltage was found
      if nargin<3 % if no voltage was specified
        for i = 1:size(obj.BOARD_MAPS)(1) % check every mapping again
          if strcmp(obj.Board,obj.BOARD_MAPS{i,2}) % if the board name matches
            obj.Voltage = obj.BOARD_MAPS{i,3}; % save it
            found_voltage = 1;
            break;
          endif
        endfor
        if ~found_voltage
          obj.Voltage = 5; % default to 5V logic
        endif
      else
        obj.Voltage = Voltage;
      endif
      
      % finally, the board is set up!
    endfunction
    function mode = _configurePin(obj,pin,mode)
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
              disp('unknown pin mode\n');
              error();
          endswitch
          obj.pin_modes{pin} = mode;
          msg = [obj.SET_PIN_MODE,pin,m];
          n = obj.ard_write(obj.connection,char(msg)); % write the actual message
        endif % only run if it was a new mode
      else % if the mode is not read in, return it
        % analog_mapping_query(obj);
        mode = obj.pin_modes{pin};
      endif
    endfunction
    function [val,err] = _readDigitalPin(obj,pin)
      old_mode = obj._configurePin(pin);
      if (~strcmp(old_mode,'DigitalInput')) && (~strcmp(old_mode,'Pullup'))
        obj._configurePin(pin,'DigitalInput');
      endif
      p = obj.pinNumber(pin);
      port = floor(p / 7); % find the port
      bit = mod(p,7); % find the bit
      msg1 = char([bitor(obj.REPORT_DIGITAL,port),1]); % turn on reporting
      msg2 = char([bitor(obj.REPORT_DIGITAL,port),0]); % immediately turn it off
      obj.ard_write(obj.connection,msg1);
      obj.ard_write(obj.connection,msg2);
      
      data = 0;
      strt = time();
      while data ~= bitor(obj.DIGITAL_MSG,port)
        [data,count] = obj.ard_read(obj.connection,1); % read in the info, while trying to get rid of more
        if (time()-strt) > obj.TIMEOUT
          disp('timed out');
          err = 1;
          return;
        endif
      endwhile
      [data,count] = obj.ard_read(obj.connection,2);
      port_map = bitor(data(1), bitshift(bitand(data(2),1),7)); % make a port map
      val = ~(0==bitand(port_map,bitshift(1,bit))); % return the value of that bit
    endfunction
    function _writeDigitalPin(obj,pin,val)
      p = obj.pinNumber(pin);
      msg = [obj.SET_DIGITAL_PIN_VAL,p,~(val==0)];
      obj._configurePin(pin,'DigitalOutput');
      n = obj.ard_write(obj.connection,char(msg));
      %srl_flush(obj.connection,0); % flush output
    endfunction
    function _writePWMVoltage(obj,pin,volt)
      duty = volt / obj.Voltage; % get the percentage
      obj._writePWMDutyCycle(pin,duty);
    endfunction
    function _writePWMDutyCycle(obj,pin,duty)
      duty = int16(255*duty); % convert to the 8-bit value
      if duty > 255
        duty = 255;
      endif
      [p,a] = obj.pinNumber(pin);
      obj._configurePin(pin,'PWM');
      lsb = bitand(duty,0x7F);
      msb = bitshift(duty,-7);
      msg = char([obj.START_SYSEX, obj.EXTENDED_ANALOG, p, lsb, msb, obj.END_SYSEX]);
      n = obj.ard_write(obj.connection,msg);
    endfunction
    function [volt,value,err] = _readVoltage(obj,pin)
      volt = 0;
      value = 0;
      err = 0;
      [p,a] = obj.pinNumber(pin); % get the pin number and the analog
      if a<0 % if the pin isn't analog
        disp("readVoltage can only be used on analog pins ('A0','A6')\n");
        error();
      endif
      obj._configurePin(pin,'AnalogInput');
      msg1 = char([bitor(obj.REPORT_ANALOG,a), 1]);
      msg2 = char([bitor(obj.REPORT_ANALOG,a), 0]);
      % srl_flush(obj.connection);
      obj.ard_write(obj.connection,msg1);
      obj.ard_write(obj.connection,msg2);
      
      data = 0;
      strt = time();
      while data~=bitor(obj.ANALOG_MSG,a)
        [data,count] = obj.ard_read(obj.connection,1);
        if (time()-strt>obj.TIMEOUT)
          disp('timed out');
          err = 1;
          return
        endif
      endwhile
      [data,count] = obj.ard_read(obj.connection,2);
      lsb = double(data(1));
      msb = bitshift(double(data(2)),7);
      value = bitor(lsb,msb);
      volt =  double(value*obj.Voltage) / double(obj.ANALOG_MAX);
    endfunction
    function display(obj)
      printf("   arduino with properties:\n\n");
      if strcmp(obj.connection_type,'tcp')
        printf("            DeviceAddress: '");printf(obj.DeviceAddress);printf("'\n");
        printf("                     Port: ");printf("%i",obj.Port);printf("\n");
      else
        printf("                     Port: '");printf(obj.Port);printf("'\n");
      endif
      printf("                    Board: '");printf(obj.Board);printf("'\n");
      printf("                 Firmware: '");printf(obj.firmware);printf("'\n");
      printf("           FirmataVersion: ");printf(obj.FirmataVersion);printf("\n");
      printf("            AvailablePins: ");printf(obj.AvailablePins);printf("\n");
      printf("                  Voltage: ");printf(num2str(obj.Voltage));printf("V\n");
      printf("\n");
    endfunction
  endmethods
  methods %(Access=private,Hidden=true)
    function [p,analog] = pinNumber(obj,pin)
      if ~ischar(pin)
        disp("pin must be a string ('D3', 'A10')\n");
        error();
      endif
      if (pin(1)~='D') && (pin(1)~='A')
        disp("pin must be labeled as digital or analog ('D2', 'A5')\n");
        error();
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
      #srl_flush(obj.connection) % flush the serial line
      n = obj.ard_write(obj.connection,msg); % send the query
      
      % get sysex response
      [cmd,msg] = obj.read_sysex();
      if cmd ~= obj.ANALOG_MAPPING_RESPONSE
        disp(sprintf("problem with reading analog map, try again. %i\n",cmd));
        error();
      endif
      % get max pin number
      obj.digital_max = length(msg)-1; % the highest pin available
      
      % start saving the available pins in a string
      obj.AvailablePins = sprintf("{'D0-D%i'",obj.digital_max);
      
      % parse analog map
      obj.analog_map = struct();
      analog_pins = [];
      analog_min = -1;
      analog_prev = -1;
      for i = 1:obj.digital_max+1
        if msg(i) ~= 127 % 127 means the pin doesn't support analog
          obj.analog_map.(sprintf("A%i",msg(i))) = i-1; % save the analog to digital conversion
          analog_pins = [analog_pins (msg(i))];
        endif
      endfor
      
      % sort the pins, for analog reference
      if length(analog_pins) > 0
        analog_pins = sort(analog_pins); % sort all pin numberings
        seq = diff(analog_pins); % find the difference between them all
        analog_min = analog_pins(1);
        analog_prev = analog_pins(1);
        obj.AvailablePins = [obj.AvailablePins, sprintf(", 'A%i",analog_pins(1))];
        if length(seq) > 0 % more than one analog pin
          for i = 1:length(seq) % for every difference
            if seq(i) > 1 % if the jump was greater than 1
              if analog_prev ~= analog_min % if the last pin wasn't already written
                obj.AvailablePins = [obj.AvailablePins, sprintf("-A%i",analog_prev)]; % write it up
                analog_min = analog_prev; % save the last pin
              endif
              obj.AvailablePins = [obj.AvailablePins, sprintf("', 'A%i",analog_pins(i))];
            endif
            analog_prev = analog_pins(i);
          endfor
          % after looping, add the last pin
          obj.AvailablePins = [obj.AvailablePins, sprintf("-A%i",analog_pins(end))];
        endif
        obj.AvailablePins = [obj.AvailablePins, "'"];
      endif
      obj.AvailablePins = [obj.AvailablePins, "}"];
    endfunction
    function [cmd,msg] = read_sysex(obj,max_size=100)
      % a backend function to read a sysex message
      msg = []; % a buffer to hold the message
      data = 0;
      % check for sysex start message
      strt = time();
      while data ~= obj.START_SYSEX
        [data,count] = obj.ard_read(obj.connection,1);
        if (time()-strt) > obj.TIMEOUT
          disp("reading sysex timed out\n");
          error();
        endif
      endwhile
      [cmd,count] = obj.ard_read(obj.connection,1); % read the command
      while true
        [data,count] = obj.ard_read(obj.connection,1); % read each value
        if data==obj.END_SYSEX
          return % return the completed message
        endif
        msg = [msg data]; % append the new data to the whole message
      endwhile
    endfunction
    function [val,ip,port] = ifIP(obj,msg)
      % tells if msg is an ip address, returns the ip and port if so.
      val = 0; % default to no ip
      ip = '';
      port = -1;
      expression1 = '^\d*\.\d*\.\d*\.\d*'; % expression to find ip address at beginning of text
      expression2 = '\<\:\d*$'; % expression to find port after an ip address and at end of text
      [start,fin] = regexp(msg,expression1);
      if length(start) % if an ip was found
        val = 1; % state that an ip was found
        ip = msg(start:fin); % save the ip
        [start,fin] = regexp(msg,expression2);
        if length(start) % if a port was found
          port = msg(start+1:fin); % save the port
        else
          port = 3030; % default firmata port
        endif
      endif
    endfunction
  endmethods

end
