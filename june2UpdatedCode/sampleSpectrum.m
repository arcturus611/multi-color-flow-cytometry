classdef sampleSpectrum < mySingleton
    %Summary: sample the intensity values of all tracked beads
    %Detailed explanation:
    %since the beads flow through an LVF, each location along the path
    %represents a different wavelength. To get the correct classification
    %of a bead, we need to have its intensity values at a pre-decided set
    %of wavelengths
    %Note that this can NOT be done by choosing values at uniformly spaced
    %intervals from the obtained intensity vectors, because that would be
    %sampling the intensities at uniform intervals of time, when what we
    %really want is sampling them at uniform  intervals in space. 
    
    properties (Constant)
        sampleEndMargin = 25;   
        minSamplePtsInSpecPerChan = 2;
    end
    
    properties (Access = 'private')
        numOfSamples
        sampleLocs
        spectrumEps
    end
    %%
    
    methods(Access='private')
        function obj = sampleSpectrum(numofsamples)
            obj.sampleLocs = [];
            obj.spectrumEps = 10;
            obj.numOfSamples = numofsamples;
        end
    end
    
    methods(Static)
        function obj = instance(numofsamples)
            persistent uniqueInstance
            if isempty(uniqueInstance)
                obj = sampleSpectrum(numofsamples);
                uniqueInstance = obj;
            else
                obj = uniqueInstance;
            end
        end
    end
    
    %%
    methods
        function setSpectrumEps(obj, s)
            obj.spectrumEps = s;
        end
        
        function s = getSpectrumEps(obj)
            s = obj.spectrumEps;
        end
        
        function sl = getSampleLocs(obj)
            sl = obj.sampleLocs;
        end
        
        function setSampleLocs(obj, myframe)
            frameLen = size(myframe(1).getMat,2);
            obj.sampleLocs = round(linspace(obj.sampleEndMargin, frameLen-obj.sampleEndMargin, obj.numOfSamples));
        end
        
        function allBeadsData = sampleObtainedData(obj, mybeads, mytracker, mydata)
            frameIdxVec = 1:mydata.getnumframes; 
            posIdxVec = 1:obj.numOfSamples;%@
            posData = zeros(mytracker.getbeadCount, obj.numOfSamples);
            truBeadIdx = zeros(mytracker.getbeadCount, 1);
            allBeadsIntensityData = zeros(mytracker.getbeadCount, 3*obj.numOfSamples);
            truBeadCnt = 0;
            for i = 1:1000
                if mybeads(i).getframeIndex
                    truBeadCnt = truBeadCnt + 1;
                    truBeadIdx(truBeadCnt) = i;
                    singleBeadIntensityData = zeros(3, obj.numOfSamples);
                    x = mybeads(i).getcoordinate(1:mydata.getnumframes);
                    colCoords = (x(:, 2))';
                    endpoint1 = find(colCoords>0, 1, 'first');
                    endpoint2 = find(colCoords>0, 1, 'last');
                    colCoordsSnipped = colCoords(endpoint1:endpoint2);
                    %#@
                    [a b] = meshgrid(obj.sampleLocs, colCoordsSnipped);
                    z = abs(a-b);
                    if numel(colCoordsSnipped)==1
                        z = [z; max(z)*ones(1, numel(z))];
                    end
                    [v idx] = min(z);
                    p = v<obj.spectrumEps;
                    while p==0
                        obj.setSpectrumEps(obj.spectrumEps + 5);
                        p = v<obj.spectrumEps;
                    end
                    posData(truBeadCnt, posIdxVec(p)) = colCoordsSnipped(idx(p));
                    ff = find(posData(truBeadCnt, :));
                    %@ EDITED UP TO THIS LINE ON FEBRUARY 27-28. 
                    for ii = 1:sum(posData(truBeadCnt,:)>0)
                        framenum = min(frameIdxVec(colCoords == posData(truBeadCnt, ff(ii))));
                        singleBeadIntensityData(:, ff(ii)) = (mybeads(i).getintensity(framenum))';
                    end
                    unnormalizedintensity = [singleBeadIntensityData(1,:) singleBeadIntensityData(2, :) singleBeadIntensityData(3,:)];
                    %@EDITED on March 1
                     allBeadsIntensityData(truBeadCnt ,:) = 255*unnormalizedintensity/max(unnormalizedintensity);
                end
            end
            %@EDITED March 15
            %remove data points with less than 3 sampled values per bead
            temp = allBeadsIntensityData;
            allBeadsIntensityData(sum(allBeadsIntensityData>0,2)<3*obj.minSamplePtsInSpecPerChan,:) = [];
            truBeadIdx(sum(temp>0,2)<3*obj.minSamplePtsInSpecPerChan) = [];

            %interpolate intensity values where there are gaps
            
            
            %EDIT ends
            allBeadsData = [truBeadIdx allBeadsIntensityData];
            mytracker.setbeadCount(size(allBeadsData,1)); 
            sprintf('Total bead count is %d', mytracker.getbeadCount)

        end   
    end 
end

