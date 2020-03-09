function [ peakIdxValid ] = GetPilotPeaks( xcorrResult, threshold, window )
% 20/05/08: this function briefly showed the peak detection idea in the reference [24]
% the function returns the indexs of the peaks
    
    peaks = xcorrResult > threshold;
    peakIdxAll = find(peaks>0);
    
    peakIdxValid = [];
    peakIdxValid_n = 0;
    i = 1;
   
    while i <= length(peakIdxAll),
        peakIdx= peakIdxAll(i); 
        idxSetInWindow = find(peakIdxAll - peakIdx>= 0 & peakIdxAll - peakIdx< window );
        
        % put the ID of the selected maxPeak in  peakIdxValid
        [~,maxPeaki] = max(xcorrResult(peakIdxAll(idxSetInWindow)));
        
        peakIdxValid_n = peakIdxValid_n+1;
        peakIdxValid(peakIdxValid_n) = peakIdxAll(idxSetInWindow(maxPeaki));
        
        
      %   CHECK_RATIO = 2;
        %idxRangeCheck = find(peakIdxAll - idxNow >= 0 & peakIdxAll - idxNow < CHECK_RATIO*window );
       % if length(idxRangeCheck) > length(idxSetInWindow),
         %   fprintf('[WARN]: find additioanl peaks outside the window at %d (need a large window?)\n', maxPeaki)
        %end
        
        % update i
        i = i + length(idxSetInWindow);
    end

    
end

