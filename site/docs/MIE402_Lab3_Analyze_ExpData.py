"""Lab 3 double-pendulum tracking QC and analysis (2026-10-20).

Run: python MIE402_Lab3_Analyze_ExpData.py recording.mat --output results
Requires numpy, scipy, matplotlib. Does not fit a single sine or change raw data.
Angles: absolute link angles from downward vertical; x right, y up, millimetres.
"""
from __future__ import annotations
import argparse
import json
from pathlib import Path
import zipfile
import numpy as np
from scipy.io import loadmat
from scipy.signal import savgol_filter
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt


def runs(mask):
    edge = np.diff(np.r_[False, np.asarray(mask, bool), False].astype(int))
    return list(zip(np.flatnonzero(edge == 1), np.flatnonzero(edge == -1)))  # stop exclusive


def read_expdata(path):
    path = Path(path)
    if path.suffix.lower() == ".zip":
        from io import BytesIO
        with zipfile.ZipFile(path) as z:
            files = [n for n in z.namelist() if n.lower().endswith('.mat') and not n.startswith('__MACOSX/')]
            if len(files) != 1:
                raise ValueError('Select a MAT directly, or a ZIP containing exactly one MAT.')
            source = BytesIO(z.read(files[0]))
            data = loadmat(source)
    else:
        data = loadmat(path)
    if 'ExpData' not in data:
        raise ValueError('MAT file has no ExpData variable.')
    d = np.asarray(data['ExpData'], dtype=float)
    if d.ndim != 2 or d.shape[1] < 5 or d.shape[0] < 20:
        raise ValueError('ExpData must contain >=20 rows: time_s,x1_mm,y1_mm,x2_mm,y2_mm.')
    return d[:, :5].copy()


def reference_length(length, supplied=None):
    if supplied is not None:
        if not np.isfinite(supplied) or supplied <= 0:
            raise ValueError('Measured link lengths must be positive millimetres.')
        return float(supplied)
    finite = length[np.isfinite(length) & (length > 0)]
    if len(finite) < 20:
        raise ValueError('Too few nonzero measured link vectors to establish geometry.')
    # An estimate for tracking QC, NOT an independent physical length calibration.
    return float(np.median(finite))


def repair_angle(t, wrapped, observed, max_gap_s=0.05, max_bridge_deg=60):
    """Fill bounded SHORT gaps by a circular arc. Never extrapolate or join long gaps."""
    theta = np.where(observed, wrapped, np.nan).copy()
    interpolated = np.zeros(len(t), bool)
    for a, b in runs(~observed):
        if a == 0 or b == len(t):
            continue  # preserve original time and missing endpoints
        duration = t[b] - t[a-1]  # complete anchor-to-anchor interval
        delta = np.arctan2(np.sin(theta[b]-theta[a-1]), np.cos(theta[b]-theta[a-1]))
        if duration <= max_gap_s and abs(delta) <= np.deg2rad(max_bridge_deg):
            frac = (t[a:b]-t[a-1])/duration
            theta[a:b] = theta[a-1] + frac*delta
            interpolated[a:b] = True
    usable = np.isfinite(theta)
    continuous = np.full(len(t), np.nan)
    for a, b in runs(usable):
        continuous[a:b] = np.unwrap(theta[a:b])
    principal = np.arctan2(np.sin(continuous), np.cos(continuous))
    return principal, continuous, interpolated


def velocity(t, theta, interpolated, window_s=0.021):
    """SG derivative only on uniform segments; retain gaps and mark interpolation influence."""
    out = np.full(len(t), np.nan)
    smooth = np.full(len(t), np.nan)
    influence = np.zeros(len(t), bool)
    for a, b in runs(np.isfinite(theta)):
        if b-a < 5:
            continue
        dt = float(np.median(np.diff(t[a:b])))
        w = max(5, int(round(window_s/dt)) | 1)
        w = min(w, (b-a) if (b-a) % 2 else b-a-1)
        uniform = np.max(np.abs(np.diff(t[a:b])-dt)) <= .02*dt
        smooth[a:b] = savgol_filter(theta[a:b], w, 3, mode='interp')
        if uniform:
            out[a:b] = savgol_filter(theta[a:b], w, 3, deriv=1, delta=dt, mode='interp')
        else:
            out[a:b] = np.gradient(smooth[a:b], t[a:b])
        # Edges and neighborhoods of filled data are not independent velocity measurements.
        h = w//2
        influence[a:a+h] = True
        influence[b-h:b] = True
        local = np.convolve(interpolated[a:b].astype(int), np.ones(w), mode='same') > 0
        influence[a:b] |= local
    out[influence] = np.nan
    return out, smooth, influence


