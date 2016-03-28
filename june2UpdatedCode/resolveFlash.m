classdef resolveFlash < mySingleton
%     properties(Constant)
% 
%         %if bead is visible for fewer than this many frames, it is
%         %annihilated
%         %@EDITED on 20 February: 
%         %-->5 : g10calibg10o15
%     end
properties (Access = 'private')
    minVisPeriod; 
end

    %%
    methods(Access='private')
        function newObj = resolveFlash(x)
            newObj.minVisPeriod = x;
        end
    end
    
    methods(Static)
        function obj = instance(x)
            persistent uniqueInstance
            if isempty(uniqueInstance)
                obj = resolveFlash(x);
                uniqueInstance = obj;
            else
                obj = uniqueInstance;
            end
        end
    end
    
    %%
    methods
        
        function fbi = getFlashBeadsIdx(obj, resolveFlicker, mybeads, currfrmnum)
            deadIdx = resolveFlicker.getdeadBeadsIdx;
            azCount = 0;
            fbi = zeros(size(deadIdx, 1),1);
            
            for i = 1:numel(deadIdx)
                x = mybeads(deadIdx(i)).getcoordinate(1:currfrmnum);
                colCoords = (x(:, 2))';
                endpoint1 = find(colCoords>0, 1, 'first');
                endpoint2 = find(colCoords>0, 1, 'last');
                
                if (abs(endpoint1 - endpoint2)<obj.minVisPeriod)
                    azCount = azCount + 1;
                    fbi(azCount) = deadIdx(i);
                end
                
            end
            
            if azCount==0
                fbi = [];
            else
                fbi = fbi(1:find(fbi>0, 1, 'last'));
            end
                
        end
        
    end
end



