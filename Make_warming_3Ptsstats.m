%Make_warming_endstats.m
%Edward Tekwa Oct 22, 17
%run food web simulations with parallel warming and no-warming cases

clear all; %close all;

numIt=20;    %number of iterations for each parameter combination
TimeData=string(datetime);
%%%% Testing realization ofsize-shifts
global P %v vw % P has parameters, v are current thermal envelopes
%if matlabpool('size') ~= 0; matlabpool close; end; matlabpool local 2


%%-- Load ensemble trait values
%load ./Data/Data_traits
make_traits;

%%-- Make storage
P = make_parameters(TR,1); % get parameters of model
!rm -f ./Data/Data_ensembles.nc
nccreate('./Data/Data_ensembles.nc','B','Dimensions',...
    {'TR',size(TR,2),'nx',P.nx,'sp',P.n,'t',P.Tend+1});
nccreate('./Data/Data_ensembles.nc','Z','Dimensions',...
    {'TR',size(TR,2),'nx',P.nx,'t',P.Tend+1});


%%-- Run ensemble demographics
%for i = 200; size(TR,1);

%create matrices to store ensemble data
%no warming
EnsembleGbar=[];
EnsembleGBbins=[];
EnsembleprodBbins=[];
avgB=[];
avgP=[];
Ps=P;

%warming
EnsembleGbar_w=[];
EnsembleGBbins_w=[];
EnsembleprodBbins_w=[];
avgB_w=[];
avgP_w=[];

%timepoints:
TimePts=[100000 118250 136500 154750 173000];

Iter=1;
for i = 1:size(TR,2)
    %i=1;
    %disp([num2str(i) ', basalSize=' num2str(TR{i}.s.m0) ', meanD=' num2str(HP.sdm(i)) ', stdD='])
    sprintf('Foodweb_%s_%s%s.mat', TimeData, num2str(Iter), ['_numSpecies' num2str(P.n) '_dT' num2str(P.dT*73000) '_basalSize' num2str(P.s.m0) '_meanD' num2str(HP.sdm(i)) '_stdD' num2str(HP.sdv(i))])  
    %% make parameters for a given set of traits
    [P B Z T] = make_parameters(TR,i);
    TE = zeros(P.n, P.nx, 5); %trophic efficiency
    PB = zeros(P.n, P.nx); %doubling time
    prodZ=zeros(P.nx, 1); %productivity of basal resource
    prodB=zeros(P.nx, P.n); %productivity of heterotrophs
    
    TE_5 = zeros(P.n, P.nx,5); %trophic efficiency
    PB_5 = zeros(P.n, P.nx,5); %doubling time
    prodZ_5=zeros(P.nx, 1,5); %productivity of basal resource
    prodB_5=zeros(P.nx, P.n,5); %productivity of heterotrophs
    
    
    %with warming
    TEw_5 = zeros(P.n, P.nx,5);
    PBw_5 = zeros(P.n, P.nx,5);
    prodZw_5=zeros(P.nx, 1,5);
    prodBw_5=zeros(P.nx, P.n,5);
    
    %% Iterate model forward in time (days at the moment)
    YearStartT=1;
    for t = 1:P.Tend;
        %    for t = 1:5000;
        
        if t==100001 %transition time when no-warming and warming experiments diverge from common states
            Bw=B; Zw =Z;
        end
        
        % fix
        B(B<eps) = 0;% eps;
        Z(Z<eps) = 0;% eps;
        if t>100000
            Bw(Bw<eps) = 0;% eps;
            Zw(Zw<eps) = 0;% eps;
        end
        
        % Shift thermal gradient
        T1      = P.T;% + t.*P.dT; %<<< add this when time is right
        if t>100000
            T1w      = P.T + (t-100000)*P.dT;
        end
        %T1      = P.T + 2*sin(2*pi*((365-t.*P.dt)/365)); %seasonal cycle
        %T1      = P.T + 2*sin(2*pi*((365-t.*P.dt/10)/365)); %decadal cycle
        
        
        % demographics
        B        = sub_move(B); % move
        [gainB gainZ dB dZ v TE PB TLik TLi TLk TLall] = sub_demog(t,B,Z,T1); % grow/die
        if t>100000
            Bw        = sub_move(Bw); % move
            [gainBw gainZw dBw dZw vw TEw PBw TLikw TLiw TLkw TLallw] = sub_demog(t,Bw,Zw,T1w); % grow/die
        end
        % time step
        Z = Z + (dZ .* P.dt);
        B = B + (dB .* P.dt);
        
        if t>100000
            Zw = Zw + (dZw .* P.dt);
            Bw = Bw + (dBw .* P.dt);
        end
        %fix again?
        %B(B(:,:,t+1)<eps) = eps;
        
        %disp(num2str(t))
        
        %record major time points:
        Tpos=find(t==TimePts);
        if ~isempty(Tpos)
            Z_5(:,:,Tpos)=Z;
            B_5(:,:,Tpos)=B;
            Zw_5(:,:,Tpos)=Zw;
            Bw_5(:,:,Tpos)=Bw;
            gainB_5(:,:,Tpos)=gainB;
            gainZ_5(:,:,Tpos)=gainZ;
            v_5(:,:,:,Tpos)=v;
            TE_5(:,:,Tpos)=TE;
            PB_5(:,:,Tpos)=PB;
            TLik_5(:,:,Tpos)=TLik;
            TLi_5(:,:,Tpos)=TLi;
            TLk_5(:,:,Tpos)=TLk;
            TLall_5(Tpos)=TLall;
            gainBw_5(:,:,Tpos)=gainBw;
            gainZw_5(:,:,Tpos)=gainZw;
            vw_5(:,:,:,Tpos)=vw;
            TEw_5(:,:,Tpos)=TEw;
            PBw_5(:,:,Tpos)=PBw;
            TLikw_5(:,:,Tpos)=TLikw;
            TLiw_5(:,:,Tpos)=TLiw;
            TLkw_5(:,:,Tpos)=TLkw;
            TLallw_5(Tpos)=TLallw;
        end
    end
    
    %     %% Save ensemble member here
    %     ncwrite('./Data/Data_ensembles.nc','B',...
    %             reshape(B,[1 P.nx P.n P.Tend+1]),[i 1 1 1]);
    %     ncwrite('./Data/Data_ensembles.nc','Z',...
    %             reshape(Z,[1 P.nx P.Tend+1]),[i 1 1]);
    
    %%-- Data analysis
    %B(B<eps) = eps;
    %Z(Z<eps) = eps;
    %% Simple plotting to file (see Fig/biomass_plots.pdf)
    %plot_demog_spatial(25, Z, B, P, v) % plots ts from patch 25
    %plot_demog_spatial_B(1,Z, B, P) % plots ts from patch 1 (coldest)
    
