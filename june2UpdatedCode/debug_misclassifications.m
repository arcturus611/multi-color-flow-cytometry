%script to analyze and debug misclassifications
%@classic 2 bead red/green case: 1:red 2:green
%@3 bead case: 1: red, 2:green, 3:orange
%@2 bead orange/green case: 1:green, 2:orange
close all;
%@ From output get beadsamples of a specific color
choosetype = 1
spcolbeadidx = find(sampleTypeIdx(:,2)==choosetype);
beadsamples = sampledData(spcolbeadidx, 2:size(sampledData,2));
ra = 1; rz= size(beadsamples,2)/3;
ga = rz +1; gz = 2*rz;
oa = gz + 1; oz = 3*rz;
%@From training data get bead intensity values
if choosetype == 1
    Tbeadsamples = trainingdata(1:size(trainingdata,1)/3, :); %red
elseif choosetype == 2
    Tbeadsamples = trainingdata(size(trainingdata,1)/3+1:2*size(trainingdata,1)/3, :); %green
elseif choosetype == 3
    Tbeadsamples = trainingdata(2*size(trainingdata, 1)/3:size(trainingdata, 1), :); %orange
end
h = figure;
if choosetype == -1
    for i = 1:size(beadsamples,1)
        plot(beadsamples(i, ra:rz), 'r'), hold on; plot(beadsamples(i, ga:gz), 'g'), hold on; plot(beadsamples(i, oa:oz), 'b'); hold on; axis tight
        xlabel('Points along the LVF'); ylabel('Normalised bead intensities');
        title('train data : green, march 18'); %train data also
    end
else
    subplot(1,2,1);
    for i = 1:size(Tbeadsamples,1)
        plot(Tbeadsamples(i, ra:rz), 'r'), hold on; plot(Tbeadsamples(i, ga:gz), 'g'), hold on; plot(Tbeadsamples(i, oa:oz), 'b'); hold on; axis tight
        if choosetype == 1
            title('Training data : red ');
        elseif choosetype == 2
            title('Training data : green  ');
        elseif choosetype == 3
            title('Training data : orange  ');
        end
    end
    subplot(1,2,2);
    for i = 1:size(beadsamples,1)
        plot(beadsamples(i, ra:rz), 'r'), hold on; plot(beadsamples(i, ga:gz), 'g'), hold on; plot(beadsamples(i, oa:oz), 'b'); hold on; axis tight
        xlabel('Points along the LVF'); ylabel('Normalised bead intensities');
        title(sprintf(cat(2, 'Test data : ', videofileName.name))); 
    end
end