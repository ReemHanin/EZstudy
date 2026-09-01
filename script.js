/* העתקת ערך בודד ללוח, עם משוב ויזואלי קצר */

(function () {
  'use strict';

  var FEEDBACK_MS = 1500;
  var timers = new WeakMap();
  var liveRegion = document.getElementById('live-region');

  function copyText(text) {
    if (navigator.clipboard && window.isSecureContext) {
      return navigator.clipboard.writeText(text);
    }

    // גיבוי לדפדפנים ישנים או להקשר לא מאובטח
    return new Promise(function (resolve, reject) {
      var textarea = document.createElement('textarea');
      textarea.value = text;
      textarea.setAttribute('readonly', '');
      textarea.style.position = 'fixed';
      textarea.style.top = '0';
      textarea.style.opacity = '0';
      document.body.appendChild(textarea);
      textarea.select();
      textarea.setSelectionRange(0, textarea.value.length);

      var ok = false;
      try {
        ok = document.execCommand('copy');
      } catch (err) {
        ok = false;
      }

      document.body.removeChild(textarea);
      ok ? resolve() : reject(new Error('copy failed'));
    });
  }

  function showFeedback(button) {
    button.classList.add('is-copied');
    if (liveRegion) {
      liveRegion.textContent = 'הועתק';
    }

    clearTimeout(timers.get(button));
    timers.set(
      button,
      setTimeout(function () {
        button.classList.remove('is-copied');
        if (liveRegion) {
          liveRegion.textContent = '';
        }
      }, FEEDBACK_MS)
    );
  }

  document.querySelectorAll('.copy').forEach(function (button) {
    button.addEventListener('click', function () {
      var target = document.getElementById(button.dataset.copyTarget);
      if (!target) {
        return;
      }

      var value = target.textContent.trim();

      copyText(value).then(
        function () {
          showFeedback(button);
        },
        function () {
          // אם ההעתקה נכשלה — מסמנים את הערך כדי שניתן יהיה להעתיק ידנית
          var selection = window.getSelection();
          var range = document.createRange();
          range.selectNodeContents(target);
          selection.removeAllRanges();
          selection.addRange(range);
        }
      );
    });
  });
})();
