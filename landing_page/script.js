(function () {
  "use strict";

  var attribution = collectAttribution();

  trackCampaignVisit(attribution);
  trackOutboundClicks(attribution);

  var revealItems = document.querySelectorAll(".reveal");

  if (!("IntersectionObserver" in window)) {
    revealItems.forEach(function (item) {
      item.classList.add("is-visible");
    });
    return;
  }

  var observer = new IntersectionObserver(function (entries) {
    entries.forEach(function (entry) {
      if (!entry.isIntersecting) {
        return;
      }

      entry.target.classList.add("is-visible");
      observer.unobserve(entry.target);
    });
  }, {
    rootMargin: "0px 0px -10% 0px",
    threshold: 0.12
  });

  revealItems.forEach(function (item) {
    observer.observe(item);
  });

  function collectAttribution() {
    var params = new URLSearchParams(window.location.search);
    var keys = [
      "utm_source",
      "utm_medium",
      "utm_campaign",
      "utm_content",
      "utm_term",
      "mube_source",
      "mube_campaign"
    ];
    var data = {};

    keys.forEach(function (key) {
      var value = params.get(key);

      if (value) {
        data[key] = value;
      }
    });

    return data;
  }

  function trackCampaignVisit(data) {
    if (!hasAttribution(data)) {
      return;
    }

    pushEvent("campaign_landing_visit", data);

    if (data.utm_medium === "qr" || data.utm_source === "palheta") {
      pushEvent("qr_visit", data);
    }
  }

  function trackOutboundClicks(data) {
    document.addEventListener("click", function (event) {
      var link = event.target.closest("a[href]");

      if (!link) {
        return;
      }

      var destination = new URL(link.href, window.location.href);

      pushEvent("landing_link_click", Object.assign({}, data, {
        destination_host: destination.host,
        destination_path: destination.pathname,
        destination_url: destination.href,
        link_label: normalizeText(link.textContent)
      }));
    });
  }

  function hasAttribution(data) {
    return Object.keys(data).length > 0;
  }

  function pushEvent(name, params) {
    window.dataLayer = window.dataLayer || [];
    window.dataLayer.push(Object.assign({
      event: name
    }, params || {}));

    if (typeof window.gtag === "function") {
      window.gtag("event", name, params || {});
    }
  }

  function normalizeText(value) {
    return (value || "").replace(/\s+/g, " ").trim().slice(0, 80);
  }
})();
