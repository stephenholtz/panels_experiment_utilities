function [result,message] = save_metadata_file(save_location,metadata)
    
    result = 1;
    message = 'Metadata Saved';
    
    try
        save(fullfile(save_location,'metadata'),'metadata');
    catch ME
        result = 0;
        message = ['Metadata Failed to Save ' ME.message];
    end
    
end