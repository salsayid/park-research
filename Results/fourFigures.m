%% WSS Multi-Re Analysis
% Loops over Result_Re2000 ... Result_Re10000
% Extracts col 10 (bottom wall) and col 11 (top wall) from evol.dat
% Skips first 1000 rows as noise.
% For mean/std vs Re: averages both walls together.
% For PDF: plots both walls separately with shared colour per Re.

clear; clc; close all;

%% ---- User Settings -------------------------------------------------------
base_path  = '/Users/sayidalsayid/Desktop/Park Research Group/Results';
Re_values  = [2000, 3000, 4000, 5000, 6000, 7000, 8000, 9000, 10000];
noise_rows = 1000;
% ---------------------------------------------------------------------------

nRe = numel(Re_values);

mean_bot = zeros(1, nRe);
mean_top = zeros(1, nRe);
std_bot  = zeros(1, nRe);
std_top  = zeros(1, nRe);
all_wss_bot = cell(1, nRe);
all_wss_top = cell(1, nRe);

%% ---- Load all files ------------------------------------------------------
for i = 1:nRe
    Re    = Re_values(i);
    fpath = fullfile(base_path, sprintf('Result_Re%d', Re), 'evol.dat');
    fid   = fopen(fpath, 'r');
    if fid == -1
        warning('Cannot open: %s — skipping Re=%d', fpath, Re);
        mean_bot(i) = NaN; mean_top(i) = NaN;
        std_bot(i)  = NaN; std_top(i)  = NaN;
        continue;
    end

    data = []; lineNum = 0;
    while ~feof(fid)
        line = strtrim(fgetl(fid));
        if isempty(line) || line(1) == '%', continue; end
        lineNum = lineNum + 1;
        if lineNum <= noise_rows, continue; end
        data = [data; str2double(strsplit(line))]; %#ok<AGROW>
    end
    fclose(fid);

    wss_b = data(:, 10);
    wss_t = data(:, 11);

    mean_bot(i)    = mean(wss_b);
    mean_top(i)    = mean(abs(wss_t));
    std_bot(i)     = std(wss_b);
    std_top(i)     = std(wss_t);
    all_wss_bot{i} = wss_b;
    all_wss_top{i} = wss_t;

    fprintf('Re=%5d  |  bot: mean=%+.4f  std=%.4f  |  top: mean=%+.4f  std=%.4f\n', ...
            Re, mean_bot(i), std_bot(i), mean_top(i), std_top(i));
end

% Average both walls
mean_avg = (mean_bot + mean_top) / 2;
std_avg  = (std_bot  + std_top)  / 2;

%% ---- One distinct colour per Re ------------------------------------------
% Evenly spaced around the colour wheel — maximally distinct
cmap = [
    0.894  0.102  0.110;   % red
    0.216  0.494  0.722;   % blue
    0.302  0.686  0.290;   % green
    0.596  0.306  0.639;   % purple
    1.000  0.498  0.000;   % orange
    1.000  1.000  0.200;   % yellow
    0.651  0.337  0.157;   % brown
    0.969  0.506  0.749;   % pink
    0.400  0.400  0.400;   % grey
];

fsize = 11;
lw    = 1.4;
ms    = 7;

function set_axes(ax, fsize)
    set(ax, 'FontSize', fsize, 'Box', 'off', 'TickDir', 'out', ...
            'LineWidth', 0.7, 'Color', 'w', ...
            'XColor', [0.15 0.15 0.15], 'YColor', [0.15 0.15 0.15]);
    grid(ax, 'off');
end

%% =========================================================================
%  FIGURE 1 — Mean WSS vs Re  (single line, walls averaged)
%% =========================================================================
f1 = figure('Units','centimeters','Position',[2 2 13 8],'Color','w');

for i = 1:nRe
    plot(Re_values(i), mean_avg(i), 'o', ...
         'Color', cmap(i,:), 'MarkerFaceColor', cmap(i,:), ...
         'MarkerSize', ms, 'DisplayName', sprintf('Re = %d', Re_values(i)));
    hold on;
end
plot(Re_values, mean_avg, '-', 'Color', [0.6 0.6 0.6], 'LineWidth', 1.0, ...
     'HandleVisibility', 'off');

xlabel('Re',                    'FontSize', fsize);
ylabel('\langle\tau_w\rangle',  'FontSize', fsize);
title('Mean wall shear stress', 'FontSize', fsize, 'FontWeight', 'normal');
legend('FontSize', fsize-2, 'Box', 'off', 'Location', 'northwest', 'NumColumns', 2);
set_axes(gca, fsize);
xlim([1500 10500]);

