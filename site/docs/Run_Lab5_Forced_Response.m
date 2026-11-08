function results = Run_Lab5_Forced_Response
% MIE 402 Lab 5. Run this file; keep the three .m files in one folder.
% Base MATLAB only. CSV/XLSX/XLS; select one run per file. Position in meters.
clc;
mode=input('Analyze 1 = impulse/free decay, 2 = harmonic sweep: ');
if ~ismember(mode,[1 2]), error('Choose 1 or 2.'); end
P.m=input('Total moving mass INCLUDING mounted dampers [kg]: ');
P.kFixed=input('Fixed-side spring stiffness [N/m]: ');
P.kDrive=input('Driven-side spring stiffness [N/m]: ');
if mode==2
    P.c=input('Damping c [N*s/m] from a decay with SAME mass and dampers: ');
end
[names,folder]=uigetfile({'*.csv;*.xlsx;*.xls','Vernier exports (*.csv, *.xlsx, *.xls)'},'Select run files','MultiSelect','on');
if isequal(names,0), results={}; return; end
if ischar(names), names={names}; end
out=fullfile(folder,'Lab5_Results'); if ~exist(out,'dir'), mkdir(out); end
results=cell(numel(names),1); summary=[];
for j=1:numel(names)
    file=fullfile(folder,names{j}); fprintf('\nRun %d: %s\n',j,names{j});
    sheet=1; [~,~,ext]=fileparts(file);
    if any(strcmpi(ext,{'.xlsx','.xls'}))
        disp(sheetnames(file)); sheet=input('Worksheet name in quotes or number [1]: '); if isempty(sheet), sheet=1; end
    end
    cols=input('Time and position column numbers [e.g. 1 2], or [] for header detection: ');
    [t,x,meta]=Lab5_Read_Vernier(file,cols,sheet);
    fprintf('Original export time %.4g to %.4g s; sampling %.4g Hz.\n',t(1),t(end),meta.fs_Hz);
    window=input('Start/end times from the Vernier plot [s], e.g. [10 30]: ');
    if numel(window)~=2||any(~isfinite(window))||window(2)<=window(1), error('Enter [start end].'); end
    q=t>=window(1)&t<=window(2); t=t(q); x=x(q);
    scale=input('Position units: 1=m, 2=cm, 3=mm [1]: '); if isempty(scale), scale=1; end
    factors=[1 .01 .001]; if ~ismember(scale,1:3), error('Choose 1, 2 or 3.'); end; x=x*factors(scale);
    if mode==2
        rpm=input('Measured drive speed [rpm], one cycle/revolution: ');
        pp=input('Measured input PEAK-TO-PEAK displacement [m]: '); P.Y=pp/2;
        R=Lab5_Analyze_Record(t,x,P,'harmonic',rpm/60);
        row=[rpm/60,2*pi*rpm/60,R.X_m,R.Y_m,R.gain,R.gain_dB,R.gain_theory,R.rmse_m,R.X_theory_m,R.amplitude_error_percent,R.phase_lag_theory_rad];
    else
        R=Lab5_Analyze_Record(t,x,P,'impulse');
        row=[R.fd_fit_Hz,R.fn_fit_Hz,R.fn_theory_Hz,R.c_est_Ns_m,R.zeta_fit,R.rmse_m];
    end
    results{j}=R; summary=[summary;row]; %#ok<AGROW>
    [~,stem]=fileparts(file); fig=figure('Color','w','Name',stem);
    subplot(2,1,1); plot(R.t,R.x,'k.',R.t,R.fit,'b-'); hold on;
    if mode==1, plot(R.t,R.theory,'r--'); legend('Measured','Identified decay','Measured m,k; identified c','Location','best');
    else
        plot(R.t,R.theory,'r--','LineWidth',1.2);
        legend('Measured','Sine fit at measured drive frequency','Analytical amplitude; phase aligned','Location','best');
        fprintf('Measured X = %.5g m; analytical X = %.5g m; signed difference = %.3g%%.\n',R.X_m,R.X_theory_m,R.amplitude_error_percent);
        fprintf('%s\n',R.theory_note);
    end
    xlabel('Time from selected start (s)'); ylabel('Position (m)'); grid on;
    title(strrep(stem,'_','\_'));
    subplot(2,1,2); plot(R.f_Hz,R.spectrum_m,'k-'); grid on;
    xlabel('Frequency (Hz)'); ylabel('Windowed amplitude (m)');
    if mode==2, xline(R.drive_Hz,'b--',sprintf('drive %.3f Hz',R.drive_Hz));
    else, xline(R.fd_fit_Hz,'b--',sprintf('fit %.3f Hz',R.fd_fit_Hz)); end
    title(sprintf('Hann spectrum; bin spacing %.3g Hz',R.bin_Hz));
    exportgraphics(fig,fullfile(out,[stem '_analysis.png']),'Resolution',220);
    writetable(table(R.t,R.x,R.fit,R.theory,'VariableNames',{'time_s','position_m','fit_m','theory_m'}),fullfile(out,[stem '_fit.csv']));
    if mode==2
        fid=fopen(fullfile(out,[stem '_comparison.txt']),'w');
        if fid>=0
            fprintf(fid,'%s\nMeasured peak X: %.9g m\nAnalytical peak X: %.9g m\nSigned amplitude difference: %.6g percent\n',R.theory_note,R.X_m,R.X_theory_m,R.amplitude_error_percent);
            fprintf(fid,'Analytical phase lag: %.9g rad (prediction only, not measured).\n',R.phase_lag_theory_rad);
            fclose(fid);
        end
    end
end
if mode==2
    labels={'drive_Hz','omega_rad_s','X_peak_m','Y_peak_m','gain','gain_dB','gain_theory','RMSE_m','X_theory_peak_m','amplitude_error_percent','phase_lag_theory_rad'};
    w=logspace(log10(min(summary(:,2))*.7),log10(max(summary(:,2))*1.4),600);
    H=P.kDrive./sqrt((P.kFixed+P.kDrive-P.m*w.^2).^2+(P.c*w).^2);
    fig=figure('Color','w'); semilogx(w,20*log10(H),'k-',summary(:,2),summary(:,6),'bo'); grid on;
    xlabel('Drive angular frequency (rad/s)'); ylabel('Displacement ratio X/Y (dB)'); legend('Theory','Experiment','Location','best');
    exportgraphics(fig,fullfile(out,'Lab5_Frequency_Response.png'),'Resolution',220);
    output='Lab5_Harmonic_Summary.csv';
else
    labels={'fd_fit_Hz','fn_fit_Hz','fn_theory_Hz','c_est_Ns_m','zeta_fit','RMSE_m'};
    output='Lab5_Impulse_Summary.csv';
end
T=array2table(summary,'VariableNames',labels); T.File=string(names(:));
writetable(T,fullfile(out,output)); save(fullfile(out,strrep(output,'.csv','.mat')),'results','P','names');
fprintf('\nSaved figures and tables in %s\n',out); disp(T);
end
