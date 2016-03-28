classdef bead
    properties (Access = 'private')
        beadIndex %which #bead is it?
        frameIndex %which frame did it first appear in?
        coordinate
        intensity
        velocity
    end
    
    methods%constructor
        function obj = bead(beadarraysize, beadlifespan) %constructor method for bead object array
            if nargin~=0 
                m = beadarraysize; 
                obj(m) = bead; 
                for i = 1:m 
                    obj(i).beadIndex = i;
                    obj(i).frameIndex = 0;
                    obj(i).coordinate = zeros(beadlifespan, 2);
                    obj(i).intensity = zeros(beadlifespan, 3);
                    obj(i).velocity = zeros(beadlifespan, 2);
                end
            end
        end
    end
    
    methods 
        function obj = setcoordinate(obj, coordinate, frameIndex)%because this is a value class, we need to return an instance of the object.
            obj.coordinate(frameIndex, :) = coordinate;
        end
        
        function coordinate = getcoordinate(obj, frameIndex)
            coordinate = obj.coordinate(frameIndex, :);
        end
        
        function obj = setintensity(obj, intensity, frameIndex)
            obj.intensity(frameIndex, :) = intensity;                              
        end
        
        function intensity = getintensity(obj, frameIndex)
            intensity = obj.intensity(frameIndex, :);
        end
        
        function obj = setvelocity(obj, velocity, frameIndex)
            obj.velocity(frameIndex, :) = velocity;
        end
        
        function velocity = getvelocity(obj, frameIndex)
            velocity = obj.velocity(frameIndex, :);
        end
        
        function obj = setbeadIndex(obj, beadIndex)
            obj.beadIndex = beadIndex;
        end          
        
        function beadIndex = getbeadIndex(obj)
            beadIndex = obj.beadIndex;
        end
        
        function obj = setframeIndex(obj, frameIndex)
            obj.frameIndex = frameIndex;
        end        
        
        function frameIndex = getframeIndex(obj)
            frameIndex = obj.frameIndex;
        end   
    end
end