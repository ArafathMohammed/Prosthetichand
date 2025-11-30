% Prompt the user to select multiple MATLAB figure files
[filenames, pathname] = uigetfile('*.fig', 'Select MATLAB Figure Files', 'MultiSelect', 'on');
if isequal(filenames, 0)
    disp('User canceled the file selection.');
    return; % Exit if no files are selected
end

% Ensure filenames is a cell array
if ischar(filenames)  % If only one file is selected, convert to cell array
    filenames = {filenames};
end

% Create a new folder for saving SNR outputs
outputDir = fullfile(pathname, 'SNR outputs'); % Define the output directory path
if ~exist(outputDir, 'dir')  % Check if the directory exists
    mkdir(outputDir);  % Create the directory if it does not exist
end

% Initialize an array to store SNR values for all figures
allSNRValues = cell(length(filenames), 1); % Cell array to hold SNR values for each figure

% Loop through each selected figure file
for f = 1:length(filenames)
    % Construct the full path to the selected figure file
    figFilePath = fullfile(pathname, filenames{f});
    
    % Open the specified figure
    hFig = openfig(figFilePath); % Open figure

    % Get all axes in the figure
    axesHandles = findall(hFig, 'Type', 'axes');

    % Initialize an array to store SNR values for this figure
    numIMFs = length(axesHandles); % Assuming each axis corresponds to an IMF
    snrValues = zeros(numIMFs, 1);
    
    bestSNR = -Inf; % Initialize best SNR
    bestIMFIndex = 0; % Initialize index of best IMF
    bestIMFData = []; % Initialize variable to store best IMF data

    % Define your sampling frequency (Fs) here; adjust as necessary based on your data
    Fs = 10000; % Example: Set this to your actual sampling frequency in Hz

    % Loop through each axis (IMF)
    for k = 1:numIMFs
        % Get the current axis handle
        currentAxis = axesHandles(k);
        
        % Get the data from the current axis (assuming it's a line plot)
        lineHandles = findall(currentAxis, 'Type', 'line');
        
        if ~isempty(lineHandles)
            % Extract Y data from the first line object in the current axis
            currentIMF = get(lineHandles(1), 'YData');
            
            % Calculate signal power (mean of squares)
            signalPower = mean(currentIMF.^2);
            
            % Estimate noise: Here we define a threshold for noise estimation
            threshold = 0.05 * max(abs(currentIMF)); % Adjust threshold as needed
            noise = currentIMF(abs(currentIMF) < threshold); % Values below threshold considered as noise
            
            % Calculate power of the estimated noise (mean of squares)
            noisePower = mean(noise.^2);
            
            % Calculate SNR in dB
            if noisePower > 0  % Prevent division by zero
                snrValues(k) = 10 * log10(signalPower / noisePower);
            else
                snrValues(k) = Inf; % Assign infinity if there's no noise
            end
            
            % Debugging output for signal and noise powers
            fprintf('Signal Power for IMF %d in file "%s": %.6f\n', k, filenames{f}, signalPower);
            fprintf('Noise Power for IMF %d in file "%s": %.6f\n', k, filenames{f}, noisePower);
            
            % Display the SNR value for the current IMF
            fprintf('SNR for IMF %d in file "%s": %.2f dB\n', k, filenames{f}, snrValues(k));
            
            % Check if this is the best IMF based on SNR
            if snrValues(k) > bestSNR
                bestSNR = snrValues(k);
                bestIMFIndex = k;
                bestIMFData = currentIMF; % Store the best IMF data
            end
            
        else
            fprintf('No line data found for IMF %d in file "%s".\n', k, filenames{f});
        end
    end
    
    % Display which IMF is best based on SNR
    fprintf('Best IMF is IMF %d with SNR: %.2f dB\n', bestIMFIndex, bestSNR);

    % Create a new figure for the best IMF and plot it using time on X-axis
    t_bestIMF = (0:length(bestIMFData)-1) / Fs; % Time vector in seconds

    bestIMFFigure = figure;
    plot(t_bestIMF, bestIMFData); % Use time vector for X-axis instead of sample indices
    title(['Best IMF (Index ' num2str(bestIMFIndex) ') of ' filenames{f}]);
    xlabel('Time (s)'); % Change label to Time (seconds)
    ylabel('Amplitude');
    grid on;

    % Save this best IMF plot as a new .fig file with modified name in output directory
    bestIMFFigName = fullfile(outputDir, ['Best_IMF_' num2str(bestIMFIndex) '_' filenames{f}]);
    savefig(bestIMFFigure, bestIMFFigName);
    
    % Store SNR values for this figure in the cell array
    allSNRValues{f} = snrValues;
    
    % Plotting SNR values for visualization per figure and save as .fig file in output directory
    snrFigure = figure;
    bar(snrValues);
    title(['SNR of Each IMF for ', filenames{f}]);
    xlabel('IMF Index');
    ylabel('SNR (dB)');
    grid on;

    % Save the SNR plot as a .fig file in output directory with modified name 
    snrFigName = fullfile(outputDir, [filenames{f}(1:end-4) '_SNR.fig']);  % Remove .fig extension and add _SNR 
    savefig(snrFigure, snrFigName);  % Save as .fig
    
end

disp('Figures saved successfully in "SNR outputs" directory.');

% Close all figures at the end of processing.
close all;