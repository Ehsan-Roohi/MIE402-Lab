function R = Lab6_Molecular_MC(N,Tgas,Thot,Tcold,diffuseFraction,seed)
% Educational free-molecular wall-collision Monte Carlo, NOT a rotor DSMC.
% Independent equal gas reservoirs at Tgas supply the two sides of a plate.
% Flux-weighted normal speeds have density m*v/(k*T)*exp(-m*v^2/(2*k*T)).
% Diffuse re-emission uses wall temperature; specular re-emission preserves
% incident normal speed. The same incident samples and reflection choices
% are paired across faces to reduce noise. Outgoing diffuse draws are independent.
% No gas-gas collisions, finite-vane edges, enclosure, heat balance or rotor.
validateattributes(N,{'numeric'},{'scalar','integer','>=',2});
validateattributes([Tgas Thot Tcold],{'numeric'},{'real','finite','positive'});
validateattributes(diffuseFraction,{'numeric'},{'scalar','>=',0,'<=',1,'finite'});
validateattributes(seed,{'numeric'},{'scalar','integer','nonnegative','finite'});
state=rng; cleanup=onCleanup(@() rng(state)); %#ok<NASGU>
rng(seed,'twister');
kB=1.380649e-23; moleculeMass=28*1.66053906660e-27; % illustrative N2
vin=sqrt(-2*kB*Tgas/moleculeMass*log(max(rand(N,1),realmin)));
vh=sqrt(-2*kB*Thot/moleculeMass*log(max(rand(N,1),realmin)));
vc=sqrt(-2*kB*Tcold/moleculeMass*log(max(rand(N,1),realmin)));
diffuse=rand(N,1)<diffuseFraction;
vh(~diffuse)=vin(~diffuse); vc(~diffuse)=vin(~diffuse);
% Incident number flux Gamma=n*sqrt(kB*Tgas/(2*pi*m)). Since p=n*kB*Tgas,
% Gamma*m/p = 1/sqrt(2*pi*kB*Tgas/m). Impulse per collision is m*(vin+vout).
factor=1/sqrt(2*pi*kB*Tgas/moleculeMass);
sample=factor*(vh-vc); % positive means net recoil from hot toward cold face
analytic=diffuseFraction/2*(sqrt(Thot/Tgas)-sqrt(Tcold/Tgas));
R=struct('deltaP_over_p',mean(sample),'analytic_deltaP_over_p',analytic,...
 'standard_error',std(sample)/sqrt(N),'samples_deltaP_over_p',sample,...
 'normal_speed_hot_m_s',vh,'normal_speed_cold_m_s',vc,...
 'hotPressure_over_p',factor*mean(vin+vh),...
 'coldPressure_over_p',factor*mean(vin+vc),...
 'kB',kB,'molecule_mass_kg',moleculeMass,'Tgas_K',Tgas,...
 'Thot_K',Thot,'Tcold_K',Tcold,'diffuse_fraction',diffuseFraction,'N',N,'seed',seed);
end
