classdef datagen < mySingleton
    
   properties (Access = 'private')
      frames;
      colorframes;
      numframes; 
   end
   
   methods(Access= 'private')
      function newObj = datagen()
         newObj.frames = [];
         newObj.colorframes = [];
         newObj.numframes = 0;
      end
   end
   
   methods(Static)
      function obj = instance()
         persistent uniqueInstance
         if isempty(uniqueInstance)
            obj = datagen();
            uniqueInstance = obj;
         else
            obj = uniqueInstance;
         end
      end
   end
   
   methods 
      function frames = getframes(obj)
         frames = obj.frames;
      end
      
      function numframes = getnumframes(obj)
         numframes = obj.numframes;
      end
      
      function  setframes(obj, frames)
          obj.frames= frames;
          obj.numframes = size(frames, 3);
      end
      
      function colorframes = getcolorframes(obj)
          colorframes = obj.colorframes;
      end
      
      function  setcolorframes(obj, colorframes)
         obj.colorframes= colorframes;
      end
      
   end  
end
