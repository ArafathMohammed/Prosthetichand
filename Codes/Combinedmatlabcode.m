%% Step 1: Perform VMD on EMG WAV files and save IMF figures
function performVMDonEMG()
    [filenames, path] = uigetfile('*.wav', 'Select WAV Files', 'MultiSelect', 'on');
    if isequal(filenames, 0)
        disp('User canceled the file selection.');
        return;
    end
    if ischar(filenames)
        filenames = {filenames};
    end

    for i = 1:length(filenames)
        filename = fullfile(path, filenames{i});
        [emgSignal, Fs] = audioread(filename);

        % Perform Variational Mode Decomposition (VMD)
        [imf, ~] = vmd(emgSignal, 'NumIMF', 5);

        t = (0:length(emgSignal)-1) / Fs;

        figure;
        numIMFs = size(imf, 2);
        for j = 1:numIMFs
            subplot(numIMFs, 1, j);
            plot(t, imf(:, j));
            title(['IMF ' num2str(j) ' from ' filenames{i}]);
            xlabel('Time (s)');
            ylabel('Amplitude');
            grid on;
        end
        sgtitle(['VMD of EMG Signal: ' filenames{i}]);

        [~, name, ~] = fileparts(filenames{i});
        savefig(gcf, fullfile(path, [name '_VMD_IMFs.fig']));
        close(gcf);
    end
end


%% Step 2: Calculate SNR of IMFs from saved figures and save best IMF plots
function calculateSNRandSaveBestIMF()
    [filenames, pathname] = uigetfile('*.fig', 'Select MATLAB Figure Files', 'MultiSelect', 'on');
    if isequal(filenames, 0)
        disp('User canceled the file selection.');
        return;
    end
    if ischar(filenames)
        filenames = {filenames};
    end

    outputDir = fullfile(pathname, 'SNR outputs');
    if ~exist(outputDir, 'dir')
        mkdir(outputDir);
    end

    Fs = 10000; % Sampling frequency (adjust if needed)

    for f = 1:length(filenames)
        figFilePath = fullfile(pathname, filenames{f});
        hFig = openfig(figFilePath);

        axesHandles = findall(hFig, 'Type', 'axes');
        numIMFs = length(axesHandles);
        snrValues = zeros(numIMFs, 1);

        bestSNR = -Inf;
        bestIMFIndex = 0;
        bestIMFData = [];

        for k = 1:numIMFs
            currentAxis = axesHandles(k);
            lineHandles = findall(currentAxis, 'Type', 'line');

            if ~isempty(lineHandles)
                currentIMF = get(lineHandles(1), 'YData');

                signalPower = mean(currentIMF.^2);
                threshold = 0.05 * max(abs(currentIMF));
                noise = currentIMF(abs(currentIMF) < threshold);
                noisePower = mean(noise.^2);

                if noisePower > 0
                    snrValues(k) = 10 * log10(signalPower / noisePower);
                else
                    snrValues(k) = Inf;
                end

                fprintf('SNR for IMF %d in file "%s": %.2f dB\n', k, filenames{f}, snrValues(k));

                if snrValues(k) > bestSNR
                    bestSNR = snrValues(k);
                    bestIMFIndex = k;
                    bestIMFData = currentIMF;
                end
            else
                fprintf('No line data found for IMF %d in file "%s".\n', k, filenames{f});
            end
        end

        fprintf('Best IMF is IMF %d with SNR: %.2f dB\n', bestIMFIndex, bestSNR);

        t_bestIMF = (0:length(bestIMFData)-1) / Fs;

        bestIMFFigure = figure;
        plot(t_bestIMF, bestIMFData);
        title(['Best IMF (Index ' num2str(bestIMFIndex) ') of ' filenames{f}]);
        xlabel('Time (s)');
        ylabel('Amplitude');
        grid on;

        bestIMFFigName = fullfile(outputDir, ['Best_IMF_' num2str(bestIMFIndex) '_' filenames{f}]);
        savefig(bestIMFFigure, bestIMFFigName);
        close(bestIMFFigure);

        snrFigure = figure;
        bar(snrValues);
        title(['SNR of Each IMF for ', filenames{f}]);
        xlabel('IMF Index');
        ylabel('SNR (dB)');
        grid on;

        snrFigName = fullfile(outputDir, [filenames{f}(1:end-4) '_SNR.fig']);
        savefig(snrFigure, snrFigName);
        close(snrFigure);

        close(hFig);
    end
    disp('SNR analysis and best IMF figures saved.');
end


