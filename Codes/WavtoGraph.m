% Open a file dialog to select multiple WAV files
[filenames, path] = uigetfile('*.wav', 'Select WAV Files', 'MultiSelect', 'on');

% Check if the user canceled the dialog
if isequal(filenames, 0)
    disp('User canceled the file selection.');
else
    % If only one file is selected, convert it to a cell array for consistency
    if ischar(filenames)
        filenames = {filenames}; % Convert to cell array
    end

    % Loop through each selected file
    for i = 1:length(filenames)
        filename = fullfile(path, filenames{i}); % Get the full path of the current filename
        
        % Read the WAV file
        [y, Fs] = audioread(filename); % y is the audio data, Fs is the sample rate

        % Create a time vector based on the length of y and sample rate Fs
        t = (0:length(y)-1) / Fs;

        % Create a new figure window for each file
        figure; 
        plot(t, y); % Plot time vs. EMG data
        xlabel('Time (seconds)'); % Label for x-axis
        ylabel('Amplitude'); % Label for y-axis
        title(['EMG Signal Waveform - ' filenames{i}]); % Title of the plot with filename
        grid on; % Add a grid for better visualization

        % If stereo, plot both channels
        if size(y, 2) == 2
            hold on; % Hold the current plot
            plot(t, y(:,2)); % Plot the second channel if exists
            legend('Channel 1', 'Channel 2'); % Add legend for clarity
        end 
        
        % Save the plot as a MATLAB figure file (.fig)
        savefig(fullfile(path, [filenames{i}(1:end-4) '.fig'])); 
        
        close(gcf); % Close the figure after saving to avoid cluttering workspace
    end 
end