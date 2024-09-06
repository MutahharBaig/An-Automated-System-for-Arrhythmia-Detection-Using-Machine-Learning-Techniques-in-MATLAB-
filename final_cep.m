% Define the filenames of the datasets
filenames = {'N1m.mat', 'N2m.mat', 'N3m.mat', 'N4M.mat', 'N5m.mat', ...
             'N6m.mat', 'N7m.mat', 'N8m.mat', 'N9m.mat',  'N10m.mat', 'B1m.mat', ...
             'B2m.mat', 'B3m.mat', 'B4m.mat','T1m.mat', 'T2m.mat', ...
             'T3m.mat', 'T4m.mat', 'T5m.mat', 'T7m.mat', ...
              'VT1m.mat', 'VT2m.mat', 'VT3m.mat'};

% Initialize arrays to store heart rates, arrhythmia detection results, and AV block detection results
heart_rates = zeros(1, numel(filenames));
arrhythmia_results = cell(1, numel(filenames));
av_block_results = cell(1, numel(filenames));

% Enable command window input to get heart rate, arrhythmia detection, and AV block detection for a specific dataset
while true
    dataset_number = input('Enter dataset number (1-27) or 0 to exit: ');
    if dataset_number == 0
        break;
    elseif dataset_number >= 1 && dataset_number <= numel(filenames)
        % Load the dataset
        load(filenames{dataset_number});
        
        % Plot Original ECG Waveform
        figure;
        subplot(5,2,1);
        plot(val(1,:));
        title('Original ECG Waveform');
        xlabel('Sample');
        ylabel('Amplitude');
        
        % Define the sampling frequency
        fs = 360; % Hz

        % Define the passband frequency range
        fpass = [5 15]; % Hz

        % Design the bandpass filter using butterworth filter
        order = 4; % Filter order
        [b_bandpass, a_bandpass] = butter(order, fpass/(fs/2), 'bandpass');

        % Apply the bandpass filter to the ECG signal (assuming MLII signal)
        filtered_MLII_bandpass = filtfilt(b_bandpass, a_bandpass, val(1,:)); % Apply zero-phase filtering

        % Plot Output of Band-pass Filter
        subplot(5,2,2);
        plot(filtered_MLII_bandpass);
        title('Output of Band-pass Filter');
        xlabel('Sample');
        ylabel('Amplitude');
        
        % Derivative filter coefficients
        b_diff = [1 -1]; % First-order difference

        % Apply the derivative filter to the filtered ECG signal
        ecg_derivative = filter(b_diff, 1, filtered_MLII_bandpass);

        % Plot Output of Derivative Filter
        subplot(5,2,3);
        plot(ecg_derivative);
        title('Output of Derivative Filter');
        xlabel('Sample');
        ylabel('Amplitude');

        % Apply squaring function to emphasize R peaks
        squared_ecg = ecg_derivative.^2;

        % Plot Output of Squaring Process
        subplot(5,2,4);
        plot(squared_ecg);
        title('Output of Squaring Process');
        xlabel('Sample');
        ylabel('Amplitude');

        % Define the threshold value for thresholding1
        threshold1 = 0.5 * max(squared_ecg); % Adjust threshold as needed

        % Thresholding to identify QRS peaks
        QRS_peaks_threshold1 = squared_ecg > threshold1;

        % Plot Output of Thresholding1 Process
        subplot(5,2,5);
        plot(QRS_peaks_threshold1);
        title('Output of Thresholding1 Process');
        xlabel('Sample');
        ylabel('Amplitude');

        % Define the window width (N) based on the sampling rate
        % For fs = 360Hz, N=30 might be a suitable value (adjust as needed)
        N = 30;

        % Apply moving average filter for moving window integration
        smoothed_ecg = movmean(QRS_peaks_threshold1, N);

        % Plot Output of Moving Window Integration Process
        subplot(5,2,6);
        plot(smoothed_ecg);
        title('Output of Moving Window Integration Process');
        xlabel('Sample');
        ylabel('Amplitude');

        % Define the threshold value for thresholding2
        threshold2 = 0.5; % Adjust threshold as needed

        % Thresholding to identify QRS peaks after smoothing
        QRS_peaks_threshold2 = smoothed_ecg > threshold2;

        % Plot Output of Thresholding2 Process
        subplot(5,2,7);
        plot(QRS_peaks_threshold2);
        title('Output of Thresholding2 Process');
        xlabel('Sample');
        ylabel('Amplitude');

        % Detect peaks at the rising edge of the smoothed QRS signal
        [~, peak_locations] = findpeaks(smoothed_ecg);

        % Initialize arrays to store QRS peak locations and values
        QRS_peak_locations = [];
        QRS_peak_values = [];

        % Iterate through the detected peaks and find the maximum amplitude within the window
        for j = 1:length(peak_locations)
            % Determine the start and end indices of the horizontal window
            window_start = max(1, peak_locations(j) - 20);
            window_end = min(length(val), peak_locations(j) + 20);

            % Extract the signal within the window
            window_signal = val(window_start:window_end);

            % Find the maximum amplitude within the window
            [max_amplitude, max_index] = max(window_signal);

            % Adjust the index to the global signal indices
            max_index_global = window_start + max_index - 1;

            % Store the location and value of the QRS peak
            QRS_peak_locations = [QRS_peak_locations max_index_global];
            QRS_peak_values = [QRS_peak_values max_amplitude];
        end

        % Plot ECG with detected QRS peak
        subplot(5,2,[8,10]);
        plot(val(1,:));
        hold on;
        plot(QRS_peak_locations, QRS_peak_values, 'ro', 'MarkerSize', 10);
        hold off;
        title('ECG with Detected QRS Peak');
        xlabel('Sample');
        ylabel('Amplitude');
        
        % Calculate the intervals between consecutive QRS peaks
        RR_intervals = diff(QRS_peak_locations);

        % Calculate the heart rate (beats per minute)
        heart_rate = 60 ./ (mean(RR_intervals) / fs); % fs is the sampling frequency

        % Store heart rate
        heart_rates(dataset_number) = heart_rate;

        % Define threshold values for arrhythmia detection (adjust as needed)
        tachycardia_threshold = 100; % bpm
        bradycardia_threshold = 60; % bpm

        % Detect arrhythmias based on heart rate
        if isnan(heart_rate)
            arrhythmia_results{dataset_number} = 'Asystole Detected';
        elseif heart_rate > tachycardia_threshold
            arrhythmia_results{dataset_number} = 'Tachycardia Detected';
        elseif heart_rate < bradycardia_threshold
            arrhythmia_results{dataset_number} = 'Bradycardia Detected';
        elseif heart_rate >= 140 && heart_rate <= 300
            arrhythmia_results{dataset_number} = 'Supraventricular Tachycardia';
        else
            arrhythmia_results{dataset_number} = 'Normal Heart Rate';
        end

        % Display heart rate and arrhythmia detection result
        fprintf('Dataset: %s\n', filenames{dataset_number});
        fprintf('Heart Rate: %.2f bpm\n', heart_rate);
        fprintf('%s\n', arrhythmia_results{dataset_number});
        fprintf('\n');
        
        % Feature extraction
        amplitude = max(QRS_peak_values); % Amplitude
        RR_value = mean(RR_intervals) / fs; % RR value (in seconds)
        speed = length(QRS_peak_locations) / (length(val) / fs) * 60; % Speed (beats per minute)
        
        % Save features to Excel file
        filename_excel = sprintf('Dataset_%d_features.xlsx', dataset_number);
        features = {'Amplitude', 'RR Value (s)', 'Speed (bpm)';
                    amplitude, RR_value, speed};
        xlswrite(filename_excel, features);
        fprintf('Features extracted and saved to %s\n', filename_excel);
    else
        fprintf('Invalid dataset number. Please enter a number between 1 and 27.\n');
    end
end
