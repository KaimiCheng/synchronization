function [ pilotEndOffsets ] = FindPilot( signalBuff, preambleChirp, singlechannel)

% 20/05/08: this function briefly showed if pilot is found successfully with reference to [24]

% pilotEndOffset is the end sample offset of last pilot signal；
% the sensing data starts from the first sample after pilotEndOffset+endoffset(if has) in the signalBuff
%  signalBuff= all preamble signals+enough sensing signals

    pilotChirp = preambleChirp; % 500 sample chirp signal as the pilot
    PILOT_CHANNEL =singlechannel; %=1
    PILOT_SEARCH_PEAK_WINDOW = 30;
    PILOT_REPEAT_NUM = 10;    
    PILOT_REPEAT_UNIT = 1000;  %500 sample chirp signal+500 sample '0'
    PILOT_LOCK_WINDOW_HALF_SIZE = floor(PILOT_REPEAT_UNIT*PILOT_REPEAT_NUM*1.2/2)
    
    pilotAll = repmat([pilotChirp;zeros(PILOT_REPEAT_UNIT-length(pilotChirp), 1)], [PILOT_REPEAT_NUM, 1]); % pilot =(500 sample chirp signal+500 sample '0')*10
    
    pilotEndOffsets = zeros(PILOT_CHANNEL, 1);%pilotEndOffsets=0 when PILOT_CHANNEL=1
    
    for chToSearchIdx = 1:PILOT_CHANNEL,
      %  chIdx = chToSearchIdx;
        signal = signalBuff; 
        
        xcorrBuff = abs(conv(signal, pilotAll(end:-1:1), 'same')); % do cross-correlation between the signalBuff and the pilot
        
        [~, maxIdx] = max(xcorrBuff) % get the max ID
        
        % lock the serach signal only to limited size
        xcorrLimiStart = max(1, maxIdx-PILOT_LOCK_WINDOW_HALF_SIZE)
        signal = signal(xcorrLimiStart:min(maxIdx+PILOT_LOCK_WINDOW_HALF_SIZE, length(signal)));
        
        xcorrResult = abs(conv(signal, pilotChirp(end:-1:1), 'same')); % do cross-correlation 
        
        % now start to search best theshold until get the matched result
        corMean = mean(xcorrResult);
        corStd = std(xcorrResult);
        
        THRES_MIN = 5;
        THRES_MAX = 15;
        
        thresPrevMin = THRES_MIN;
        thresPrevMax = THRES_MAX;
        thres = 10; % number of std added
        
        % binary search the matched result
        MAX_FOR_LOOP_FOR_SEARCH = 20;
        Match = 0;
        for searchIdx = 1:MAX_FOR_LOOP_FOR_SEARCH,
            peakIdxValid = GetPilotPeaks( xcorrResult, corMean + thres*corStd,  PILOT_SEARCH_PEAK_WINDOW);
            if length(peakIdxValid) ~= PILOT_REPEAT_NUM,
                fprintf('[WARN]: pilotChirp repeat num not matches at search %d\n', searchIdx);
               
                if length(peakIdxValid)>=PILOT_REPEAT_NUM, % thres is too low -> so there is too many peaks
                    thresPrevMin = thres;
                    thres = (thresPrevMax+thres)/2;
                else
                    thresPrevMax = thres;
                    thres = (thresPrevMin+thres)/2;
                end
            else
                pilotDiffer = peakIdxValid(2:end) - peakIdxValid(1:end-1)
                if sum(pilotDiffer == PILOT_REPEAT_UNIT)<5, % lose mode       
                    fprintf(2, '[WARN]: pilotChirp repeat unit not matches -> go random search\n');
                    if randi(2) == 1,
                        thresPrevMin = thres;
                        thres = (thresPrevMax+thres)/2;
                    else
                        thresPrevMax = thres;
                        thres = (thresPrevMin+thres)/2;
                    end
                else % pilotChirp matches           
                    Match = 1;              
                    break;
                end
            end
        end     
        if Match == 1,     
            pilotEndOffsets(chToSearchIdx) = xcorrLimiStart -1+ peakIdxValid(end) - floor(length(pilotChirp)/2) + PILOT_REPEAT_UNIT           
        else
            fprintf(2,'[ERROR]: unable to find valid pilotChirp at chIdx = %d\n',chIdx);          
            pilotEndOffsets(chToSearchIdx) = -1;      
        end
    end
        
end

