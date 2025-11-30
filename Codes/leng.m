% Open a dialog box to select multiple .fig files
[files, path] = uigetfile('*.fig', 'Select multiple MATLAB figure files', 'MultiSelect', 'on');

% Check if any files were selected
if isequal(files, 0)
    disp('No files selected');
else
    % Initialize variables to store the maximum time length and corresponding file name
    maxTimeLength = -Inf; % Start with negative infinity to ensure any found time is larger
    maxTimeFile = '';

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

                % Find the maximum time in this line's x-data
                currentMaxTime = max(xData);
                
                % Update if this file has a greater maximum time length
                if currentMaxTime > maxTimeLength
                    maxTimeLength = currentMaxTime;
                    maxTimeFile = files{i}; % Store the name of the current file
                end
            end
        end
        
        close(figHandle); % Close the figure after processing
    end

    % Display the results
    fprintf('File with Highest Time Length: %s\n', maxTimeFile);
    fprintf('Highest Time Value: %.2f seconds\n', maxTimeLength);
end
