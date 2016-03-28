classdef resolveflicker < mySingleton
    properties (Access = 'private')
        predictionTable;
        definitelyNewData;
        reappearedOldData;
        deadBeadsIdx;
        tolFlickerGap;
        lookforOldBeadRadius;
    end
    
    methods(Access='private')
        function obj = resolveflicker(x, y)
            obj.predictionTable = [];
            obj.definitelyNewData = [];
            obj.reappearedOldData = [];
            obj.deadBeadsIdx = [];
            obj.tolFlickerGap = x;
            obj.lookforOldBeadRadius  = y;
        end
    end
    
    methods(Static)
        function obj = instance(x, y)
            persistent uniqueInstance
            if isempty(uniqueInstance)
                obj = resolveflicker(x, y);
                uniqueInstance = obj;
            else
                obj = uniqueInstance;
            end
        end
    end
    
    methods
        function o = getReappearedOldData(obj)
            o = obj.reappearedOldData;
        end
        
        function setReappearedOldData(obj, r)
            obj.reappearedOldData = r;
        end
        
        function pT = getpredictionTable(obj)
            pT = obj.predictionTable;
        end
        
        function setpredictionTable(obj, pT)
            obj.predictionTable = pT;
        end
        
        function nD = getnewdata(obj)
            nD = obj.definitelyNewData;
        end
        
        function setnewdata(obj, nD)
            obj.definitelyNewData = nD;
        end
        
        function setdeadBeadsIdx(obj, s)
            obj.deadBeadsIdx = s;
        end
        
        function d = getdeadBeadsIdx(obj)
            d = obj.deadBeadsIdx;
        end
        
        function predictReappearance(obj, missingData)
            pT = getpredictionTable(obj);
            obj.deadBeadsIdx = [];
            if (~isempty(pT))
                pT(:, 6) = pT(:, 6) + 1;
                obj.deadBeadsIdx = pT(pT(:,6)>obj.tolFlickerGap, 1);
                pT((pT(:, 6)>obj.tolFlickerGap), :) = [];
                pT(:, 2:3) = pT(:, 2:3) + pT(:, 4:5);
            end
            if ~isempty(missingData)
                pT(end+1:end+size(missingData, 1),:) = [missingData zeros(size(missingData, 1), 1)];
            end
            obj.setpredictionTable(pT);
        end
        
        function lookforData(obj, maybenewData) %@EDITED March 13
            predData = getpredictionTable(obj);
            %@EDITED on February 21:
            % --> For the case of the big orange beads, the tail is very
            % big and therefore leads to false positives. We prevent
            % this by deleting any detections beyond a certain limit.
            %==> Actually we use this for all cases; it's just the
            %value of the detection limit that differs from video to
            %video
            %@EDITED March 13
            %This problem is being taken care of in window.m by having
            %sectional detetction thresholds. We do not need this guy,
            %in my opinion
            %             if ~isempty(maybenewData)
            %                 if currfrmnum>obj.framenumFromWhichToStartLimitingDetections
            %                     maybenewData(maybenewData(:,2)<obj.detectionLimiterLeft,:) = [];
            %                     maybenewData(maybenewData(:,2)>obj.detectionLimiterRight,:) = [];
            %                 end
            %             end
            if isempty(predData)
                %no prediction. some potential new beads.
                %all are new beads. no old beads. no change in the
                %prediction table other than what has already been done in
                %the earlier method.
                obj.definitelyNewData = maybenewData;
                obj.reappearedOldData = [];
            else
                %if there is some 'possibly new detection', check if it
                %matches with the missing beads being tracked. if there's a
                %match, it is a reappeared bead.
                if ~isempty(maybenewData)
                    [rowP, rowD] = meshgrid(predData(:, 2), maybenewData(:, 1));
                    [colP, colD] = meshgrid(predData(:, 3), maybenewData(:, 2));
                    Z = (rowP-rowD).^2 + (colP-colD).^2;
                    if size(Z, 1)== 1
                        Z = [Z; max(max(Z))*ones(1, numel(Z))];
                    end
                    [vals, detIndex] = min(sqrt(Z));
                    predIndex = vals<obj.lookforOldBeadRadius;
                    
                    if (~isempty(predIndex))
                        notNewData = predData(predIndex',1:5);
                        notNewData(:, 2:3) = maybenewData((detIndex(predIndex))',:);
                        predData(predIndex',:) = [];
                        obj.reappearedOldData = notNewData;
                        uniqueDetIndex = unique(detIndex(predIndex));
                        maybenewData(uniqueDetIndex',:) = [];
                    else
                        obj.reappearedOldData = [];
                    end
                    %reset the prediction table
                    setpredictionTable(obj, predData);
                    obj.definitelyNewData = maybenewData;
                else
                    %no new data, no predictions.
                    obj.definitelyNewData = maybenewData;
                    obj.reappearedOldData = [];
                end
            end
        end
        
        
    end
end

