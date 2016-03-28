classdef myfirstiteration < mySingleton
    
    methods (Static)
        function mybeads = runfirstiteration(myframe, mywindow, mymap, mybeads, mytracker, myloop)
            %the first detection
            framenum = 0;
            while (~mywindow.getdetect)
                framenum = framenum + 1;
                currentframe = myframe(framenum);
                mywindow.isDetection(currentframe);
            end
            
            %A bead is defined as 'alive' at a certain time if is present in
            %the current frame. Thus if the bead is visible, it definitely is 'alive',
            %However, there are also some tricky cases when a bead
            %'flickers' and disappears momentarily, but it still is, by our
            %definition, 'alive'. 
            
            %The first mapping:
            %1. initializing #new beads
            %2. initializing #alive beads
            %3. initializing alive beads index : This gives the indices of
            %beads that are 'alive'. 
            mymap.setnewbeadcount(size(mywindow.getcentroid,1));
            mymap.setbeadsalivecount(size(mywindow.getcentroid, 1));
            mymap.setaliveindex((1:mymap.getbeadsalivecount())');
            
            %We already have an empty array of bead objects. The idea is,
            %as we detect/track beads, we update the attributes of those
            %bead elements in the array. 
            beadPos = mywindow.getcentroid;
            beadcolorframe = getcolorMat(currentframe);
            for n = 1:mymap.getbeadsalivecount()
                mybeads(n) = mybeads(n).setframeIndex(framenum);
                mybeads(n) = mybeads(n).setcoordinate(beadPos(n,:), framenum);
                mybeads(n) = mybeads(n).setintensity(beadcolorframe(beadPos(n, 1), beadPos(n, 2), :), framenum);
                mybeads(n) = mybeads(n).setvelocity([0 -1], framenum);%#@EDITED March 29
            end
            
            %Updating total bead count in tracker
            %and tracking (predicting) the beads found so far
            mytracker.setbeadCount(mymap.getbeadsalivecount());
            nextframe = myframe(framenum+1);
            mytracker.track(mybeads, mymap, currentframe, nextframe);
            
            %Updating the value of first frame in myloop. This is the only
            %reason we had to instantiate the class myloop2M. It is a
            %terrible idea to do so, but because MATLAB doesn't have static
            %properties, this seemed to be the only way out. 
            %@@@ It would be great if this could be changed so that myloop
            %does not need to be instantiated. It does not make sense to
            %make an object just to do an iteration. 
            framenum = framenum + 1;
            myloop.setfirstframenum(framenum);
            
            %The above process is followed in all the following frames, but
            %there are additional functions that come into play (for
            %example, resolveFlicker, resolveFlash, etc)
        end
    end
end