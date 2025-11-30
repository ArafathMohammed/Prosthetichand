% Setup Serial Communication using serialport
serialPort = 'COM6'; % Change this to your actual COM port
baudRate = 230400;

% Use serialport instead of serial for newer MATLAB versions
s = serialport(serialPort, baudRate);

% Define parameters
fs = 10000; % Sampling frequency in Hz
numIMF = 2; % Number of IMFs for VMD
threshold = 0.05; % Threshold for noise estimation

% Initialize buffer for EMG data
dataBuffer = []; 
processingTime = 3; % Time in seconds for each processing interval

try
    while true
        % Start time for processing interval
        startTime = tic; 

        while toc(startTime) < processingTime
            if s.NumBytesAvailable > 0 % Check if data is available
                emgSignal = read(s, 1, "uint16"); % Read EMG signal
                
                % Append new signal to buffer
                dataBuffer(end + 1) = emgSignal;
                
                % Notify that a new EMG signal has been received
                fprintf('Received EMG Signal: %.2f\n', emgSignal);
            end
            
            pause(0.01); % Small delay to avoid overwhelming the buffer
        end
        
        if length(dataBuffer) > 0
            fprintf('Processing collected EMG data...\n');
            
            % Perform VMD on the collected signal
            [imf, residual] = vmd(dataBuffer, 'NumIMF', numIMF); 
            fprintf('VMD completed.\n');

            % Calculate SNR for each IMF and find the best one
            bestSNR = -Inf; 
            bestIMFIndex = 0; 
            bestIMFData = []; 

            for k = 1:numIMF
                currentIMF = imf(:, k);
                signalPower = mean(currentIMF.^2);
                noise = currentIMF(abs(currentIMF) < threshold * max(abs(currentIMF))); 
                noisePower = mean(noise.^2);
                
                if noisePower > 0  
                    snrValue = 10 * log10(signalPower / noisePower);
                else
                    snrValue = Inf; 
                end
                
                % Check for best IMF based on SNR
                if snrValue > bestSNR
                    bestSNR = snrValue;
                    bestIMFIndex = k;
                    bestIMFData = currentIMF;
                end
                
                fprintf('SNR for IMF %d: %.2f dB\n', k, snrValue);
            end
            
            fprintf('Best IMF is IMF %d with SNR: %.2f dB\n', bestIMFIndex, bestSNR);

            % Extract features from the best IMF
            features = extractEMGFeatures(bestIMFData, fs);
            fprintf('Feature extraction completed.\n');

            % Load trained ANN model and predict action
            load('trainedANNModel.mat', 'net');
            predictedLabel = net(features'); 
            fprintf('Prediction completed. Predicted Label: %.2f\n', predictedLabel);

            % Send command based on prediction
            switch round(predictedLabel) 
                case 2 % Grip action
                    fprintf(s, 'G'); 
                    fprintf('Command sent: Grip\n');
                case 1 % Tripod action
                    fprintf(s, 'T'); 
                    fprintf('Command sent: Tripod\n');
                otherwise
                    fprintf(s, 'S'); 
                    fprintf('Command sent: Stop\n');
            end
            
            dataBuffer = []; % Clear buffer after processing
        end
        
    end
    
catch ME
    disp('Error occurred:');
    disp(ME.message);
end

clear s; % Close serial port at end of execution.

% Function to extract features from EMG signal
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

