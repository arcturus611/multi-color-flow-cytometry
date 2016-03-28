classdef Tracker < mySingleton
    
    properties (Constant)
        winSize = 15;
        searchRadius = 10;
        se = [1 1 1; 1 0 1; 1 1 1];
        velocityweight = 1; 
        gaussspread = .75;
    end
   
    properties (Access = 'private')
        beadCount;
        predictions;
    end
    
    %%
    
    methods(Access='private')
        function newObj = Tracker()
            newObj.beadCount = 0;
            newObj.predictions = [];
        end
    end
    
    methods(Static)
        function obj = instance()
            persistent uniqueInstance
            if isempty(uniqueInstance)
                obj = Tracker();
                uniqueInstance = obj;
            else
                obj = uniqueInstance;
            end
        end
    end
    
    %%
    
    methods
        function beadCount = getbeadCount(obj)
            beadCount = obj.beadCount;
        end
        
        function setbeadCount(obj, beadCount)%Tracker is a subclass of the handle class
            obj.beadCount= beadCount;
        end
        
        function predictions = getpredictions(obj)
            predictions = obj.predictions;
        end
        
        function setpredictions(obj, predictions)
            obj.predictions = predictions;
        end
        
        function track(obj, mybeads, mymap, currentframe, nextframe)
            
            winsize = obj.winSize;
            searchradius = obj.searchRadius;
            
            currentmatrix = currentframe.getMat();
            currentframenum = currentframe.getframeNum();
            nextframematrix = nextframe.getMat();
            Sz = size(currentmatrix);
            
            for num = mymap.getbeadsalivecount():-1:1
                beadindex = mymap.getaliveindex(num);
                beadcoords = mybeads(beadindex).getcoordinate(currentframenum);
                cx = beadcoords(1); cy = beadcoords(2);
                beadvel = mybeads(beadindex).getvelocity(currentframenum);
                vx = beadvel(1); vy = beadvel(2);
                
                [yy,xx] = meshgrid(1:Sz(2),1:Sz(1));
                
                Win = currentmatrix(max(1,cx-winsize):min(Sz(1),cx+winsize), max(1,cy-winsize):min(Sz(2),cy+winsize));
                
                fIm = filter2(Win, nextframematrix,'same');
                
                xxx = xx-cx-obj.velocityweight*vx;
                yyy = yy-cy-obj.velocityweight*vy;
                
                E = exp(-(xxx.^2+yyy.^2)/(2*searchradius^2));
                E(E>max(E(:))*obj.gaussspread) = 1;
                fIm = fIm.*E;
                
                iOld = cx;
                jOld = cy;
                
                [cx cy] = find(fIm>=imdilate(fIm, obj.se));
                if (isempty(cx))
                    [cx cy] = find(fIm == max(fIm(:)));
                end
                
                [~, idx] = min((cx-(iOld+obj.velocityweight*vx)).^2 + (cy-(obj.velocityweight*vy+jOld)).^2);
                cx = cx(idx); cy = cy(idx);
                
                pred(num, :) = [beadindex [round(cx) round(cy)]];
            end
            setpredictions(obj, pred);
        end
        
    end
end
