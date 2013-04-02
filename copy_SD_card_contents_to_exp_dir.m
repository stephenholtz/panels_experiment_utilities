function [result,message] = copy_SD_card_contents_to_exp_dir(protocol_folder,exp_dir)
% This function copies a folder 'SD_card_contents' that should exist in the
% protocol_folder (along with metadata and the experimental conditions
% files) to the current experiment's data folder. This preserves a copy for
% later use... probably good practice. 
%
% This does not check the contents of the folder

try
    mkdir(fullfile(exp_dir,'SD_card_contents'));
    copyfile(fullfile(protocol_folder,'SD_card_contents'),fullfile(exp_dir,'SD_card_contents'));
    result = 1;
    message = 'SD_card_contents copied sucessfully.';
catch ME
    result = 1;
    message = ['SD_card_contents copying failed: ' ME.message];
end

end