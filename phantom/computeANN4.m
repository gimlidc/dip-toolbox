function computeANN3( M, layersID, fileID )
% computeANN(phantomID, M, layersID,fileID) - function for cesnet computing. 
% Function takes one phantom from directory and train one FF-ANN. Results 
% (error vectors and network itself) stores into ouput file.

cd '/storage/ostrava1/home/gimli/dip-toolbox/phantom';

load('materials-firenze.mat');
pattern = createPhantomPattern(int16(500/M), 500, M, 120, 0.02);
permutation = randperm(120);
mStatsPerm(1:120,:,:) = mStats(permutation, :, :); % mStats is loaded from materials-firenze
mStatsPerm(121:240,:,:) = mStats(120+permutation, :, :);
phantom = createPhantom(pattern, mStatsPerm);
load('layersStore');

height = size(phantom.clean,1);
width = size(phantom.clean,2);

trainSetSize = min(height*width, 10^5);

[net, perf] = trainANN(phantom.work, layers{layersID}, trainSetSize); 

oneLayer = reshape(phantom.clean(1:height, 1, 1:16), height, 16);
twoLayers = reshape(phantom.clean(1:height, width, 1:16), height, 16);

oneLayerNir = net(oneLayer')';
twoLayersNir = net(twoLayers')';

err.oneLayer = (oneLayerNir - reshape(phantom.clean(1:height, 1, 17:32), height, 16)).^2;
err.twoLayers = (twoLayersNir - reshape(phantom.clean(1:height, width, 17:32), height, 16)).^2;

filename = ['materials-out-M', num2str(M), '-L', num2str(layersID), '-c', num2str(fileID)];

save(filename, 'err', 'net', 'perf', 'mStatPerm');

end

