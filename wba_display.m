function wba_display(update_period,TrialInfo,varargin)
% WBA_DISPLAY code for a very quick and dirty wba_display

% Settings for the figure
len_data_buffer = 1000; % 4 seconds
voltage_range = 6;      % +/- 6 volts
bgnd_color = [.9 .9 .9];
fgnd_color = [.1 .1 .1];
figure_name = 'Wing Beat Analyzer Output';

% Initialize the plotted vector
global plotted_vals
plotted_vals = zeros(1,len_data_buffer);
time_vector = 1:len_data_buffer;

%  Initialize and hide the GUI as it is being constructed.
fHand = figure('Visible','off','Position',[75,250,600,400],...
                'Color',bgnd_color,...
                'NumberTitle','off',...
                'MenuBar','none',...
                'Name',figure_name);

% Set up the plot
axes_hand = axes('Units','normalized','Position',[.10,.13,.85,.75],'Color',bgnd_color,'Xcolor',fgnd_color,'Ycolor',fgnd_color);
plot(axes_hand,time_vector,plotted_vals,...
    'XDataSource','time_vector',...
    'YDataSource','plotted_vals',...
    'Color',bgnd_color);
axis([0 len_data_buffer -voltage_range voltage_range])
ylabel('Volts','FontSize',10,'Color',fgnd_color)
xlabel('Relative Time','FontSize',10,'Color',fgnd_color)
title(figure_name,'FontSize',12,'Color',fgnd_color)
grid on; box off;

% Set up the timer
timer_hand = timer('BusyMode','queue','Period',update_period,...
    'ExecutionMode','FixedRate',...
    'TimerFcn',{@update_wba_display,fHand,TrialInfo,len_data_buffer});
start(timer_hand)

% Show the figure, in all its glory
set(fHand,'Visible','on')

% Callback Function
    function update_wba_display(obj,event,fHand,TrialInfo,len_data_buffer) %#ok<*INUSL>
        % Callback that just updates the plot with TrialInfo Fields
        plotted_vals = [plotted_vals TrialInfo.lmr_wba];

        if length(plotted_vals) > len_data_buffer
            plotted_vals = plotted_vals((1+end-len_data_buffer):end); %#ok<*NASGU>
        end
        
        if ishandle(fHand)
            refreshdata(fHand,'caller')
            %disp(TrialInfo.lmr_wba)
        else
            stop(obj)
            delete(obj)
        end
    end
end