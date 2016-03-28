classdef classifierKNN
  
    methods(Access='private')
        function obj = classifierKNN()
        end
    end
    
    methods(Static)
        function obj = instance()
            persistent uniqueInstance
            if isempty(uniqueInstance)
                obj = classifierKNN();
                uniqueInstance = obj;
            else
                obj = uniqueInstance;
            end
        end
    end
    
    %%
    
    methods (Static)
        function sampleTypeAndIdx = classifyKNN(sampledata, trainingdata, traininglabels, numNeighbours)
            sampleintensities = sampledata(:, 2:end);
            %#@ EDITED on March 1. 
            %instead of normalizing by the maximum of the entire set of
            %beads, normalize each bead against its own maximum. Which
            %makes sense, because each bead ka maximum should be taken as
            %its 255 value.
%             normalizedsampleintensities = 255*sampleintensities./(max(sampleintensities, [], 2)*ones(1,size(sampleintensities,2))); %normalizing the obtained sample points
%             samplelabels = knnclassify(normalizedsampleintensities, trainingdata, traininglabels, numNeighbours);  
%@EDITED on March 7
%             samplelabels = knnclassify(sampleintensities, trainingdata, traininglabels, numNeighbours);  
            [samplelabelsT, ~] = cvKnn(sampleintensities', trainingdata', traininglabels', numNeighbours);
            samplelabels = samplelabelsT';
            
            %@EDIT ends
            sampleTypeIdx = zeros(numel(samplelabels),1); 

            allClasses = unique(samplelabels); 
            for i = 1:size(allClasses, 1)
                x = samplelabels; 
                x(x~=allClasses(i)) = 0;
                x(find(x)) = (1:numel(find(x))); 
                sampleTypeIdx = sampleTypeIdx + x;
            end
            
            sampleTypeAndIdx = [sampleTypeIdx samplelabels];
        end
    end
    
end

