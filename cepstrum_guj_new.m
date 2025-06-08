function cepstralAnalysisApp
    % Create the GUI figure
    f = figure('Name', 'Cepstral Analysis App', ...
        'Position', [100 100 1000 600]);

    % UI components
    uicontrol('Style', 'pushbutton', 'String', 'Load Audio', ...
        'Position', [20 550 100 30], 'Callback', @loadAudioCallback);

    uicontrol('Style', 'text', 'Position', [150 555 80 20], ...
        'String', 'Lifter Type:');
    lifterPopup = uicontrol('Style', 'popupmenu', ...
        'String', {'None','Low-pass','High-pass'}, ...
        'Position', [230 550 100 30]);

    uicontrol('Style', 'text', 'Position', [350 555 80 20], ...
        'String', 'Cutoff:');
    cutoffSlider = uicontrol('Style', 'slider', ...
        'Position', [420 550 150 30], 'Min', 1, 'Max', 200, ...
        'Value', 40);

    uicontrol('Style', 'text', 'Position', [600 555 100 20], ...
        'String', 'Cepstrum Type:');
    cepstrumTypePopup = uicontrol('Style', 'popupmenu', ...
        'String', {'Power Cepstrum','Complex Cepstrum'}, ...
        'Position', [700 550 150 30]);

    uicontrol('Style', 'pushbutton', 'String', 'Compute Cepstrum', ...
        'Position', [870 550 100 30], 'Callback', @computeCepstrumCallback);

    % Axes
    waveformAx = axes('Parent', f, 'Position', [0.07 0.6 0.4 0.3]);
    spectroAx = axes('Parent', f, 'Position', [0.57 0.6 0.4 0.3]);
    cepstrumAx = axes('Parent', f, 'Position', [0.07 0.1 0.9 0.35]);

    % Store audio data
    audioData = [];
    fs = 0;

    % --- Callbacks ---
    function loadAudioCallback(~, ~)
        [file, path] = uigetfile('*.mat', 'Select a MAT file');
        if isequal(file, 0)
            return;
        end
        data = load(fullfile(path, file)); % Load the .mat file

        if isfield(data, 'signal') && isfield(data, 'fs')
            audioData = data.signal;
            fs = data.fs;
        else
            msgbox('MAT file must contain "signal" and "fs" variables.');
            return;
        end

        if isrow(audioData)
            audioData = audioData';
        end

        % Plot waveform
        t = (0:length(audioData)-1)/fs;
        plot(waveformAx, t, audioData);
        title(waveformAx, 'Waveform'); xlabel(waveformAx, 'Time (s)');
        ylabel(waveformAx, 'Amplitude');

        % Plot spectrogram
        axes(spectroAx);
        spectrogram(audioData, hamming(256), 200, 512, fs, 'yaxis');
        title('Spectrogram');
    end

    function computeCepstrumCallback(~, ~)
        if isempty(audioData)
            msgbox('Please load an audio file first!');
            return;
        end

        y = audioData;
        N = length(y);
        q = (0:N-1)/fs;

        % Get cepstrum type
        cepstrumType = cepstrumTypePopup.String{cepstrumTypePopup.Value};
        switch cepstrumType
            case 'Power Cepstrum'
                Y = fft(y);
                ceps = abs(ifft(log(abs(Y).^2 + eps)));  

            case 'Complex Cepstrum'
                Y = fft(y);
                ceps = real(ifft(log(Y + eps)));         
        end

        % Get liftering options
        lifterTypeStr = lifterPopup.String{lifterPopup.Value};
        cutoff = round(cutoffSlider.Value);
        switch lifterTypeStr
            case 'Low-pass'
                lifter = zeros(size(ceps));
                lifter(1:cutoff) = 1;
                ceps = ceps .* lifter;
            case 'High-pass'
                lifter = ones(size(ceps));
                lifter(1:cutoff) = 0;
                ceps = ceps .* lifter;
        end

        % Plot cepstrum
        plot(cepstrumAx, q, abs(ceps));
        title(cepstrumAx, ['Cepstrum - ', cepstrumType, ' | ', lifterTypeStr]);
        xlabel(cepstrumAx, 'Quefrency (s)');
        ylabel(cepstrumAx, 'Magnitude');
        xlim(cepstrumAx, [0 0.02]); % Zoom in to typical pitch range
    end
end