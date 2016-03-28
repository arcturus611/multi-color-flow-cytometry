%script to get information from the processed video:
%1. Flow rate
%2. Velocities of beads
%March 10. Works.
%EDITED on March 26/27
classdef getflowresults < mySingleton
    methods(Static)
        function getflowrate(sampledData, sampleTypeIdx, myBeads, myFrame, viewplots)
            if viewplots == 'y'
                
beadType = sampleTypeIdx(:, 2);
redBeadCount =sum(beadType==1); greenBeadCount = sum(beadType==2);
orangeBeadCount = sum(beadType==3); unknownBeadCount = sum(beadType==-1);

frameIdx = zeros(size(sampledData,1),1);
                for f = 1:size(sampledData,1)
                    frameIdx(f) = myBeads(sampledData(f,1)).getframeIndex;
                end
 redBeadIndices = find(beadType==1); greenBeadIndices= find(beadType==2); orangeBeadIndices= find(beadType==3); unknownBeadIndices= find(beadType== -1);
 redFrameIdx = zeros(redBeadCount,1);
 for f = 1:redBeadCount
     redFrameIdx(f) = myBeads(sampledData(redBeadIndices, 1)).getframeIndex;
 end
 greenFrameIdx = zeros(greenBeadCount,1);
 for f = 1:greenBeadCount
     greenFrameIdx(f) = myBeads(sampledData(greenBeadIndices, 1)).getframeIndex;
 end
 orangeFrameIdx = zeros(orangeBeadCount,1);
 for f = 1:orangeBeadCount
     orangeFrameIdx(f) = myBeads(sampledData(orangeBeadIndices, 1)).getframeIndex; 
 end
 unknownFrameIdx = zeros(unknownBeadCount,1);
 for f = 1:unknownBeadCount
     unknownFrameIdx(f) = myBeads(sampledData(unknownBeadIndices,1)).getframeIndex;
 end
 
 
                framestart = input('What frame# do you want flow rate results from?: ');
                framestep = input('What is your frame step size? ');
                h = figure; stem(frameIdx, 1:size(sampledData,1));
                xlabel('frame#'); ylabel('bead index of bead detected in a frame');
                title('frame# in which beads are detected');
                
                xflowrate = framestart:framestep:numel(myFrame);
                flowrate = xflowrate;
                redFlowrate = xflowrate; 
                greenFlowrate = xflowrate; 
                orangeFlowrate = xflowrate; 
                
                for count = 1:numel(xflowrate)
                    prnetcount = numel(frameIdx(frameIdx<xflowrate(count)));
                    prRedcount = numel(redFrameIdx(redFrameIdx<xflowrate(count)));
                    prGreencount = numel(greenFrameIdx(greenFrameIdx<xflowrate(count)));
                    prOrangecount = numel(orangeFrameIdx(orangeFrameIdx<xflowrate(count)));
                    if count~=1
                        pastnetcount = numel(frameIdx(frameIdx<xflowrate(count-1)));
                        pastRedcount = numel(redFrameIdx(redFrameIdx<xflowrate(count-1)));
                        pastGreencount = numel(greenFrameIdx(greenFrameIdx<xflowrate(count-1)));
                        pastOrangecount = numel(orangeFrameIdx(orangeFrameIdx<xflowrate(count-1)));
                        flowrate(count) = prnetcount - pastnetcount;
                       redFlowrate(count) = prRedcount-pastRedcount;
                       greenFlowrate(count) = prGreencount - pastGreencount;
                       orangeFlowrate(count) = prOrangecount  - pastOrangecount; 
                    else
                        flowrate(count) = prnetcount;
                        redFlowrate(count) = prRedcount;
                        greenFlowrate(count) = prGreencount;
                        orangeFlowrate(count) = prOrangecount;
                    end
                end
                
                h = figure; stem(xflowrate, flowrate);
                xlabel('frame#'); ylabel(sprintf(cat(2, '#new beads every ', num2str(framestep), ' frames')));
                title(sprintf(cat(2, '#new beads every ', num2str(framestep), ' frames')));
                
                h = figure; stem(xflowrate, redFlowrate);
                xlabel('frame #'); ylabel(sprintf(cat(2, '#new RED beads every ', num2str(framestep), 'frames')));
                title(sprintf(cat(2, '#new RED beads every ', num2str(framestep), 'frames')));
                
                h = figure; stem(xflowrate, greenFlowrate);
                xlabel('frame #'); ylabel(sprintf(cat(2, '#new GREEN beads every ', num2str(framestep), 'frames')));
                title(sprintf(cat(2, '#new GREEN  beads every ', num2str(framestep), 'frames')));
                
                h = figure; stem(xflowrate, orangeFlowrate);
                xlabel('frame #'); ylabel(sprintf(cat(2, '#new ORANGE beads every ', num2str(framestep), 'frames')));
                title(sprintf(cat(2, '#new ORANGE beads every ', num2str(framestep), 'frames')));
            end
        end
        
        function avgbeadvel = getbeadvel(sampledData, myBeads, myData, viewplots)
            beadVel = zeros(size(sampledData,1), 1);
            beadIdx = zeros(size(sampledData,1),1);
            for f = 1:size(sampledData,1)
                beadIdx(f) = myBeads(sampledData(f,1)).getbeadIndex;
                x = myBeads(sampledData(f,1)).getcoordinate(1:myData.getnumframes);
                colCoords = (x(:, 2))';
                endpoint1 = find(colCoords>0, 1, 'first');
                endpoint2 = find(colCoords>0, 1, 'last');
                beadVel(f) = abs((colCoords(endpoint2) - colCoords(endpoint1))/(endpoint2 - endpoint1 + 1));
            end
            
            avgbeadvel = mean(beadVel); %EDITED April 12, 2012 to display avgbeadvel
            
            sprintf('Avg bead vel is %f', avgbeadvel)
            if viewplots == 'y'
                h = figure; stem(beadIdx, beadVel);
                xlabel('bead#'); ylabel('bead velocities in pixels per frame');
                title('velocities of beads in pixels per frame');
            end
        end
    end
end

