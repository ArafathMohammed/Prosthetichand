import serial
import time

# Configure your COM port and baud rate
COM_PORT = 'COM6'  # Change this to your Arduino COM port
BAUD_RATE = 9600

# Open serial port
ser = serial.Serial(COM_PORT, BAUD_RATE)
time.sleep(2)  # Wait for connection to establish

# Open a file to save data
with open('output.csv', 'w') as file:
    while True:
        line = ser.readline().decode('utf-8').rstrip()  # Read line from serial
        print(line)  # Print to console
        file.write(line + '\n')  # Write line to file
