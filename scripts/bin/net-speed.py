import sys
import socket
import fcntl
import struct

def get_ip_address(ifname):
    try:
        s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        return socket.inet_ntoa(fcntl.ioctl(
            s.fileno(),
            0x8915,  # SIOCGIFADDR
            struct.pack('256s', ifname[:15].encode('utf-8'))
        )[20:24])
    except:
        return "No IP"

if __name__ == "__main__":
    iface = sys.argv[1] if len(sys.argv) > 1 else "wlan0"
    print(get_ip_address(iface))
