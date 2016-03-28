classdef resolveTwins < mySingleton
    
    properties (Constant)
        
        detectionErrorFlag = 1;
        overlapErrorFlag = 2;

        %75 for g10o15, 100 for g10r10
        %this seems like a large number, but I think it is fine.
        %the number of past frames we will check
        %to classify the twins into some overlap category
    end
    
    properties (Access = 'private')
        twins
        twinErrorClass
        numPastFrames 
        overlappingBeadsSearchRadius 
    end
    
    %%
    
    methods(Access='private')
        function obj = resolveTwins(x, y)
            obj.twins = [];
            obj.twinErrorClass = [];
            obj.numPastFrames = x;
            obj.overlappingBeadsSearchRadius = y;
        end
    end
    
    methods(Static)
        function obj = instance(x, y)
            persistent uniqueInstance
            if isempty(uniqueInstance)
                obj = resolveTwins(x, y);
                uniqueInstance = obj;
            else
                obj = uniqueInstance;
            end
        end
    end
    
    %%
    methods
        function t = gettwins(obj)
            t = obj.twins;
        end
        
        function te = gettwinerrorclass(obj)
            te = obj.twinErrorClass;
        end
        
        function findTwins(obj, mymap, mybeads)
            mymap.getcurrentframenum
            oldData = mymap.getoldbeadsupdate;
            newData = mymap.getnewbeadsupdate;
            updatedData = [];
            if (~isempty(oldData))
                updatedData = oldData(:, 1:3);
            end
            if ~isempty(newData)
                updatedData = [updatedData; newData(:, 1:3)];
            end
            if ~isempty(updatedData)
                allPos = updatedData(:, 2:3);
                [uniPos, ~, n] = unique(allPos, 'rows');
                repPos = uniPos(accumarray(n, 1)>1, :);
                if ~isempty(repPos)
                    allIdx = updatedData(:, 1);
                    twinsIdx = zeros(size(repPos, 1), 2);
                    for i = 1:size(repPos,1)
                        locIdx = ismember(allPos, repPos(i,:), 'rows');
                        if sum(locIdx)>2
                            nTuplesIdx = allIdx(locIdx);
                            nTupleBeadsHistLen = zeros(numel(nTuplesIdx),1);
                            for k = 1:numel(nTuplesIdx)
                                nTupleBeadsHistLen(k) = mybeads(nTuplesIdx(k)).getframeIndex;
                            end
                            [~,ind1] = sort(nTupleBeadsHistLen, 'descend');
                            [twinsIdx(i,1), ~] = find(allIdx == nTuplesIdx(ind1(1)));
                            [twinsIdx(i,2), ~] = find(allIdx == nTuplesIdx(ind1(2)));
                        else
                            twinsIdx(i,:) = (find(locIdx))';
                        end
                    end
                    
                    if size(twinsIdx,1) == 1
                        obj.twins = (allIdx(twinsIdx))';
                    else
                        obj.twins = allIdx(twinsIdx);
                    end
                else
                    obj.twins = [];
                end
            else
                obj.twins = [];
            end
            
        end
        
        function classifyTwins(obj, mybeads, mymap)
            twinsIdx = obj.twins;
            currframenum = mymap.getcurrentframenum;
            if ~isempty(twinsIdx)
                errorClass = [twinsIdx zeros(size(twinsIdx, 1), 1)];
                for i = 1:size(twinsIdx, 1)
                    b1 = twinsIdx(i, 1); b2 = twinsIdx(i, 2);
                    b1_frameIdx = mybeads(b1).getframeIndex; b2_frameIdx = mybeads(b2).getframeIndex;
                    if ( (abs(b1_frameIdx - currframenum)<obj.numPastFrames) ||  (abs(b2_frameIdx-currframenum)<obj.numPastFrames))
                        errorClass(i,3) = obj.detectionErrorFlag;
                    else
                        errorClass(i,3) = obj.overlapErrorFlag;
                    end
                end
                obj.twinErrorClass = errorClass;
            else
                obj.twinErrorClass = [];
            end
        end
        
        function mybeads = resolveDetectionErrors(obj, mybeads, mymap)
            errClass = obj.twinErrorClass;
            if ~isempty(errClass)
                errDetTwinsIdx =  errClass(errClass(:, 3)==obj.detectionErrorFlag, 1:2);
                if ~isempty(errDetTwinsIdx)
                    errDetBeadsIdx = zeros(size(errDetTwinsIdx, 1), 1);
                    for i = 1:size(errDetTwinsIdx, 1)
                        f1 = mybeads(errDetTwinsIdx(i, 1)).getframeIndex; f2 = mybeads(errDetTwinsIdx(i, 2)).getframeIndex;
                        [~, ind] = max([f1 f2]); %greater frame index => more recent => more likely to be the incorrect detection
                        errDetBeadsIdx(i) = errDetTwinsIdx(i, ind);
                        mybeads(errDetBeadsIdx(i)) = mybeads(errDetBeadsIdx(i)).setframeIndex(0);
                    end
                    mymap.setbeadsalivecount(mymap.getbeadsalivecount - numel(errDetBeadsIdx));
                    
                    tempA = mymap.getaliveindex(1:mymap.getaliveindexlen);
                    if ~isempty(tempA)
                        tempA(ismember(tempA, errDetBeadsIdx)) = [];
                        mymap.setaliveindex(tempA);
                    end
                    
                    tempO = mymap.getoldbeadsupdate;
                    if ~isempty(tempO)
                        tempO(ismember(tempO(:, 1), errDetBeadsIdx, 'rows'), :) = [];
                        mymap.setoldbeadsupdate(tempO);
                    end
                    
                    tempN = mymap.getnewbeadsupdate();
                    if ~isempty(tempN)
                        tempN(ismember(tempN(:, 1), errDetBeadsIdx, 'rows'), :) = [];
                        mymap.setnewbeadsupdate(tempN);
                    end
                    
                    mymap.setnewbeadcount(size(mymap.getnewbeadsupdate, 1));
                end
            end
        end
        
        function resolveOverlapErrors(obj, mymap, mybeads, currfrmnum)
            errClass = obj.twinErrorClass;
            
            if ~isempty(errClass)
                overlappingTwinsIdx = errClass(errClass(:, 3)== obj.overlapErrorFlag, 1:2);
                if ~isempty(overlappingTwinsIdx)
                    overlappingBeadsIdx = overlappingTwinsIdx(:, 2);
                    ovPos = zeros(numel(overlappingBeadsIdx), 2);
                    oldPosSoFar = mymap.getoldbeadsupdate;
                    for oo = 1:size(ovPos, 1)
                        ovPos(oo,:) = oldPosSoFar(oldPosSoFar(:,1)==overlappingBeadsIdx(oo), 2:3);
                    end
                    %this is an entirely arbitrary choice. Why is it justified?
                    %because the twins are identical in every respect and both
                    %have had several frames behind them, it is justified to
                    %assign the new (separate) position to either one
                    %of them. Whether bead#x goes to the new position
                    %or bead#y goes to it is irrelevant.
                    tempN = mymap.getnewbeadsupdate; 
                    if ~isempty(tempN)
                        %if there ARE overlapping beads close enough to
                        %'newly detected beads', then mymap and mybeads
                        %both will have to be updated
                        newPos = tempN(:, 2:3);
                        
                        [rO, rN] = meshgrid(ovPos(:, 1), newPos(:, 1));
                        [cO, cN] = meshgrid(ovPos(:, 2), newPos(:, 2));
                        Zon = sqrt((rO-rN).^2 + (cO-cN).^2); %size(Zon) = #new beads by #ov beads chosen for correction
                        if size(Zon, 1)==1 %if Zon has only one row,
                            %there will be confusion later when we try
                            %finding the minimum. 'confusion' because
                            %MATLAB gives the row# when we deal with
                            %matrices, but the element# when dealing with
                            %vectors. 
                            Zon = [Zon; (max(Zon))*ones(1, numel(Zon))];
                        end
                        
                        [vz, idxz] = min(Zon); %idx gives the row# of 
                        %newPos containing the position of the 'new bead'
                        %which we shall assign to the overlapping bead idx of
                        %that column. 
                        %however, we do this only for those cases where the
                        %dist is less than a pre-decided search radius. 
                        idxOvToNew = overlappingBeadsIdx(vz<obj.overlappingBeadsSearchRadius);
                        idxNewToOv = idxz(vz<obj.overlappingBeadsSearchRadius); 
                        
                        %we are now ready to change oldbeadsupdate and
                        %newbeadsupdate
                        %if an ov bead is close enough to a 'new bead',
                        %then and only then will there be a change in
                        %mymap.oldbeadsupdate and mymap.newbeadsupdate
                        if vz<obj.overlappingBeadsSearchRadius
                            tempO = mymap.getoldbeadsupdate; 
                            %locate the rows with first col vals = vals of
                            %idxOvToNew. 
                            for zz = 1:numel(idxOvToNew)
                                tempO(tempO(:,1) == idxOvToNew(zz), 2:3) = tempN(idxNewToOv(zz), 2:3);
                                tempO(tempO(:,1) == idxOvToNew(zz), 4:5) = tempN(idxNewToOv(zz), 2:3) - mybeads(idxOvToNew(zz)).getcoordinate(currfrmnum-1); %[0 -3] %#@ CHANGES ON FEBRUARY 26
                            end
                            mymap.setoldbeadsupdate(tempO);
                            
                            %@ CHANGES MADE ON FEB 20
                            %@
                            firstNewBeadIdx = min(tempN(:,1)); 
                            tempN(idxNewToOv, :) = [];
                            tempN(:,1) = (firstNewBeadIdx:firstNewBeadIdx + size(tempN, 1) - 1)';
                            mymap.setnewbeadsupdate(tempN);
                            %@
                            %changing aliveindex: (these steps must be done
                            %carefully, in a proper order)
                            tempA = mymap.getaliveindex(1:mymap.getaliveindexlen);
                            tempA(end:-1:end-mymap.getnewbeadcount+1) = [];
                            %@
                            tempA = [tempA; tempN(:, 1)];
                            %@
                            mymap.setaliveindex(tempA);
                            
                            mymap.setnewbeadcount(size(tempN, 1));
                            mymap.setbeadsalivecount(mymap.getbeadsalivecount - numel(idxNewToOv));
                            
                        end
                        
                    end
                end
            end 
            
        end %end function
        
        
    end
    
end

