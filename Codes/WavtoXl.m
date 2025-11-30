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

    % Initialize Excel application outside the loop
    excelApp = actxserver('Excel.Application'); % Start Excel application
    excelApp.Visible = false; % Make Excel invisible (set to true to see it)

    % Loop through each file
    for i = 1:length(filenames)
        filename = fullfile(path, filenames{i}); % Get the full path of the current filename

        % Read the WAV file
        [y, Fs] = audioread(filename); % y is the audio data, Fs is the sample rate

        % Create a time vector based on the length of y and sample rate Fs
        t = (0:length(y)-1) / Fs;

        % Prepare data for Excel
        % If stereo, use only one channel (e.g., left channel)
        if size(y, 2) == 2
            y = y(:, 1); % Select first channel
        end

        data = table(t', y); % Create a table with time and amplitude

        % Generate output filename by replacing .wav with .xlsx
        [~, name, ~] = fileparts(filenames{i}); % Get the base name without extension
        outputFilename = fullfile(path, [name '.xlsx']); % Create output filename with full path

        % Write to Excel
        writetable(data, outputFilename); % Write table to Excel

        % Open Excel and add custom headers
        try
            workbook = excelApp.Workbooks.Open(outputFilename); % Open the workbook
            sheet = workbook.Sheets.Item(1); % Select the first sheet

            % Add filename in A1 and merge A1 and B1
            sheet.Range('A1:B1').Merge(); % Merge cells A1 and B1
            sheet.Range('A1').Value = name;  % Add filename without prefix

            % Add custom axis labels in specific cells
            sheet.Range('A2').Value = 'Time in seconds';  % X-axis label
            sheet.Range('B2').Value = 'Amplitude value';  % Y-axis label

            % Save changes and close workbook
            workbook.Save(); 
            workbook.Close(false); 

        catch ME
            disp(['An error occurred while accessing Excel for ' name ':']);
            disp(ME.message);
        end

    end

    % Quit Excel application after processing all files
    excelApp.Quit();
    delete(excelApp); % Clean up COM server

    disp('Data written to Excel files with custom axis labels and filenames for all specified WAV files.');
end