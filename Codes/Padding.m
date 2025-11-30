% Open a dialog box to select multiple .fig files
[files, path] = uigetfile('*.fig', 'Select multiple MATLAB figure files', 'MultiSelect', 'on');

% Check if any files were selected
if isequal(files, 0)
    disp('No files selected');
else
    % Create a new folder for padded figures
    outputFolder = fullfile(path, 'padding');
    if ~exist(outputFolder, 'dir')
        mkdir(outputFolder); % Create the folder if it doesn't exist
    end

    % Ensure files is a cell array for single file selection
    if ischar(files)
        files = {files}; % Convert to cell array if only one file is selected
    end

    % Loop through each selected file
    for i = 1:length(files)
        % Open the figure file
        figHandle = openfig(fullfile(path, files{i}), 'invisible'); % Load without displaying
        
        % Get data from the axes of the figure
        axesHandles = findobj(figHandle, 'Type', 'axes'); % Find all axes in the figure
        
        for j = 1:length(axesHandles)
            % Get data from each axis (assuming first child is line data)
            lineHandles = findobj(axesHandles(j), 'Type', 'line'); 
            if ~isempty(lineHandles)
                xData = get(lineHandles, 'XData'); % Get x-axis data (time)
                yData = get(lineHandles, 'YData'); % Get y-axis data (amplitude)

                % Determine the current time range and pad accordingly
                maxTimeValue = max(xData);
                if maxTimeValue < 1.2
                    % Create new xData from 0 to 1.2 seconds with a fixed number of points
                    newXData = linspace(0, 1.2, 100); 
                    
                    % Initialize newYData with zeros for padding
                    newYData = zeros(size(newXData)); 

                    % Interpolate existing yData to match new xData length
                    if ~isempty(xData)
                        interpolatedYData = interp1(xData, yData, newXData, 'linear', 'extrap');
                        newYData(interpolatedYData ~= 0) = interpolatedYData(interpolatedYData ~= 0); 
                    end

                    % Update line data with padded values
                    set(lineHandles, 'XData', newXData, 'YData', newYData);
                end

                % Set x-axis limit to 1.2 seconds and adjust y-axis limits accordingly
                xlim(axesHandles(j), [0 1.2]);
                ylim(axesHandles(j), [-1 max(yData)]); % Adjust y-limits as necessary
            end
        end
        
        % Save the modified figure with a new name in the padding folder
        [~, name, ext] = fileparts(files{i}); % Get file name without extension
        saveas(figHandle, fullfile(outputFolder, ['Pad' name ext])); % Save with prefix 'Pad'
        
        close(figHandle); % Close the figure after processing
    end

    disp('Padding complete. Modified figures saved in "padding" folder.');
end
