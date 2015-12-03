function [igScaled, nets] = informationGain(visible, target, areaSize)
% igScaled = informationGain(visible, target, areaSize) - function estimate 
% target image from visible one. This is made by FF-ANN. Estimate is than
% subtracted from the target values, this way we obtain information gain.
% IG is than scaled into range 0-1.

nets = trainNetworks(areaSize, visible, target);
nets = reshape(nets, size(nets, 1) * size(nets,2), 1);

width = size(visible, 2);
height = size(visible, 1);

map = createMap(width, height, areaSize);
[x, y] = meshgrid(1:width, 1:height);
[seg, wx, wy] = getSegment(x, y, areaSize);

toProcess = reshape(double(visible), width * height, size(visible,3))';
q = zeros(width * height, size(target, 3), 4);

q1 = map(sub2ind(size(map), seg(:,2), seg(:,1), ones(size(seg,1),1)));
q2 = map(sub2ind(size(map), seg(:,2), seg(:,1), 2 * ones(size(seg,1),1)));
q3 = map(sub2ind(size(map), seg(:,2), seg(:,1), 3 * ones(size(seg,1),1)));
q4 = map(sub2ind(size(map), seg(:,2), seg(:,1), 4 * ones(size(seg,1),1)));

wy = reshape(wy, width*height, 1);
wx = reshape(wx, width*height, 1);

wy(q1 == 0 & q2 == 0) = 1;
wy(q3 == 0 & q4 == 0) = 0;

wx(q1 == 0 & q3 == 0) = 1;
wx(q2 == 0 & q4 == 0) = 0;

display('Computing approximation of target');

for netId = 1:size(nets,1);
    ind = find(q1 == netId);
    q(ind, :, 1) = nets{netId}.net(toProcess(:, ind), 'useGPU', 'yes')';
    ind = find(q2 == netId);
    q(ind, :, 2) = nets{netId}.net(toProcess(:, ind), 'useGPU', 'yes')';
    ind = find(q3 == netId);
    q(ind, :, 3) = nets{netId}.net(toProcess(:, ind), 'useGPU', 'yes')';
    ind = find(q4 == netId);
    q(ind, :, 4) = nets{netId}.net(toProcess(:, ind), 'useGPU', 'yes')';
end        

display('Final bilinear interpolation');

wx = reshape(wx, width*height, 1) * ones(1,size(target,3));
wy = reshape(wy, width*height, 1) * ones(1,size(target,3));

try 
    gpuDevice(1);

    wxGpu = gpuArray(wx);
    wyGpu = gpuArray(wy);

    qGpu = gpuArray(q);

    igScaled =  qGpu(:,:,1) .* (1 - wxGpu) .* (1 - wyGpu) ...
                + qGpu(:,:,2) .* wxGpu .* (1 - wyGpu) ...
                + qGpu(:,:,3) .* (1 - wxGpu) .* wyGpu ...
                + qGpu(:,:,4) .* wxGpu .* wyGpu;            
catch
    display('GPU device problem. Computing on CPU ...');
                
    igScaled =  q(:,:,1) .* (1 - wx) .* (1 - wy) ...
                + q(:,:,2) .* wx .* (1 - wy) ...
                + q(:,:,3) .* (1 - wx) .* wy ...
                + q(:,:,4) .* wx .* wy;                
end
        
igScaled = reshape(igScaled, height, width, size(target,3));        

end