classdef initializer<mySingleton
  
    methods (Static)
        function [myData, myFrame, myBeads, myWindow, myTracker, myMap, myLoop, myResolveFlicker, myResolveTwins, myResolveFlash, mySampledSpectrum, myClassifierKNN]=instantiateEverything(AnalysisParameters)
            [colordata, graydata] = myVideoReader.readVideo(fullfile(AnalysisParameters.videopath, AnalysisParameters.videoname), AnalysisParameters.startFrame, AnalysisParameters.minNumFrames, AnalysisParameters.resizeFactor); %static method, hence no need to instantiate the class

            myData = datagen.instance();
            setframes(myData, graydata);
            setcolorframes(myData, colordata);
            
            myFrame = frame( (1:getnumframes(myData))', getframes(myData), getcolorframes(myData));
            
            myBeads = bead(15000, getnumframes(myData)); %arbitrarily chosen value, because we cannot grow an array of objects
            
            myWindow = window.instance(AnalysisParameters.winTopEdge, AnalysisParameters.winLowerEdge, AnalysisParameters.detThresLims, AnalysisParameters.detThresVals); 
            
            myTracker = Tracker.instance();
            
            myMap = mymap2M.instance(AnalysisParameters.continuingBeadsSearchRadius);
            
            myLoop = myloop2M.instance();
            
            myResolveFlicker = resolveflicker.instance(AnalysisParameters.tolerableFlicker, AnalysisParameters.flickeringBeadsSearchRadius);
            
            myResolveTwins = resolveTwins.instance(AnalysisParameters.falseBeadsSearchPeriod, AnalysisParameters.overlappingBeadsSearchRadius);
            
            myResolveFlash = resolveFlash.instance(AnalysisParameters.flashingBeadsSearchPeriod);
            
            mySampledSpectrum = sampleSpectrum.instance(AnalysisParameters.numOfSpectrumSamples);
            mySampledSpectrum.setSampleLocs(myFrame);
            
            myClassifierKNN = classifierKNN.instance();
            
        end
    end
end