%% Step 3: Segment EMG signals from figure files and save them
function segmentEMGSignals()
    [filenames, pathname] = uigetfile('*.fig', 'Select MATLAB Figure Files', 'MultiSelect', 'on');
    if isequal(filenames, 0)
        disp('User canceled the file selection.');
        return;
    end
    if ischar(filenames)
        filenames = {filenames};
    end

    outputDir = fullfile(pathname, 'Segments');
    if ~exist(outputDir, 'dir')
        mkdir(outputDir);
    end

    segmentTimes = [
        0.1008, 0.7402;
        0.9808, 1.7005;
        2.03, 2.6801;
        3.007, 3.6783;
        4, 4.6397;
    ];

    for f = 1:length(filenames)
        figFilePath = fullfile(pathname, filenames{f});
        hFig = openfig(figFilePath, 'invisible');

        axesHandles = findall(hFig, 'Type', 'axes');
        if isempty(axesHandles)
            error('No axes found in the selected figure: %s', filenames{f});
        end

        lineHandles = findall(axesHandles(1), 'Type', 'line');
        if isempty(lineHandles)
            error('No line objects found in the selected axes of figure: %s', filenames{f});
        end

        xData = get(lineHandles(1), 'XData');
        yData = get(lineHandles(1), 'YData');
        close(hFig);

        [~, baseName, ~] = fileparts(filenames{f});

        for i = 1:size(segmentTimes, 1)
            startTime = segmentTimes(i, 1);
            endTime = segmentTimes(i, 2);

            startIdx = find(xData >= startTime, 1);
            endIdx = find(xData <= endTime, 1, 'last');

            if isempty(startIdx) || isempty(endIdx) || startIdx < 1 || endIdx > length(yData) || startIdx >= endIdx
                error('Invalid segment times for segment %d in file "%s": [%d s, %d s]', i, filenames{f}, startTime, endTime);
            end

            segmentX = xData(startIdx:endIdx);
            segmentY = yData(startIdx:endIdx);
            adjustedX = segmentX - segmentX(1);

            figure;
            plot(adjustedX, segmentY);
            title([baseName ' - Segment ' num2str(i)]);
            xlabel('Time (s)');
            ylabel('EMG Amplitude');

            saveas(gcf, fullfile(outputDir, [baseName '_Segmented' num2str(i) '.fig']));
            close(gcf);
        end
    end
    disp('Segments saved successfully.');
end


%% Step 4: Pad EMG figure data to fixed length and save modified figures
function padEMFFigures()
    [files, path] = uigetfile('*.fig', 'Select multiple MATLAB figure files', 'MultiSelect', 'on');
    if isequal(files, 0)
        disp('No files selected');
        return;
    end
    if ischar(files)
        files = {files};
    end

    outputFolder = fullfile(path, 'padding');
    if ~exist(outputFolder, 'dir')
        mkdir(outputFolder);
    end

    for i = 1:length(files)
        figHandle = openfig(fullfile(path, files{i}), 'invisible');
        axesHandles = findobj(figHandle, 'Type', 'axes');

        for j = 1:length(axesHandles)
            lineHandles = findobj(axesHandles(j), 'Type', 'line');
            if ~isempty(lineHandles)
                xData = get(lineHandles, 'XData');
                yData = get(lineHandles, 'YData');

                maxTimeValue = max(xData);
                if maxTimeValue < 1.2
                    newXData = linspace(0, 1.2, 100);
                    newYData = zeros(size(newXData));

                    if ~isempty(xData)
                        interpolatedYData = interp1(xData, yData, newXData, 'linear', 'extrap');
                        newYData(interpolatedYData ~= 0) = interpolatedYData(interpolatedYData ~= 0);
                    end

                    set(lineHandles, 'XData', newXData, 'YData', newYData);
                end

                xlim(axesHandles(j), [0 1.2]);
                ylim(axesHandles(j), [-1 max(yData)]);
            end
        end

        [~, name, ext] = fileparts(files{i});
        saveas(figHandle, fullfile(outputFolder, ['Pad' name ext]));
        close(figHandle);
    end
    disp('Padding complete. Modified figures saved.');
end


