(function () {
  "use strict";

  const REGION = "southamerica-east1";
  const FUNCTION_REGIONS = {
    getConversationAdminDetail: "us-central1",
    listGigsAdmin: "us-central1",
    getGigAdminDetail: "us-central1",
    getMatchpointAdminOverview: "us-central1",
    getSystemAdminData: "us-central1",
    inspectFirestorePath: "us-central1",
    inspectStoragePrefix: "us-central1",
  };
  const SECTION_META = {
    dashboard: { title: "Dashboard", kicker: "Visao geral do backend", loader: loadDashboard },
    users: { title: "Usuarios", kicker: "Base, perfis e moderacao", loader: loadUsers },
    conversations: { title: "Conversas", kicker: "Chat, mensagens e compliance", loader: loadConversations },
    gigs: { title: "Gigs", kicker: "Marketplace e operacao", loader: loadGigs },
    matchpoint: { title: "MatchPoint", kicker: "Matching, hashtags e ranking", loader: loadMatchpoint },
    featured: { title: "Perfis em destaque", kicker: "Curadoria do feed", loader: loadFeatured },
    reports: { title: "Denuncias", kicker: "Moderacao e processamento", loader: loadReports },
    suspensions: { title: "Suspensoes", kicker: "Controle de acesso", loader: loadSuspensions },
    tickets: { title: "Tickets", kicker: "Suporte e resposta administrativa", loader: loadTickets },
    system: { title: "Sistema", kicker: "Infra, config e exploradores", loader: loadSystem },
  };

  const ui = {
    loginScreen: requiredElement("login-screen"),
    loginForm: requiredElement("login-form"),
    loginEmail: requiredElement("login-email"),
    loginPassword: requiredElement("login-password"),
    loginButton: requiredElement("login-btn"),
    loginError: requiredElement("login-error"),
    adminShell: requiredElement("admin-shell"),
    sidebar: requiredElement("sidebar"),
    sidebarScrim: requiredElement("sidebar-scrim"),
    sidebarOpen: requiredElement("sidebar-open"),
    sidebarClose: requiredElement("sidebar-close"),
    sidebarAdminEmail: requiredElement("sidebar-admin-email"),
    topbarAdminEmail: requiredElement("topbar-admin-email"),
    logoutButton: requiredElement("logout-btn"),
    pageKicker: requiredElement("page-kicker"),
    pageTitle: requiredElement("page-title"),
    refreshActiveSection: requiredElement("refresh-active-section"),
    navItems: Array.from(document.querySelectorAll(".nav-item[data-section]")),
    pageSections: Array.from(document.querySelectorAll(".page-section")),
    detailDrawer: requiredElement("detail-drawer"),
    detailDrawerScrim: requiredElement("detail-drawer-scrim"),
    drawerClose: requiredElement("drawer-close"),
    drawerKicker: requiredElement("drawer-kicker"),
    drawerTitle: requiredElement("drawer-title"),
    drawerSubtitle: requiredElement("drawer-subtitle"),
    drawerBody: requiredElement("drawer-body"),
    toast: requiredElement("toast"),
    dashboardQuickStats: requiredElement("dashboard-quick-stats"),
    dashboardMetrics: requiredElement("dashboard-metrics"),
    dashboardHealth: requiredElement("dashboard-health"),
    dashboardActivity: requiredElement("dashboard-activity"),
    dashboardAudit: requiredElement("dashboard-audit"),
    usersRefreshButton: requiredElement("users-refresh-btn"),
    userSearchInput: requiredElement("user-search-input"),
    usersStatusFilter: requiredElement("users-status-filter"),
    usersProfileFilter: requiredElement("users-profile-filter"),
    usersRegistrationFilter: requiredElement("users-registration-filter"),
    usersPageSize: requiredElement("users-page-size"),
    userSearchButton: requiredElement("user-search-btn"),
    userClearButton: requiredElement("user-clear-btn"),
    usersSummary: requiredElement("users-summary"),
    usersResults: requiredElement("users-results"),
    usersLoadMoreButton: requiredElement("users-load-more-btn"),
    conversationSearchInput: requiredElement("conversation-search-input"),
    conversationLimitSelect: requiredElement("conversation-limit-select"),
    conversationsRefreshButton: requiredElement("conversations-refresh-btn"),
    conversationsList: requiredElement("conversations-list"),
    conversationsDetail: requiredElement("conversations-detail"),
    gigSearchInput: requiredElement("gig-search-input"),
    gigStatusFilter: requiredElement("gig-status-filter"),
    gigLimitSelect: requiredElement("gig-limit-select"),
    gigsRefreshButton: requiredElement("gigs-refresh-btn"),
    gigsList: requiredElement("gigs-list"),
    gigsDetail: requiredElement("gigs-detail"),
    matchpointRefreshButton: requiredElement("matchpoint-refresh-btn"),
    matchpointSummary: requiredElement("matchpoint-summary"),
    matchpointHashtags: requiredElement("matchpoint-hashtags"),
    matchpointMatches: requiredElement("matchpoint-matches"),
    matchpointInteractions: requiredElement("matchpoint-interactions"),
    featuredUidInput: requiredElement("featured-uid-input"),
    featuredLookupButton: requiredElement("featured-lookup-btn"),
    featuredAddButton: requiredElement("featured-add-btn"),
    featuredPreview: requiredElement("featured-preview"),
    featuredSaveButton: requiredElement("featured-save-btn"),
    featuredList: requiredElement("featured-list"),
    reportsFilter: requiredElement("reports-filter"),
    reportsList: requiredElement("reports-list"),
    suspendUidInput: requiredElement("suspend-uid"),
    suspendReasonInput: requiredElement("suspend-reason"),
    suspendDaysInput: requiredElement("suspend-days"),
    suspendConfirmButton: requiredElement("suspend-confirm-btn"),
    suspensionsFilter: requiredElement("suspensions-filter"),
    suspensionsList: requiredElement("suspensions-list"),
    ticketsFilter: requiredElement("tickets-filter"),
    ticketsList: requiredElement("tickets-list"),
    ticketsLoadMoreButton: requiredElement("tickets-load-more-btn"),
    ticketsDetail: requiredElement("tickets-detail"),
    systemRefreshButton: requiredElement("system-refresh-btn"),
    systemConfigCards: requiredElement("system-config-cards"),
    systemTranscodeJobs: requiredElement("system-transcode-jobs"),
    firestorePathInput: requiredElement("firestore-path-input"),
    firestoreLimitSelect: requiredElement("firestore-limit-select"),
    firestoreInspectButton: requiredElement("firestore-inspect-btn"),
    firestoreExplorerResult: requiredElement("firestore-explorer-result"),
    storagePrefixInput: requiredElement("storage-prefix-input"),
    storageLimitSelect: requiredElement("storage-limit-select"),
    storageInspectButton: requiredElement("storage-inspect-btn"),
    storageExplorerResult: requiredElement("storage-explorer-result"),
  };

  const firebaseApp = firebase.app();
  const auth = firebase.auth();
  const functionsByRegion = {};

  const state = {
    activeSection: resolveInitialSection(),
    sectionLoaded: {},
    authUser: null,
    dashboard: null,
    dashboardAudit: null,
    dashboardLoadErrors: { overview: false, audit: false },
    users: { items: [], mode: "list", totalUsersBase: 0, scannedCount: 0, total: 0, hasMore: false, nextCursor: null },
    userDetail: null,
    conversations: { items: [], total: 0, selectedId: "", detail: null },
    gigs: { items: [], total: 0, selectedId: "", detail: null },
    matchpoint: null,
    featured: { uids: [], profiles: [], preview: null },
    reports: [],
    suspensions: [],
    tickets: { items: [], selectedId: "", hasMore: false, nextCursor: null },
    system: { data: null, firestoreResult: null, storageResult: null },
    drawerPayloads: Object.create(null),
    toastTimer: null,
  };

  auth.setPersistence(firebase.auth.Auth.Persistence.LOCAL).catch(function () {
    return null;
  });

  bindStaticEvents();
  exposeDebugHandle();
  setLoggedOutUI();
  auth.onAuthStateChanged(handleAuthStateChanged);

  function bindStaticEvents() {
    ui.loginForm.addEventListener("submit", onLoginSubmit);
    ui.logoutButton.addEventListener("click", onLogoutClick);
    ui.sidebarOpen.addEventListener("click", openSidebar);
    ui.sidebarClose.addEventListener("click", closeSidebar);
    ui.sidebarScrim.addEventListener("click", closeSidebar);
    ui.detailDrawerScrim.addEventListener("click", closeDrawer);
    ui.drawerClose.addEventListener("click", closeDrawer);
    ui.refreshActiveSection.addEventListener("click", function () {
      activateSection(state.activeSection, { force: true }).catch(handleError);
    });
    ui.navItems.forEach(function (button) {
      button.addEventListener("click", function () {
        activateSection(button.dataset.section).catch(handleError);
      });
    });

    ui.usersRefreshButton.addEventListener("click", function () { loadUsers({ force: true, reset: true }).catch(handleError); });
    ui.userSearchButton.addEventListener("click", function () { loadUsers({ force: true, reset: true }).catch(handleError); });
    ui.userClearButton.addEventListener("click", function () {
      ui.userSearchInput.value = "";
      ui.usersStatusFilter.value = "all";
      ui.usersProfileFilter.value = "all";
      ui.usersRegistrationFilter.value = "all";
      loadUsers({ force: true, reset: true }).catch(handleError);
    });
    ui.usersLoadMoreButton.addEventListener("click", function () { loadUsers({ append: true }).catch(handleError); });
    ui.userSearchInput.addEventListener("keydown", function (event) {
      if (event.key === "Enter") {
        event.preventDefault();
        loadUsers({ force: true, reset: true }).catch(handleError);
      }
    });
    [ui.usersStatusFilter, ui.usersProfileFilter, ui.usersRegistrationFilter, ui.usersPageSize].forEach(function (element) {
      element.addEventListener("change", function () {
        loadUsers({ force: true, reset: true }).catch(handleError);
      });
    });

    ui.conversationsRefreshButton.addEventListener("click", function () { loadConversations({ force: true }).catch(handleError); });
    ui.conversationSearchInput.addEventListener("keydown", function (event) {
      if (event.key === "Enter") {
        event.preventDefault();
        loadConversations({ force: true }).catch(handleError);
      }
    });
    ui.conversationLimitSelect.addEventListener("change", function () { loadConversations({ force: true }).catch(handleError); });

    ui.gigsRefreshButton.addEventListener("click", function () { loadGigs({ force: true }).catch(handleError); });
    ui.gigSearchInput.addEventListener("keydown", function (event) {
      if (event.key === "Enter") {
        event.preventDefault();
        loadGigs({ force: true }).catch(handleError);
      }
    });
    ui.gigStatusFilter.addEventListener("change", function () { loadGigs({ force: true }).catch(handleError); });
    ui.gigLimitSelect.addEventListener("change", function () { loadGigs({ force: true }).catch(handleError); });

    ui.matchpointRefreshButton.addEventListener("click", function () { loadMatchpoint({ force: true }).catch(handleError); });
    ui.featuredLookupButton.addEventListener("click", function () { lookupFeaturedPreview().catch(handleError); });
    ui.featuredAddButton.addEventListener("click", function () {
      if (state.featured.preview) {
        addFeaturedFromUid(stringValue(state.featured.preview.uid)).catch(handleError);
      }
    });
    ui.featuredUidInput.addEventListener("keydown", function (event) {
      if (event.key === "Enter") {
        event.preventDefault();
        lookupFeaturedPreview().catch(handleError);
      }
    });
    ui.featuredSaveButton.addEventListener("click", function () { saveFeaturedProfiles().catch(handleError); });
    ui.reportsFilter.addEventListener("change", function () { loadReports({ force: true }).catch(handleError); });
    ui.suspendConfirmButton.addEventListener("click", function () { createSuspension().catch(handleError); });
    ui.suspensionsFilter.addEventListener("change", function () { loadSuspensions({ force: true }).catch(handleError); });
    ui.ticketsFilter.addEventListener("change", function () { loadTickets({ force: true, reset: true }).catch(handleError); });
    ui.ticketsLoadMoreButton.addEventListener("click", function () { loadTickets({ append: true }).catch(handleError); });
    ui.systemRefreshButton.addEventListener("click", function () { loadSystem({ force: true }).catch(handleError); });
    ui.firestoreInspectButton.addEventListener("click", function () { inspectFirestorePath().catch(handleError); });
    ui.storageInspectButton.addEventListener("click", function () { inspectStoragePrefix().catch(handleError); });
    ui.firestorePathInput.addEventListener("keydown", function (event) {
      if (event.key === "Enter") {
        event.preventDefault();
        inspectFirestorePath().catch(handleError);
      }
    });
    ui.storagePrefixInput.addEventListener("keydown", function (event) {
      if (event.key === "Enter") {
        event.preventDefault();
        inspectStoragePrefix().catch(handleError);
      }
    });

    document.addEventListener("click", onDocumentActionClick);
    window.addEventListener("hashchange", function () {
      const section = resolveInitialSection();
      if (section !== state.activeSection && state.authUser) {
        activateSection(section).catch(handleError);
      }
    });
    window.addEventListener("keydown", function (event) {
      if (event.key === "Escape") {
        closeDrawer();
        closeSidebar();
      }
    });
  }

  function exposeDebugHandle() {
    window.mubeAdmin = {
      state: state,
      activateSection: activateSection,
      openUserDetail: openUserDetail,
      refresh: function () {
        return activateSection(state.activeSection, { force: true });
      },
    };
  }

  async function handleAuthStateChanged(user) {
    if (!user) {
      state.authUser = null;
      setLoggedOutUI();
      return;
    }

    setLoginLoading(true, "Validando acesso...");
    try {
      await ensureAdminAccess(user);
      state.authUser = user;
      setLoggedInUI(user);
      await activateSection(state.activeSection, { force: true });
    } catch (error) {
      await auth.signOut().catch(function () { return null; });
      showLoginError(getErrorMessage(error));
      setLoggedOutUI();
    } finally {
      setLoginLoading(false, "Entrar");
    }
  }

  async function onLoginSubmit(event) {
    event.preventDefault();
    hideLoginError();
    const email = ui.loginEmail.value.trim();
    const password = ui.loginPassword.value;
    if (!email || !password) {
      showLoginError("Informe email e senha para entrar.");
      return;
    }
    setLoginLoading(true, "Entrando...");
    try {
      await auth.signInWithEmailAndPassword(email, password);
    } catch (error) {
      showLoginError(getErrorMessage(error));
      setLoginLoading(false, "Entrar");
    }
  }

  async function onLogoutClick() {
    setButtonBusy(ui.logoutButton, true);
    try {
      await auth.signOut();
    } catch (error) {
      handleError(error);
    } finally {
      setButtonBusy(ui.logoutButton, false);
    }
  }

  async function ensureAdminAccess(user) {
    let tokenResult = await user.getIdTokenResult(true);
    if (tokenResult.claims && tokenResult.claims.admin === true) {
      return tokenResult;
    }

    const email = user.email || ui.loginEmail.value.trim();
    if (!email) {
      throw new Error("Nao foi possivel validar a conta administrativa.");
    }

    try {
      await callFunction("setAdminClaim", { email: email });
      await user.getIdToken(true);
      tokenResult = await user.getIdTokenResult(true);
      if (tokenResult.claims && tokenResult.claims.admin === true) {
        showToast("Acesso administrativo habilitado para esta conta.", "success");
        return tokenResult;
      }
    } catch (error) {
      if (!isPermissionDeniedError(error)) {
        throw error;
      }
    }

    throw new Error("Sua conta autenticou, mas ainda nao possui permissao de admin.");
  }

  async function activateSection(section, options) {
    const settings = options || {};
    if (!SECTION_META[section]) {
      section = "dashboard";
    }
    state.activeSection = section;
    ui.navItems.forEach(function (button) {
      button.classList.toggle("is-active", button.dataset.section === section);
    });
    ui.pageSections.forEach(function (panel) {
      const isActive = panel.id === "section-" + section;
      panel.classList.toggle("hidden", !isActive);
      panel.classList.toggle("is-active", isActive);
    });
    ui.pageTitle.textContent = SECTION_META[section].title;
    ui.pageKicker.textContent = SECTION_META[section].kicker;
    window.history.replaceState(null, "", "#" + section);
    closeSidebar();

    const shouldReload = settings.force === true || state.sectionLoaded[section] !== true;
    if (state.authUser && shouldReload) {
      await SECTION_META[section].loader({ force: settings.force === true, reset: settings.reset === true });
      state.sectionLoaded[section] = !(section === "dashboard" && state.dashboardLoadErrors.overview);
    }
  }

  async function loadDashboard(options) {
    const force = Boolean(options && options.force);
    if (!force && state.dashboard) {
      renderDashboard();
      return;
    }

    setLoadingMarkup(ui.dashboardQuickStats, "Carregando visao executiva...", "query_stats");
    setLoadingMarkup(ui.dashboardMetrics, "Carregando indicadores...", "insights");
    setLoadingMarkup(ui.dashboardHealth, "Avaliando saude operacional...", "monitor_heart");
    setLoadingMarkup(ui.dashboardActivity, "Montando linhas do tempo...", "schedule");
    setLoadingMarkup(ui.dashboardAudit, "Buscando buckets de auditoria...", "analytics");

    const results = await Promise.allSettled([
      callFunction("getDashboardOverview", {}),
      callFunction("getMatchpointRankingAuditDashboard", { limit: 12 }),
    ]);
    state.dashboard = results[0].status === "fulfilled" ? results[0].value : null;
    state.dashboardAudit = results[1].status === "fulfilled" ? results[1].value : null;
    state.dashboardLoadErrors.overview = results[0].status === "rejected";
    state.dashboardLoadErrors.audit = results[1].status === "rejected";

    renderDashboard();

    if (state.dashboardLoadErrors.overview && state.dashboardLoadErrors.audit) {
      showToast("Nao foi possivel carregar o dashboard agora.", "error");
      return;
    }
    if (state.dashboardLoadErrors.overview) {
      showToast("Dashboard carregado parcialmente. A visao geral falhou.", "error");
      return;
    }
    if (state.dashboardLoadErrors.audit) {
      showToast("Dashboard carregado com falha na auditoria MatchPoint.", "error");
    }
  }

  function renderDashboard() {
    if (!state.dashboard) {
      ui.dashboardQuickStats.innerHTML = renderEmptyState(
        state.dashboardLoadErrors.overview ?
          "Nao foi possivel carregar a visao executiva agora." :
          "Nenhum dado de dashboard disponivel.",
        "dashboard"
      );
      ui.dashboardMetrics.innerHTML = renderEmptyState(
        "Indicadores indisponiveis no momento.",
        "insights"
      );
      ui.dashboardHealth.innerHTML = renderEmptyState(
        "Saude operacional indisponivel no momento.",
        "monitor_heart"
      );
      ui.dashboardActivity.innerHTML = renderEmptyState(
        "Atividade recente indisponivel no momento.",
        "schedule"
      );
      renderDashboardAudit();
      return;
    }

    const counts = asObject(state.dashboard.counts);
    ui.dashboardQuickStats.innerHTML = [
      renderSummaryCard({ icon: "groups", label: "Usuarios totais", value: formatNumber(counts.totalUsers), text: formatNumber(counts.completedProfiles) + " com cadastro concluido" }),
      renderSummaryCard({ icon: "forum", label: "Conversas", value: formatNumber(counts.totalConversations), text: formatNumber(counts.totalMatches) + " matches registrados" }),
      renderSummaryCard({ icon: "event_note", label: "Gigs", value: formatNumber(counts.totalGigs), text: formatNumber(counts.openGigs) + " abertas agora" }),
      renderSummaryCard({ icon: "support_agent", label: "Tickets abertos", value: formatNumber(counts.openTickets), text: formatNumber(counts.pendingReports) + " denuncias pendentes" }),
    ].join("");

    ui.dashboardMetrics.innerHTML = [
      renderMetricCard({ icon: "radio_button_checked", label: "Perfis MatchPoint ativos", value: formatNumber(counts.activeMatchpointProfiles), text: "Usuarios com perfil ativo no motor de matching" }),
      renderMetricCard({ icon: "swap_horiz", label: "Interacoes", value: formatNumber(counts.totalInteractions), text: "Likes e dislikes acumulados" }),
      renderMetricCard({ icon: "gpp_bad", label: "Suspensoes ativas", value: formatNumber(counts.activeSuspensions), text: "Contas com acesso bloqueado" }),
      renderMetricCard({ icon: "video_settings", label: "Transcodes em processamento", value: formatNumber(counts.processingTranscodes), text: formatNumber(counts.featuredProfiles) + " perfis em destaque" }),
    ].join("");

    ui.dashboardHealth.innerHTML = [
      healthCard("Denuncias pendentes", counts.pendingReports, counts.pendingReports > 0 ? "pill-red" : "pill-green", counts.pendingReports > 0 ? "Existe fila de moderacao aguardando tratamento." : "Fila de denuncias sem pendencias relevantes."),
      healthCard("Tickets abertos", counts.openTickets, counts.openTickets > 4 ? "pill-yellow" : "pill-blue", counts.openTickets > 4 ? "Vale revisar tempos de resposta do suporte." : "Atendimento sob controle."),
      healthCard("Jobs de transcode", counts.processingTranscodes, counts.processingTranscodes > 0 ? "pill-blue" : "pill-green", counts.processingTranscodes > 0 ? "Pipeline de video com trabalhos em andamento." : "Nenhum job ativo no momento."),
      healthCard("Curadoria do feed", counts.featuredProfiles, counts.featuredProfiles === 0 ? "pill-red" : "pill-accent", counts.featuredProfiles === 0 ? "A lista de destaques esta vazia." : "Lista de destaque pronta para o app."),
    ].join("");

    ui.dashboardActivity.innerHTML = [
      timelineColumn("Usuarios recentes", "person_add", asArray(state.dashboard.recentUsers).slice(0, 4).map(function (user) {
        return timelineItem(
          escapeHtml(stringValue(user.nome, stringValue(user.uid))),
          [escapeHtml(stringValue(user.email, "Sem email")), escapeHtml(stringValue(user.displayLocation, "Local nao informado"))].join(" | "),
          badgeHtml(stringValue(user.statusLabel, "Ativo"), stringValue(user.statusKey, "active")),
          actionButton("open-user", "Ver", "visibility", { uid: stringValue(user.uid) }, "secondary")
        );
      })),
      timelineColumn("Conversas recentes", "forum", asArray(state.dashboard.recentConversations).slice(0, 4).map(function (conversation) {
        const participants = asArray(conversation.participants).map(function (user) {
          return stringValue(user.nome, stringValue(user.uid));
        }).filter(Boolean);
        return timelineItem(
          escapeHtml(participants.join(" x ") || stringValue(conversation.id)),
          escapeHtml(stringValue(conversation.lastMessageText, "Sem ultima mensagem")),
          badgeHtml(stringValue(conversation.type, "direct"), stringValue(conversation.type, "active")),
          actionButton("open-conversation", "Abrir", "chat", { conversationId: stringValue(conversation.id) }, "secondary")
        );
      })),
      timelineColumn("Gigs recentes", "event_note", asArray(state.dashboard.recentGigs).slice(0, 4).map(function (gig) {
        return timelineItem(
          escapeHtml(stringValue(gig.title, "Gig sem titulo")),
          escapeHtml([stringValue(asObject(gig.creator).nome, "Criador nao identificado"), "Candidaturas: " + formatNumber(gig.applicantCount)].join(" | ")),
          badgeHtml(stringValue(gig.status, "open"), stringValue(gig.status, "open")),
          actionButton("open-gig", "Detalhar", "event_repeat", { gigId: stringValue(gig.id) }, "secondary")
        );
      })),
      timelineColumn("Operacao recente", "warning_amber", [
        timelineItem("Tickets mais novos", escapeHtml(asArray(state.dashboard.recentTickets).length > 0 ? asArray(state.dashboard.recentTickets).map(function (doc) {
          return stringValue(asObject(doc.data).subject, stringValue(doc.id));
        }).slice(0, 3).join(", ") : "Nenhum ticket recente"), badgeHtml(formatNumber(counts.openTickets) + " abertos", "open"), actionButton("open-section", "Suporte", "support_agent", { section: "tickets" }, "secondary")),
        timelineItem("Trending hashtags", escapeHtml(asArray(state.dashboard.trendingHashtags).slice(0, 3).map(function (tag) {
          return "#" + stringValue(tag.label);
        }).join(", ") || "Sem hashtags"), badgeHtml(formatNumber(asArray(state.dashboard.trendingHashtags).length) + " itens", "processed"), actionButton("open-section", "MatchPoint", "bolt", { section: "matchpoint" }, "secondary")),
        timelineItem("Config do app", escapeHtml(state.dashboard.configSummary && state.dashboard.configSummary.exists ? "Documento app_data encontrado." : "Documento app_data nao encontrado."), badgeHtml(state.dashboard.configSummary && state.dashboard.configSummary.exists ? "Disponivel" : "Ausente", state.dashboard.configSummary && state.dashboard.configSummary.exists ? "processed" : "pending"), actionButton("open-section", "Sistema", "memory", { section: "system" }, "secondary")),
      ]),
    ].join("");

    renderDashboardAudit();
  }

  function renderDashboardAudit() {
    const audit = state.dashboardAudit;
    if (audit && asArray(audit.buckets).length > 0) {
      const summary = asObject(audit.summary);
      ui.dashboardAudit.innerHTML = [
        stackCard("Resumo acumulado", ["Eventos: " + formatNumber(summary.totalEvents), "Pool medio/evento: " + formatDecimal(summary.averagePoolPerEvent), "Retorno medio/evento: " + formatDecimal(summary.averageReturnedPerEvent), "Buckets com geohash: " + formatNumber(summary.geohashUsedCount)].join(" | "), pillHtml("Auditoria ativa", "pill-blue")),
      ].concat(asArray(audit.buckets).slice(0, 8).map(function (bucket) {
        return stackCard("Bucket " + formatDateTime(bucket.bucketStart), ["Eventos: " + formatNumber(bucket.totalEvents), "Pool: " + formatNumber(bucket.poolTotal), "Retornados: " + formatNumber(bucket.returnedTotal), "Proximidade: " + formatNumber(bucket.returnedProximity)].join(" | "), pillHtml("Geohash " + formatNumber(bucket.geohashUsedCount), "pill-accent"));
      })).join("");
    } else if (state.dashboardLoadErrors.audit) {
      ui.dashboardAudit.innerHTML = renderEmptyState("Nao foi possivel carregar a auditoria de ranking agora.", "analytics");
    } else {
      ui.dashboardAudit.innerHTML = renderEmptyState("Nenhuma auditoria de ranking encontrada.", "analytics");
    }
  }

  async function loadUsers(options) {
    const settings = options || {};
    const search = (ui.userSearchInput.value || "").trim();
    const pageSize = Math.min(toInteger(ui.usersPageSize.value, 24), 60);
    const filters = {
      status: ui.usersStatusFilter.value || "all",
      profileType: ui.usersProfileFilter.value || "all",
      registrationStatus: ui.usersRegistrationFilter.value || "all",
    };

    if (settings.reset || !settings.append) {
      state.users.nextCursor = null;
    }

    if (search) {
      setLoadingMarkup(ui.usersResults, "Buscando usuarios...", "search");
      const response = await callFunction("searchUsers", {
        query: search,
        limit: Math.min(pageSize, 50),
      });
      state.users.items = asArray(response.results || response.users);
      state.users.total = toInteger(response.total, state.users.items.length);
      state.users.mode = "search";
      state.users.hasMore = false;
      state.users.totalUsersBase = state.users.total;
      renderUsers();
      return;
    }

    if (!settings.append) {
      setLoadingMarkup(ui.usersResults, "Carregando base de usuarios...", "groups");
    }

    const response = await callFunction("listUsersAdmin", {
      pageSize: pageSize,
      cursor: settings.append ? state.users.nextCursor : null,
      status: filters.status,
      profileType: filters.profileType,
      registrationStatus: filters.registrationStatus,
      includeTotal: !settings.append,
    });

    const incoming = asArray(response.users);
    state.users.mode = "list";
    state.users.items = settings.append ? state.users.items.concat(incoming) : incoming;
    state.users.total = state.users.items.length;
    state.users.totalUsersBase = toInteger(response.totalUsersBase, settings.append ? state.users.totalUsersBase : incoming.length);
    state.users.scannedCount = toInteger(response.scannedCount, 0);
    state.users.hasMore = response.hasMore === true;
    state.users.nextCursor = response.nextCursor || null;
    renderUsers();
  }

  function renderUsers() {
    const users = state.users.items;
    ui.usersSummary.innerHTML = [
      renderSummaryCard({ icon: "groups", label: "Usuarios carregados", value: formatNumber(users.length), text: state.users.mode === "search" ? "Resultado da busca atual" : "Pagina exibida agora" }),
      renderSummaryCard({ icon: "database", label: "Base total", value: formatNumber(state.users.totalUsersBase), text: "Contagem base do collection users" }),
      renderSummaryCard({ icon: "gpp_bad", label: "Suspensos na pagina", value: formatNumber(users.filter(function (user) { return stringValue(user.statusKey, stringValue(user.status)) === "suspended"; }).length), text: "Filtro local sobre os itens retornados" }),
      renderSummaryCard({ icon: "bolt", label: "MatchPoint ativo", value: formatNumber(users.filter(function (user) { return user.matchpointActive === true; }).length), text: "Perfis ativos no matching" }),
    ].join("");

    ui.usersResults.innerHTML = users.length > 0 ?
      users.map(renderUserCard).join("") :
      renderEmptyState("Nenhum usuario encontrado com os filtros atuais.", "person_search");
    ui.usersLoadMoreButton.classList.toggle("hidden", !state.users.hasMore || state.users.mode !== "list");
  }

  function renderUserCard(user) {
    const uid = stringValue(user.uid);
    return [
      "<article class=\"card-row\">",
      avatarMarkup(stringValue(user.foto), stringValue(user.nome, uid), true),
      "<div class=\"card-copy\">",
      "<h3>" + escapeHtml(stringValue(user.nome, uid)) + "</h3>",
      "<p>" + escapeHtml(buildUserSubtitle(user)) + "</p>",
      "<div class=\"card-meta\">",
      badgeHtml(stringValue(user.statusLabel, "Ativo"), stringValue(user.statusKey, "active")),
      badgeHtml(stringValue(user.cadastroStatusLabel, "Cadastro"), registrationBadgeKey(stringValue(user.cadastroStatusKey, stringValue(user.cadastroStatus)))),
      pillHtml(stringValue(user.tipoPerfilLabel, stringValue(user.tipoPerfil, "Perfil")), "pill-blue"),
      "</div>",
      "<div class=\"card-tags\">",
      pillHtml(formatNumber(user.likeCount) + " likes", "pill-accent"),
      pillHtml(formatNumber(user.reportCount) + " reports", user.reportCount > 0 ? "pill-yellow" : "pill-green"),
      user.matchpointActive === true ? pillHtml("MatchPoint ativo", "pill-green") : "",
      "</div>",
      "</div>",
      "<div class=\"card-actions\">",
      actionButton("open-user", "Ver tudo", "visibility", { uid: uid }, "secondary"),
      actionButton("prepare-suspension", "Suspender", "gpp_bad", { uid: uid }, "ghost"),
      actionButton("add-featured-user", "Destacar", "stars", { uid: uid }, "secondary"),
      "</div>",
      "</article>",
    ].join("");
  }

  async function openUserDetail(uid) {
    if (!uid) return;

    openDrawer({
      kicker: "Usuario",
      title: uid,
      subtitle: "Carregando detalhes administrativos...",
      html: renderEmptyState("Buscando perfil, auth, moderacao e relacoes...", "manage_accounts"),
    });

    const detail = await callFunction("getUserAdminDetail", { uid: uid });
    state.userDetail = detail;
    const profile = asObject(detail.profile);
    const payloadKey = "user-raw-" + uid;
    registerDrawerPayload(payloadKey, {
      kicker: "Usuario",
      title: stringValue(profile.nome, uid),
      subtitle: "JSON bruto consolidado",
      data: detail,
    });

    openDrawer({
      kicker: "Usuario",
      title: stringValue(profile.nome, uid),
      subtitle: [stringValue(profile.email, "Sem email"), stringValue(profile.tipoPerfilLabel, "Perfil nao definido"), stringValue(profile.displayLocation)].filter(Boolean).join(" | "),
      html: renderUserDrawer(detail, payloadKey),
    });
  }

  function renderUserDrawer(detail, payloadKey) {
    const profile = asObject(detail.profile);
    const authData = asObject(detail.auth);
    const moderation = asObject(detail.moderation);
    const interactions = asObject(detail.interactions);
    const counts = [
      { label: "Likes", value: formatNumber(profile.likeCount) },
      { label: "Reports", value: formatNumber(profile.reportCount) },
      { label: "Suspensoes", value: formatNumber(profile.suspensionCount) },
      { label: "Bloqueados", value: formatNumber(profile.blockedUsersCount) },
      { label: "Favoritos", value: formatNumber(asArray(detail.favoritesSent).length) },
      { label: "Conversas preview", value: formatNumber(asArray(detail.conversationPreviews).length) },
      { label: "Gigs criadas", value: formatNumber(asArray(detail.gigsCreated).length) },
      { label: "Aplicacoes", value: formatNumber(asArray(detail.gigApplications).length) },
      { label: "Tickets", value: formatNumber(asArray(detail.tickets).length) },
      { label: "Matches", value: formatNumber(asArray(detail.matches).length) },
      { label: "Interacoes enviadas", value: formatNumber(asArray(interactions.sent).length) },
      { label: "Interacoes recebidas", value: formatNumber(asArray(interactions.received).length) },
    ];

    return [
      detailSection("Resumo da conta", renderKeyValueGrid([
        ["UID", stringValue(profile.uid)],
        ["Email", stringValue(profile.email)],
        ["Perfil", stringValue(profile.tipoPerfilLabel)],
        ["Status", badgeHtml(stringValue(profile.statusLabel), stringValue(profile.statusKey, "active"))],
        ["Cadastro", badgeHtml(stringValue(profile.cadastroStatusLabel), registrationBadgeKey(stringValue(profile.cadastroStatusKey)))],
        ["Localizacao", stringValue(profile.displayLocation, "Nao informada")],
        ["Criado em", formatDateTime(profile.createdAt)],
        ["Ultimo login", formatDateTime(profile.lastSignInAt)],
        ["Email verificado", profile.emailVerified === true ? "Sim" : "Nao"],
        ["Auth desabilitado", profile.authDisabled === true ? "Sim" : "Nao"],
        ["Visivel no feed", profile.visibleInHome === true ? "Sim" : "Nao"],
        ["Visivel na busca", profile.visibleInSearch === true ? "Sim" : "Nao"],
      ])),
      detailSection("Bio e operacao", "<div class=\"detail-rich-text\">" + escapeHtml(stringValue(profile.bio, "Sem bio cadastrada.")) + "</div><div class=\"kv-grid\" style=\"margin-top:12px;\">" + counts.map(function (item) { return renderKvItem(item.label, item.value); }).join("") + "</div>"),
      detailSection("Auth e claims", renderKeyValueGrid([
        ["UID auth", stringValue(authData.uid, stringValue(profile.uid))],
        ["Providers", asArray(profile.providerIds).join(", ") || "Nenhum"],
        ["Claims", asArray(Object.keys(asObject(authData.customClaims))).join(", ") || "Nenhuma"],
        ["Conta existe no Auth", profile.authExists === true ? "Sim" : "Nao"],
        ["Suspenso ate", formatDateTime(profile.suspendedUntil)],
        ["Ghost mode", profile.ghostMode === true ? "Sim" : "Nao"],
      ])),
      detailSection("Moderacao e storage", renderKeyValueGrid([
        ["Report count", formatNumber(moderation.report_count || profile.reportCount)],
        ["Suspension count", formatNumber(moderation.suspension_count || profile.suspensionCount)],
        ["Storage sugerido", asArray(detail.derivedStoragePrefixes).join(", ") || "Nenhum prefixo derivado"],
        ["Jobs de transcode", formatNumber(asArray(detail.transcodeJobs).length)],
      ])),
      detailSection("Atividade relacionada", [
        renderMiniList("Favoritos enviados", asArray(detail.favoritesSent), function (item) { return simpleLine(stringValue(item.id), "Path: " + stringValue(item.path)); }, "Nenhum favorito registrado."),
        renderMiniList("Bloqueados", asArray(detail.blockedUsers), function (item) { return simpleLine(stringValue(item.id), "Path: " + stringValue(item.path)); }, "Nenhum bloqueio."),
        renderMiniList("Previews de conversa", asArray(detail.conversationPreviews), function (item) { return simpleLine(stringValue(item.id), "Atualizado em " + formatDateTime(asObject(item.data).updatedAt)); }, "Nenhum preview."),
        renderMiniList("Notificacoes", asArray(detail.notifications), function (item) { return simpleLine(stringValue(item.id), "Atualizado em " + formatDateTime(asObject(item.data).updatedAt)); }, "Nenhuma notificacao recente."),
        renderMiniList("Tickets", asArray(detail.tickets), function (item) { return simpleLine(stringValue(item.subject, stringValue(item.title, stringValue(item.id))), "Status: " + stringValue(item.status, "open")); }, "Nenhum ticket."),
        renderMiniList("Suspensoes", asArray(detail.suspensions), function (item) { return simpleLine(stringValue(item.id), "Status: " + stringValue(asObject(item.data).status, "active")); }, "Nenhuma suspensao registrada."),
      ].join("")),
      detailSection("Acoes rapidas", "<div class=\"drawer-actions\">" + actionButton("prepare-suspension", "Abrir suspensao", "gpp_bad", { uid: stringValue(profile.uid) }, "danger") + actionButton("add-featured-user", "Adicionar aos destaques", "stars", { uid: stringValue(profile.uid) }, "secondary") + actionButton("open-payload", "Ver JSON bruto", "data_object", { payloadKey: payloadKey }, "ghost") + "</div>"),
    ].join("");
  }

  async function loadConversations(options) {
    const force = Boolean(options && options.force);
    if (!force && state.conversations.items.length > 0) {
      renderConversations();
      return;
    }

    setLoadingMarkup(ui.conversationsList, "Carregando conversas...", "forum");
    setLoadingMarkup(ui.conversationsDetail, "Selecione uma conversa para detalhar.", "chat");

    const payload = {
      search: ui.conversationSearchInput.value.trim(),
      limit: Math.min(toInteger(ui.conversationLimitSelect.value, 20), 80),
    };

    let response;
    try {
      response = await callFunction("listConversationsAdmin", payload);
    } catch (error) {
      response = await callFunction("listConversations", payload);
    }

    state.conversations.items = asArray(response.conversations);
    state.conversations.total = toInteger(response.total, state.conversations.items.length);

    const stillSelected = state.conversations.items.some(function (item) {
      return stringValue(item.id) === state.conversations.selectedId;
    });
    if (!stillSelected) {
      state.conversations.selectedId = "";
      state.conversations.detail = null;
    }

    renderConversations();
    if (stillSelected && state.conversations.selectedId) {
      await selectConversation(state.conversations.selectedId);
    }
  }

  function renderConversations() {
    ui.conversationsList.innerHTML = state.conversations.items.length > 0 ?
      state.conversations.items.map(function (conversation) {
        const id = stringValue(conversation.id);
        const participants = asArray(conversation.participants);
        const title = participants.map(function (user) { return stringValue(user.nome, stringValue(user.uid)); }).filter(Boolean).join(" x ") || id;
        return "<article class=\"stack-card\"><div class=\"panel-header\"><div><h3>" + escapeHtml(title) + "</h3><p>" + escapeHtml(stringValue(conversation.lastMessageText, "Sem ultima mensagem")) + "</p></div>" + badgeHtml(stringValue(conversation.type, "direct"), stringValue(conversation.type, "active")) + "</div><div class=\"card-meta\">" + pillHtml("Atualizada " + formatDateTime(conversation.updatedAt), "pill-blue") + pillHtml("Mens. em " + formatDateTime(conversation.lastMessageAt), "pill-accent") + "</div><div class=\"drawer-actions\" style=\"margin-top:12px;\">" + actionButton("open-conversation", "Abrir conversa", "chat", { conversationId: id }, "primary") + participants.map(function (user) { return actionButton("open-user", stringValue(user.nome, "Usuario"), "person", { uid: stringValue(user.uid) }, "ghost"); }).join("") + "</div></article>";
      }).join("") :
      renderEmptyState("Nenhuma conversa encontrada com esse filtro.", "forum");

    if (!state.conversations.detail) {
      ui.conversationsDetail.innerHTML = renderEmptyState("Selecione uma conversa para ver mensagens, participantes e eventos de seguranca.", "mark_chat_read");
    }
  }

  async function selectConversation(conversationId) {
    if (!conversationId) return;
    state.conversations.selectedId = conversationId;
    setLoadingMarkup(ui.conversationsDetail, "Carregando mensagens e contexto...", "chat");

    let detail;
    try {
      detail = await callFunction("getConversationAdminDetail", { conversationId: conversationId, messageLimit: 120 });
    } catch (error) {
      const fallbackMessages = await callFunction("getConversationMessages", { conversationId: conversationId, limit: 120 });
      const listItem = state.conversations.items.find(function (item) { return stringValue(item.id) === conversationId; }) || {};
      detail = { conversation: listItem, messages: asArray(fallbackMessages.messages), chatSafetyEvents: [], participantPreviews: [] };
    }

    state.conversations.detail = detail;
    const payloadKey = "conversation-" + conversationId + "-raw";
    registerDrawerPayload(payloadKey, { kicker: "Conversa", title: conversationId, subtitle: "Estrutura consolidada da conversa", data: detail });
    ui.conversationsDetail.innerHTML = renderConversationDetail(detail, payloadKey);
  }

  function renderConversationDetail(detail, payloadKey) {
    const conversation = asObject(detail.conversation);
    const participants = asArray(conversation.participants);
    const messages = asArray(detail.messages);
    const safetyEvents = asArray(detail.chatSafetyEvents);
    const previews = asArray(detail.participantPreviews);

    return [
      detailSection("Resumo da conversa", renderKeyValueGrid([
        ["Conversa", stringValue(conversation.id)],
        ["Tipo", badgeHtml(stringValue(conversation.type, "direct"), stringValue(conversation.type, "active"))],
        ["Criada em", formatDateTime(conversation.createdAt)],
        ["Atualizada em", formatDateTime(conversation.updatedAt)],
        ["Ultimo envio", formatDateTime(conversation.lastMessageAt)],
        ["Ultimo remetente", stringValue(conversation.lastSenderId, "Nao identificado")],
      ]) + "<div class=\"drawer-actions\" style=\"margin-top:12px;\">" + actionButton("open-payload", "Abrir JSON", "data_object", { payloadKey: payloadKey }, "ghost") + "</div>"),
      detailSection("Participantes", participants.length > 0 ? "<div class=\"stack-list\">" + participants.map(function (user) {
        return "<article class=\"stack-card\"><div class=\"panel-header\"><div><h3>" + escapeHtml(stringValue(user.nome, stringValue(user.uid, "Usuario"))) + "</h3><p>" + escapeHtml(buildUserSubtitle(user)) + "</p></div>" + badgeHtml(stringValue(user.tipoPerfilLabel, "Perfil"), stringValue(user.statusKey, "active")) + "</div><div class=\"drawer-actions\">" + actionButton("open-user", "Abrir usuario", "person", { uid: stringValue(user.uid) }, "secondary") + "</div></article>";
      }).join("") + "</div>" : renderEmptyState("Nenhum participante identificado.", "person")),
      detailSection("Mensagens", messages.length > 0 ? "<div class=\"stack-list\">" + messages.map(function (message) {
        const sender = asObject(message.sender);
        return "<article class=\"stack-card\"><div class=\"panel-header\"><div><h3>" + escapeHtml(stringValue(sender.nome, stringValue(message.senderId, "Sistema"))) + "</h3><p>" + escapeHtml(stringValue(message.text, "[sem texto]")) + "</p></div>" + badgeHtml(stringValue(message.type, "text"), stringValue(message.type, "processed")) + "</div><div class=\"card-meta\">" + pillHtml(formatDateTime(message.createdAt), "pill-blue") + (sender.uid ? actionButton("open-user", "Ver usuario", "person", { uid: stringValue(sender.uid) }, "ghost") : "") + "</div></article>";
      }).join("") + "</div>" : renderEmptyState("Nao ha mensagens retornadas para esta conversa.", "sms")),
      detailSection("Chat safety e previews", [
        renderMiniList("Eventos de chat safety", safetyEvents, function (item) { return simpleLine(stringValue(item.id), "Path: " + stringValue(item.path)); }, "Nenhum evento de chat safety."),
        renderMiniList("Conversation previews", previews, function (item) { return simpleLine(stringValue(item.id), "Path: " + stringValue(item.path)); }, "Nenhum preview localizado."),
      ].join("")),
    ].join("");
  }

  async function loadGigs(options) {
    const force = Boolean(options && options.force);
    if (!force && state.gigs.items.length > 0) {
      renderGigs();
      return;
    }

    setLoadingMarkup(ui.gigsList, "Carregando gigs...", "event_repeat");
    setLoadingMarkup(ui.gigsDetail, "Selecione uma gig para detalhar.", "receipt_long");

    const response = await callFunction("listGigsAdmin", {
      search: ui.gigSearchInput.value.trim(),
      status: ui.gigStatusFilter.value || "all",
      limit: Math.min(toInteger(ui.gigLimitSelect.value, 20), 80),
    });

    state.gigs.items = asArray(response.gigs);
    state.gigs.total = toInteger(response.total, state.gigs.items.length);
    const stillSelected = state.gigs.items.some(function (item) { return stringValue(item.id) === state.gigs.selectedId; });
    if (!stillSelected) {
      state.gigs.selectedId = "";
      state.gigs.detail = null;
    }

    renderGigs();
    if (stillSelected && state.gigs.selectedId) {
      await selectGig(state.gigs.selectedId);
    }
  }

  function renderGigs() {
    ui.gigsList.innerHTML = state.gigs.items.length > 0 ?
      state.gigs.items.map(function (gig) {
        const creator = asObject(gig.creator);
        return "<article class=\"stack-card\"><div class=\"panel-header\"><div><h3>" + escapeHtml(stringValue(gig.title, "Gig sem titulo")) + "</h3><p>" + escapeHtml(stringValue(gig.description, "Sem descricao")) + "</p></div>" + badgeHtml(stringValue(gig.status, "open"), stringValue(gig.status, "open")) + "</div><div class=\"card-meta\">" + pillHtml("Criador: " + escapeHtml(stringValue(creator.nome, stringValue(gig.creatorId, "nao identificado"))), "pill-blue") + pillHtml("Candidaturas: " + formatNumber(gig.applicantCount), "pill-accent") + pillHtml("Criada em " + formatDateTime(gig.createdAt), "pill-green") + "</div><div class=\"drawer-actions\" style=\"margin-top:12px;\">" + actionButton("open-gig", "Detalhar", "event_note", { gigId: stringValue(gig.id) }, "primary") + (creator.uid ? actionButton("open-user", "Criador", "person", { uid: stringValue(creator.uid) }, "ghost") : "") + "</div></article>";
      }).join("") :
      renderEmptyState("Nenhuma gig encontrada com os filtros atuais.", "event_busy");

    if (!state.gigs.detail) {
      ui.gigsDetail.innerHTML = renderEmptyState("Selecione uma gig para ver descricao, aplicacoes e reviews.", "assignment");
    }
  }

  async function selectGig(gigId) {
    if (!gigId) return;
    state.gigs.selectedId = gigId;
    setLoadingMarkup(ui.gigsDetail, "Buscando detalhes da gig...", "receipt_long");
    const detail = await callFunction("getGigAdminDetail", { gigId: gigId });
    state.gigs.detail = detail;
    const payloadKey = "gig-" + gigId + "-raw";
    registerDrawerPayload(payloadKey, { kicker: "Gig", title: stringValue(asObject(detail.gig).title, gigId), subtitle: "Estrutura consolidada da gig", data: detail });
    ui.gigsDetail.innerHTML = renderGigDetail(detail, payloadKey);
  }

  function renderGigDetail(detail, payloadKey) {
    const gig = asObject(detail.gig);
    const creator = asObject(gig.creator);
    const applications = asArray(detail.applications);
    const reviews = asArray(detail.reviews);
    return [
      detailSection("Resumo da gig", renderKeyValueGrid([
        ["Gig", stringValue(gig.title)],
        ["Status", badgeHtml(stringValue(gig.status, "open"), stringValue(gig.status, "open"))],
        ["Tipo", stringValue(gig.gigType, "outro")],
        ["Modelo de data", stringValue(gig.dateMode, "nao informado")],
        ["Local", stringValue(gig.locationType, "nao informado")],
        ["Compensacao", stringValue(gig.compensationType, "nao informado") + " / " + stringValue(gig.compensationValue, "-")],
        ["Candidaturas", formatNumber(gig.applicantCount)],
        ["Slots", formatNumber(gig.slotsFilled) + " / " + formatNumber(gig.slotsTotal)],
        ["Criada em", formatDateTime(gig.createdAt)],
        ["Expira em", formatDateTime(gig.expiresAt)],
      ]) + "<div class=\"detail-rich-text\" style=\"margin-top:12px;\">" + escapeHtml(stringValue(gig.description, "Sem descricao da gig.")) + "</div><div class=\"drawer-actions\" style=\"margin-top:12px;\">" + (creator.uid ? actionButton("open-user", "Abrir criador", "person", { uid: stringValue(creator.uid) }, "secondary") : "") + actionButton("open-payload", "Ver JSON", "data_object", { payloadKey: payloadKey }, "ghost") + "</div>"),
      detailSection("Aplicacoes", applications.length > 0 ? "<div class=\"stack-list\">" + applications.map(function (item) {
        const applicant = asObject(item.applicant);
        return "<article class=\"stack-card\"><div class=\"panel-header\"><div><h3>" + escapeHtml(stringValue(applicant.nome, stringValue(item.applicantId, "Candidato"))) + "</h3><p>" + escapeHtml(stringValue(item.message, "Sem mensagem enviada.")) + "</p></div>" + badgeHtml(stringValue(item.status, "pending"), stringValue(item.status, "pending")) + "</div><div class=\"card-meta\">" + pillHtml("Aplicado em " + formatDateTime(item.appliedAt), "pill-blue") + (item.applicantId ? actionButton("open-user", "Abrir usuario", "person", { uid: stringValue(item.applicantId) }, "ghost") : "") + "</div></article>";
      }).join("") + "</div>" : renderEmptyState("Nenhuma candidatura encontrada para esta gig.", "group_add")),
      detailSection("Reviews", reviews.length > 0 ? "<div class=\"stack-list\">" + reviews.map(function (item) {
        const reviewer = asObject(item.reviewer);
        const reviewedUser = asObject(item.reviewedUser);
        return "<article class=\"stack-card\"><div class=\"panel-header\"><div><h3>" + escapeHtml(stringValue(reviewer.nome, stringValue(item.reviewerId, "Review"))) + "</h3><p>" + escapeHtml(stringValue(item.comment, "Sem comentario")) + "</p></div>" + pillHtml("Nota " + formatNumber(item.rating), "pill-accent") + "</div><div class=\"card-meta\">" + pillHtml("Para " + escapeHtml(stringValue(reviewedUser.nome, stringValue(item.reviewedUserId, "usuario"))), "pill-blue") + pillHtml(formatDateTime(item.createdAt), "pill-green") + (item.reviewedUserId ? actionButton("open-user", "Ver avaliado", "person", { uid: stringValue(item.reviewedUserId) }, "ghost") : "") + "</div></article>";
      }).join("") + "</div>" : renderEmptyState("Nenhuma review localizada para esta gig.", "rate_review")),
    ].join("");
  }

  async function loadMatchpoint(options) {
    const force = Boolean(options && options.force);
    if (!force && state.matchpoint) {
      renderMatchpoint();
      return;
    }

    setLoadingMarkup(ui.matchpointSummary, "Carregando MatchPoint...", "bolt");
    setLoadingMarkup(ui.matchpointHashtags, "Buscando hashtags...", "tag");
    setLoadingMarkup(ui.matchpointMatches, "Listando matches...", "favorite");
    setLoadingMarkup(ui.matchpointInteractions, "Montando interacoes...", "swap_horiz");

    state.matchpoint = await callFunction("getMatchpointAdminOverview", { limit: 24 });
    renderMatchpoint();
  }

  function renderMatchpoint() {
    const data = state.matchpoint;
    if (!data) return;
    const counts = asObject(data.counts);
    const rankingAudit = asObject(data.rankingAudit);
    const summary = asObject(rankingAudit.summary);

    ui.matchpointSummary.innerHTML = [
      renderSummaryCard({ icon: "bolt", label: "Perfis ativos", value: formatNumber(counts.activeProfiles), text: "Usuarios com MatchPoint ativo" }),
      renderSummaryCard({ icon: "favorite", label: "Matches retornados", value: formatNumber(counts.matches), text: "Matches recentes da amostra" }),
      renderSummaryCard({ icon: "swap_horiz", label: "Interacoes recentes", value: formatNumber(counts.recentInteractions), text: "Likes e dislikes recentes" }),
      renderSummaryCard({ icon: "analytics", label: "Media retornada", value: formatDecimal(summary.averageReturnedPerEvent), text: "Itens retornados por evento de auditoria" }),
    ].join("");

    ui.matchpointHashtags.innerHTML = asArray(data.hashtags).length > 0 ? asArray(data.hashtags).map(function (item) {
      return stackCard("#" + escapeHtml(stringValue(item.label)), ["Uso total: " + formatNumber(item.useCount), "Semana: " + formatNumber(item.weeklyCount), "Tendencia: " + escapeHtml(stringValue(item.trend, "stable"))].join(" | "), item.isTrending === true ? pillHtml("Trending", "pill-green") : pillHtml("Estavel", "pill-blue"));
    }).join("") : renderEmptyState("Nenhuma hashtag encontrada.", "tag");

    ui.matchpointMatches.innerHTML = asArray(data.matches).length > 0 ? asArray(data.matches).map(function (match) {
      const users = asArray(match.users);
      return "<article class=\"stack-card\"><div class=\"panel-header\"><div><h3>" + escapeHtml(users.map(function (user) { return stringValue(user.nome, stringValue(user.uid)); }).join(" x ") || stringValue(match.id)) + "</h3><p>" + escapeHtml("Conversa: " + stringValue(match.conversationId, "nao vinculada")) + "</p></div>" + pillHtml(formatDateTime(match.createdAt), "pill-blue") + "</div><div class=\"drawer-actions\">" + users.map(function (user) { return actionButton("open-user", stringValue(user.nome, "Usuario"), "person", { uid: stringValue(user.uid) }, "ghost"); }).join("") + (match.conversationId ? actionButton("open-conversation", "Abrir conversa", "chat", { conversationId: stringValue(match.conversationId) }, "secondary") : "") + "</div></article>";
    }).join("") : renderEmptyState("Nenhum match recente.", "favorite_border");

    ui.matchpointInteractions.innerHTML = renderInteractionsTable(asArray(data.interactions));
  }

  async function loadFeatured(options) {
    const force = Boolean(options && options.force);
    if (!force && state.featured.uids.length > 0) {
      renderFeatured();
      return;
    }

    setLoadingMarkup(ui.featuredList, "Carregando curadoria...", "stars");
    const response = await callFunction("getFeaturedProfiles", {});
    state.featured.uids = asArray(response.uids).map(function (uid) { return String(uid || ""); }).filter(Boolean);
    state.featured.profiles = asArray(response.profiles);
    state.featured.preview = null;
    renderFeatured();
  }

  function renderFeatured() {
    const profilesByUid = new Map();
    state.featured.profiles.forEach(function (profile) { profilesByUid.set(stringValue(profile.uid), profile); });

    ui.featuredAddButton.classList.toggle("hidden", !state.featured.preview);
    ui.featuredPreview.innerHTML = state.featured.preview ? renderUserCard(state.featured.preview) : renderEmptyState("Busque um UID para visualizar o perfil antes de adicionar.", "search");
    ui.featuredList.innerHTML = state.featured.uids.length > 0 ? state.featured.uids.map(function (uid, index) {
      const profile = profilesByUid.get(uid) || { uid: uid, nome: uid };
      return "<article class=\"card-row\">" + avatarMarkup(stringValue(profile.foto), stringValue(profile.nome, uid), true) + "<div class=\"card-copy\"><h3>" + escapeHtml((index + 1) + ". " + stringValue(profile.nome, uid)) + "</h3><p>" + escapeHtml(buildUserSubtitle(profile)) + "</p><div class=\"card-meta\">" + pillHtml("UID: " + escapeHtml(uid), "pill-blue") + pillHtml("Likes: " + formatNumber(profile.likeCount), "pill-accent") + "</div></div><div class=\"card-actions\">" + actionButton("open-user", "Ver usuario", "visibility", { uid: uid }, "secondary") + actionButton("featured-move-up", "Subir", "arrow_upward", { uid: uid }, "ghost") + actionButton("featured-move-down", "Descer", "arrow_downward", { uid: uid }, "ghost") + actionButton("featured-remove", "Remover", "delete", { uid: uid }, "danger") + "</div></article>";
    }).join("") : renderEmptyState("Nenhum perfil em destaque configurado.", "stars");
  }

  async function lookupFeaturedPreview() {
    const uid = ui.featuredUidInput.value.trim();
    if (!uid) {
      showToast("Informe um UID para buscar o perfil.", "error");
      return;
    }
    setButtonBusy(ui.featuredLookupButton, true);
    try {
      state.featured.preview = await callFunction("lookupUser", { uid: uid });
      renderFeatured();
      showToast("Perfil localizado e pronto para destaque.", "success");
    } finally {
      setButtonBusy(ui.featuredLookupButton, false);
    }
  }

  async function addFeaturedFromUid(uid, quiet) {
    if (!uid) return;
    if (state.featured.uids.indexOf(uid) >= 0) {
      if (!quiet) showToast("Esse usuario ja esta na lista de destaque.", "error");
      return;
    }
    let profile = state.featured.preview;
    if (!profile || stringValue(profile.uid) !== uid) {
      profile = await callFunction("lookupUser", { uid: uid });
    }
    state.featured.uids.push(uid);
    if (!state.featured.profiles.some(function (item) { return stringValue(item.uid) === uid; })) {
      state.featured.profiles.push(profile);
    }
    state.featured.preview = profile;
    renderFeatured();
    if (!quiet) showToast("Perfil adicionado a curadoria local. Clique em salvar para publicar.", "success");
  }

  function removeFeatured(uid) {
    state.featured.uids = state.featured.uids.filter(function (item) { return item !== uid; });
    renderFeatured();
  }

  function moveFeatured(uid, direction) {
    const currentIndex = state.featured.uids.indexOf(uid);
    if (currentIndex < 0) return;
    const targetIndex = currentIndex + direction;
    if (targetIndex < 0 || targetIndex >= state.featured.uids.length) return;
    const next = state.featured.uids.slice();
    const temp = next[currentIndex];
    next[currentIndex] = next[targetIndex];
    next[targetIndex] = temp;
    state.featured.uids = next;
    renderFeatured();
  }

  async function saveFeaturedProfiles() {
    setButtonBusy(ui.featuredSaveButton, true);
    try {
      await callFunction("setFeaturedProfiles", { uids: state.featured.uids });
      showToast("Perfis em destaque salvos no backend.", "success");
      await loadFeatured({ force: true });
    } finally {
      setButtonBusy(ui.featuredSaveButton, false);
    }
  }

  async function loadReports(options) {
    const force = Boolean(options && options.force);
    if (!force && state.reports.length > 0) {
      renderReports();
      return;
    }
    setLoadingMarkup(ui.reportsList, "Carregando denuncias...", "outlined_flag");
    const response = await callFunction("listReports", { status: ui.reportsFilter.value || "all", limit: 60 });
    state.reports = asArray(response.reports);
    renderReports();
  }

  function renderReports() {
    if (state.reports.length === 0) {
      ui.reportsList.innerHTML = renderEmptyState("Nenhuma denuncia retornada para este filtro.", "outlined_flag");
      return;
    }
    ui.reportsList.innerHTML = "<table class=\"data-table\"><thead><tr><th>Data</th><th>Reportado</th><th>Motivo</th><th>Status</th><th>Acoes</th></tr></thead><tbody>" + state.reports.map(function (report) {
      const reportedId = stringValue(report.reportedItemId);
      return "<tr><td><div><strong>" + escapeHtml(formatDateTime(report.createdAt)) + "</strong></div><div class=\"detail-meta mono\">" + escapeHtml(stringValue(report.id)) + "</div></td><td><div><strong>" + escapeHtml(stringValue(report.reportedName, reportedId)) + "</strong></div><div class=\"detail-meta mono\">" + escapeHtml(reportedId) + "</div></td><td><div><strong>" + escapeHtml(stringValue(report.reason, "Sem motivo")) + "</strong></div><div class=\"detail-meta\">" + escapeHtml(stringValue(report.description, "Sem descricao")) + "</div></td><td>" + badgeHtml(stringValue(report.status, "pending"), stringValue(report.status, "pending")) + "</td><td><div class=\"table-actions\">" + (reportedId && stringValue(report.reportedItemType) === "user" ? actionButton("open-user", "Usuario", "person", { uid: reportedId }, "ghost") : "") + actionButton("report-status", "Processing", "schedule", { reportId: stringValue(report.id), status: "processing" }, "secondary") + actionButton("report-status", "Processar", "done", { reportId: stringValue(report.id), status: "processed" }, "primary") + actionButton("report-status", "Rejeitar", "close", { reportId: stringValue(report.id), status: "rejected" }, "danger") + "</div></td></tr>";
    }).join("") + "</tbody></table>";
  }

  async function updateReportStatus(reportId, status) {
    if (!reportId || !status) return;
    await callFunction("updateReportStatus", { reportId: reportId, status: status });
    showToast("Status da denuncia atualizado.", "success");
    await loadReports({ force: true });
  }

  async function loadSuspensions(options) {
    const force = Boolean(options && options.force);
    if (!force && state.suspensions.length > 0) {
      renderSuspensions();
      return;
    }
    setLoadingMarkup(ui.suspensionsList, "Carregando suspensoes...", "gpp_bad");
    const response = await callFunction("listSuspensions", { status: ui.suspensionsFilter.value || "active", limit: 60 });
    state.suspensions = asArray(response.suspensions);
    renderSuspensions();
  }

  function renderSuspensions() {
    if (state.suspensions.length === 0) {
      ui.suspensionsList.innerHTML = renderEmptyState("Nenhuma suspensao encontrada.", "gpp_maybe");
      return;
    }
    ui.suspensionsList.innerHTML = "<table class=\"data-table\"><thead><tr><th>Usuario</th><th>Motivo</th><th>Periodo</th><th>Status</th><th>Acoes</th></tr></thead><tbody>" + state.suspensions.map(function (item) {
      const userId = stringValue(item.userId);
      return "<tr><td><div><strong>" + escapeHtml(stringValue(item.userName, userId)) + "</strong></div><div class=\"detail-meta mono\">" + escapeHtml(userId) + "</div></td><td>" + escapeHtml(stringValue(item.reason, "Sem motivo")) + "</td><td><div>" + escapeHtml("Criada em " + formatDateTime(item.createdAt)) + "</div><div class=\"detail-meta\">" + escapeHtml("Ate " + formatDateTime(item.suspendedUntil)) + "</div></td><td>" + badgeHtml(stringValue(item.status, "active"), stringValue(item.status, "active")) + "</td><td><div class=\"table-actions\">" + (userId ? actionButton("open-user", "Usuario", "person", { uid: userId }, "ghost") : "") + (stringValue(item.status) === "active" ? actionButton("lift-suspension", "Levantar", "gpp_good", { suspensionId: stringValue(item.id) }, "secondary") : "") + "</div></td></tr>";
    }).join("") + "</tbody></table>";
  }

  async function createSuspension() {
    const userId = ui.suspendUidInput.value.trim();
    const reason = ui.suspendReasonInput.value.trim();
    const durationDays = Math.min(Math.max(toInteger(ui.suspendDaysInput.value, 7), 1), 365);
    if (!userId || !reason) {
      showToast("Informe o UID e o motivo da suspensao.", "error");
      return;
    }
    setButtonBusy(ui.suspendConfirmButton, true);
    try {
      await callFunction("manageSuspension", { action: "create", userId: userId, reason: reason, durationDays: durationDays });
      ui.suspendReasonInput.value = "";
      ui.suspendDaysInput.value = "7";
      showToast("Suspensao criada com sucesso.", "success");
      await loadSuspensions({ force: true });
    } finally {
      setButtonBusy(ui.suspendConfirmButton, false);
    }
  }

  async function liftSuspension(suspensionId) {
    if (!suspensionId) return;
    await callFunction("manageSuspension", { action: "lift", suspensionId: suspensionId });
    showToast("Suspensao levantada.", "success");
    await loadSuspensions({ force: true });
  }

  async function loadTickets(options) {
    const settings = options || {};
    const force = Boolean(settings.force);
    if (settings.append && !state.tickets.nextCursor) {
      return;
    }

    if (!settings.append && !force && state.tickets.items.length > 0) {
      renderTickets();
      return;
    }

    if (!settings.append) {
      state.tickets.nextCursor = null;
      state.tickets.hasMore = false;
      setLoadingMarkup(ui.ticketsList, "Carregando tickets...", "support_agent");
    } else {
      setButtonBusy(ui.ticketsLoadMoreButton, true);
    }

    try {
      const response = await callFunction("listTickets", {
        status: ui.ticketsFilter.value || "all",
        limit: 30,
        cursor: settings.append ? state.tickets.nextCursor : null,
      });
      const incomingTickets = asArray(response.tickets);
      state.tickets.items = settings.append ?
        mergeItemsById(state.tickets.items, incomingTickets) :
        incomingTickets;
      state.tickets.hasMore = response.hasMore === true;
      state.tickets.nextCursor = response.nextCursor || null;
      const selectedExists = state.tickets.items.some(function (item) { return stringValue(item.id) === state.tickets.selectedId; });
      if (!selectedExists) state.tickets.selectedId = "";
      renderTickets();
    } finally {
      setButtonBusy(ui.ticketsLoadMoreButton, false);
    }
  }

  function renderTickets() {
    const tickets = state.tickets.items;
    ui.ticketsList.innerHTML = tickets.length > 0 ? tickets.map(function (ticket) {
      const ticketId = stringValue(ticket.id);
      return "<article class=\"stack-card\"><div class=\"panel-header\"><div><h3>" + escapeHtml(stringValue(ticket.subject, stringValue(ticket.title, ticketId))) + "</h3><p>" + escapeHtml(stringValue(ticket.contactEmail, stringValue(ticket.userId, "Sem contato"))) + "</p></div>" + badgeHtml(stringValue(ticket.status, "open"), stringValue(ticket.status, "open")) + "</div><div class=\"card-meta\">" + pillHtml(stringValue(ticket.category, "Sem categoria"), "pill-blue") + pillHtml("Criado em " + formatDateTime(ticket.createdAt), "pill-accent") + "</div><div class=\"drawer-actions\" style=\"margin-top:12px;\">" + actionButton("open-ticket", "Abrir", "mark_email_read", { ticketId: ticketId }, "primary") + (ticket.userId ? actionButton("open-user", "Usuario", "person", { uid: stringValue(ticket.userId) }, "ghost") : "") + "</div></article>";
    }).join("") : renderEmptyState("Nenhum ticket encontrado com esse status.", "mail");
    ui.ticketsLoadMoreButton.classList.toggle("hidden", !state.tickets.hasMore);
    ui.ticketsLoadMoreButton.disabled = false;
    const selected = tickets.find(function (ticket) { return stringValue(ticket.id) === state.tickets.selectedId; });
    ui.ticketsDetail.innerHTML = selected ? renderTicketDetail(selected) : renderEmptyState("Selecione um ticket para responder ou atualizar o status.", "support_agent");
  }

  function renderTicketDetail(ticket) {
    const payloadKey = "ticket-" + stringValue(ticket.id) + "-raw";
    registerDrawerPayload(payloadKey, { kicker: "Ticket", title: stringValue(ticket.subject, stringValue(ticket.id)), subtitle: "Estrutura atual do ticket", data: ticket });
    return [
      detailSection("Resumo", renderKeyValueGrid([
        ["Ticket", stringValue(ticket.id)],
        ["Status", badgeHtml(stringValue(ticket.status, "open"), stringValue(ticket.status, "open"))],
        ["Categoria", stringValue(ticket.category, "Nao informada")],
        ["Origem", stringValue(ticket.source, "app")],
        ["Contato", stringValue(ticket.contactName, "Nao informado")],
        ["Email", stringValue(ticket.contactEmail, "Nao informado")],
        ["Criado em", formatDateTime(ticket.createdAt)],
        ["Atualizado em", formatDateTime(ticket.updatedAt)],
      ])),
      detailSection("Mensagem", "<div class=\"detail-rich-text\">" + escapeHtml(stringValue(ticket.message, stringValue(ticket.description, "Sem descricao."))) + "</div>"),
      detailSection("Atualizar ticket", "<label class=\"field\"><span>Status</span><select id=\"ticket-status-editor\">" + selectOption("open", "Aberto", stringValue(ticket.status) === "open") + selectOption("in_progress", "Em andamento", stringValue(ticket.status) === "in_progress") + selectOption("resolved", "Resolvido", stringValue(ticket.status) === "resolved") + selectOption("closed", "Fechado", stringValue(ticket.status) === "closed") + "</select></label><label class=\"field\"><span>Resposta administrativa</span><textarea id=\"ticket-response-editor\" rows=\"6\" placeholder=\"Escreva a resposta interna ou enviada ao usuario\">" + escapeHtml(stringValue(ticket.adminResponse)) + "</textarea></label><div class=\"drawer-actions\">" + actionButton("save-ticket", "Salvar atualizacao", "save", {}, "primary") + (ticket.userId ? actionButton("open-user", "Abrir usuario", "person", { uid: stringValue(ticket.userId) }, "secondary") : "") + actionButton("open-payload", "Ver JSON", "data_object", { payloadKey: payloadKey }, "ghost") + "</div>"),
    ].join("");
  }

  function selectTicket(ticketId) {
    state.tickets.selectedId = ticketId || "";
    renderTickets();
  }

  async function saveSelectedTicket() {
    const selected = state.tickets.items.find(function (ticket) { return stringValue(ticket.id) === state.tickets.selectedId; });
    if (!selected) {
      showToast("Selecione um ticket antes de salvar.", "error");
      return;
    }
    const statusEditor = document.getElementById("ticket-status-editor");
    const responseEditor = document.getElementById("ticket-response-editor");
    const status = statusEditor ? statusEditor.value : stringValue(selected.status, "open");
    const response = responseEditor ? responseEditor.value.trim() : "";
    await callFunction("updateTicket", { ticketId: stringValue(selected.id), status: status, response: response });
    showToast("Ticket atualizado com sucesso.", "success");
    await loadTickets({ force: true });
    state.tickets.selectedId = stringValue(selected.id);
    renderTickets();
  }

  async function loadSystem(options) {
    const force = Boolean(options && options.force);
    if (!force && state.system.data) {
      renderSystem();
      return;
    }
    setLoadingMarkup(ui.systemConfigCards, "Carregando configuracoes...", "memory");
    setLoadingMarkup(ui.systemTranscodeJobs, "Buscando jobs de transcode...", "video_settings");
    if (!state.system.firestoreResult) setLoadingMarkup(ui.firestoreExplorerResult, "Use o explorador para inspecionar caminhos Firestore.", "saved_search");
    if (!state.system.storageResult) setLoadingMarkup(ui.storageExplorerResult, "Use o explorador para listar arquivos do Storage.", "folder_open");
    state.system.data = await callFunction("getSystemAdminData", { limit: 40 });
    renderSystem();
  }

  function renderSystem() {
    const data = state.system.data;
    if (!data) return;
    const config = asObject(data.config);
    ui.systemConfigCards.innerHTML = [
      systemConfigCard("appData", "Config app_data", asObject(config.appData)),
      systemConfigCard("featuredProfiles", "Config featuredProfiles", asObject(config.featuredProfiles)),
      systemConfigCard("admin", "Config admin", asObject(config.admin)),
      stackCard("Collections raiz", asArray(data.rootCollections).map(function (collection) { return stringValue(collection.path); }).join(", ") || "Nenhuma collection retornada.", pillHtml(formatNumber(asArray(data.rootCollections).length) + " colecoes", "pill-blue")),
    ].join("");

    ui.systemTranscodeJobs.innerHTML = asArray(data.transcodeJobs).length > 0 ? asArray(data.transcodeJobs).map(function (job, index) {
      const payloadKey = "transcode-job-" + index;
      registerDrawerPayload(payloadKey, { kicker: "Sistema", title: stringValue(job.id, "Transcode job"), subtitle: stringValue(job.path), data: job });
      const jobData = asObject(job.data);
      return "<article class=\"stack-card\"><div class=\"panel-header\"><div><h3>" + escapeHtml(stringValue(job.id, "Job")) + "</h3><p>" + escapeHtml(stringValue(job.path, "Sem path")) + "</p></div>" + badgeHtml(stringValue(jobData.status, "pending"), stringValue(jobData.status, "pending")) + "</div><div class=\"card-meta\">" + pillHtml("User: " + escapeHtml(stringValue(jobData.userId, "nao informado")), "pill-blue") + pillHtml("Atualizado em " + formatDateTime(jobData.updatedAt || jobData.updated_at), "pill-green") + "</div><div class=\"drawer-actions\" style=\"margin-top:12px;\">" + (jobData.userId ? actionButton("open-user", "Abrir usuario", "person", { uid: stringValue(jobData.userId) }, "secondary") : "") + actionButton("open-payload", "Ver JSON", "data_object", { payloadKey: payloadKey }, "ghost") + "</div></article>";
    }).join("") : renderEmptyState("Nenhum job de transcode retornado.", "video_library");

    renderSystemExplorerResult(ui.firestoreExplorerResult, state.system.firestoreResult, "Firestore");
    renderSystemExplorerResult(ui.storageExplorerResult, state.system.storageResult, "Storage");
  }

  function systemConfigCard(key, title, snapshot) {
    const payloadKey = "system-config-" + key;
    registerDrawerPayload(payloadKey, { kicker: "Sistema", title: title, subtitle: stringValue(snapshot.path, "Documento de configuracao"), data: snapshot });
    return "<article class=\"stack-card\"><div class=\"panel-header\"><div><h3>" + escapeHtml(title) + "</h3><p>" + escapeHtml(stringValue(snapshot.path, "Sem path")) + "</p></div>" + badgeHtml(snapshot.exists === true ? "Disponivel" : "Ausente", snapshot.exists === true ? "processed" : "pending") + "</div><div class=\"card-meta\">" + pillHtml("Doc id: " + escapeHtml(stringValue(snapshot.id, "-")), "pill-blue") + pillHtml("Tem dados: " + (snapshot.exists === true ? "sim" : "nao"), "pill-accent") + "</div><div class=\"drawer-actions\" style=\"margin-top:12px;\">" + actionButton("open-payload", "Inspecionar JSON", "data_object", { payloadKey: payloadKey }, "secondary") + "</div></article>";
  }

  async function inspectFirestorePath() {
    const path = ui.firestorePathInput.value.trim();
    const limit = Math.min(toInteger(ui.firestoreLimitSelect.value, 10), 50);
    setButtonBusy(ui.firestoreInspectButton, true);
    setLoadingMarkup(ui.firestoreExplorerResult, "Inspecionando caminho Firestore...", "saved_search");
    try {
      state.system.firestoreResult = await callFunction("inspectFirestorePath", { path: path, limit: limit });
      renderSystem();
    } finally {
      setButtonBusy(ui.firestoreInspectButton, false);
    }
  }

  async function inspectStoragePrefix() {
    const prefix = ui.storagePrefixInput.value.trim();
    const limit = Math.min(toInteger(ui.storageLimitSelect.value, 20), 100);
    setButtonBusy(ui.storageInspectButton, true);
    setLoadingMarkup(ui.storageExplorerResult, "Listando arquivos do Storage...", "folder_open");
    try {
      state.system.storageResult = await callFunction("inspectStoragePrefix", { prefix: prefix, limit: limit });
      renderSystem();
    } finally {
      setButtonBusy(ui.storageInspectButton, false);
    }
  }

  function renderSystemExplorerResult(element, payload, kindLabel) {
    if (!payload) {
      element.innerHTML = renderEmptyState("Nenhum resultado carregado ainda para " + kindLabel + ".", kindLabel === "Firestore" ? "saved_search" : "folder_open");
      return;
    }
    const payloadKey = "explorer-" + kindLabel.toLowerCase();
    registerDrawerPayload(payloadKey, { kicker: "Explorador " + kindLabel, title: kindLabel, subtitle: "Resultado bruto da ultima consulta", data: payload });
    const lines = [];
    if (kindLabel === "Firestore") {
      lines.push("kind: " + stringValue(payload.kind, "unknown"));
      lines.push("path: " + stringValue(payload.path, "(root)"));
      if (payload.kind === "root") lines.push("collections: " + formatNumber(asArray(payload.collections).length));
      if (payload.kind === "document") lines.push("subcollections: " + formatNumber(asArray(payload.subcollections).length));
      if (payload.kind === "collection") {
        lines.push("documents: " + formatNumber(asArray(payload.documents).length));
        lines.push("nextCursor: " + stringValue(payload.nextCursor, "null"));
      }
    } else {
      lines.push("bucket: " + stringValue(payload.bucket));
      lines.push("prefix: " + stringValue(payload.prefix, "(root)"));
      lines.push("files: " + formatNumber(asArray(payload.files).length));
      lines.push("nextPageToken: " + stringValue(payload.nextPageToken, "null"));
    }
    element.innerHTML = "<div class=\"stack-list\"><article class=\"stack-card\"><div class=\"panel-header\"><div><h3>" + escapeHtml(kindLabel + " Explorer") + "</h3><p>" + escapeHtml(lines.join(" | ")) + "</p></div></div><div class=\"drawer-actions\">" + actionButton("open-payload", "Abrir JSON completo", "data_object", { payloadKey: payloadKey }, "secondary") + "</div></article><div class=\"code-shell\"><pre>" + escapeHtml(prettyJson(payload)) + "</pre></div></div>";
  }

  function callFunction(name, payload) {
    const region = FUNCTION_REGIONS[name] || REGION;
    if (!functionsByRegion[region]) {
      functionsByRegion[region] = firebaseApp.functions(region);
    }
    return functionsByRegion[region].httpsCallable(name)(payload || {}).then(function (response) {
      return response.data;
    });
  }

  function onDocumentActionClick(event) {
    const button = event.target.closest("[data-action]");
    if (!button) return;
    event.preventDefault();
    const action = button.dataset.action;
    switch (action) {
    case "open-user":
      openUserDetail(button.dataset.uid).catch(handleError);
      break;
    case "prepare-suspension":
      prepareSuspension(button.dataset.uid);
      break;
    case "add-featured-user":
      addFeaturedFromUid(button.dataset.uid).catch(handleError);
      break;
    case "open-conversation":
      activateSection("conversations").then(function () { return selectConversation(button.dataset.conversationId); }).catch(handleError);
      break;
    case "open-gig":
      activateSection("gigs").then(function () { return selectGig(button.dataset.gigId); }).catch(handleError);
      break;
    case "open-ticket":
      activateSection("tickets").then(function () { selectTicket(button.dataset.ticketId); }).catch(handleError);
      break;
    case "save-ticket":
      saveSelectedTicket().catch(handleError);
      break;
    case "featured-remove":
      removeFeatured(button.dataset.uid);
      break;
    case "featured-move-up":
      moveFeatured(button.dataset.uid, -1);
      break;
    case "featured-move-down":
      moveFeatured(button.dataset.uid, 1);
      break;
    case "report-status":
      updateReportStatus(button.dataset.reportId, button.dataset.status).catch(handleError);
      break;
    case "lift-suspension":
      liftSuspension(button.dataset.suspensionId).catch(handleError);
      break;
    case "open-section":
      activateSection(button.dataset.section).catch(handleError);
      break;
    case "open-payload":
      openRegisteredPayload(button.dataset.payloadKey);
      break;
    default:
      break;
    }
  }

  function prepareSuspension(uid) {
    if (!uid) return;
    ui.suspendUidInput.value = uid;
    activateSection("suspensions").catch(handleError);
    showToast("UID preenchido na tela de suspensoes.", "success");
    closeDrawer();
  }

  function openRegisteredPayload(key) {
    const payload = state.drawerPayloads[key];
    if (!payload) {
      showToast("Conteudo bruto nao encontrado para esta acao.", "error");
      return;
    }
    openDrawer({
      kicker: stringValue(payload.kicker, "Inspecao"),
      title: stringValue(payload.title, "JSON"),
      subtitle: stringValue(payload.subtitle),
      html: "<div class=\"code-shell\"><pre>" + escapeHtml(prettyJson(payload.data)) + "</pre></div>",
    });
  }

  function registerDrawerPayload(key, payload) {
    state.drawerPayloads[key] = payload;
    return key;
  }

  function openDrawer(config) {
    ui.drawerKicker.textContent = stringValue(config.kicker, "Detalhes");
    ui.drawerTitle.textContent = stringValue(config.title, "Inspecao");
    ui.drawerSubtitle.textContent = stringValue(config.subtitle);
    ui.drawerBody.innerHTML = stringValue(config.html);
    ui.detailDrawer.classList.remove("hidden");
  }

  function closeDrawer() {
    ui.detailDrawer.classList.add("hidden");
  }

  function openSidebar() {
    ui.sidebar.classList.add("is-open");
    ui.sidebarScrim.classList.remove("hidden");
  }

  function closeSidebar() {
    ui.sidebar.classList.remove("is-open");
    ui.sidebarScrim.classList.add("hidden");
  }

  function setLoggedOutUI() {
    ui.loginScreen.classList.remove("hidden");
    ui.adminShell.classList.add("hidden");
    ui.sidebar.classList.remove("is-open");
    ui.sidebarScrim.classList.add("hidden");
    closeDrawer();
  }

  function setLoggedInUI(user) {
    const email = user && user.email ? user.email : "admin@mube";
    ui.sidebarAdminEmail.textContent = email;
    ui.topbarAdminEmail.textContent = email;
    ui.loginScreen.classList.add("hidden");
    ui.adminShell.classList.remove("hidden");
    hideLoginError();
  }

  function setLoginLoading(isLoading, label) {
    const textElement = ui.loginButton.querySelector(".btn-text");
    const loader = ui.loginButton.querySelector(".btn-loader");
    ui.loginButton.disabled = isLoading;
    if (textElement) textElement.textContent = label || "Entrar";
    if (loader) loader.classList.toggle("hidden", !isLoading);
  }

  function showLoginError(message) {
    ui.loginError.textContent = message;
    ui.loginError.classList.remove("hidden");
  }

  function hideLoginError() {
    ui.loginError.textContent = "";
    ui.loginError.classList.add("hidden");
  }

  function showToast(message, type) {
    clearTimeout(state.toastTimer);
    ui.toast.textContent = message;
    ui.toast.className = "toast " + (type || "success");
    ui.toast.classList.remove("hidden");
    state.toastTimer = window.setTimeout(function () {
      ui.toast.classList.add("hidden");
    }, 3600);
  }

  function setButtonBusy(button, isBusy) {
    if (button) button.disabled = isBusy;
  }

  function setLoadingMarkup(element, message, icon) {
    element.innerHTML = renderEmptyState(message, icon || "hourglass_top");
  }

  function renderSummaryCard(item) {
    return "<article class=\"summary-card\"><span class=\"material-icons-round\">" + escapeHtml(item.icon || "insights") + "</span><strong>" + escapeHtml(stringValue(item.value, "0")) + "</strong><p>" + escapeHtml(stringValue(item.label)) + "</p>" + (item.text ? "<p class=\"detail-meta\">" + escapeHtml(stringValue(item.text)) + "</p>" : "") + "</article>";
  }

  function renderMetricCard(item) {
    return "<article class=\"metric-card\"><span class=\"material-icons-round\">" + escapeHtml(item.icon || "analytics") + "</span><strong>" + escapeHtml(stringValue(item.value, "0")) + "</strong><p>" + escapeHtml(stringValue(item.label)) + "</p>" + (item.text ? "<p class=\"detail-meta\">" + escapeHtml(stringValue(item.text)) + "</p>" : "") + "</article>";
  }

  function healthCard(title, value, variant, text) {
    return stackCard(title, text, pillHtml(formatNumber(value), variant));
  }

  function timelineColumn(title, icon, items) {
    return "<article class=\"timeline-card\"><div class=\"panel-header\"><div><h3>" + escapeHtml(title) + "</h3><p>Atualizado a partir do backend administrativo</p></div><span class=\"material-icons-round\">" + escapeHtml(icon) + "</span></div>" + (items.length > 0 ? items.join("") : renderEmptyState("Sem itens recentes.", icon)) + "</article>";
  }

  function timelineItem(title, text, badge, action) {
    return "<article class=\"stack-card\"><div class=\"panel-header\"><div><h3>" + title + "</h3><p>" + text + "</p></div>" + (badge || "") + "</div>" + (action ? "<div class=\"drawer-actions\">" + action + "</div>" : "") + "</article>";
  }

  function stackCard(title, text, trailingHtml) {
    return "<article class=\"stack-card\"><div class=\"panel-header\"><div><h3>" + title + "</h3><p>" + text + "</p></div>" + (trailingHtml || "") + "</div></article>";
  }

  function mergeItemsById(existingItems, nextItems) {
    const itemsById = new Map();
    asArray(existingItems).forEach(function (item) {
      itemsById.set(stringValue(item.id), item);
    });
    asArray(nextItems).forEach(function (item) {
      itemsById.set(stringValue(item.id), item);
    });
    return Array.from(itemsById.values());
  }

  function detailSection(title, bodyHtml) {
    return "<section class=\"detail-section\"><h3>" + escapeHtml(title) + "</h3>" + bodyHtml + "</section>";
  }

  function renderKeyValueGrid(items) {
    return "<div class=\"kv-grid\">" + items.map(function (item) { return renderKvItem(item[0], item[1]); }).join("") + "</div>";
  }

  function renderKvItem(label, value) {
    return "<div class=\"kv-item\"><strong>" + escapeHtml(stringValue(label)) + "</strong><div>" + (typeof value === "string" && /<[^>]+>/.test(value) ? value : escapeHtml(stringValue(value, "-"))) + "</div></div>";
  }

  function renderMiniList(title, items, formatter, emptyText) {
    return "<div style=\"margin-bottom:14px;\"><strong style=\"display:block;margin-bottom:8px;\">" + escapeHtml(title) + "</strong>" + (items.length > 0 ? "<div class=\"stack-list\">" + items.slice(0, 6).map(function (item) { return "<article class=\"stack-card\">" + formatter(item) + "</article>"; }).join("") + "</div>" : renderEmptyState(emptyText, "inbox")) + "</div>";
  }

  function simpleLine(title, subtitle) {
    return "<div><strong>" + escapeHtml(title) + "</strong></div><div class=\"detail-meta\">" + escapeHtml(subtitle) + "</div>";
  }

  function renderInteractionsTable(items) {
    if (items.length === 0) return renderEmptyState("Nenhuma interacao recente encontrada.", "swap_horiz");
    return "<table class=\"data-table\"><thead><tr><th>Data</th><th>Tipo</th><th>Origem</th><th>Destino</th><th>Acoes</th></tr></thead><tbody>" + items.map(function (item) {
      const sourceUser = asObject(item.sourceUser);
      const targetUser = asObject(item.targetUser);
      return "<tr><td>" + escapeHtml(formatDateTime(item.createdAt)) + "</td><td>" + badgeHtml(stringValue(item.type, "unknown"), stringValue(item.type, "pending")) + "</td><td><div><strong>" + escapeHtml(stringValue(sourceUser.nome, stringValue(item.sourceUserId))) + "</strong></div><div class=\"detail-meta mono\">" + escapeHtml(stringValue(item.sourceUserId)) + "</div></td><td><div><strong>" + escapeHtml(stringValue(targetUser.nome, stringValue(item.targetUserId))) + "</strong></div><div class=\"detail-meta mono\">" + escapeHtml(stringValue(item.targetUserId)) + "</div></td><td><div class=\"table-actions\">" + (item.sourceUserId ? actionButton("open-user", "Origem", "person", { uid: stringValue(item.sourceUserId) }, "ghost") : "") + (item.targetUserId ? actionButton("open-user", "Destino", "person", { uid: stringValue(item.targetUserId) }, "ghost") : "") + "</div></td></tr>";
    }).join("") + "</tbody></table>";
  }

  function renderEmptyState(message, icon) {
    return "<div class=\"empty-state\"><span class=\"material-icons-round\">" + escapeHtml(icon || "inbox") + "</span><p>" + escapeHtml(message) + "</p></div>";
  }

  function avatarMarkup(photoUrl, label, round) {
    const safeLabel = escapeHtml(firstWord(label || "U"));
    if (photoUrl) return "<img class=\"card-avatar" + (round ? " is-round" : "") + "\" src=\"" + escapeHtml(photoUrl) + "\" alt=\"" + escapeHtml(label || "Avatar") + "\">";
    return "<div class=\"card-avatar" + (round ? " is-round" : "") + "\" style=\"display:grid;place-items:center;color:var(--text-soft);font-weight:700;\">" + safeLabel.slice(0, 1).toUpperCase() + "</div>";
  }

  function actionButton(action, label, icon, data, variant) {
    const attrs = Object.keys(data || {}).map(function (key) { return " data-" + camelToKebab(key) + "=\"" + escapeHtml(String(data[key])) + "\""; }).join("");
    return "<button class=\"btn btn-" + escapeHtml(variant || "secondary") + "\" type=\"button\" data-action=\"" + escapeHtml(action) + "\"" + attrs + ">" + (icon ? "<span class=\"material-icons-round\">" + escapeHtml(icon) + "</span>" : "") + "<span>" + escapeHtml(label) + "</span></button>";
  }

  function badgeHtml(label, key) {
    return "<span class=\"badge badge-" + escapeHtml(sanitizeBadgeKey(key || label)) + "\">" + escapeHtml(label) + "</span>";
  }

  function pillHtml(label, className) {
    return "<span class=\"pill " + escapeHtml(className || "") + "\">" + label + "</span>";
  }

  function selectOption(value, label, selected) {
    return "<option value=\"" + escapeHtml(value) + "\"" + (selected ? " selected" : "") + ">" + escapeHtml(label) + "</option>";
  }

  function resolveInitialSection() {
    const hash = (window.location.hash || "").replace(/^#/, "").trim();
    return SECTION_META[hash] ? hash : "dashboard";
  }

  function requiredElement(id) {
    const element = document.getElementById(id);
    if (!element) throw new Error("Elemento obrigatorio nao encontrado: #" + id);
    return element;
  }

  function sanitizeBadgeKey(value) {
    return String(value || "default").trim().toLowerCase().replace(/\s+/g, "_").replace(/[^a-z0-9_-]/g, "_");
  }

  function registrationBadgeKey(value) {
    if (value === "completed") return "completed";
    if (value === "profile-pending") return "profile-pending";
    if (value === "type-pending") return "type-pending";
    return sanitizeBadgeKey(value || "pending");
  }

  function buildUserSubtitle(user) {
    return [stringValue(user.email), stringValue(user.displayLocation), stringValue(user.tipoPerfilLabel)].filter(Boolean).join(" | ") || "Sem contexto adicional";
  }

  function stringValue(value, fallback) {
    if (value === null || value === undefined) return fallback || "";
    return String(value);
  }

  function toInteger(value, fallback) {
    const number = Number(value);
    return Number.isFinite(number) ? Math.floor(number) : (fallback || 0);
  }

  function formatNumber(value) {
    const number = Number(value);
    return Number.isFinite(number) ? new Intl.NumberFormat("pt-BR").format(number) : "0";
  }

  function formatDecimal(value) {
    const number = Number(value);
    if (!Number.isFinite(number)) return "0";
    return new Intl.NumberFormat("pt-BR", { minimumFractionDigits: 1, maximumFractionDigits: 2 }).format(number);
  }

  function formatDateTime(value) {
    const millis = toMillis(value);
    if (!millis) return "-";
    return new Intl.DateTimeFormat("pt-BR", { dateStyle: "short", timeStyle: "short" }).format(new Date(millis));
  }

  function toMillis(value) {
    if (!value && value !== 0) return null;
    if (typeof value === "number" && Number.isFinite(value)) return value;
    if (typeof value === "string") {
      const parsed = Date.parse(value);
      return Number.isNaN(parsed) ? null : parsed;
    }
    if (value instanceof Date) return value.getTime();
    if (typeof value.toMillis === "function") return value.toMillis();
    if (typeof value.millis === "number") return value.millis;
    if (typeof value._seconds === "number") return value._seconds * 1000 + Math.floor((value._nanoseconds || 0) / 1000000);
    if (typeof value.seconds === "number") return value.seconds * 1000 + Math.floor((value.nanoseconds || 0) / 1000000);
    if (typeof value.iso === "string") {
      const parsedIso = Date.parse(value.iso);
      return Number.isNaN(parsedIso) ? null : parsedIso;
    }
    return null;
  }

  function prettyJson(value) {
    try {
      return JSON.stringify(value, null, 2);
    } catch (error) {
      return String(value);
    }
  }

  function escapeHtml(value) {
    return String(value || "").replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;").replace(/"/g, "&quot;").replace(/'/g, "&#39;");
  }

  function camelToKebab(value) {
    return String(value || "").replace(/([a-z0-9])([A-Z])/g, "$1-$2").toLowerCase();
  }

  function firstWord(value) {
    return String(value || "").trim().split(/\s+/)[0] || "U";
  }

  function asArray(value) {
    return Array.isArray(value) ? value : [];
  }

  function asObject(value) {
    return value && typeof value === "object" && !Array.isArray(value) ? value : {};
  }

  function isPermissionDeniedError(error) {
    const code = stringValue(error && error.code);
    return code === "functions/permission-denied" || code === "permission-denied";
  }

  function getErrorMessage(error) {
    const code = stringValue(error && error.code);
    const message = stringValue(error && error.message, "Falha inesperada.");
    if (code === "auth/wrong-password" || code === "auth/invalid-credential") return "Email ou senha invalidos.";
    if (code === "auth/user-not-found") return "Conta nao encontrada.";
    if (code === "functions/permission-denied" || code === "permission-denied") return "Sua conta nao possui permissao para esta operacao.";
    return message.replace(/^Firebase:\s*/i, "").trim();
  }

  function handleError(error) {
    console.error("[Mube Admin]", error);
    showToast(getErrorMessage(error), "error");
  }
})();
