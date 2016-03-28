classdef frame

    properties(GetAccess = 'private')
        frameNum
        Mat
        colorMat
    end
    
    methods
        
        function obj = frame(init, allgrayframes, allcolorframes) %constructor for array of objects of class 'frame'. 
            if nargin~=0
                m = size(init, 1);
                obj(m) = frame; 
                for i = 1:m
                    obj(i).frameNum = init(i);
                    obj(i).Mat = allgrayframes(:,:,i);
                    obj(i).colorMat = allcolorframes(:, :, :, i);
                end
            end
        end
        
        function frameNum = getframeNum(obj)
            frameNum = obj.frameNum;
        end
        
        function Mat = getMat(obj)
            Mat = obj.Mat;
        end

        function colorMat = getcolorMat(obj)
            colorMat = obj.colorMat;
        end
    end  
end