def spectrum(t, theta, interpolated):
    """Use the longest complete segment only. Do not concatenate across tracking gaps."""
    segments = runs(np.isfinite(theta))
    if not segments:
        return None
    a, b = max(segments, key=lambda s: s[1]-s[0])
    if b-a < 32:
        return None
    dt = float(np.median(np.diff(t[a:b])))
    if np.max(np.abs(np.diff(t[a:b])-dt)) > .02*dt:
        return None
    x = theta[a:b].copy()
    rotating = np.ptp(x) > 2*np.pi
    if rotating:
        x = np.sin(x)
        quantity = 'sin(theta): dimensionless orientation, not an angle spectrum'
        unit = '1'
    else:
        quantity = 'continuous angle within one valid segment'
        unit = 'rad'
    x -= np.mean(x)
    w = np.hanning(len(x))
    f = np.fft.rfftfreq(len(x), dt)
    amplitude = 2*np.abs(np.fft.rfft(x*w))/np.sum(w)
    amplitude[0] /= 2
    if len(x) % 2 == 0:
        amplitude[-1] /= 2
    peak = int(np.argmax(amplitude[1:])+1)
    return dict(f=f, amplitude=amplitude, peak_hz=float(f[peak]), unit=unit,
                quantity=quantity, start_index=int(a), stop_index=int(b),
                time_start_s=float(t[a]), time_end_s=float(t[b-1]),
                bin_spacing_hz=float(1/(len(x)*dt)),
                interpolated_fraction=float(np.mean(interpolated[a:b])))


def analyze(d, length_tolerance=.20, max_gap_s=.05, measured_lengths=None):
    d = np.asarray(d, float)
    if d.ndim != 2 or d.shape[1] < 5 or len(d) < 20:
        raise ValueError('Expected at least 20 rows and five columns.')
    if not 0 < length_tolerance < .5 or max_gap_s < 0:
        raise ValueError('Use 0 < length tolerance < 0.5 and a nonnegative gap limit.')
    t = d[:, 0].copy()
    if not np.all(np.isfinite(t)) or np.any(np.diff(t) <= 0):
        raise ValueError('Time must be finite and strictly increasing; check the original capture fps.')
    xy = d[:, 1:5]
    v1, v2 = xy[:, :2], xy[:, 2:]-xy[:, :2]
    lengths = np.column_stack((np.linalg.norm(v1, axis=1), np.linalg.norm(v2, axis=1)))
    refs = [reference_length(lengths[:, j], None if measured_lengths is None else measured_lengths[j]) for j in range(2)]
    finite1 = np.all(np.isfinite(v1), axis=1)
    finite2 = np.all(np.isfinite(xy), axis=1)
    geometry = np.abs(lengths/np.array(refs)-1) <= length_tolerance
    observed = np.column_stack((finite1 & geometry[:, 0], finite2 & geometry[:, 0] & geometry[:, 1]))
    wrapped = np.column_stack((np.arctan2(v1[:, 0], -v1[:, 1]), np.arctan2(v2[:, 0], -v2[:, 1])))
    principal = np.full((len(t), 2), np.nan)
    continuous = principal.copy(); omega = principal.copy(); smooth = principal.copy()
    filled = np.zeros((len(t), 2), bool); derivative_mask = filled.copy(); specs = []
    links = []
    for j in range(2):
        principal[:, j], continuous[:, j], filled[:, j] = repair_angle(t, wrapped[:, j], observed[:, j], max_gap_s)
        omega[:, j], smooth[:, j], derivative_mask[:, j] = velocity(t, continuous[:, j], filled[:, j])
        good = np.isfinite(continuous[:, j]); idx = np.flatnonzero(good)
        links.append(dict(link=j+1, qc_reference_length_mm=refs[j],
            missing_coordinate_rows=int(np.sum(~(finite1 if j == 0 else finite2))),
            geometry_rejected_rows=int(np.sum((finite1 if j == 0 else finite2) & ~observed[:, j])),
            observed_rows=int(np.sum(observed[:, j])), interpolated_rows=int(np.sum(filled[:, j])),
            unresolved_rows=int(np.sum(~good)), usable_segments=len(runs(good)),
            first_usable_time_s=float(t[idx[0]]) if len(idx) else None,
            last_usable_time_s=float(t[idx[-1]]) if len(idx) else None,
            continuous_angle_range_deg=[float(np.rad2deg(np.nanmin(continuous[:, j]))),float(np.rad2deg(np.nanmax(continuous[:, j])))] if len(idx) else None,
            continuous_segments=[dict(start_s=float(t[a]),end_s=float(t[b-1]),
                net_turns=float((continuous[b-1,j]-continuous[a,j])/(2*np.pi)))
                for a,b in runs(good)]))
    common = np.all(np.isfinite(continuous), axis=1)
    for j in range(2):
        sp=spectrum(t,np.where(common,continuous[:,j],np.nan),filled[:,j])
        specs.append(sp)
        links[j]['spectrum']=None if sp is None else {k:v for k,v in sp.items() if k not in ('f','amplitude')}
    qc = dict(rows=len(t), input_time_start_s=float(t[0]), input_time_end_s=float(t[-1]),
              inferred_sample_rate_hz=float(1/np.median(np.diff(t))),
              sample_rate_note='Inferred from MAT timestamps; verify against capture settings, not playback fps.',
              length_tolerance_fraction=length_tolerance, maximum_bridge_s=max_gap_s,
              maximum_bridge_angle_deg=60, velocity_smoothing_window_s=.021, links=links,
              interpretation='QC length estimates are not physical calibration. Large continuous angles can represent genuine rotations; do not clip them. Each segment has its own winding origin. No angle is inferred across a long gap. Both FFTs use the same longest joint-valid segment. Large-angle spectra are descriptive, not small-angle mode identification.')
    return dict(t=t, raw=d[:, :5].copy(), lengths=lengths, refs=np.array(refs), observed=observed,
                filled=filled, principal=principal, continuous=continuous, omega=omega,
                smoothed_theta=smooth, derivative_influence=derivative_mask, spectra=specs, qc=qc)


