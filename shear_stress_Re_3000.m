%% Wall Shear Stress Extraction from evol.dat
% Extracts bottom wall (col 10: duxdy_a) and top wall (col 11: duxdy_b)
% shear stress data, discarding the first 1000 data points as noise.

clear; clc; close all;

%% ---- User Settings -------------------------------------------------------
filename       = 'evol.dat';
noise_rows     = 1000;
movavg_window  = 500;
Re_label       = '3000';      % shown in the sgtitle
% ---------------------------------------------------------------------------

%% Load data
fid = fopen(filename, 'r');
if fid == -1, error('Cannot open file: %s', filename); end

data = []; lineNum = 0;
while ~feof(fid)
    line = strtrim(fgetl(fid));
    if isempty(line) || line(1) == '%', continue; end
    lineNum = lineNum + 1;
    if lineNum <= noise_rows, continue; end
    data = [data; str2double(strsplit(line))]; %#ok<AGROW>
end
fclose(fid);
if isempty(data), error('No data loaded.'); end

%% Extract
t       = data(:, 1);
wss_bot = data(:, 10);
wss_top = data(:, 11);

mean_bot = mean(wss_bot);
mean_top = mean(wss_top);

run_avg_bot = movmean(wss_bot, movavg_window);
run_avg_top = movmean(wss_top, movavg_window);

fprintf('Bottom WSS  mean: %+.6f,  std: %.6f\n', mean_bot, std(wss_bot));
fprintf('Top    WSS  mean: %+.6f,  std: %.6f\n', mean_top, std(wss_top));

%% ---- Helper: insert mean as a coloured extra y-tick --------------------
function apply_mean_tick(ax, mean_val, color)
    % Round existing auto-ticks to 2 dp to avoid near-duplicates
    current = get(ax, 'YTick');
    current(abs(current - mean_val) < 0.05) = [];  % remove any tick too close
    new_ticks = sort([current, mean_val]);
    set(ax, 'YTick', new_ticks);

    % Build tick labels — mean gets its own formatted string
    labels = cell(size(new_ticks));
    for k = 1:numel(new_ticks)
        if abs(new_ticks(k) - mean_val) < 1e-9
            labels{k} = sprintf('%.3f', mean_val);
        else
            labels{k} = num2str(new_ticks(k));
        end
    end
    set(ax, 'YTickLabel', labels);

    try
        ax.YAxis.TickLabelColor = 'k';
        drawnow;
        th = text(ax, xpos, mean_val, sprintf('  %.3f', mean_val), ...
            'Color', color, ...
            'FontSize', ax.FontSize, ...
            'HorizontalAlignment', 'right', ...
            'VerticalAlignment', 'middle', ...
            'Clipping', 'off', ...
            'Units', 'data');
        th.Position(1) = ax.XLim(1);
        th.Units = 'normalized';
        th.Position(1) = -0.01;
        th.Units = 'data';
        th.Position(1) = ax.XLim(1) - 0.01*diff(ax.XLim);
    catch
    end
end

%% ---- Plot ----------------------------------------------------------------
fsize = 12;

figure('Units','centimeters','Position',[2 2 18 13], ...
       'Color','w','PaperPositionMode','auto');

% --- Bottom wall ---
ax1 = subplot(2,1,1);
plot(t, wss_bot, 'k', 'LineWidth', 0.6); hold on;
plot(t, run_avg_bot, 'b', 'LineWidth', 2);
yline(mean_bot, '--r', 'LineWidth', 1.2);
hold off;


ylabel('$\tau_w^{\,\mathrm{bot}}$', 'Interpreter','latex', 'FontSize', fsize);
title('Bottom Wall Shear Stress', 'FontSize', fsize, 'FontWeight','normal');
legend('Raw','Running avg','Mean', ...
       'Location','northeast','FontSize', fsize-1, 'Box','off');
set(ax1, 'FontSize', fsize, 'Box','on', 'TickDir','out', ...
         'XTickLabel',[], 'LineWidth', 0.8);
xlim([t(1) t(end)]);

apply_mean_tick(ax1, mean_bot, [0.85 0 0]);

% --- Top wall ---
ax2 = subplot(2,1,2);
plot(t, wss_top, 'k', 'LineWidth', 0.6); hold on;
plot(t, run_avg_top, 'b', 'LineWidth', 2);
yline(mean_top, '--r', 'LineWidth', 1.2);
hold off;

xlabel('Time $(t)$', 'Interpreter','latex', 'FontSize', fsize);
ylabel('$\tau_w^{\,\mathrm{top}}$', 'Interpreter','latex', 'FontSize', fsize);
title('Top Wall Shear Stress', 'FontSize', fsize, 'FontWeight','normal');
legend('Raw','Running avg','Mean', ...
       'Location','northeast','FontSize', fsize-1, 'Box','off');
set(ax2, 'FontSize', fsize, 'Box','on', 'TickDir','out', 'LineWidth', 0.8);
xlim([t(1) t(end)]);

apply_mean_tick(ax2, mean_top, [0.85 0 0]);

sgtitle(['Re = ' Re_label ' — Wall Shear Stress'], 'FontSize', fsize+1);

% Tighten subplot spacing
ax1.Position(2) = 0.54;
ax2.Position(2) = 0.10;

%% Export
exportgraphics(gcf, 'wall_shear_stress_Re3000.png', 'Resolution', 300);
fprintf('Figure saved to wall_shear_stress_Re3000.png\n');

%% Save data
fid_out = fopen('wall_shear_stress_Re3000.txt', 'w');
fprintf(fid_out, '%% t\tduxdy_a (bottom)\tduxdy_b (top)\n');
fprintf(fid_out, '%.6f\t%.6f\t%.6f\n', [t, wss_bot, wss_top].');
fclose(fid_out);