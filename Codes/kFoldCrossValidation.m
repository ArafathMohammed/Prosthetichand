function kFoldCrossValidation(k)

    % Load Prepared Data from .mat file
    data = load('PreparedData.mat');
    
    featureList = data.featureList;
    labelList = data.labelList;

    % Check dimensions of featureList and labelList
    numSamples = size(featureList, 1); % Total number of samples
    indices = randperm(numSamples); % Randomly shuffle indices
    foldSize = floor(numSamples / k); % Size of each fold
    accuracies = zeros(k, 1); % Array to store accuracies for each fold

    for i = 1:k
        % Define validation and training indices
        valIndices = indices((i-1)*foldSize + 1:min(i*foldSize, numSamples));
        trainIndices = setdiff(indices, valIndices);
        
        % Create training and validation sets
        trainFeatures = featureList(trainIndices, :);
        trainLabels = labelList(trainIndices);
        
        valFeatures = featureList(valIndices, :);
        valLabels = labelList(valIndices);
        
        % Load the trained ANN model (assumes it's saved as 'trainedANNModel.mat')
        loadedData = load('trainedANNModel.mat');
        net = loadedData.net; % Load the trained network
        
        % Train the network using transposed trainFeatures and trainLabels
        net = train(net, trainFeatures', trainLabels');  

        % Validate the model
        predictedLabels = net(valFeatures');  
        predictedLabels = round(predictedLabels);  

        % Calculate accuracy for this fold
        accuracies(i) = sum(predictedLabels' == valLabels) / length(valLabels);
        
        disp(['Fold ', num2str(i), ' Accuracy: ', num2str(accuracies(i) * 100), '%']);
    end

    % Calculate average accuracy across all folds
    avgAccuracy = mean(accuracies);
    disp(['Average Accuracy across ', num2str(k), ' folds: ', num2str(avgAccuracy * 100), '%']);
end
