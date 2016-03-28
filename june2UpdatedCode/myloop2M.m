classdef myloop2M < mySingleton
    %%
    properties (Access = 'private')
        firstframenum;
        assumedInitVelForNewBeads = [0 -1];  %@EDITED March 29
    end
    %%
    %The constructor method for this class. This is the way we get around
    %MATLAB's no-static-attributes-policy. We create a singleton object, so
    %we have only one instance of it in our workspace. 
    methods(Access='private')
        function obj = myloop2M()
            obj.firstframenum = 0;
        end
    end
    
    methods (Static)
        function obj = instance()
            persistent uniqueInstance
            if isempty(uniqueInstance)
                obj = myloop2M();
                uniqueInstance = obj;
            else
                obj = uniqueInstance;
            end
        end
    end
    %%
    methods
        function setfirstframenum(obj, framenum)
            obj.firstframenum = framenum;
        end
        
        function f= getfirstframenum(obj)
            f = obj.firstframenum;
        end
        
        %The flowchart for the tracking code:
        function mybeads = allTogetherNow(obj, myframe, mywindow, mymap, mybeads, mytracker, resolveflicker, resolvetwins, resolveflash)
            
            for framenum = obj.firstframenum : numel(myframe)-1
                %@ EDITED on Feb 2
                %--> For the purpose of debugging stop the loop at the
                %suspected frame and examine all values.
                %currentframe and nextframe
                currentframe = myframe(framenum);
                nextframe = myframe(framenum+1);
                
                %detection
                mywindow.isDetection(currentframe);
                
                %Mapping old beads and identifying new ones from 
                %detections in the present frame and predictions from
                %the past frame. 
                %There are several cases to be taken into consideration
                %when mapping the detected beads. 
                %1. Detection at predicted position: Simply update old
                %bead.
                %2. No detection at predicted position: Old bead could be
                %either 'flickering' or gone from the frame. To confirm
                %this, pass it to the resolveflicker object. 
                %3. Detection at position not predicted by tracker
                %previously: Either a new bead or an old bead showing up
                %while flickering
                %4. Other cases: 
                %4a. Incorrect detection: Sometimes due to non-uniform
                %intensity, two or more points in the same bead get
                %detected leading to overcounting of beads. To get around
                %this, we use the fact that after a few frames (typically
                %3-5) this gets corrected and now we have only one bright
                %spot in the bead. So all the extra beads we had counted
                %have the exact same position/vel/intensity this frame
                %onward. When we detect this, we simply discard all the
                %extra beads. 
                %4b. Overlapping beads: All the beads we have in our video
                %have different velocities. It is therefore inevitable that
                %they overlap during the course of the video. They
                %therefore have the same vel/int/pos for a couple of
                %frames, and because of the way the tracking code works,
                %this leads to those beads getting stuck together
                %throughout all the frames. To avoid this, we search the
                %neighbourhood of beads that are sticking together, and
                %when there's a new detection nearby, we assign the new
                %position to one of the overlapping beads. Works like a
                %motherfucking charm. 
                %5. Post-processing: To be on the safe side, we also discard 
                %all beads which appear in fewer than 2-3 frames. 
               
                mymap.setcurrentframenum(framenum);
                mymap.mapbeads(mywindow, mytracker, mybeads, resolveflicker, resolveflash);
                %the beads that need to be discarded because upon mapping
                %it was found that they were actually just flickering for a
                %few frames/points in the tail incorrectly detected as new
                %beads/whatever other shit is possible in the world
                dem = mymap.getazkabanBeadsIdx; 
                for az = 1:numel(dem)
                    mybeads(dem(az)) = mybeads(dem(az)).setframeIndex(0);
                end
                resolvetwins.findTwins(mymap, mybeads);
                resolvetwins.classifyTwins(mybeads, mymap);
                mybeads = resolvetwins.resolveDetectionErrors(mybeads, mymap);
                %@ EDITED on Feb 26.
                %--> the frame number is needed
                %==> it now works
                resolvetwins.resolveOverlapErrors(mymap, mybeads, framenum);
                %%
                oldBeadsUpdate = mymap.getoldbeadsupdate; 
                newBeadsUpdate = mymap.getnewbeadsupdate; 
                beadcolorframe = getcolorMat(currentframe);
                
                %updating the properties of the alive beads
                if mymap.getbeadsalivecount()
                    if (~isempty(oldBeadsUpdate))
                        for o = 1:size(oldBeadsUpdate,1)
                            mybeads(oldBeadsUpdate(o, 1)) = mybeads(oldBeadsUpdate(o, 1)).setcoordinate(oldBeadsUpdate(o, 2:3), framenum);
                            mybeads(oldBeadsUpdate(o, 1)) = mybeads(oldBeadsUpdate(o, 1)).setintensity(beadcolorframe(oldBeadsUpdate(o, 2), oldBeadsUpdate(o, 3), :), framenum);
                            
                            mybeads(oldBeadsUpdate(o, 1)) = mybeads(oldBeadsUpdate(o, 1)).setvelocity(oldBeadsUpdate(o, 4:5), framenum);
                        end
                    end
                    if ~isempty(newBeadsUpdate)
                        for n = 1:size(newBeadsUpdate, 1)
                            mybeads(newBeadsUpdate(n, 1)) = mybeads(newBeadsUpdate(n, 1)).setframeIndex(framenum);
                            mybeads(newBeadsUpdate(n, 1)) = mybeads(newBeadsUpdate(n, 1)).setcoordinate(newBeadsUpdate(n, 2:3), framenum);
                            mybeads(newBeadsUpdate(n, 1)) = mybeads(newBeadsUpdate(n, 1)).setintensity(beadcolorframe(newBeadsUpdate(n, 2), newBeadsUpdate(n, 3), :), framenum);
                            
                            mybeads(newBeadsUpdate(n, 1)) = mybeads(newBeadsUpdate(n, 1)).setvelocity(obj.assumedInitVelForNewBeads, framenum);
                        end
                    end
                end
                
                %%
                %setting the tentative bead count and tracking the alive beads
                mytracker.setbeadCount(mytracker.getbeadCount() + mymap.getnewbeadcount());
                if mymap.getbeadsalivecount~=0
                    mytracker.track(mybeads, mymap, currentframe, nextframe);
                end
            end
            %Change the tracker count. After removing beads which appeared
            %for only a few frames, we now reset the indices of all beads
            %that we have 
            tempbeadcount = 0;
            for b = 1:numel(mybeads)%@EDITED March 13
                if mybeads(b).getframeIndex
                    tempbeadcount = tempbeadcount + 1;
                end
            end
            mytracker.setbeadCount(tempbeadcount);
        end
    end
end
