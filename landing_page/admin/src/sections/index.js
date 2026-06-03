// Section registry + grouped navigation. All sections are now migrated to the
// new safe-by-construction renderer; the legacy /admin stays live until we
// promote /admin/next over it.
import { mountDashboard } from "./dashboard.js";
import { mountUsers } from "./users.js";
import { mountConversations } from "./conversations.js";
import { mountGigs } from "./gigs.js";
import { mountReports } from "./reports.js";
import { mountSuspensions } from "./suspensions.js";
import { mountMatchpoint } from "./matchpoint.js";
import { mountTickets } from "./tickets.js";
import { mountFeatured } from "./featured.js";
import { mountSystem } from "./system.js";

export const NAV = [
  { group: "Visão geral", items: ["dashboard"] },
  { group: "Pessoas", items: ["users"] },
  { group: "Conteúdo", items: ["conversations", "gigs"] },
  { group: "Moderação", items: ["reports", "suspensions", "matchpoint"] },
  { group: "Engajamento", items: ["tickets", "featured"] },
  { group: "Sistema", items: ["system"] },
];

export const SECTIONS = {
  dashboard: { title: "Dashboard", kicker: "Visão geral do backend", icon: "dashboard", mount: mountDashboard },
  users: { title: "Usuários", kicker: "Base, perfis e moderação", icon: "groups", mount: mountUsers },
  conversations: { title: "Conversas", kicker: "Chat e compliance", icon: "forum", mount: mountConversations },
  gigs: { title: "Gigs", kicker: "Marketplace", icon: "event_note", mount: mountGigs },
  reports: { title: "Denúncias", kicker: "Moderação", icon: "outlined_flag", mount: mountReports },
  suspensions: { title: "Suspensões", kicker: "Controle de acesso", icon: "gpp_bad", mount: mountSuspensions },
  matchpoint: { title: "MatchPoint", kicker: "Motor de matching", icon: "bolt", mount: mountMatchpoint },
  tickets: { title: "Tickets", kicker: "Suporte", icon: "support_agent", mount: mountTickets },
  featured: { title: "Em destaque", kicker: "Curadoria do feed", icon: "stars", mount: mountFeatured },
  system: { title: "Sistema", kicker: "Infra e configuração", icon: "memory", mount: mountSystem },
};