def legacy(d):
    good = np.all(np.isfinite(d[:, 1:5]), axis=1)
    xyz = np.column_stack([np.interp(d[:,0], d[good,0], d[good,j]) for j in range(1,5)])
    x,y,X,Y=xyz.T
    return np.column_stack((np.unwrap(np.arctan2(x,-y)),np.unwrap(np.arctan2(X-x,-(Y-y)))))


def save_results(result, source, directory):
    out=Path(directory);out.mkdir(parents=True,exist_ok=True)
    r=result;t=r['t'];raw=r['raw'];old=legacy(raw)
    r['qc']['legacy_unwrapped_range_deg']=[[float(np.rad2deg(np.min(old[:,j]))),float(np.rad2deg(np.max(old[:,j])))] for j in range(2)]
    (out/'quality_report.json').write_text(json.dumps(r['qc'],indent=2),encoding='utf-8')
    arr=np.column_stack((raw,np.rad2deg(r['principal']),np.rad2deg(r['continuous']),r['omega'],r['lengths'],r['observed'],r['filled'],r['derivative_influence']))
    header='time_s,x1_raw_mm,y1_raw_mm,x2_raw_mm,y2_raw_mm,theta1_principal_deg,theta2_principal_deg,theta1_continuous_deg,theta2_continuous_deg,omega1_rad_s,omega2_rad_s,L1_raw_mm,L2_raw_mm,link1_observed,link2_observed,link1_interpolated,link2_interpolated,omega1_influenced,omega2_influenced'
    np.savetxt(out/'analysis_with_quality_flags.csv',arr,delimiter=',',header=header,comments='',fmt='%.10g')
    colors=['#1766a6','#bb3d28']
    fig,ax=plt.subplots(3,1,figsize=(12,10),sharex=True,constrained_layout=True)
    for j,c in enumerate(colors):
        ax[0].plot(t,np.rad2deg(old[:,j]),color=c,lw=.8,label=f'Link {j+1}: legacy unwrap')
        ax[1].plot(t,np.rad2deg(r['continuous'][:,j]),color=c,lw=1,label=f'Link {j+1}: geometry checked')
        ax[2].plot(t,r['lengths'][:,j],color=c,lw=.7,label=f'Link {j+1} tracked length')
        ax[2].axhline(r['refs'][j],color=c,ls='--',alpha=.5)
    ax[0].set(ylabel='Legacy angle (deg)',title=f'{Path(source).name}: diagnosis; raw tracking is unchanged')
    ax[1].set(ylabel='Continuous angle (deg)',title='Continuous angle only within valid/repaired segments; no forced angle clipping')
    ax[2].set(xlabel='Original MAT time (s)',ylabel='Tracked length (mm)',title='Collapsed link length identifies duplicate/wrong bob detections')
    for a in ax:a.grid(alpha=.25);a.legend(loc='upper right')
    fig.savefig(out/'01_tracking_diagnosis.png',dpi=170,bbox_inches='tight',pad_inches=.12);plt.close(fig)
    fig,ax=plt.subplots(2,1,figsize=(12,7),sharex=True,constrained_layout=True)
    for j,c in enumerate(colors):
        deg=np.rad2deg(r['principal'][:,j]).copy()
        # Break the drawn line at the angular coordinate's branch cut, not the data itself.
        display=deg.copy();display[np.r_[False,np.abs(np.diff(deg))>180]]=np.nan
        ax[0].plot(t,display,color=c,lw=1,label=f'Link {j+1}')
        idx=r['filled'][:,j]
        ax[0].scatter(t[idx],deg[idx],s=12,facecolors='none',edgecolors=c,label=f'Link {j+1}: short-gap estimates')
        ax[1].plot(t,r['omega'][:,j],color=c,lw=.7,label=f'Link {j+1}')
    ax[0].set(ylabel='Principal angle (deg)',title='Report figure: orientation from downward vertical; +/-180 deg is a coordinate wrap')
    ax[1].set(xlabel='Original MAT time (s)',ylabel='Angular velocity (rad/s)',title='21 ms local-polynomial derivative; interpolation neighborhoods and edges excluded')
    for a in ax:a.grid(alpha=.25);a.legend()
    fig.savefig(out/'02_angles_and_velocity.png',dpi=170,bbox_inches='tight',pad_inches=.12);plt.close(fig)
    fig,axes=plt.subplots(1,2,figsize=(12,4),constrained_layout=True)
    for j,ax in enumerate(axes):
        sp=r['spectra'][j]
        if sp is None:
            ax.text(.1,.5,'No sufficiently long, uniformly sampled\ncomplete segment for FFT.');continue
        ax.plot(sp['f'],sp['amplitude'],color=colors[j]);ax.set_xlim(0,min(15,sp['f'][-1]))
        ax.axvline(sp['peak_hz'],ls='--',color='black',lw=.8)
        ax.set(xlabel='Frequency (Hz)',ylabel=f"One-sided amplitude ({sp['unit']})",title=f"Link {j+1}: largest bin {sp['peak_hz']:.3f} Hz\nsegment {sp['time_start_s']:.3f}–{sp['time_end_s']:.3f} s")
        ax.grid(alpha=.25)
        np.savetxt(out/f'link{j+1}_spectrum.csv',np.column_stack((sp['f'],sp['amplitude'])),delimiter=',',header='frequency_hz,amplitude',comments='')
    fig.savefig(out/'03_frequency_spectra.png',dpi=170,bbox_inches='tight',pad_inches=.12);plt.close(fig)
    fig,ax=plt.subplots(figsize=(12,4.5),constrained_layout=True)
    for j,c in enumerate(colors):
        ax.plot(t,np.rad2deg(r['continuous'][:,j]),color=c,lw=1,label=f'Link {j+1}')
        for a,b in runs(np.isfinite(r['continuous'][:,j])):
            if b-a>10:
                turns=(r['continuous'][b-1,j]-r['continuous'][a,j])/(2*np.pi)
                if abs(turns)>1:ax.annotate(f'{turns:.2f} net turns within this segment',xy=(t[a],np.rad2deg(r['continuous'][a,j])),xytext=(10,-30),textcoords='offset points',color=c)
    ax.set(xlabel='Original MAT time (s)',ylabel='Continuous angle (deg)',title='Rotation diagnostic: winding is preserved only within each connected valid segment')
    ax.grid(alpha=.25);ax.legend();fig.savefig(out/'04_continuous_rotation.png',dpi=170,bbox_inches='tight',pad_inches=.12);plt.close(fig)
    summary='\n'.join(f"Link {v['link']}: {v['observed_rows']} observed; {v['geometry_rejected_rows']} finite geometry failures; {v['interpolated_rows']} short-gap estimates; {v['unresolved_rows']} rows remain missing." for v in r['qc']['links'])
    (out/'READ_RESULTS.txt').write_text(f"Source: {Path(source).name}\n\n{summary}\n\nUse 02_angles_and_velocity.png for orientation and 03_frequency_spectra.png for frequency content on the SAME joint-valid interval. Explain interpolation and quality checks. 01_tracking_diagnosis.png shows the old processing and geometry failures; a large accumulated angle is NOT by itself a failure. 04_continuous_rotation.png retains possible genuine multi-turn motion. A principal angle in [-180,180] is a coordinate convention, not clipping or a change to the measured trajectory. Raw coordinates and original timestamps are preserved in the CSV. Do not interpret spectral peaks from a strongly nonlinear run as the two small-angle modes. Confirm original capture fps. A MAT file cannot recover the true position during a long tracking failure; retrack the EXISTING video if needed, rather than inventing data. Geometry checks cannot detect every wrong point on a plausible path; verify representative video frames.\n",encoding='utf-8')
    return r['qc']


def main():
    p=argparse.ArgumentParser(description=__doc__)
    p.add_argument('input',type=Path);p.add_argument('--output',type=Path,default=Path('Lab3_results'))
    p.add_argument('--max-gap',type=float,default=.05);p.add_argument('--length-tolerance',type=float,default=.20)
    p.add_argument('--lengths-mm',type=float,nargs=2,default=None)
    a=p.parse_args();d=read_expdata(a.input)
    r=analyze(d,a.length_tolerance,a.max_gap,a.lengths_mm)
    qc=save_results(r,a.input,a.output)
    print(json.dumps(qc,indent=2))


if __name__=='__main__':main()
