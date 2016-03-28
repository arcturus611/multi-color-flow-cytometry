
classdef visualizer < mySingleton
    
    methods(Access='private')
        function obj = visualizer()
        end
    end
    
    methods(Static)
        function obj = instance()
            persistent uniqueInstance
            if isempty(uniqueInstance)
                obj = visualizer();
                uniqueInstance = obj;
            else
                obj = uniqueInstance;
            end
        end
    end
    
    methods (Static)
        function showcountvideo(myframe, mybeads, beadIdx, vidname)
            h = figure; 
            for k=numel(myframe):-1:1
                currfrm = myframe(k).getcolorMat();
                imagesc(currfrm);
                for t = size(beadIdx,1):-1:1
                    hold on
                    x = mybeads(beadIdx(t)).getcoordinate(k);
                    if (x(1)>1 && x(2)>1 && x(1)<size(currfrm,1) && x(2)<size(currfrm,2))
                        xr = x(1); xc = x(2);
                        plot(xc, xr, 'ow','markersize',10);
                        text(xc+8, xr-8, num2str(t) , 'BackgroundColor', [.6 .6 .6]);%cat(2, num2str(t), 'g', num2str(sampleTypeAndIdx(t, 1))
                    end
                end
                drawnow; 
                title(cat(2, 'frame#', num2str(k)));
                axis equal
                mymov(k) = getframe(h);
            end
            hold off
            close(h)
            savedVidName = cat(2, vidname(1:find(vidname=='.', 1, 'first')-1), '_processed', '.avi');
            movie2avi(mymov, savedVidName);
        end
        
        
        function mymov = showvideo(myframe, mybeads, beadIdx, sampleTypeAndIdx, vidname)
            h = figure; 
            for k=numel(myframe):-1:1
                currfrm = myframe(k).getcolorMat();
                imagesc(currfrm);
                for t = size(sampleTypeAndIdx,1):-1:1
                    hold on
                    x = mybeads(beadIdx(t)).getcoordinate(k);
                    myflag = sampleTypeAndIdx(t, 2);
                    if (x(1)>1 && x(2)>1 && x(1)<size(currfrm,1) && x(2)<size(currfrm,2))
                        xr = x(1); xc = x(2);
                        if (myflag == 1)%red
                            plot(xc, xr, 'ow','markersize',10);
                            text(xc+8, xr-8, num2str(sampleTypeAndIdx(t,1)) , 'BackgroundColor', [.9 .2 .2]);%cat(2, num2str(t), 'g', num2str(sampleTypeAndIdx(t, 1))
                            %num2str(t)
                        end
                        if myflag == 2%green
                            plot(xc, xr, 'ow','markersize',10);
                            text(xc+8, xr-8, num2str(sampleTypeAndIdx(t,1)), 'BackgroundColor', [.2 .9 .7]);
                            %num2str(t)
                        end
                        if myflag == 3%orange
                            plot(xc, xr, 'ow','markersize',10);
                            text(xc+8, xr-8, num2str(sampleTypeAndIdx(t,1)), 'BackgroundColor', [.8 .7 .1]);
                            %num2str(t)
                        end
                        if myflag == -1
                            plot(xc, xr, 'ow','markersize',10);
                            text(xc+8, xr-8, num2str(sampleTypeAndIdx(t,1)), 'BackgroundColor', [.9 .9 .9]);
                            %num2str(t)
                        end
                    end
                end
               
                drawnow;
                title(cat(2, 'frame#', num2str(k)));
                mymov(k) = getframe(h);
            end
            hold off
            close(h);           
            savedVidName = cat(2, vidname(1:find(vidname=='.', 1, 'first')-1), '_processed', '.avi');
            movie2avi(mymov, savedVidName);
        end
    end
end



