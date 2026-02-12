/* ==========================================================================
   Mube Landing Page — Interactive Script
   ========================================================================== */

(function () {
  'use strict';

  /* ---- Header Scroll Effect ---- */
  const header = document.getElementById('header');

  function handleHeaderScroll() {
    if (window.scrollY > 60) {
      header.classList.add('scrolled');
    } else {
      header.classList.remove('scrolled');
    }
  }

  window.addEventListener('scroll', handleHeaderScroll, { passive: true });
  handleHeaderScroll();

  /* ---- Mobile Menu ---- */
  const hamburger = document.getElementById('hamburger');
  const mobileMenu = document.getElementById('mobileMenu');

  hamburger.addEventListener('click', function () {
    hamburger.classList.toggle('active');
    mobileMenu.classList.toggle('active');
    document.body.style.overflow = mobileMenu.classList.contains('active') ? 'hidden' : '';
  });

  // Close mobile menu when a link is clicked
  document.querySelectorAll('.mobile-menu__link, .mobile-menu__cta').forEach(function (link) {
    link.addEventListener('click', function () {
      hamburger.classList.remove('active');
      mobileMenu.classList.remove('active');
      document.body.style.overflow = '';
    });
  });

  /* ---- Smooth Scroll ---- */
  document.querySelectorAll('a[href^="#"]').forEach(function (anchor) {
    anchor.addEventListener('click', function (e) {
      var target = document.querySelector(this.getAttribute('href'));
      if (target) {
        e.preventDefault();
        var offset = header.offsetHeight + 20;
        var top = target.getBoundingClientRect().top + window.scrollY - offset;
        window.scrollTo({ top: top, behavior: 'smooth' });
      }
    });
  });

  /* ---- Scroll Animations (Intersection Observer) ---- */
  var animatedElements = document.querySelectorAll('.animate-on-scroll');

  var observerOptions = {
    root: null,
    rootMargin: '0px 0px -60px 0px',
    threshold: 0.1
  };

  var observer = new IntersectionObserver(function (entries) {
    entries.forEach(function (entry) {
      if (entry.isIntersecting) {
        var delay = parseInt(entry.target.getAttribute('data-delay') || '0', 10);
        setTimeout(function () {
          entry.target.classList.add('visible');
        }, delay);
        observer.unobserve(entry.target);
      }
    });
  }, observerOptions);

  animatedElements.forEach(function (el) {
    observer.observe(el);
  });

  /* ---- Counter Animation ---- */
  var counters = document.querySelectorAll('.stat__number[data-target]');
  var counterStarted = {};

  var counterObserver = new IntersectionObserver(function (entries) {
    entries.forEach(function (entry) {
      if (entry.isIntersecting) {
        var el = entry.target;
        var id = el.getAttribute('data-target');

        if (counterStarted[id]) return;
        counterStarted[id] = true;

        animateCounter(el, parseInt(id, 10));
        counterObserver.unobserve(el);
      }
    });
  }, { threshold: 0.5 });

  counters.forEach(function (counter) {
    counterObserver.observe(counter);
  });

  function animateCounter(element, target) {
    var duration = 2000;
    var startTime = null;
    var startVal = 0;

    function easeOutExpo(t) {
      return t === 1 ? 1 : 1 - Math.pow(2, -10 * t);
    }

    function step(timestamp) {
      if (!startTime) startTime = timestamp;
      var progress = Math.min((timestamp - startTime) / duration, 1);
      var easedProgress = easeOutExpo(progress);
      var currentVal = Math.floor(startVal + (target - startVal) * easedProgress);

      element.textContent = formatNumber(currentVal);

      if (progress < 1) {
        requestAnimationFrame(step);
      } else {
        element.textContent = formatNumber(target);
      }
    }

    requestAnimationFrame(step);
  }

  function formatNumber(num) {
    if (num >= 1000) {
      return num.toLocaleString('pt-BR');
    }
    return num.toString();
  }

  /* ---- Active Nav Link Highlighting ---- */
  var sections = document.querySelectorAll('section[id]');
  var navLinks = document.querySelectorAll('.header__link');

  function highlightNav() {
    var scrollY = window.scrollY + header.offsetHeight + 100;

    sections.forEach(function (section) {
      var sectionTop = section.offsetTop;
      var sectionHeight = section.offsetHeight;
      var sectionId = section.getAttribute('id');

      if (scrollY >= sectionTop && scrollY < sectionTop + sectionHeight) {
        navLinks.forEach(function (link) {
          link.classList.remove('active');
          if (link.getAttribute('href') === '#' + sectionId) {
            link.classList.add('active');
          }
        });
      }
    });
  }

  window.addEventListener('scroll', highlightNav, { passive: true });

  /* ---- Parallax on Hero Glows ---- */
  var glows = document.querySelectorAll('.hero__glow');

  function parallaxGlows() {
    var scrollY = window.scrollY;
    if (scrollY > window.innerHeight) return;

    glows.forEach(function (glow, i) {
      var speed = (i + 1) * 0.05;
      glow.style.transform = 'translateY(' + scrollY * speed + 'px)';
    });
  }

  window.addEventListener('scroll', parallaxGlows, { passive: true });

})();
