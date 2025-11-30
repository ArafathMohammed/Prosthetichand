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
        [emgSignal, Fs] = audioread(filename); % emgSignal is the audio data, Fs is the sample rate

        % Perform Variational Mode Decomposition
        [imf, residual] = vmd(emgSignal, 'NumIMF', 5); % Adjust NumIMF as needed

        % Time vector for plotting
        t = (0:length(emgSignal)-1) / Fs; 

        % Plotting only the IMFs
        figure;
        numIMFs = size(imf, 2); % Number of IMFs
        for j = 1:numIMFs
            subplot(numIMFs, 1, j);
            plot(t, imf(:, j));
            title(['IMF ' num2str(j) ' from ' filenames{i}]);
            xlabel('Time (s)');
            ylabel('Amplitude');
            grid on;
        end
        
        % Adjust layout for better visibility
        sgtitle(['VMD of EMG Signal: ' filenames{i}]); % Overall title for the figure

        % Save the figure as a .fig file with the same name as the original file
        [~, name, ~] = fileparts(filenames{i}); % Get the base name without extension
        savefig(gcf, fullfile(path, [name '_VMD_IMFs.fig'])); % Save as .fig file with full path

        close(gcf); % Close figure after saving to avoid cluttering workspace
    end 
end