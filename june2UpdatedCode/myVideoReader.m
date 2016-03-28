%how do you read video in MATLAB? It is a bloody pain. So here's a
%step-by-step guide showing how to go about the inevitable torture.

%first convert whatever you have to avi file. This is ESSENTIAL. Else you
%are doomed. I use the pazera converter. It is installed in my machine
%(DeepThought) but in case it isn't there on the machine you are working
%on, google 'pazera mp4 to avi converter' and download and install the
%application from the first link.
classdef myVideoReader < mySingleton
    methods(Static)
        function [movieData, movieGraydata] = readVideo(movieName, startFrm, minNumFrms, rszFac)
            movieObj = mmreader(movieName);
            
            rszR = rszFac(1); rszC = rszFac(2);
            numFrm =  min(minNumFrms, movieObj.NumberOfFrames - startFrm + 1);
            movieData = zeros(rszR*movieObj.height, rszC*movieObj.width, 3, numFrm, 'uint8');
            movieframecount = 0;
            for videoframenumber = startFrm:startFrm + numFrm - 1
                videoframenumber
                movieframecount = movieframecount + 1;
                frame = movieObj.read(videoframenumber);
                for k = 1:3
                    movieData(:, :, k, movieframecount) = imresize(frame(:, :, k), [rszR*movieObj.height rszC*movieObj.width], 'bicubic');
                end
            end
            movieGraydata = zeros(size(movieData,1), size(movieData,2), numFrm, 'uint8');
            movieframecount = 0;
            for videoframenumber = startFrm:startFrm + numFrm - 1
                movieframecount = movieframecount + 1;
                movieGraydata(:,:,movieframecount) = rgb2gray(movieData(:, :, :, movieframecount));
            end
            
        end
    end
end
