function extractAndSaveEMGFeatures()
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

    % Initialize a structure to hold all features for each file
    allFeatures = struct();
    maxFeatureLength = 0; % Initialize variable to track maximum feature length

    % Define parameters for overlapping windows
    fs = 10000; % Sampling frequency in Hz (adjust as necessary)
    windowSize = round(fs * 0.5); % Window size for feature extraction (e.g., 2 seconds)
    overlapSize = round(windowSize * 0.5); % Overlap size (e.g., 50% overlap)

    % Loop through each selected figure file
    for k = 1:length(filenames)
        % Construct the full path to the selected figure file
        figFilePath = fullfile(pathname, filenames{k});
        
        % Open the specified figure
        hFig = openfig(figFilePath); % Open figure

        % Get all axes in the figure
        axesHandles = findall(hFig, 'Type', 'axes');

        if ~isempty(axesHandles)
            currentAxis = axesHandles(1); % Get the first axis handle
            lineHandles = findall(currentAxis, 'Type', 'line');
            
            if ~isempty(lineHandles)
                % Extract X (time) and Y (amplitude) data from the first line object in the current axis
                timeData = get(lineHandles(1), 'XData'); 
                filteredEMG = get(lineHandles(1), 'YData'); 
                
                % Initialize index for windowing
                startIdx = 1;
                while startIdx + windowSize - 1 <= length(filteredEMG)
                    segment = filteredEMG(startIdx:startIdx + windowSize - 1);
                    
                    % Extract features from the current segment
                    features = extractEMGFeatures(segment, fs);
                    
                    % Update maximum feature length
                    maxFeatureLength = max(maxFeatureLength, length(features));

                    % Sanitize filename for use as a field name
                    fieldName = strrep(filenames{k}, '.fig', '');  
                    fieldName = regexprep(fieldName, '[^\w]', '_');  

                    % Store features and corresponding label in allFeatures structure with sanitized field name
                    if ~isfield(allFeatures, fieldName)
                        allFeatures.(fieldName).features = features;
                        allFeatures.(fieldName).label = determineLabel(filenames{k}); 
                    else
                        allFeatures.(fieldName).features = [allFeatures.(fieldName).features; features'];
                    end

                    startIdx = startIdx + windowSize - overlapSize; % Move to the next window with overlap
                end

            else
                error(['No line data found in the selected figure: ' filenames{k}]);
            end
        else
            error(['No axes found in the selected figure: ' filenames{k}]);
        end

        if ishghandle(hFig) 
            close(hFig);
        end
        
    end

    % Pad features to ensure consistent length based on maxFeatureLength
    fieldNames = fieldnames(allFeatures);
    for i = 1:length(fieldNames)
        actionName = fieldNames{i};
        
        features = allFeatures.(actionName).features;  
        
        % Pad with zeros to match maxFeatureLength
        if size(features, 2) < maxFeatureLength 
            features(end+1:maxFeatureLength) = 0; 
        elseif size(features, 2) > maxFeatureLength 
            features = features(:, 1:maxFeatureLength); 
        end
        
        allFeatures.(actionName).features = features; % Update padded features back into structure
    end

    % Save all extracted features to a .mat file for further processing
    save(fullfile(pathname, 'oExtractedFeatures.mat'), 'allFeatures');

    disp('All features extracted and saved successfully in "ExtractedFeatures.mat".');

    %% Step 2: Prepare Data for Classification
    featureList = [];
    labelList = [];

    fieldNames = fieldnames(allFeatures);
    for i = 1:length(fieldNames)
        actionName = fieldNames{i};
        
        % Extract features and label
        features = allFeatures.(actionName).features;  
        
        % Check dimensions of the current feature vector
        disp(['Size of features for ', actionName, ':']);
        disp(size(features));  % Display size of current feature vector
        
        % Ensure features are in matrix form (row vector)
        if isrow(features)
            features = features';  % Transpose to make it a column vector if necessary
        end
        
        label = allFeatures.(actionName).label;  
        
        % Append only if dimensions match or handle inconsistencies accordingly
        if isempty(featureList)
            featureList = features';  % Initialize with the first feature set (as a row)
            labelList = [label];       % Initialize labels
        else
            if size(features, 1) == size(featureList, 2)  % Check if dimensions match
                featureList = [featureList; features'];  % Append as a new row
                labelList = [labelList; label];  
            else
                warning(['Feature dimensions do not match for ', actionName]);
            end
        end
    end

    % Check dimensions before saving
    disp('Size of featureList:');
    disp(size(featureList));  % Should show [num_samples, num_features]

    disp('Size of labelList:');
    disp(size(labelList));     % Should show [num_samples, 1]

    %% Save Prepared Data for ANN Training as .mat file and Excel file
    save(fullfile(pathname, 'oPreparedData.mat'), 'featureList', 'labelList');

    %% New Code: Save Features and Labels to Excel File 
    featureTable = array2table(featureList);   % Convert feature list to table format 
    featureTable.Labels = labelList;           % Add labels as a new column in the table 

    % Define output Excel file name and path 
    excelFilePath = fullfile(pathname, 'oPreparedData.xlsx'); 

    writetable(featureTable, excelFilePath);   % Write table to Excel file 
    disp(['Feature data saved successfully in "', excelFilePath, '".']); 
end

function label = determineLabel(filename)
    if contains(filename, 'Tripod', 'IgnoreCase', true)
        label = 1;  
    elseif contains(filename, 'Grip', 'IgnoreCase', true)
        label = 2;  
    else
        label = NaN;  
        warning(['No valid action found in filename: ', filename]);
    end
end

function features = extractEMGFeatures(filteredEMG, fs)
   features = [];  
    
   % Time Domain Features 
   meanValue = mean(filteredEMG); 
   stdValue = std(filteredEMG); 
   rmsValue = sqrt(mean(filteredEMG.^2)); 
   zeroCrossings = sum(diff(sign(filteredEMG)) ~= 0); 

   features = [features; meanValue; stdValue; rmsValue; zeroCrossings];  

   % Wavelet Transform Features using CWT 
   [wt, f_wavelet] = cwt(filteredEMG, 'amor', fs); 
    
   energyWavelet = sum(abs(wt).^2, 2);  
   features = [features; energyWavelet];  

   % Frequency Domain Features using Short-Time Fourier Transform (STFT) 
   windowSize = round(fs * 0.1);   
   overlapSize = round(windowSize * 0.5);  
    
   FFTLength = max(1024, windowSize);  
    
   [S, F, T] = stft(filteredEMG, fs, 'Window', hamming(windowSize), ...
                    'OverlapLength', overlapSize, 'FFTLength', FFTLength); 
    
   powerSpectralDensity = abs(S).^2;  
   meanPSD = mean(powerSpectralDensity, 2);  
   features = [features; meanPSD];  

   return;
end

