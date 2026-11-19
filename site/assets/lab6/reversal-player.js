function setReplayTime(video, start) {
  if (video.readyState >= 1) {
    video.currentTime = start;
  } else {
    video.addEventListener('loadedmetadata', () => { video.currentTime = start; }, {once: true});
  }
}

// Each replay link controls the player in its own figure.
document.querySelectorAll('[data-reversal-time]').forEach(link => {
  const video = link.closest('figure').querySelector('video');
  link.addEventListener('click', event => {
    if (event.ctrlKey || event.metaKey || event.shiftKey || event.altKey) return;
    event.preventDefault();
    setReplayTime(video, Number(link.dataset.reversalTime));
    video.play().catch(() => video.focus());
  });
});

// A handout link to a replay cue opens the matching shot, paused.
function cueLinkedReplay() {
  const link = document.getElementById(location.hash.slice(1));
  if (!link || !link.matches('a[data-reversal-time]')) return;
  const figure = link.closest('figure');
  const video = figure.querySelector('video');
  setReplayTime(video, Number(link.dataset.reversalTime));
  if (video.readyState === 0) {
    video.preload = 'metadata';
    if (video.networkState !== HTMLMediaElement.NETWORK_LOADING) video.load();
  }
  figure.scrollIntoView({block: 'start', behavior: 'instant'});
}
window.addEventListener('load', cueLinkedReplay);
window.addEventListener('hashchange', cueLinkedReplay);

// Keep links to recordings that were previously embedded on the course and lab pages.
function followArchivedRecording() {
  const archive = document.querySelector('[data-reversal-archive]');
  if (!archive) return;
  const id = location.hash.slice(1);
  const moved = ['rotation-reversal', 'reversal-video', 'reversal-caption',
    'position-swap', 'swap-video', 'swap-caption', 'position-swap-plots'];
  const target = document.getElementById(id);
  if (target) {
    const details = target.closest('details');
    if (details && !details.open) {
      details.open = true;
      target.scrollIntoView({block: 'start', behavior: 'instant'});
    }
  } else if (['radiometer-videos','reverse-rotation','home-rotation-caption'].includes(id)) {
    location.replace(archive.href + '#two-rotors');
  } else if (moved.includes(id)) {
    location.replace(archive.href + '#' + id);
  }
}
followArchivedRecording();
window.addEventListener('hashchange', followArchivedRecording);
