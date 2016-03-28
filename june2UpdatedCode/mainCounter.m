
close all; clear classes; clc;
countorclassify = input('Enter 1 for count, 2 for classification: ');
save countorclassify countorclassify
if countorclassify == 2
    beadtypes = input('how many types of beads?: ');
    alltrainingdata = []; alltraininglabels = [];
    save alltrainingdata alltrainingdata
    save alltraininglabels alltraininglabels
else
    beadtypes = 1;
end
save beadtypes beadtypes


for beadclass = 1:beadtypes + countorclassify - 1
    pathName = input('Complete file path: '); %'C:\Users\Arcturus\Documents\Lab projects\MultiColourFlowCytometer\NewCounter\The Updated Code\';
    videoname = input('Video: ');
    videofileName = dir(fullfile(pathName, videoname));
    
    display('\n Please watch video for ~5 seconds and enter the following data. \n')
    
    winTopEdge = input('Top edge: ');
    winLowerEdge = input('Lower edge: ');
    detThresLims = input('Lengthwise partitioning of each frame for sectional thresholding: ');
    detThresVals = input('Threshold values for your chosen partitions: ');
    startFrame = input('Startframe: ');
    minNumFrames = input('Min #frames to be processed: ');
    
    tic;
    %create a structure initialising parameters
    AnalysisParameters = struct('videopath', pathName, 'videoname', videofileName.name,...
        'startFrame', startFrame, 'minNumFrames', minNumFrames,...
        'resizeFactor', [.25 .25],...
        'winTopEdge', winTopEdge, 'winLowerEdge', winLowerEdge,...
        'detThresLims', detThresLims, 'detThresVals', detThresVals, ...
        'continuingBeadsSearchRadius', 10, ...
        'tolerableFlicker', 5, 'flickeringBeadsSearchRadius', 20,...
        'flashingBeadsSearchPeriod', 3, ...
        'falseBeadsSearchPeriod', 3, 'overlappingBeadsSearchRadius', 75, ...
        'numOfSpectrumSamples', 24);
    
    [myData, myFrame, myBeads, myWindow, ...
        myTracker, myMap, myLoop, ...
        myResolveFlicker, myResolveTwins, myResolveFlash, ...
        mySampledSpectrum, myClassifierKNN] = initializer.instantiateEverything(AnalysisParameters);
    
    myBeads = myfirstiteration.runfirstiteration(myFrame, myWindow, myMap, myBeads, myTracker, myLoop);
    
    myBeads = myLoop.allTogetherNow(myFrame, myWindow, myMap, myBeads, myTracker, myResolveFlicker, myResolveTwins, myResolveFlash);
    
    sampledData = mySampledSpectrum.sampleObtainedData(myBeads, myTracker, myData);
    
    toc;
    %editing here august 5. 
    
    if (countorclassify==1)
        visualizer.showcountvideo(myFrame, myBeads, sampledData(:, 1), videoname);
    else
        if beadclass <= beadtypes
            load alltrainingdata
            load alltraininglabels
            trainingdata = sampledData(:, 2:end);
            alltrainingdata = [alltrainingdata; trainingdata];
            switch videoname
                case 'red.avi'
                    labelfactor = 1;
                case 'green.avi'
                    labelfactor = 2;
                case 'orange.avi'
                    labelfactor = 3;
            end
            traininglabels = labelfactor*ones(size(trainingdata,1),1);
            alltraininglabels = [alltraininglabels; traininglabels];
            save alltrainingdata alltrainingdata
            save alltraininglabels alltraininglabels
            save beadclass beadclass
            clear classes;
            clc;
            load beadclass
            load beadtypes
            load countorclassify
        end
    end
end

load alltrainingdata
load alltraininglabels
sampleTypeIdx = myClassifierKNN.classifyKNN(sampledData, alltrainingdata, alltraininglabels, 25);

    %visualising all outputs %edit on august 5
    viewplots  = input('Do you want to view the plots obtained from flow rate data? y/n: ');
    getflowresults.getflowrate(sampledData, sampleTypeIdx, myBeads, myFrame, viewplots);
    avgbeadvel = getflowresults.getbeadvel(sampledData,myBeads, myData, viewplots);
    
%display bead count
beadTypeIndices = sampleTypeIdx(:, 2);
redBeadCount = fprintf('Number of red beads is %d\n', sum(beadTypeIndices==1));
greenBeadCount = fprintf('Number of green beads is %d\n', sum(beadTypeIndices==2));
orangeBeadCount = fprintf('Number of orange beads is %d\n', sum(beadTypeIndices==3));
unknownBeadCount = fprintf('Number of unknown beads is %d\n', sum(beadTypeIndices==-1));
%See the labeled beads being tracked
visualizer.showvideo(myFrame, myBeads, sampledData(:, 1), sampleTypeIdx, videoname);
