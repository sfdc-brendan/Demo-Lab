/**
 * Preview host script. Generic across cards — copy it verbatim into a new
 * card's preview/ folder.
 *
 * Responsibilities:
 *   - show one [data-state] block at a time
 *   - accept state changes from the gallery via postMessage
 *   - report content height so the gallery can size the iframe to the card
 *   - give buttons local feedback, so a click does something without
 *     pretending anything was actually sent
 */
(function () {
    'use strict';

    function states() {
        return Array.prototype.slice.call(document.querySelectorAll('[data-state]'));
    }

    function showState(id) {
        var blocks = states();
        var match = blocks.some(function (el) { return el.getAttribute('data-state') === id; });
        var target = match ? id : (blocks[0] && blocks[0].getAttribute('data-state'));
        blocks.forEach(function (el) {
            el.classList.toggle('is-active', el.getAttribute('data-state') === target);
        });
        resetButtons();
        reportHeight();
    }

    function resetButtons() {
        document.querySelectorAll('.lc-button').forEach(function (btn) {
            if (btn.dataset.originalLabel) {
                btn.textContent = btn.dataset.originalLabel;
                delete btn.dataset.originalLabel;
            }
            btn.disabled = false;
            btn.classList.remove('lc-button_flash');
        });
    }

    function reportHeight() {
        // rAF so the measurement happens after the state swap has laid out.
        requestAnimationFrame(function () {
            // Measure the visible card, not the document. Once the parent sizes
            // the iframe, documentElement.scrollHeight can never report smaller
            // than that, so switching to a shorter state would never shrink it.
            var active = document.querySelector('[data-state].is-active');
            var height = active
                ? Math.ceil(active.getBoundingClientRect().height) + 2 // room for the card's shadow
                : document.documentElement.scrollHeight;
            try {
                window.parent.postMessage({ type: 'lt-preview:height', height: height }, '*');
            } catch (e) { /* cross-origin parent, nothing to do */ }
        });
    }

    function handleClick(event) {
        var btn = event.target.closest('.lc-button');
        if (!btn || btn.disabled) return;

        // Sticky: the button has done its job and stays done (e.g. a reply sent).
        if (btn.dataset.stickyLabel) {
            btn.dataset.originalLabel = btn.dataset.originalLabel || btn.textContent;
            btn.textContent = btn.dataset.stickyLabel;
            btn.disabled = true;
            return;
        }

        // Flash: momentary acknowledgement, then back to normal.
        if (btn.dataset.flashLabel) {
            var original = btn.dataset.originalLabel || btn.textContent;
            btn.dataset.originalLabel = original;
            btn.textContent = btn.dataset.flashLabel;
            btn.classList.add('lc-button_flash');
            setTimeout(function () {
                btn.textContent = original;
                btn.classList.remove('lc-button_flash');
                delete btn.dataset.originalLabel;
            }, 1400);
        }
    }

    window.addEventListener('message', function (event) {
        var data = event.data;
        if (data && data.type === 'lt-preview:set-state') {
            showState(data.state);
        }
    });

    document.addEventListener('click', handleClick);
    window.addEventListener('load', reportHeight);
    window.addEventListener('resize', reportHeight);

    var initial = new URLSearchParams(window.location.search).get('state');
    showState(initial || 'default');
})();
