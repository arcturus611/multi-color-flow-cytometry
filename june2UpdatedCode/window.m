classdef window < mySingleton
    
    properties (Constant)
        winSize = 15;
        leftEdge = .1;
        rightEdge = 100;
        %@EDITED on March 7
        %We want different thresholds for different sections of the frame.
        %We define the sections by this partition vector
        %@EDITED on Feb 20:
        %-->50 : g10calibg10o15, 50 : g10r10, 150/> : g10o15
        %--> Some videos have beads with big tails/halo of light around
        %them. To minimize false detections in such cases, we RAISE the
        %threshold of detection so that only the brightest center of the
        %bead gets detected and not the other crap around it.
    end
    
    properties (Access = 'private')
        centroid;
        detect;
        
        topEdge;
        bottomEdge;
        detThresLims;
        detThres;
    end
    %The constructor method for this class. This is the way we get around
    %MATLAB's no-static-attributes-policy. We create a singleton object, so
    %we have only one instance of it in our workspace.
    
    methods(Access='private')
        function obj = window(topedge, bottomedge, detthreslims, detthres)
            obj.detect = 0;
            obj.centroid = [];
            obj.topEdge = topedge;
            obj.bottomEdge = bottomedge; 
            obj.detThresLims = detthreslims;%Points along frame (in terms of percentage of entire length) where there's partitioning
            obj.detThres = detthres; %numel(detThres)= numel(detThresLims) + 1 ... ALWAYS
        end
    end
    
    methods(Static)
        function obj = instance(topedge, bottomedge, detthreslims, detthres)
            persistent uniqueInstance
            if isempty(uniqueInstance)
                obj = window(topedge, bottomedge, detthreslims, detthres);
                uniqueInstance = obj;
            else
                obj = uniqueInstance;
            end
        end
    end
    
    methods
        function centroid = getcentroid(obj)
            centroid = obj.centroid;
        end
        
        function setcentroid(obj, centroid)
            obj.centroid = centroid;
        end
        
        function detect = getdetect(obj)
            detect = obj.detect;
        end
        
        function setdetect(obj, detect)
            obj.detect = detect;
        end
        
        function isDetection(obj, frame)
            colormat = getcolorMat(frame);
            upperLim = ceil(size(colormat, 1)*obj.topEdge/100); lowerLim = ceil(size(colormat, 1)*obj.bottomEdge/100);
            leftLim = ceil(size(colormat, 2)*obj.leftEdge/100); rightLim = ceil(size(colormat,2)*obj.rightEdge/100); 
            colorwin = colormat(upperLim:lowerLim, leftLim:rightLim,:);
            
            R = colorwin(:, :, 1); G = colorwin(:, :, 2); B = colorwin(:, :, 3);
            H = R+G+B; %sum of three channels is a measure of brightness
            %@EDITED March 7, 2012
            %sectional thresholding to avoid false detections in tails
            if ~isempty(obj.detThresLims)
                markerCols = [1 ceil(size(H,2)*obj.detThresLims/100) size(H,2)];
                for markerColIdx= 1:numel(markerCols)-1
                    Htemp = H(:, markerCols(markerColIdx):markerCols(markerColIdx+1));
                    Htemp(Htemp<obj.detThres(markerColIdx)) = 0;
                    H(:, markerCols(markerColIdx): markerCols(markerColIdx+1)) = Htemp;
                end
            else
                H(H<obj.detThres) = 0;
            end
            %@EDIT ends
            %@EDITED: March 6, 2012
            %dilation to make broken detections continuous
            H = imdilate(H, strel('disk', 1));
            
            %@EDIT ends
            CC = bwconncomp(H);
            CS = regionprops(CC, 'Centroid');
            if ~isempty(CS)
                for l = numel(CS):-1:1
                    locs(l, :) = round(CS(l).Centroid);
                end
            else
                locs = [];
            end
            
            obj.setdetect(~isempty(locs));
            if obj.getdetect
                setcentroid(obj, [locs(:, 2) + upperLim - 1, locs(:, 1) + leftLim - 1]);
            else setcentroid(obj, []);
            end
        end
    end
end