%     set(0,'DefaultFigureVisible', 'on'); %use this to suppress plot display but still runs through the stats
%     [EnsembleGbar(i,:),EnsembleGBbins(i,:),EnsembleprodBbins(i,:),avgB(:,:,i),avgP(:,:,i),figs]=plot_demog_spatial_B(P.nx,Z, B, P,HP,prodZ,prodB,i);
%     savefig(figs,[FoodWebFile '_' num2str(i) '_TimeSeries_noWarming.fig'],'compact');
%     close(figs);
%     [EnsembleGbar_w(i,:),EnsembleGBbins_w(i,:),EnsembleprodBbins_w(i,:),avgB_w(:,:,i),avgP_w(:,:,i),figs]=plot_demog_spatial_B(P.nx,Zw_comp, Bw_comp, P,HP,prodZw_comp,prodBw_comp,i);
%     savefig(figs,[FoodWebFile '_' num2str(i) '_TimeSeries_Warming.fig'],'compact');
%     close(figs);
    
    %plot_demog_spatial_spectra(P.nx,Z, B(:,:,ceil(4*t/5):t), P,HP,prodZ,prodB,i) %spectra plots only
    %Ps(i)=P; %store parameters
    
    if min(min(min(B)))<log10(eps)
       disp('negative biomass error'); 
    end
    %clear Z B prodZ prodB Zw_comp Bw_comp prodZw_comp prodBw_comp 
    %save and overwrite after every new simulation in the ensemble
    FoodWebFile=sprintf('Foodweb_%s_%s%s.mat', TimeData, num2str(Iter), ['_numSpecies' num2str(P.n) '_dT' num2str(P.dT*73000) '_basalSize' num2str(P.s.m0) '_meanD' num2str(HP.sdm(i)) '_stdD' num2str(HP.sdv(i))]);
    %save(FoodWebFile, 'Z_5','B_5','gainB_5','gainZ_5','v_5','TE_5','PB_5','TLik_5','TLi_5','TLk_5','TLall_5','Zw_5','Bw_5','gainBw_5','gainZw_5','vw_5','TEw_5','PBw_5','TLikw_5','TLiw_5','TLkw_5','TLallw_5','P');
    savemat_Foodweb(FoodWebFile,Z_5,B_5,gainB_5,gainZ_5,v_5,TE_5,PB_5,TLik_5,TLi_5,TLk_5,TLall_5,Zw_5,Bw_5,gainBw_5,gainZw_5,vw_5,TEw_5,PBw_5,TLikw_5,TLiw_5,TLkw_5,TLallw_5,P);
    clear Z B gainB gainZ dB dZ v TE PB TLik TLi TLk TLall Zw Bw gainBw gainZw dBw dZw vw TEw PBw TLikw TLiw TLkw TLallw Z_5 B_5 gainB_5 gainZ_5  v_5 TE_5 PB_5 TLik_5 TLi_5 TLk_5 TLall_5 Zw_5 Bw_5 gainBw_5 gainZw_5 vw_5 TEw_5 PBw_5 TLikw_5 TLiw_5 TLkw_5 TLallw_5
    if Iter<numIt
        Iter=Iter+1;
    else
        Iter=1;
    end
end
%compute and plot ensemble stats
% scrsz = get(0,'ScreenSize');
% fig=figure ('Color', [1 1 1],'Position',[1 scrsz(2) scrsz(3) scrsz(4)]);
% subplot(2,3,1)
% b=bar(nanmean(EnsembleGbar)-floor(log10(eps)),'FaceColor',BiomassColor);
%     hold on
%     b=bar(Y2bins-floor(log10(eps)),'FaceColor',ProdColor);
%     errorbar([1:1+numBins]-0.04,Ybins-floor(log10(eps)),Ybins-YbinsTimeLo,YbinsTimeHi-Ybins,'.','Color',BiomassErrColor,'LineWidth',2);
%     errorbar([1:1+numBins]+0.04,Y2bins-floor(log10(eps)),Y2bins-Y2binsTimeLo,Y2binsTimeHi-Y2bins,'.','Color',ProdErrColor,'LineWidth',2);
%    