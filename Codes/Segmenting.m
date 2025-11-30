function main()
    % Step 1: Load multiple .fig files invisibly
    [filenames, pathname] = uigetfile('*.fig', 'Select MATLAB Figure Files', 'MultiSelect', 'on');
    if isequal(filenames, 0)
        disp('User canceled the file selection.');
        return; % Exit if no files are selected
    end
    
    % Ensure filenames is a cell array
    if ischar(filenames)  % If only one file is selected, convert to cell array
        filenames = {filenames};
    end

    % Create a new folder for saving segments
    outputDir = fullfile(pathname, 'Segments'); % Define the output directory path
    if ~exist(outputDir, 'dir')  % Check if the directory exists
        mkdir(outputDir);  % Create the directory if it does not exist
    end

    % Loop through each selected figure file
    for f = 1:length(filenames)
        % Construct the full path to the selected figure file
        figFilePath = fullfile(pathname, filenames{f});
        
        % Open figure invisibly
        hFig = openfig(figFilePath, 'invisible');
        
        % Step 2: Get axes and line objects
        axesHandles = findall(hFig, 'Type', 'axes'); % Find all axes in the figure
        
        if isempty(axesHandles)
            error('No axes found in the selected figure: %s', filenames{f});
        end
        
        lineHandles = findall(axesHandles(1), 'Type', 'line');
        
        if isempty(lineHandles)
            error('No line objects found in the selected axes of figure: %s', filenames{f});
        end
        
        % Step 3: Extract X and Y data from the first line object
        xData = get(lineHandles(1), 'XData'); % Time data (in seconds)
        yData = get(lineHandles(1), 'YData'); % EMG amplitude data
        
        % Close the figure after extracting data
        close(hFig);

        % Step 4: Define time intervals for segmentation (in seconds)
        segmentTimes = [
            0.1008, 0.7402;   % Segment 1: from 5s to 15s
            0.9808, 1.7005;   % Segment 2: from 16s to 27s
            2.03, 2.6801;   % Segment 3: from 33s to 43s
            3.007, 3.6783;   % Segment 4: from 45s to 54s
            4, 4.6397;   % Segment 5: from 59s to 68s
        ];

        % Get base name for saving figures
        [~, baseName, ~] = fileparts(filenames{f}); % Extract base name without extension

        % Validate indices and extract segments
        for i = 1:size(segmentTimes, 1)
            startTime = segmentTimes(i, 1);
            endTime = segmentTimes(i, 2);
            
            % Convert time values to indices based on xData (assuming xData is in seconds)
            startIdx = find(xData >= startTime, 1); 
            endIdx = find(xData <= endTime, 1, 'last');
            
            % Check for valid indices
            if isempty(startIdx) || isempty(endIdx) || startIdx < 1 || endIdx > length(yData) || startIdx >= endIdx
                error('Invalid segment times for segment %d in file "%s": [%d s, %d s]', i, filenames{f}, startTime, endTime);
            end
            
            % Extract the segment
            segmentX = xData(startIdx:endIdx);
            segmentY = yData(startIdx:endIdx);
            
            % Adjust x-axis values to start from zero for each segment
            adjustedX = segmentX - segmentX(1); 

            % Plot the segment with adjusted x-axis values
            figure;
            plot(adjustedX, segmentY); 
            title([baseName ' - Segment ' num2str(i)]); % Title with base name
            xlabel('Time (s)'); 
            ylabel('EMG Amplitude');
            
            % Save the figure as .fig file in "Segments" folder with same base name + segmented index
            saveas(gcf, fullfile(outputDir, [baseName '_Segmented' num2str(i) '.fig']));
            
            close(gcf); % Close the figure after saving
        end

    end

    disp('Segments saved as separate graphs successfully in "Segments" folder.');
end