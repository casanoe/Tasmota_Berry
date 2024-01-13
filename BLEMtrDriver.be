#-
 - Tasmota Driver written in Berry
 - Automaticaly plublish BLE sensors in Matter
 - As a Workaround for my personal use : HomeKit + LYWSD03MMC / ATC (unencrypted)
 - See : https://github.com/arendst/Tasmota/discussions/20388 
 -#

 import global
 global.BLEMtrDriver_value = {}
 #global.BLEMtrDriver_bledev = {}
 
 class BLEMtrDriver
   var ok
   var last_updated
   var seconds
 
   def init()
     tasmota.cmd("MI32OPTION2 1")
     log("BLEMtrDriver: Init...")
     self.last_updated = 0
     self.seconds = 0
     self.check(true)
   end
 
   def update_mtr_devices(b)
     import path
     var dt = path.last_modified("_matter_device.json")
     if (dt > self.last_updated) || b
       import json
       import string
       log("BLEMtrDriver: Update devices", 3)
       global.BLEMtrDriver_value = {}
       self.last_updated= tasmota.time_dump(tasmota.rtc()['local'])['epoch']
       var f = open("_matter_device.json")
       var d1 = json.load(f.read())['config']
       f.close()
       var se = json.load(tasmota.read_sensors())
       var dev
       self.remove_allrules()
       #self.add_rule_ble()
       for v:d1
         if v.find('filter')
           dev = string.split(v['filter'], '#')[0]
           if (se == nil || se.find(dev) == nil) && global.BLEMtrDriver_value.find(dev) == nil
             self.add_rule(dev)
             global.BLEMtrDriver_value[dev] = {}
           end
         end
       end
     end
   end
 
   #- def add_rule_ble()
     log("BLEMtrDriver: Add rule BLE ", 3)
     tasmota.add_rule("BLEDevices", 
       def(value) 
         import global
         log("BLEMtrDriver: update "..dev, 3)
         global.BLEMtrDriver_bledev = value
       end
       , "BLEMtrDriver_BLEDevices")
     end -#

   def add_rule(dev)
     log("BLEMtrDriver: Add rule "..dev, 3)
     tasmota.add_rule(dev, 
       def(value) 
         import global
         log("BLEMtrDriver: update "..dev, 3)
         global.BLEMtrDriver_value[dev] = value
       end
       , "BLEMtrDriver_"..dev)
     end

   def remove_allrules()
     import string
     if tasmota._rules
       var i = 0
       while i < tasmota._rules.size()
         if string.find(tasmota._rules[i].id, 'BLEMtrDriver_') == 0
           log("BLEMtrDriver: remove rule "..str(i).." "..tasmota._rules[i].id, 3)
           tasmota._rules.remove(i)
         else
           i += 1
         end
       end
     end
   end
 
   def check(b)
     import path
     log("BLEMtrDriver:  check", 3)
     if path.exists("_matter_device.json")
       self.ok = true
       self.update_mtr_devices(b)
       log("BLEMtrDriver: _matter_device.json exists", 3)
     else
       self.ok = false
     end
   end
 
   #- trigger a read every second -#
   def every_second()
     self.seconds = self.seconds + 1
     if self.seconds == 60
       self.check()
       self.seconds = 0
     end
   end
 
   #- display sensor value in the web UI -#
   def web_sensor()
     if !self.ok return nil end  #- exit if not initialized -#
     var msg = "{s}{m}{e}"..
      "{s}BLEMtrDriver {m}"..str(size(global.BLEMtrDriver_value)).." devices{e}"..
      "{s}BLEMtrDriver update in{m}"..str(60-self.seconds).." seconds{e}"
     tasmota.web_send_decimal(msg)
   end
 
   #- add sensor value to teleperiod -#
   def json_append()
     if !self.ok return nil end  #- exit if not initialized -#
     import global
     import json
     import string
     for dev:global.BLEMtrDriver_value.keys()
       var v = global.BLEMtrDriver_value[dev]
       v = string.replace(string.format("%s",v), "'", "\"")
       tasmota.response_append(',"'..dev..'":'..v)
       log("BLEMtrDriver: response append "..dev, 3)
     end
   end
 
 end
 
 BLEMtrDrv = BLEMtrDriver()
 tasmota.add_driver(BLEMtrDrv)
