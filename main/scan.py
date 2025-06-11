# Network scanner
# michu990
# Version: 1.0

import json
import os
import subprocess
import sys
import time
import xml.etree.ElementTree as ET
from threading import Thread, Event
from datetime import datetime

# Class creating a spinner animation in terminal during operations
class Spinner:
    # Initialize spinner with message and animation characters
    def __init__(self, message="Pracuję..."):
        self.spinner_chars = "|/-\\"
        self.message = message
        self.stop_event = Event()
        self.thread = Thread(target=self._spin)

    # Internal method implementing the spinner animation
    def _spin(self):
        i = 0
        while not self.stop_event.is_set():
            sys.stdout.write(f"\r{self.message} {self.spinner_chars[i]}")
            sys.stdout.flush()
            time.sleep(0.1)
            i = (i + 1) % len(self.spinner_chars)
        sys.stdout.write("\r" + " " * (len(self.message) + 2) + "\r")
        sys.stdout.flush()

    # Start spinner animation
    def __enter__(self):
        self.thread.start()
        return self

    # Stop spinner animation
    def __exit__(self, exc_type, exc_val, exc_tb):
        self.stop_event.set()
        self.thread.join()

# Displays scan type menu and returns appropriate nmap options
def get_scan_options():
    print("\nWybierz rodzaj skanowania: ")
    print("1. Szybki (ping)")
    print("2. Standardowy (nmap -sS)")
    print("3. Dokładny (nmap -sS -sV -O)")
    print("4. Pełny (nmap -sS -sV -O -A -T4)")
    
    choice = input("Wybierz: ")
    
    options = {
        '1': '-sn',
        '2': '-sS',
        '3': '-sS -sV -O',
        '4': '-sS -sV -O -A -T4'
    }
    
    return options.get(choice, '-sn')

# Performs network scan using nmap tool
def run_nmap_scan(network_range, scan_options):
    command = f"nmap {scan_options} {network_range} -oX -"
    try:
        with Spinner("Skanowanie sieci..."):
            result = subprocess.run(
                command,
                shell=True,
                check=True,
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                text=True
            )
        return result.stdout
    except subprocess.CalledProcessError as e:
        print(f"\nBłąd nmap: {e.stderr}")
        sys.exit(1)

# Parses nmap XML output and extracts device information
def parse_nmap_xml(xml_output):
    devices = []
    root = ET.fromstring(xml_output)
    
    for host in root.findall('host'):
        # Default values for device
        device_info = {
            'ip': '',
            'mac': 'unknown',
            'hostname': 'unknown',
            'state': 'down',
            'scan_time': datetime.now().strftime("%Y-%m-%d %H:%M:%S"),
            'ports': []
        }
        
        # Get IP address
        address = host.find("address[@addrtype='ipv4']")
        if address is not None:
            device_info['ip'] = address.get('addr')
        
        # Get MAC address and vendor
        mac = host.find("address[@addrtype='mac']")
        if mac is not None:
            device_info['mac'] = mac.get('addr')
            vendor = mac.get('vendor')
            if vendor:
                device_info['mac_vendor'] = vendor
        
        # Get hostname
        hostname = host.find("hostnames/hostname")
        if hostname is not None:
            device_info['hostname'] = hostname.get('name')
        
        # Get device status
        status = host.find('status')
        if status is not None:
            device_info['state'] = status.get('state')
        
        # Get port information
        ports = host.findall('ports/port')
        for port in ports:
            port_info = {
                'port': port.get('portid'),
                'protocol': port.get('protocol'),
                'state': port.find('state').get('state'),
                'service': port.find('service').get('name') if port.find('service') is not None else 'unknown'
            }
            device_info['ports'].append(port_info)
        
        devices.append(device_info)
    
    return devices

# Saves scan results to JSON file
def save_to_json(devices, filename='network_devices.json'):
    data = {
        'last_scan': datetime.now().strftime("%Y-%m-%d %H:%M:%S"),
        'devices': devices
    }
    
    with open(filename, 'w', encoding='utf-8') as f:
        json.dump(data, f, indent=4, ensure_ascii=False)

# Loads previous scan results from JSON file
def load_from_json(filename='network_devices.json'):
    if not os.path.exists(filename):
        return None
    
    with open(filename, 'r', encoding='utf-8') as f:
        return json.load(f)

# Compares previous and current scan results
def compare_devices(old_devices, new_devices):
    if old_devices is None:
        print("\nNie znaleziono poprzedniego pliku z zapisanymi urządzeniami. Pierwszy skan.")
        return new_devices, []
    
    old_ips = {dev['ip'] for dev in old_devices['devices']}
    new_ips = {dev['ip'] for dev in new_devices}
    
    added = [dev for dev in new_devices if dev['ip'] not in old_ips]
    removed = [dev for dev in old_devices['devices'] if dev['ip'] not in new_ips]
    
    return added, removed

# Displays device information in readable format
def print_devices(devices, title):
    if not devices:
        print(f"\n{title}: None")
        return
    
    print(f"\n{title} ({len(devices)}):")
    for i, dev in enumerate(devices, 1):
        print(f"\nUrządzenie {i}:")
        print(f"  IP: {dev.get('ip', 'unknown')}")
        print(f"  MAC: {dev.get('mac', 'unknown')}")
        if 'mac_vendor' in dev:
            print(f"  Vendor: {dev['mac_vendor']}")
        print(f"  Hostname: {dev.get('hostname', 'unknown')}")
        print(f"  Status: {dev.get('state', 'unknown')}")
        print(f"  Czas skanowania: {dev.get('scan_time', 'unknown')}")
        
        if dev['ports']:
            print("  Open ports:")
            for port in dev['ports']:
                print(f"    Port {port['port']}/{port['protocol']}: {port['service']} ({port['state']})")

# Main program function
def main():
    import argparse
    
    parser = argparse.ArgumentParser()
    parser.add_argument('--output', default='network_devices.json', help='Path to output JSON file')
    args = parser.parse_args()

    print("Skanowanie sieci lokalnej\n")
    
##############################################################################################################################################################################
#                                                                                                                                                                            #
#                                                                                   ADD NETWORK RANGE                                                                        #
#                                                                                                                                                                            #
##############################################################################################################################################################################

    network_range = "x.x.x.x/x"
    scan_options = get_scan_options()
    
    # Perform scan and process results
    xml_output = run_nmap_scan(network_range, scan_options)
    devices = parse_nmap_xml(xml_output)
    
    # Compare with previous results
    old_devices = load_from_json(args.output)
    added, removed = compare_devices(old_devices, devices)
    
    # Save results and display summary
    save_to_json(devices, args.output)
    
    print(f"\nSkan zakończony. Znaleziono {len(devices)} aktywnych urządzeń.")
    print_devices(devices, "Wszystkie urządzenia")
    print_devices(added, "Nowe urządzenia")
    print_devices(removed, "Usunięte urządzenia")
    
    # Display warning about new devices
    if added:
        print("\nUWAGA: Nowe urządzenia w sieci!")
    else:
        print("\nBrak nowych urządzeń w sieci.")

if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        print("\nPrzerwanie pracy skryptu.")
        sys.exit(0)
    except Exception as e:
        print(f"\nWystąpił błąd: {e}")
        sys.exit(1)