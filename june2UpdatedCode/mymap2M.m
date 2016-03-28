classdef mymap2M < mySingleton
    
    properties (Access = 'private')
        currentframenum;
        oldBeadMapRadius;
        newbeadcount;
        beadsalivecount;
        aliveindex;
        aliveindexlen;
        oldbeadsupdate;
        newbeadsupdate;
        azkabanbeadsidx;
    end
    %%
    
    methods(Access='private')
        function obj = mymap2M(x)
            obj.currentframenum = 0;
            obj.oldBeadMapRadius = x;
            obj.newbeadcount = 0;
            obj.beadsalivecount = 0;
            obj.aliveindex = [];
            obj.aliveindexlen = 0;
            obj.oldbeadsupdate = [];
            obj.newbeadsupdate = [];
            obj.azkabanbeadsidx = [];
        end
    end
    
    methods(Static)
        function obj = instance(x)
            persistent uniqueInstance
            if isempty(uniqueInstance)
                obj = mymap2M(x);
                uniqueInstance = obj;
            else
                obj = uniqueInstance;
            end
        end
    end
    %%
    methods
        function a = getazkabanBeadsIdx(obj)
            a = obj.azkabanbeadsidx;
        end
        
        function setazkabanBeadsIdx(obj, a)
            obj.azkabanbeadsidx = a;
        end
        
        function o = getoldbeadsupdate(obj)
            o = obj.oldbeadsupdate;
        end
        
        function n = getnewbeadsupdate(obj)
            n = obj.newbeadsupdate;
        end
        
        function setoldbeadsupdate(obj, o)
            obj.oldbeadsupdate = o;
        end
        
        function setnewbeadsupdate(obj, n)
            obj.newbeadsupdate = n;
        end
        
        function newbeadcount = getnewbeadcount(obj)
            newbeadcount = obj.newbeadcount;
        end
        
        function setnewbeadcount(obj, newbeadcount)
            obj.newbeadcount = newbeadcount;
        end
        
        function ind = getaliveindex(obj, num)
            vec = obj.aliveindex;
            ind = vec(num);
        end
        
        function setaliveindex(obj, v)
            obj.aliveindex = v;
            obj.aliveindexlen = numel(v);
        end
        
        function l = getaliveindexlen(obj)
            l = obj.aliveindexlen;
        end
        
        function beadsalivecount = getbeadsalivecount(obj)
            beadsalivecount = obj.beadsalivecount;
        end
        
        function setbeadsalivecount(obj, beadsalivecount)
            obj.beadsalivecount = beadsalivecount;
        end
        
        function setcurrentframenum(obj, c)
            obj.currentframenum = c;
        end
        
        function c = getcurrentframenum(obj)
            c = obj.currentframenum;
        end
        
        %Mapping all beads, i.e., declaring detected beads as old or new.
        function mapbeads(obj, mywindow, mytracker, mybeads, resolveFlicker, resolveFlash)
            detCent = mywindow.getcentroid;
            pred = getpredictions(mytracker);
            if ~mywindow.getdetect
                %if there are no detections, #newbeads=0, #alivebeads=0,
                %all updates= [], aliveindex = [];
                %however there still remains work to be done! we need to
                %take care of the missing beads, the beads which went
                %missing a few frames ago and are still being 'tracked' by
                %resolveFlicker.m, and finally the beads which have been
                %found to be mere flashes of light which we discard.
                obj.setnewbeadcount(0);
                obj.beadsalivecount = 0;
                obj.aliveindex = [];
                obj.newbeadsupdate = [];
                obj.oldbeadsupdate = [];
                if ~isempty(pred)
                    %If there are no detections in/around positions where
                    %the tracker had predicted some beads to be, then
                    %either those beads are just 'flickering' or have
                    %completely gone. We shall resolve this issue in the
                    %object resolveFlicker.
                    missingInd = pred(:, 1);
                    missingPos = pred(:, 2:3);
                    for xk = numel(missingInd):-1:1
                        missingVel(xk, :) = mybeads(missingInd(xk)).getvelocity(obj.currentframenum - 1);
                    end
                    missingData = [missingInd missingPos missingVel];
                    %the following is an important step without which
                    %the previous predictions are used (as mytracker is
                    %a singleton object) and THAT is SEVERELY messed up.
                    % This is something that must be
                    %taken care of for all singleton objects
                    mytracker.setpredictions([]);
                    
                    %Assuming the missing beads to be simply 'flickering',
                    %we increment their positions in every frame, and when
                    %they've been missing for more than a certain #frames,
                    %we declare them gone.
                    resolveFlicker.predictReappearance(missingData);
                    
                    %After it has been decided that a bead has disappeared
                    %from the frame forever, we check the #frames it was
                    %visible in. If this is too small a number, we discard
                    %the bead, ie, declare it as a misdetection.
                    obj.azkabanbeadsidx = resolveFlash.getFlashBeadsIdx(resolveFlicker, mybeads, obj.currentframenum);
                else
                    %if there were no predictions in the first place, then
                    %we only need to concern ourselves with the state of
                    %the old missing beads and the beads that have been
                    %found to be simply flashes  of light. Don't bother
                    %with resetting tracker.predictions because it is
                    %already an empty matrix.
                    resolveFlicker.predictReappearance([]);
                    obj.azkabanbeadsidx = resolveFlash.getFlashBeadsIdx(resolveFlicker, mybeads, obj.currentframenum);
                end
            else
                if size(pred, 1) ~= 0
                    [rowP, rowD] = meshgrid(pred(:, 2), detCent(:, 1));
                    [colP, colD] = meshgrid(pred(:, 3), detCent(:, 2));
                    Z = (rowP-rowD).^2 + (colP-colD).^2;
                    if size(Z, 1)==1
                        Z = [Z; max(max(Z))*ones(1, numel(Z))];
                    end
                    [vals, detIndex] = min(sqrt(Z));
                    predIndex = vals<obj.oldBeadMapRadius;
                    uniqueDetIndex = unique(detIndex(predIndex));
                    
                    missingInd = pred((find(~predIndex))', 1) ;
                    if ~isempty(missingInd)
                        missingPos = pred((find(~predIndex))', 2:3);
                        for xk = numel(missingInd):-1:1
                            missingVel(xk, :) = mybeads(missingInd(xk)).getvelocity(obj.currentframenum - 1);
                        end
                        missingData = [missingInd missingPos missingVel];
                    else
                        missingData = [];
                    end
                    %As mentioned earlier, this resetting of the
                    %tracker.predictions is absolutely necessary; if it is
                    %not done, then past values may get carried over as it
                    %is a singleton object
                    mytracker.setpredictions([]);
                    
                    temp = ones(1, size(detCent, 1));
                    temp(uniqueDetIndex) = 0;
                    maybenewIndex = find(temp);
                    if ~isempty(maybenewIndex)
                        maybenewData = detCent(maybenewIndex', :);
                    else
                        maybenewData = [];
                    end
                    resolveFlicker.predictReappearance(missingData);
                    obj.azkabanbeadsidx = resolveFlash.getFlashBeadsIdx(resolveFlicker, mybeads, obj.currentframenum);
                    resolveFlicker.lookforData(maybenewData);%@EDITED March 13
                    
                    obj.setnewbeadcount(size(resolveFlicker.getnewdata, 1));
                    reappearedbeadsdata = resolveFlicker.getReappearedOldData;
                    obj.setbeadsalivecount(sum(predIndex) + obj.getnewbeadcount() + size(reappearedbeadsdata, 1));
                    if size(reappearedbeadsdata, 1)
                        obj.setaliveindex([pred((find(predIndex))', 1); reappearedbeadsdata(:, 1) ;(mytracker.getbeadCount()+1: mytracker.getbeadCount() + obj.getnewbeadcount)']);
                    else
                        obj.setaliveindex([pred((find(predIndex))',1); (mytracker.getbeadCount() + 1: mytracker.getbeadCount() + obj.getnewbeadcount)']);
                    end
                    
                    if sum(find(predIndex))
                        contOldBeads = pred((find(predIndex))',1);
                        for hh = numel(contOldBeads):-1:1
                            contOldPrevPos(hh,:) = mybeads(contOldBeads(hh)).getcoordinate(obj.currentframenum - 1);
                        end
                        contOldCurrPos = detCent((detIndex(predIndex))',:);
                        obj.oldbeadsupdate = [contOldBeads contOldCurrPos contOldCurrPos-contOldPrevPos; reappearedbeadsdata];
                    else
                        obj.oldbeadsupdate = reappearedbeadsdata;
                    end
                    
                    if obj.getnewbeadcount()
                        obj.newbeadsupdate = [(mytracker.getbeadCount() + 1: mytracker.getbeadCount() + obj.getnewbeadcount)' resolveFlicker.getnewdata];
                    else
                        obj.newbeadsupdate = [];
                    end
                else
                    %if detection, but no prediction:
                    %the old missing beads still need to be continued to be
                    %tracked, but since there's no missing data, the input
                    %argument is an empty matrix. Also, check for flashes
                    %and discard beads if required.
                    resolveFlicker.predictReappearance([]);
                    obj.azkabanbeadsidx = resolveFlash.getFlashBeadsIdx(resolveFlicker, mybeads, obj.currentframenum);
                    resolveFlicker.lookforData(detCent);%@EDITED March 13
                    
                    obj.oldbeadsupdate = resolveFlicker.getReappearedOldData; %old beads' indices, present positions and old velocities
                    %note: old velocities because with no previous
                    %positions, there is no way of obtaining the actual
                    %present velocities. so we simply use the old
                    %velocities we have as present vels.
                    otemp = obj.oldbeadsupdate;
                    if ~isempty(otemp)
                        oldbeadsaliveindex = otemp(:, 1);
                    else
                        oldbeadsaliveindex = [];
                    end
                    obj.newbeadcount = size(resolveFlicker.getnewdata, 1);
                    newbeadsindex = (mytracker.getbeadCount() + 1: mytracker.getbeadCount() + obj.getnewbeadcount)';
                    
                    obj.newbeadsupdate = [(mytracker.getbeadCount() + 1: mytracker.getbeadCount() + obj.getnewbeadcount)' resolveFlicker.getnewdata];
                    obj.beadsalivecount = obj.newbeadcount + numel(oldbeadsaliveindex);
                    obj.aliveindex = [oldbeadsaliveindex; newbeadsindex];
                end
            end
        end
        
    end
    
end

