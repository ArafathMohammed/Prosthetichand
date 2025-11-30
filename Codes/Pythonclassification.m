function trainANNClassifier()
    % Load Prepared Data from .mat file
    data = load('PreparedData.mat');
    
    featureList = data.featureList;
    labelList = data.labelList;

    % Check dimensions of featureList and labelList
    disp('Size of featureList:');
    disp(size(featureList));  % Should show [num_samples, num_features]

    disp('Size of labelList:');
    disp(size(labelList));     % Should show [num_samples, 1]

    %% Step 1: Split Data into Training and Testing Sets
    numSamples = size(featureList, 1); % Total number of samples

    % Randomly shuffle the indices
    indices = randperm(numSamples);

    % Define split point (e.g., 80% for training)
    splitPoint = round(0.8 * numSamples); % For an 80/20 split

    % Create training and testing sets
    trainIndices = indices(1:splitPoint);
    testIndices = indices(splitPoint+1:end);

    trainFeatures = featureList(trainIndices, :);
    trainLabels = labelList(trainIndices);

    testFeatures = featureList(testIndices, :);
    testLabels = labelList(testIndices);

    disp('Training Features Size:');
    disp(size(trainFeatures));
    disp('Training Labels Size:');
    disp(size(trainLabels));

    disp('Testing Features Size:');
    disp(size(testFeatures));
    disp('Testing Labels Size:');
    disp(size(testLabels));

    %% Step 2: Define and Train the ANN
    hiddenLayerSize = 10;  
    net = feedforwardnet(hiddenLayerSize);

    % Train the network using transposed trainFeatures and trainLabels
    net = train(net, trainFeatures', trainLabels');  

    %% Step 3: Evaluate the Model on Test Set
    predictedLabels = net(testFeatures');  
    predictedLabels = round(predictedLabels);  

    %% Step 4: Calculate Accuracy (optional)
    accuracy = sum(predictedLabels' == testLabels) / length(testLabels);
    disp(['Classification Accuracy on Test Set: ', num2str(accuracy * 100), '%']);

    %% Step 5: Save the Trained Model
    save('trainedANNModel.mat', 'net', 'accuracy'); % Save the network and accuracy

    % Save features and labels for Python retraining
    save('training_data.mat', 'featureList', 'labelList');
end

% Example usage:
% Call this function to train your ANN classifier.
% trainANNClassifier();