%% Step 5: Extract EMG features from figures and save to MAT and Excel
function extractAndSaveEMGFeatures()
    [filenames, pathname] = uigetfile('*.fig', 'Select MATLAB Figure Files', 'MultiSelect', 'on');
    if isequal(filenames, 0)
        disp('User canceled the file selection.');
        return;
    end
    if ischar(filenames)
        filenames = {filenames};
    end

    allFeatures = struct();
    maxFeatureLength = 0;

    for k = 1:length(filenames)
        figFilePath = fullfile(pathname, filenames{k});
        hFig = openfig(figFilePath);
        axesHandles = findall(hFig, 'Type', 'axes');

        if ~isempty(axesHandles)
            currentAxis = axesHandles(1);
            lineHandles = findall(currentAxis, 'Type', 'line');

            if ~isempty(lineHandles)
                filteredEMG = get(lineHandles(1), 'YData');
                fs = 10000;

                features = extractEMGFeatures(filteredEMG, fs);

                maxFeatureLength = max(maxFeatureLength, length(features));

                fieldName = strrep(filenames{k}, '.fig', '');
                fieldName = regexprep(fieldName, '[^\w]', '_');

                if contains(filenames{k}, 'Tripod', 'IgnoreCase', true)
                    label = 1;
                elseif contains(filenames{k}, 'Grip', 'IgnoreCase', true)
                    label = 2;
                else
                    label = NaN;
                    warning(['No valid action found in filename: ', filenames{k}]);
                end

                allFeatures.(fieldName).features = features;
                allFeatures.(fieldName).label = label;
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

    % Pad features to equal length
    fieldNames = fieldnames(allFeatures);
    for i = 1:length(fieldNames)
        features = allFeatures.(fieldNames{i}).features;
        if length(features) < maxFeatureLength
            features(end+1:maxFeatureLength) = 0;
        elseif length(features) > maxFeatureLength
            features = features(1:maxFeatureLength);
        end
        allFeatures.(fieldNames{i}).features = features;
    end

    save(fullfile(pathname, 'ExtractedFeatures.mat'), 'allFeatures');
    disp('Features extracted and saved.');

    % Prepare data matrix and labels
    featureList = [];
    labelList = [];

    for i = 1:length(fieldNames)
        features = allFeatures.(fieldNames{i}).features;
        label = allFeatures.(fieldNames{i}).label;

        if isrow(features)
            features = features';
        end

        if isempty(featureList)
            featureList = features';
            labelList = label;
        else
            if size(features, 1) == size(featureList, 2)
                featureList = [featureList; features'];
                labelList = [labelList; label];
            else
                warning(['Feature dimensions do not match for ', fieldNames{i}]);
            end
        end
    end

    save(fullfile(pathname, 'PreparedData.mat'), 'featureList', 'labelList');

    % Save to Excel
    featureTable = array2table(featureList);
    featureTable.Labels = labelList;
    excelFilePath = fullfile(pathname, '7PreparedData.xlsx');
    writetable(featureTable, excelFilePath);

    disp(['Feature data saved to Excel file: ', excelFilePath]);
end

function features = extractEMGFeatures(filteredEMG, fs)
    % Time domain features
    meanValue = mean(filteredEMG);
    stdValue = std(filteredEMG);
    rmsValue = sqrt(mean(filteredEMG.^2));
    zeroCrossings = sum(diff(sign(filteredEMG)) ~= 0);

    features = [meanValue; stdValue; rmsValue; zeroCrossings];

    % Wavelet transform features (CWT with 'amor' wavelet)
    [wt, ~] = cwt(filteredEMG, 'amor', fs);
    energyWavelet = sum(abs(wt).^2, 2);
    features = [features; energyWavelet];

    % Frequency domain features (STFT)
    windowSize = round(fs * 0.1);
    overlapSize = round(windowSize * 0.5);
    FFTLength = max(1024, windowSize);

    [S, ~, ~] = stft(filteredEMG, fs, 'Window', hamming(windowSize), ...
                     'OverlapLength', overlapSize, 'FFTLength', FFTLength);
    powerSpectralDensity = abs(S).^2;
    meanPSD = mean(powerSpectralDensity, 2);
    features = [features; meanPSD];
end


%% Step 6: Train ANN classifier using extracted features
function trainANNClassifier()
    data = load('PreparedData.mat');

    featureList = data.featureList;
    labelList = data.labelList;

    % Shuffle and split data
    numSamples = size(featureList, 1);
    indices = randperm(numSamples);
    splitPoint = round(0.8 * numSamples);

    trainIndices = indices(1:splitPoint);
    testIndices = indices(splitPoint+1:end);

    trainFeatures = featureList(trainIndices, :);
    trainLabels = labelList(trainIndices);

    testFeatures = featureList(testIndices, :);
    testLabels = labelList(testIndices);

    % Define and train ANN
    hiddenLayerSize = 10;
    net = feedforwardnet(hiddenLayerSize);
    net = train(net, trainFeatures', trainLabels');

    % Test ANN
    predictedLabels = net(testFeatures');
    predictedLabels = round(predictedLabels);

    accuracy = sum(predictedLabels' == testLabels) / length(testLabels);
    fprintf('Classification Accuracy on Test Set: %.2f%%\n', accuracy * 100);

    save('trainedANNModel.mat', 'net', 'accuracy');
end
