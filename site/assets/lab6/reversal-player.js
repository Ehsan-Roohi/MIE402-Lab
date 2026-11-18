// Each replay link controls the player in its own figure.
document.querySelectorAll('[data-reversal-time]').forEach(link => {
  const video = link.closest('figure').querySelector('video');
  link.addEventListener('click', event => {
    if (event.ctrlKey || event.metaKey || event.shiftKey || event.altKey) return;
    event.preventDefault();
    const start = Number(link.dataset.reversalTime);
    if (video.readyState >= 1) {
      video.currentTime = start;
    } else {
      video.addEventListener('loadedmetadata', () => { video.currentTime = start; }, {once: true});
    }
    video.play().catch(() => video.focus());
  });
});

// Keep links to recordings that were previously embedded on the course and lab pages.
function followArchivedRecording() {
  const archive = document.querySelector('a[data-reversal-archive]');
  if (!archive) return;
  const id = location.hash.slice(1);
  const moved = ['rotation-reversal', 'reversal-video', 'reversal-caption',
    'position-swap', 'swap-video', 'swap-caption', 'position-swap-plots'];
  if (moved.includes(id)) location.replace(archive.href + '#' + id);
}
followArchivedRecording();
window.addEventListener('hashchange', followArchivedRecording);