exportgraphics(f1, fullfile(base_path, 'fig1_mean_WSS_vs_Re.png'), 'Resolution', 300);

%% =========================================================================
%  FIGURE 2 — Std WSS vs Re  (single line, walls averaged)
%% =========================================================================
f2 = figure('Units','centimeters','Position',[2 2 13 8],'Color','w');

for i = 1:nRe
    plot(Re_values(i), std_avg(i), 'o', ...
         'Color', cmap(i,:), 'MarkerFaceColor', cmap(i,:), ...
         'MarkerSize', ms, 'DisplayName', sprintf('Re = %d', Re_values(i)));
    hold on;
end
plot(Re_values, std_avg, '-', 'Color', [0.6 0.6 0.6], 'LineWidth', 1.0, ...
     'HandleVisibility', 'off');

xlabel('Re',                        'FontSize', fsize);
ylabel('\sigma(\tau_w)',             'FontSize', fsize);
title('Std of wall shear stress',   'FontSize', fsize, 'FontWeight', 'normal');
legend('FontSize', fsize-2, 'Box', 'off', 'Location', 'northeast', 'NumColumns', 2);
set_axes(gca, fsize);
xlim([1500 10500]);

exportgraphics(f2, fullfile(base_path, 'fig2_std_WSS_vs_Re.png'), 'Resolution', 300);

%% =========================================================================
%  FIGURE 3 — PDF vs Gaussian  (bottom wall, one colour per Re)
%% =========================================================================
xi    = linspace(-4.5, 4.5, 300);
gauss = (1/sqrt(2*pi)) * exp(-0.5 * xi.^2);

f3 = figure('Units','centimeters','Position',[2 2 14 9],'Color','w');

for i = 1:nRe
    wss = all_wss_bot{i};
    if isempty(wss), continue; end
    wss_norm = (wss - mean(wss)) / std(wss);
    [counts, edges] = histcounts(wss_norm, 60, 'Normalization', 'pdf');
    centres = (edges(1:end-1) + edges(2:end)) / 2;
    plot(centres, counts, '-', 'Color', cmap(i,:), 'LineWidth', lw, ...
         'DisplayName', sprintf('Re = %d', Re_values(i)));
    hold on;
end
plot(xi, gauss, '--', 'Color', [0.1 0.1 0.1], 'LineWidth', 2.0, ...
     'DisplayName', 'Gaussian');

xlabel('(\tau_w - \langle\tau_w\rangle) / \sigma', 'FontSize', fsize);
ylabel('PDF',                                        'FontSize', fsize);
title('WSS distribution — bottom wall',             'FontSize', fsize, 'FontWeight', 'normal');
legend('FontSize', fsize-2, 'Box', 'off', 'Location', 'northeast', 'NumColumns', 2);
set_axes(gca, fsize);
xlim([-4.5 4.5]);

exportgraphics(f3, fullfile(base_path, 'fig3_PDF_bottom.png'), 'Resolution', 300);

%% =========================================================================
%  FIGURE 4 — PDF vs Gaussian  (top wall, same colours)
%% =========================================================================
f4 = figure('Units','centimeters','Position',[2 2 14 9],'Color','w');

for i = 1:nRe
    wss = all_wss_top{i};
    if isempty(wss), continue; end
    wss_norm = (wss - mean(wss)) / std(wss);
    [counts, edges] = histcounts(wss_norm, 60, 'Normalization', 'pdf');
    centres = (edges(1:end-1) + edges(2:end)) / 2;
    plot(centres, counts, '-', 'Color', cmap(i,:), 'LineWidth', lw, ...
         'DisplayName', sprintf('Re = %d', Re_values(i)));
    hold on;
end
plot(xi, gauss, '--', 'Color', [0.1 0.1 0.1], 'LineWidth', 2.0, ...
     'DisplayName', 'Gaussian');

xlabel('(\tau_w - \langle\tau_w\rangle) / \sigma', 'FontSize', fsize);
ylabel('PDF',                                        'FontSize', fsize);
title('WSS distribution — top wall',               'FontSize', fsize, 'FontWeight', 'normal');
legend('FontSize', fsize-2, 'Box', 'off', 'Location', 'northeast', 'NumColumns', 2);
set_axes(gca, fsize);
xlim([-4.5 4.5]);

exportgraphics(f4, fullfile(base_path, 'fig4_PDF_top.png'), 'Resolution', 300);

fprintf('\nDone. Figures saved to:\n  %s\n', base_path);