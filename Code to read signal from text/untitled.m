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

% Convert time from milliseconds to seconds for plotting
time_sec = time / 1000;

% Define Butterworth filter parameters
fs = 1000; % Sampling frequency in Hz (adjust based on your data)
fc = 50;   % Cut-off frequency in Hz (adjust based on your requirements)
order = 4; % Filter order

% Design Butterworth low-pass filter
[b, a] = butter(order, fc/(fs/2), 'low'); % Normalize frequency

% Initialize matrix for filtered signals
filtered_emg_channels = zeros(size(emg_channels));

% Apply filter to each EMG channel
for i = 1:size(emg_channels, 2)
    filtered_emg_channels(:, i) = filter(b, a, emg_channels(:, i));
end

% Initialize figure for plotting RMS of filtered signals
figure;

% Calculate and plot RMS for each channel
for i = 1:size(filtered_emg_channels, 2)
    % Calculate RMS using a moving average window
    windowSize = round(0.1 * fs); % Window size for RMS calculation (100 ms)
    rms_signal = sqrt(movmean(filtered_emg_channels(:, i).^2, windowSize)); 

    % Plot RMS signal for each channel
    subplot(size(filtered_emg_channels, 2), 1, i);
    plot(time_sec, rms_signal, 'b', 'LineWidth', 1.5); % RMS in blue
    title(['RMS of Filtered EMG Channel ', num2str(i)]);
    xlabel('Time (s)');
    ylabel('RMS Amplitude');
    grid on;
end

% Calculate and plot RMS of averaged filtered signal
averaged_signal = mean(filtered_emg_channels, 2); % Average across channels
rms_avg_signal = sqrt(movmean(averaged_signal.^2, windowSize)); 

figure;
plot(time_sec, rms_avg_signal, 'm', 'LineWidth', 1.5); % RMS of averaged signal in magenta
title('RMS of Averaged Filtered EMG Signal');
xlabel('Time (s)');
ylabel('RMS Amplitude');
grid on;