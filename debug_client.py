import socket
import sys
import threading

def receive_data(sock):
    while True:
        data = sock.recv(4096)
        if not data:
            break
        print(data.decode("utf-8"), end="")

def main():
    if len(sys.argv) < 2:
        print("Usage: python debug_client.py <WiiU_IP>")
        return

    ip = sys.argv[1]
    port = 8000

    try:
        with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
            s.connect((ip, port))
            print(f"Connected to {ip}:{port}")
            
            # Start receiver thread
            thread = threading.Thread(target=receive_data, args=(s,))
            thread.daemon = True
            thread.start()

            # Send commands (optional)
            while True:
                cmd = input()
                if cmd.lower() == "quit":
                    break
                s.sendall((cmd + "\n").encode())
                
    except ConnectionRefusedError:
        print("Connection refused. Is the game running on Wii U?")
    except Exception as e:
        print(f"Error: {str(e)}")

if __name__ == "__main__":
    main()