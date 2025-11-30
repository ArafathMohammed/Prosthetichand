% Clear workspace and command window
clear; clc;

% Load the EMG data from a text file
filename = '1.txt'; % Specify your filename here

% Check if the file exists
if isfile(filename)
    % Read the data using readmatrix
    data = readmatrix(filename); % Read the data
else
    error('File not found: %s', filename);
end

% Extract columns from the data
time = data(:, 1); % Time in ms
emg_channels = data(:, 2:9); % Eight EMG channels
gesture_class = data(:, 10); % Class labels

% Convert time from milliseconds to seconds for plotting
time_sec = time / 1000;

% Define Butterworth filter parameters
fs = 1000; % Sampling frequency in Hz 
fc = 50;   % Cut-off frequency in Hz 
order = 4; % Filter order

% Design Butterworth low-pass filter
[b, a] = butter(order, fc/(fs/2), 'low'); % Normalize frequency

% Initialize matrix for filtered signals
filtered_emg_channels = zeros(size(emg_channels));

% Apply filter to each EMG channel
for i = 1:size(emg_channels, 2)
    filtered_emg_channels(:, i) = filter(b, a, emg_channels(:, i));
end

% Plotting original EMG channels in one figure
figure;
for i = 1:size(emg_channels, 2)
    subplot(size(emg_channels, 2), 1, i);
    plot(time_sec, emg_channels(:, i), 'k'); % Original signal in black
    title(['Original EMG Channel ', num2str(i)]);
    xlabel('Time (s)');
    ylabel('Amplitude (V)');
    grid on;
end

% Adjust x-axis limits based on your data
xlim([0 max(time_sec)]);

% Plotting filtered EMG channels in another figure
figure;
for i = 1:size(filtered_emg_channels, 2)
    subplot(size(filtered_emg_channels, 2), 1, i);
    plot(time_sec, filtered_emg_channels(:, i), 'r'); % Filtered signal in red
    title(['Filtered EMG Channel ', num2str(i)]);
    xlabel('Time (s)');
    ylabel('Amplitude (V)');
    grid on;
end

% Adjust x-axis limits based on your data
xlim([0 max(time_sec)]);

% Display gesture class information if needed
disp('Gesture Classes:');
disp(unique(gesture_class));