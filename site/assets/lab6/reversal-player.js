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

function revealLinkedFilm() {
  const preview = document.getElementById('radiometer-videos');
  const target = document.getElementById(location.hash.slice(1));
  if (preview && target && preview.contains(target) && target !== preview && !preview.open) {
    preview.open = true;
    target.scrollIntoView();
  }
}
revealLinkedFilm();
window.addEventListener('hashchange', revealLinkedFilm);
