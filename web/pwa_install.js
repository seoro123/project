(function () {
  let deferredPrompt = null;

  const isStandalone =
    window.matchMedia('(display-mode: standalone)').matches ||
    window.navigator.standalone === true;

  if (isStandalone) {
    document.documentElement.classList.add('pwa-standalone');
    return;
  }

  const style = document.createElement('style');
  style.textContent = `
    .pwa-install-card {
      position: fixed;
      left: 50%;
      bottom: calc(18px + env(safe-area-inset-bottom));
      z-index: 999999;
      display: none;
      align-items: center;
      gap: 10px;
      width: min(92vw, 420px);
      padding: 12px 14px;
      border: 1px solid rgba(111, 154, 244, 0.38);
      border-radius: 18px;
      background: rgba(248, 252, 255, 0.94);
      box-shadow: 0 16px 44px rgba(45, 59, 92, 0.20);
      color: #26324a;
      font-family: system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif;
      transform: translateX(-50%);
      backdrop-filter: blur(18px);
      -webkit-backdrop-filter: blur(18px);
    }
    .pwa-install-card[data-visible="true"] {
      display: flex;
    }
    .pwa-install-card strong {
      display: block;
      font-size: 14px;
      font-weight: 800;
      line-height: 1.25;
    }
    .pwa-install-card span {
      display: block;
      margin-top: 2px;
      font-size: 12px;
      font-weight: 650;
      color: rgba(38, 50, 74, 0.68);
      line-height: 1.25;
    }
    .pwa-install-card button {
      border: 0;
      border-radius: 999px;
      padding: 9px 12px;
      font: inherit;
      font-size: 12px;
      font-weight: 800;
      color: #ffffff;
      background: #6f9af4;
      box-shadow: 0 8px 18px rgba(111, 154, 244, 0.28);
    }
    .pwa-install-card .pwa-install-close {
      color: rgba(38, 50, 74, 0.54);
      background: transparent;
      box-shadow: none;
      padding: 6px;
    }
  `;
  document.head.appendChild(style);

  const card = document.createElement('div');
  card.className = 'pwa-install-card';
  card.innerHTML = `
    <div style="flex:1">
      <strong>Mood Diary 앱으로 설치</strong>
      <span>홈 화면에서 주소창 없이 앱처럼 열 수 있어요.</span>
    </div>
    <button type="button" class="pwa-install-action">설치</button>
    <button type="button" class="pwa-install-close" aria-label="닫기">×</button>
  `;

  const showCard = () => {
    if (sessionStorage.getItem('pwa-install-dismissed') === '1') {
      return;
    }
    card.dataset.visible = 'true';
  };

  window.addEventListener('beforeinstallprompt', (event) => {
    event.preventDefault();
    deferredPrompt = event;
    if (!card.isConnected) {
      document.body.appendChild(card);
    }
    showCard();
  });

  card.querySelector('.pwa-install-action').addEventListener('click', async () => {
    if (!deferredPrompt) {
      return;
    }
    card.dataset.visible = 'false';
    deferredPrompt.prompt();
    await deferredPrompt.userChoice;
    deferredPrompt = null;
  });

  card.querySelector('.pwa-install-close').addEventListener('click', () => {
    sessionStorage.setItem('pwa-install-dismissed', '1');
    card.dataset.visible = 'false';
  });

  window.addEventListener('appinstalled', () => {
    deferredPrompt = null;
    card.dataset.visible = 'false';
  });
})();
