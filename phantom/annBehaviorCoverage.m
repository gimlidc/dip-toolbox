function annBehaviorCoverage()

    for coverage=1:2:39
        for layerId=1:20
            for fileId=1:25
                filename = ['coverage-C', num2str(coverage), '-l', num2str(layerId), '-c', num2str(fileId), '.mat'];
                if (exist(filename,'file') == 2)
                    display('File already exist, skipping: ', filename);
                else
		    display('Computing: ', filename);
                    computeANN7(coverage, layerId, fileId);
                end
            end
        end
    end

end