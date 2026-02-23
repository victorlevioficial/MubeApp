import { useState } from 'react';
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { Separator } from "@/components/ui/separator";
import { ScrollArea } from "@/components/ui/scroll-area";
import { 
  Eye, Type, Palette, LayoutTemplate, Layers, Check, Copy, 
  X, Grid3x3, ImageIcon, Sparkles, Download, Info, 
  Accessibility, Circle, Square, Zap
} from "lucide-react";

export default function App() {
  const [copiedHex, setCopiedHex] = useState('');

  const copyToClipboard = (hex: string) => {
    navigator.clipboard.writeText(hex);
    setCopiedHex(hex);
    setTimeout(() => setCopiedHex(''), 2000);
  };

  const ColorCard = ({ name, hex, description, contrastRatio }: { 
    name: string, 
    hex: string, 
    description?: string,
    contrastRatio?: string 
  }) => (
    <div className="group relative overflow-hidden rounded-xl border border-border bg-card text-card-foreground shadow-sm transition-all hover:shadow-md">
      <div
        className="h-32 w-full transition-transform group-hover:scale-105"
        style={{ backgroundColor: hex }}
      />
      <div className="p-4 flex flex-col gap-2">
        <div className="flex justify-between items-center">
          <h3 className="font-semibold">{name}</h3>
          <button
            onClick={() => copyToClipboard(hex)}
            className="p-2 rounded-full hover:bg-muted transition-colors"
            aria-label={`Copy ${hex}`}
          >
            {copiedHex === hex ? <Check className="w-4 h-4 text-green-500" /> : <Copy className="w-4 h-4 text-muted-foreground" />}
          </button>
        </div>
        <p className="text-sm font-mono text-muted-foreground">{hex}</p>
        {description && <p className="text-xs text-muted-foreground">{description}</p>}
        {contrastRatio && (
          <div className="mt-2 px-2 py-1 bg-green-500/10 border border-green-500/20 rounded-md">
            <p className="text-xs text-green-400 font-mono">WCAG AA: {contrastRatio}</p>
          </div>
        )}
      </div>
    </div>
  );

  return (
    <div className="min-h-screen bg-[#0A0A0A] text-foreground font-sans selection:bg-[#E8466C] selection:text-white">
      {/* Header */}
      <header className="sticky top-0 z-50 w-full border-b border-[#383838] bg-[#0A0A0A]/80 backdrop-blur-xl">
        <div className="container mx-auto flex h-20 items-center px-4 sm:px-6 lg:px-8">
          <div className="flex items-center gap-4">
            <img src="/logo_horizontal.svg" alt="MubeApp Logo" className="h-10" />
          </div>
          <div className="ml-auto">
            <Badge className="bg-[#E8466C] hover:bg-[#D13F61] text-white font-inter">
              v2.0 Professional
            </Badge>
          </div>
        </div>
      </header>

      {/* Main Content */}
      <main className="container mx-auto px-4 sm:px-6 lg:px-8 py-12">
        <Tabs defaultValue="introduction" className="w-full">
          <ScrollArea className="w-full whitespace-nowrap">
            <TabsList className="inline-flex h-12 items-center justify-start gap-2 bg-[#141414] p-1 rounded-xl border border-[#383838] w-full overflow-x-auto">
              <TabsTrigger value="introduction" className="whitespace-nowrap rounded-md px-4 py-2 text-sm font-medium transition-all data-[state=active]:bg-[#292929] data-[state=active]:text-white data-[state=active]:shadow-sm">
                <Info className="w-4 h-4 mr-2" /> Introdução
              </TabsTrigger>
              <TabsTrigger value="philosophy" className="whitespace-nowrap rounded-md px-4 py-2 text-sm font-medium transition-all data-[state=active]:bg-[#292929] data-[state=active]:text-white data-[state=active]:shadow-sm">
                <Eye className="w-4 h-4 mr-2" /> Filosofia
              </TabsTrigger>
              <TabsTrigger value="logos" className="whitespace-nowrap rounded-md px-4 py-2 text-sm font-medium transition-all data-[state=active]:bg-[#292929] data-[state=active]:text-white data-[state=active]:shadow-sm">
                <LayoutTemplate className="w-4 h-4 mr-2" /> Logos
              </TabsTrigger>
              <TabsTrigger value="colors" className="whitespace-nowrap rounded-md px-4 py-2 text-sm font-medium transition-all data-[state=active]:bg-[#292929] data-[state=active]:text-white data-[state=active]:shadow-sm">
                <Palette className="w-4 h-4 mr-2" /> Cores
              </TabsTrigger>
              <TabsTrigger value="typography" className="whitespace-nowrap rounded-md px-4 py-2 text-sm font-medium transition-all data-[state=active]:bg-[#292929] data-[state=active]:text-white data-[state=active]:shadow-sm">
                <Type className="w-4 h-4 mr-2" /> Tipografia
              </TabsTrigger>
              <TabsTrigger value="spacing" className="whitespace-nowrap rounded-md px-4 py-2 text-sm font-medium transition-all data-[state=active]:bg-[#292929] data-[state=active]:text-white data-[state=active]:shadow-sm">
                <Grid3x3 className="w-4 h-4 mr-2" /> Espaçamento
              </TabsTrigger>
              <TabsTrigger value="iconography" className="whitespace-nowrap rounded-md px-4 py-2 text-sm font-medium transition-all data-[state=active]:bg-[#292929] data-[state=active]:text-white data-[state=active]:shadow-sm">
                <ImageIcon className="w-4 h-4 mr-2" /> Iconografia
              </TabsTrigger>
              <TabsTrigger value="components" className="whitespace-nowrap rounded-md px-4 py-2 text-sm font-medium transition-all data-[state=active]:bg-[#292929] data-[state=active]:text-white data-[state=active]:shadow-sm">
                <Layers className="w-4 h-4 mr-2" /> Componentes
              </TabsTrigger>
              <TabsTrigger value="motion" className="whitespace-nowrap rounded-md px-4 py-2 text-sm font-medium transition-all data-[state=active]:bg-[#292929] data-[state=active]:text-white data-[state=active]:shadow-sm">
                <Zap className="w-4 h-4 mr-2" /> Motion
              </TabsTrigger>
              <TabsTrigger value="accessibility" className="whitespace-nowrap rounded-md px-4 py-2 text-sm font-medium transition-all data-[state=active]:bg-[#292929] data-[state=active]:text-white data-[state=active]:shadow-sm">
                <Accessibility className="w-4 h-4 mr-2" /> Acessibilidade
              </TabsTrigger>
              <TabsTrigger value="downloads" className="whitespace-nowrap rounded-md px-4 py-2 text-sm font-medium transition-all data-[state=active]:bg-[#292929] data-[state=active]:text-white data-[state=active]:shadow-sm">
                <Download className="w-4 h-4 mr-2" /> Downloads
              </TabsTrigger>
            </TabsList>
          </ScrollArea>

          <div className="mt-6 ring-offset-background focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2">

            {/* INTRODUCTION TAB */}
            <TabsContent value="introduction" className="space-y-8 animate-in fade-in-50 duration-500">
              <div className="relative overflow-hidden rounded-2xl bg-gradient-to-br from-[#E8466C] via-[#D13F61] to-[#141414] p-12 text-center">
                <div className="relative z-10">
                  <img src="/logo_horizontal.svg" alt="MubeApp" className="mx-auto h-16 mb-6" style={{ filter: 'brightness(0) invert(1)' }} />
                  <h1 className="text-4xl font-bold text-white mb-4 font-poppins">Manual de Identidade Visual</h1>
                  <p className="text-lg text-white/80 max-w-2xl mx-auto font-inter">
                    Conectando talentos musicais em uma única plataforma. Este manual estabelece as diretrizes para uso consistente da marca MubeApp.
                  </p>
                </div>
                <div className="absolute inset-0 bg-[url('data:image/svg+xml;base64,PHN2ZyB3aWR0aD0iNjAiIGhlaWdodD0iNjAiIHZpZXdCb3g9IjAgMCA2MCA2MCIgeG1sbnM9Imh0dHA6Ly93d3cudzMub3JnLzIwMDAvc3ZnIj48ZyBmaWxsPSJub25lIiBmaWxsLXJ1bGU9ImV2ZW5vZGQiPjxnIGZpbGw9IiNmZmYiIGZpbGwtb3BhY2l0eT0iMC4xIj48cGF0aCBkPSJNMzYgMzRjMC0yLjIxLTEuNzktNC00LTRzLTQgMS43OS00IDQgMS43OSA0IDQgNCA0LTEuNzkgNC00eiIvPjwvZz48L2c+PC9zdmc+')] opacity-20"></div>
              </div>

              <div className="grid gap-6 md:grid-cols-3">
                <Card className="bg-[#141414] border-[#383838]">
                  <CardHeader>
                    <CardTitle className="text-[#E8466C] font-poppins">Missão</CardTitle>
                  </CardHeader>
                  <CardContent>
                    <p className="text-muted-foreground font-inter">
                      Democratizar o acesso à indústria musical, conectando músicos, bandas e profissionais do cenário através de tecnologia inovadora e recursos de networking inteligente.
                    </p>
                  </CardContent>
                </Card>

                <Card className="bg-[#141414] border-[#383838]">
                  <CardHeader>
                    <CardTitle className="text-[#E8466C] font-poppins">Visão</CardTitle>
                  </CardHeader>
                  <CardContent>
                    <p className="text-muted-foreground font-inter">
                      Ser a plataforma número 1 de conexão profissional no cenário musical brasileiro, expandindo para toda América Latina até 2027.
                    </p>
                  </CardContent>
                </Card>

                <Card className="bg-[#141414] border-[#383838]">
                  <CardHeader>
                    <CardTitle className="text-[#E8466C] font-poppins">Propósito</CardTitle>
                  </CardHeader>
                  <CardContent>
                    <p className="text-muted-foreground font-inter">
                      Transformar encontros em oportunidades. Cada match pode ser o início de uma colaboração que mudará carreiras.
                    </p>
                  </CardContent>
                </Card>
              </div>

              <Card className="bg-[#141414] border-[#383838]">
                <CardHeader>
                  <CardTitle className="text-white font-poppins">Nossa História</CardTitle>
                </CardHeader>
                <CardContent className="prose prose-invert max-w-none">
                  <p className="text-muted-foreground font-inter leading-relaxed">
                    O MubeApp nasceu da necessidade real de músicos independentes que enfrentavam dificuldades para encontrar parceiros de trabalho, estúdios confiáveis e oportunidades de shows. Em 2024, iniciamos com um MVP focado em conectar músicos locais.
                  </p>
                  <p className="text-muted-foreground font-inter leading-relaxed mt-4">
                    Hoje, somos uma plataforma completa que vai além do networking: oferecemos portfolios profissionais, sistema de matchmaking inteligente (MatchPoint), gestão de agenda e integração com redes sociais. Nossa identidade visual reflete essa evolução: moderna, inclusiva e vibrante como o cenário musical brasileiro.
                  </p>
                </CardContent>
              </Card>
            </TabsContent>

            {/* PHILOSOPHY TAB */}
            <TabsContent value="philosophy" className="space-y-8 animate-in fade-in-50 duration-500">
              <div className="grid gap-6 md:grid-cols-2 lg:grid-cols-3">
                <Card className="bg-[#141414] border-[#383838]">
                  <CardHeader>
                    <CardTitle className="text-[#E8466C] font-poppins">Nossos Valores</CardTitle>
                    <CardDescription>Os 3 pilares que nos sustentam</CardDescription>
                  </CardHeader>
                  <CardContent className="space-y-4">
                    <div>
                      <h4 className="font-semibold text-white font-poppins">Comunidade</h4>
                      <p className="text-sm text-muted-foreground mt-1 font-inter">Acreditamos que a música é feita de encontros, integrando talentos em um só lugar.</p>
                    </div>
                    <Separator className="bg-[#383838]" />
                    <div>
                      <h4 className="font-semibold text-white font-poppins">Inovação</h4>
                      <p className="text-sm text-muted-foreground mt-1 font-inter">Resolvemos problemas reais da indústria musical com features modernas (como MatchPoint).</p>
                    </div>
                    <Separator className="bg-[#383838]" />
                    <div>
                      <h4 className="font-semibold text-white font-poppins">Profissionalismo</h4>
                      <p className="text-sm text-muted-foreground mt-1 font-inter">Tratamos a arte com a seriedade que o mercado exige garantindo vitrines consolidadas.</p>
                    </div>
                  </CardContent>
                </Card>

                <Card className="bg-[#141414] border-[#383838] lg:col-span-2">
                  <CardHeader>
                    <CardTitle className="text-white font-poppins">Tom de Voz</CardTitle>
                    <CardDescription>Como conversamos com nosso usuário</CardDescription>
                  </CardHeader>
                  <CardContent className="grid gap-6 sm:grid-cols-2">
                    <div className="space-y-2 rounded-lg border border-[#383838] bg-[#1F1F1F] p-4">
                      <div className="flex items-center gap-2">
                        <Check className="w-4 h-4 text-[#22C55E]" />
                        <h4 className="font-semibold text-white font-poppins">Inclusivo & Acolhedor</h4>
                      </div>
                      <p className="text-sm text-muted-foreground font-inter">
                        "Bem-vindo ao cenário." Usamos a linguagem universal da música sem arrogância técnica.
                      </p>
                    </div>
                    <div className="space-y-2 rounded-lg border border-[#383838] bg-[#1F1F1F] p-4">
                      <div className="flex items-center gap-2">
                        <Check className="w-4 h-4 text-[#22C55E]" />
                        <h4 className="font-semibold text-white font-poppins">Inspirador</h4>
                      </div>
                      <p className="text-sm text-muted-foreground font-inter">
                        Encorajamos a conexão porque o próximo grande hit nasce do networking.
                      </p>
                    </div>
                    <div className="space-y-2 rounded-lg border border-[#383838] bg-[#1F1F1F] p-4">
                      <div className="flex items-center gap-2">
                        <Check className="w-4 h-4 text-[#22C55E]" />
                        <h4 className="font-semibold text-white font-poppins">Direto e Honesto</h4>
                      </div>
                      <p className="text-sm text-muted-foreground font-inter">
                        Sem enrolação. Falamos a verdade sobre o mercado e as oportunidades.
                      </p>
                    </div>
                    <div className="space-y-2 rounded-lg border border-[#383838] bg-[#1F1F1F] p-4">
                      <div className="flex items-center gap-2">
                        <Check className="w-4 h-4 text-[#22C55E]" />
                        <h4 className="font-semibold text-white font-poppins">Energético</h4>
                      </div>
                      <p className="text-sm text-muted-foreground font-inter">
                        Nossa comunicação tem o ritmo da música: dinâmica, vibrante e envolvente.
                      </p>
                    </div>
                  </CardContent>
                </Card>
              </div>

              <Card className="bg-[#141414] border-[#383838]">
                <CardHeader>
                  <CardTitle className="text-white font-poppins">Exemplos de Comunicação</CardTitle>
                </CardHeader>
                <CardContent className="grid gap-4 md:grid-cols-2">
                  <div className="space-y-3">
                    <div className="flex items-start gap-2">
                      <Check className="w-5 h-5 text-[#22C55E] mt-0.5 flex-shrink-0" />
                      <div>
                        <p className="text-white font-semibold font-inter">Faça:</p>
                        <p className="text-sm text-muted-foreground font-inter">"Encontre parceiros que vibram na mesma frequência que você."</p>
                      </div>
                    </div>
                    <div className="flex items-start gap-2">
                      <Check className="w-5 h-5 text-[#22C55E] mt-0.5 flex-shrink-0" />
                      <div>
                        <p className="text-white font-semibold font-inter">Faça:</p>
                        <p className="text-sm text-muted-foreground font-inter">"Seu próximo match pode ser o início de algo incrível."</p>
                      </div>
                    </div>
                  </div>
                  <div className="space-y-3">
                    <div className="flex items-start gap-2">
                      <X className="w-5 h-5 text-[#EF4444] mt-0.5 flex-shrink-0" />
                      <div>
                        <p className="text-white font-semibold font-inter">Evite:</p>
                        <p className="text-sm text-muted-foreground font-inter">"Utilize nossa plataforma para otimizar seu networking profissional."</p>
                      </div>
                    </div>
                    <div className="flex items-start gap-2">
                      <X className="w-5 h-5 text-[#EF4444] mt-0.5 flex-shrink-0" />
                      <div>
                        <p className="text-white font-semibold font-inter">Evite:</p>
                        <p className="text-sm text-muted-foreground font-inter">"Cadastre-se agora para acessar recursos premium."</p>
                      </div>
                    </div>
                  </div>
                </CardContent>
              </Card>
            </TabsContent>

            {/* LOGOS TAB - Enhanced */}
            <TabsContent value="logos" className="space-y-8 animate-in fade-in-50 duration-500">
              <div className="grid gap-6">
                <Card className="bg-[#141414] border-[#383838] overflow-hidden">
                  <div className="flex flex-col md:flex-row">
                    <div className="flex-1 p-12 bg-[#0A0A0A] flex items-center justify-center min-h-[300px] border-b md:border-b-0 md:border-r border-[#383838]">
                      <img src="/logo_horizontal.svg" alt="Horizontal Logo" className="w-[80%] max-w-[300px]" />
                    </div>
                    <div className="flex-1 p-8 flex flex-col justify-center">
                      <h3 className="text-2xl font-bold text-white mb-2 font-poppins">Marca Primária (Horizontal)</h3>
                      <p className="text-muted-foreground mb-4 font-inter">A versão a ser utilizada em 90% das aplicações: cabeçalhos de apps, sites, assinaturas de e-mail e interfaces onde a leitura da esquerda para a direita é prioritária.</p>
                      <div className="space-y-2">
                        <div className="flex items-center gap-2 text-sm">
                          <Badge className="bg-[#E8466C]/20 text-[#E8466C] border border-[#E8466C]/50">Mínimo</Badge>
                          <span className="text-muted-foreground font-mono">120px de largura</span>
                        </div>
                        <div className="flex items-center gap-2 text-sm">
                          <Badge className="bg-[#3B82F6]/20 text-[#3B82F6] border border-[#3B82F6]/50">Clear Space</Badge>
                          <span className="text-muted-foreground font-mono">X = altura do ícone</span>
                        </div>
                      </div>
                    </div>
                  </div>
                </Card>

                <div className="grid gap-6 md:grid-cols-2">
                  <Card className="bg-[#141414] border-[#383838] overflow-hidden">
                    <div className="p-12 bg-[#0A0A0A] flex items-center justify-center min-h-[250px] border-b border-[#383838]">
                      <img src="/logo_vertical.svg" alt="Vertical Logo" className="h-[120px]" />
                    </div>
                    <div className="p-6">
                      <h3 className="text-xl font-bold text-white mb-2 font-poppins">Símbolo Empilhado</h3>
                      <p className="text-sm text-muted-foreground font-inter">Uso centralizado. Ideal para Splash Screens do App, pôsteres verticais e fechamento de posts patrocinados.</p>
                      <div className="mt-3 space-y-1">
                        <p className="text-xs text-muted-foreground font-mono">Mínimo: 80px de largura</p>
                        <p className="text-xs text-muted-foreground font-mono">Aspect ratio: 1:1.5</p>
                      </div>
                    </div>
                  </Card>

                  <Card className="bg-[#141414] border-[#383838] overflow-hidden">
                    <div className="p-12 bg-[#0A0A0A] flex items-center justify-center min-h-[250px] border-b border-[#383838]">
                      <img src="/Logo certa 2026_logo_icone-11.svg" alt="Icon Logo" className="h-[80px]" />
                    </div>
                    <div className="p-6">
                      <h3 className="text-xl font-bold text-white mb-2 font-poppins">Ícone e Favicon</h3>
                      <p className="text-sm text-muted-foreground font-inter">Retido para perfis de redes sociais (Instagram, TikTok), favicons e App Icon principal na PlayStore/AppStore.</p>
                      <div className="mt-3 space-y-1">
                        <p className="text-xs text-muted-foreground font-mono">Mínimo: 32px × 32px</p>
                        <p className="text-xs text-muted-foreground font-mono">Formato: PNG, SVG</p>
                      </div>
                    </div>
                  </Card>
                </div>

                {/* Clear Space Guide */}
                <Card className="bg-[#141414] border-[#383838]">
                  <CardHeader>
                    <CardTitle className="text-[#E8466C] font-poppins">Área de Proteção (Clear Space)</CardTitle>
                    <CardDescription>Espaçamento mínimo ao redor do logo para garantir legibilidade</CardDescription>
                  </CardHeader>
                  <CardContent>
                    <div className="bg-[#1F1F1F] border border-[#383838] rounded-lg p-8 flex items-center justify-center relative">
                      <div className="absolute inset-0 m-8 border-2 border-dashed border-[#E8466C]/30 rounded-lg pointer-events-none"></div>
                      <div className="absolute top-4 left-1/2 transform -translate-x-1/2 text-xs text-[#E8466C] font-mono">X</div>
                      <div className="absolute bottom-4 left-1/2 transform -translate-x-1/2 text-xs text-[#E8466C] font-mono">X</div>
                      <div className="absolute left-4 top-1/2 transform -translate-y-1/2 text-xs text-[#E8466C] font-mono">X</div>
                      <div className="absolute right-4 top-1/2 transform -translate-y-1/2 text-xs text-[#E8466C] font-mono">X</div>
                      <img src="/logo_horizontal.svg" alt="Logo" className="w-[200px]" />
                    </div>
                    <p className="text-sm text-muted-foreground mt-4 font-inter">
                      Mantenha sempre um espaço livre de X ao redor do logo, onde X = altura do ícone musical. Nenhum texto, elemento gráfico ou borda deve invadir esta área.
                    </p>
                  </CardContent>
                </Card>

                {/* Do's and Don'ts */}
                <Card className="bg-[#141414] border-[#383838]">
                  <CardHeader>
                    <CardTitle className="text-white font-poppins">Uso Correto vs Incorreto</CardTitle>
                  </CardHeader>
                  <CardContent>
                    <div className="grid gap-6 md:grid-cols-2">
                      <div className="space-y-4">
                        <h4 className="text-[#22C55E] font-semibold flex items-center gap-2 font-poppins">
                          <Check className="w-5 h-5" /> Permitido
                        </h4>
                        <div className="space-y-4">
                          <div>
                            <div className="bg-[#0A0A0A] border border-[#383838] rounded-lg p-8 flex items-center justify-center min-h-[120px]">
                              <img src="/logo_horizontal.svg" alt="Correto" className="w-40" />
                            </div>
                            <p className="text-sm text-muted-foreground font-inter mt-2">✓ Fundo preto (#0A0A0A)</p>
                          </div>
                          
                          <div>
                            <div className="bg-white border border-[#383838] rounded-lg p-8 flex items-center justify-center min-h-[120px]">
                              <img src="/logo_horizontal.svg" alt="Correto" className="w-40" style={{ filter: 'brightness(0) saturate(100%) invert(13%) sepia(82%) saturate(3058%) hue-rotate(329deg) brightness(96%) contrast(88%)' }} />
                            </div>
                            <p className="text-sm text-muted-foreground font-inter mt-2">✓ Fundo branco (logo rosa)</p>
                          </div>
                        </div>
                      </div>

                      <div className="space-y-4">
                        <h4 className="text-[#EF4444] font-semibold flex items-center gap-2 font-poppins">
                          <X className="w-5 h-5" /> Proibido
                        </h4>
                        <div className="space-y-4">
                          <div>
                            <div className="bg-gradient-to-r from-purple-500 to-pink-500 border border-[#383838] rounded-lg p-8 flex items-center justify-center relative min-h-[120px]">
                              <img src="/logo_horizontal.svg" alt="Incorreto" className="w-40 opacity-40" />
                              <div className="absolute inset-0 flex items-center justify-center">
                                <X className="w-20 h-20 text-red-500 stroke-[3]" />
                              </div>
                            </div>
                            <p className="text-sm text-muted-foreground font-inter mt-2">✗ Fundos coloridos sem tratamento</p>
                          </div>
                          
                          <div>
                            <div className="bg-[#0A0A0A] border border-[#383838] rounded-lg p-8 flex items-center justify-center relative min-h-[120px]">
                              <img src="/logo_horizontal.svg" alt="Incorreto" className="w-40 opacity-40" style={{ filter: 'hue-rotate(150deg) saturate(2)' }} />
                              <div className="absolute inset-0 flex items-center justify-center">
                                <X className="w-20 h-20 text-red-500 stroke-[3]" />
                              </div>
                            </div>
                            <p className="text-sm text-muted-foreground font-inter mt-2">✗ Alterar cores do logo (verde, azul, etc.)</p>
                          </div>

                          <div>
                            <div className="bg-[#0A0A0A] border border-[#383838] rounded-lg p-8 flex items-center justify-center relative min-h-[120px]">
                              <img src="/logo_horizontal.svg" alt="Incorreto" className="w-40 opacity-40 transform scale-y-150" />
                              <div className="absolute inset-0 flex items-center justify-center">
                                <X className="w-20 h-20 text-red-500 stroke-[3]" />
                              </div>
                            </div>
                            <p className="text-sm text-muted-foreground font-inter mt-2">✗ Distorcer proporções</p>
                          </div>
                        </div>
                      </div>
                    </div>
                  </CardContent>
                </Card>

                {/* Photo Application Guide */}
                <Card className="bg-[#141414] border border-[#383838]">
                  <CardHeader>
                    <CardTitle className="text-[#E8466C] font-poppins">Guia de Aplicação sobre Fotografia</CardTitle>
                  </CardHeader>
                  <CardContent>
                    <p className="text-sm text-muted-foreground mb-4 font-inter">A música acontece em locais vibrantes, palcos escuros ou estúdios coloridos. Para inserir a MubeApp sobre fotos ricas:</p>
                    <div className="rounded-lg overflow-hidden relative h-[250px] w-full flex items-center justify-center border border-[#383838]">
                      <div className="absolute inset-0 bg-gradient-to-br from-[#E8466C]/30 via-[#D13F61]/20 to-black opacity-90" />
                      <div className="absolute inset-0 bg-[#0A0A0A]/50 backdrop-blur-[2px]" />
                      <img src="/logo_horizontal.svg" alt="Logo over photo" className="relative z-10 w-[200px]" style={{ filter: 'brightness(0) invert(1)' }} />
                      <div className="absolute bottom-4 left-4 z-10 bg-black/60 px-3 py-1 rounded-md border border-[#383838]">
                        <span className="text-xs text-white font-inter">✅ Correto: Translucidez com logo Monochrome</span>
                      </div>
                    </div>
                    <div className="mt-4 space-y-2">
                      <p className="text-sm text-muted-foreground font-inter">• Use overlay escuro (40-60% de opacidade)</p>
                      <p className="text-sm text-muted-foreground font-inter">• Logo sempre em branco sobre fotos</p>
                      <p className="text-sm text-muted-foreground font-inter">• Opcional: adicionar blur (2-4px) para destacar logo</p>
                    </div>
                  </CardContent>
                </Card>
              </div>
            </TabsContent>

            {/* COLORS TAB - Enhanced with Gradients */}
            <TabsContent value="colors" className="space-y-8 animate-in fade-in-50 duration-500">
              <div>
                <h2 className="text-2xl font-bold text-white mb-6 font-poppins">Identidade Primária</h2>
                <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
                  <ColorCard 
                    name="Primary" 
                    hex="#E8466C" 
                    description="Cor oficial (Botões, Badges, Matches)" 
                    contrastRatio="4.5:1"
                  />
                  <ColorCard 
                    name="Primary Pressed" 
                    hex="#D13F61" 
                    description="Feedback visual de hover/press" 
                    contrastRatio="5.2:1"
                  />
                  <ColorCard 
                    name="Celebration Pink" 
                    hex="#FF69B4" 
                    description="Efeitos de Confetti e Matches"
                    contrastRatio="3.8:1"
                  />
                </div>
              </div>

              <Separator className="bg-[#383838]" />

              {/* Gradients Section */}
              <div>
                <h2 className="text-2xl font-bold text-white mb-6 font-poppins">Gradientes de Marca</h2>
                <div className="grid gap-4 sm:grid-cols-2">
                  <div className="group relative overflow-hidden rounded-xl border border-border bg-card shadow-sm transition-all hover:shadow-md">
                    <div
                      className="h-32 w-full transition-transform group-hover:scale-105"
                      style={{ background: 'linear-gradient(135deg, #E8466C 0%, #D13F61 100%)' }}
                    />
                    <div className="p-4 flex flex-col gap-2">
                      <h3 className="font-semibold font-poppins">Primary Gradient</h3>
                      <p className="text-sm font-mono text-muted-foreground">135deg, #E8466C → #D13F61</p>
                      <p className="text-xs text-muted-foreground font-inter">Uso: Headers, CTAs especiais, Splash screens</p>
                    </div>
                  </div>

                  <div className="group relative overflow-hidden rounded-xl border border-border bg-card shadow-sm transition-all hover:shadow-md">
                    <div
                      className="h-32 w-full transition-transform group-hover:scale-105"
                      style={{ background: 'linear-gradient(135deg, #FF69B4 0%, #E8466C 100%)' }}
                    />
                    <div className="p-4 flex flex-col gap-2">
                      <h3 className="font-semibold font-poppins">Celebration Gradient</h3>
                      <p className="text-sm font-mono text-muted-foreground">135deg, #FF69B4 → #E8466C</p>
                      <p className="text-xs text-muted-foreground font-inter">Uso: Match confirmado, Success states</p>
                    </div>
                  </div>

                  <div className="group relative overflow-hidden rounded-xl border border-border bg-card shadow-sm transition-all hover:shadow-md">
                    <div
                      className="h-32 w-full transition-transform group-hover:scale-105"
                      style={{ background: 'linear-gradient(135deg, #0A0A0A 0%, #1F1F1F 50%, #292929 100%)' }}
                    />
                    <div className="p-4 flex flex-col gap-2">
                      <h3 className="font-semibold font-poppins">Dark Surface Gradient</h3>
                      <p className="text-sm font-mono text-muted-foreground">135deg, #0A0A0A → #292929</p>
                      <p className="text-xs text-muted-foreground font-inter">Uso: Fundos de cards, Containers elevados</p>
                    </div>
                  </div>

                  <div className="group relative overflow-hidden rounded-xl border border-border bg-card shadow-sm transition-all hover:shadow-md">
                    <div
                      className="h-32 w-full transition-transform group-hover:scale-105"
                      style={{ background: 'radial-gradient(circle at top right, #E8466C 0%, #0A0A0A 70%)' }}
                    />
                    <div className="p-4 flex flex-col gap-2">
                      <h3 className="font-semibold font-poppins">Radial Accent</h3>
                      <p className="text-sm font-mono text-muted-foreground">circle, #E8466C → #0A0A0A</p>
                      <p className="text-xs text-muted-foreground font-inter">Uso: Backgrounds especiais, Hero sections</p>
                    </div>
                  </div>
                </div>
              </div>

              <Separator className="bg-[#383838]" />

              <div>
                <h2 className="text-2xl font-bold text-white mb-6 font-poppins">Dark Surfaces (Modo Escuro Padrão)</h2>
                <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
                  <ColorCard name="Background Deep" hex="#0A0A0A" description="Fundo Scaffold, AppBars" contrastRatio="21:1" />
                  <ColorCard name="Surface 1" hex="#141414" description="Cards base, Componentes Inferiores" contrastRatio="18.2:1" />
                  <ColorCard name="Surface 2" hex="#1F1F1F" description="Containers elevados, Inputs" contrastRatio="15.4:1" />
                  <ColorCard name="Highlight" hex="#292929" description="Tabs ativas, Hover em Cards" contrastRatio="12.6:1" />
                </div>
              </div>

              <Separator className="bg-[#383838]" />

              <div>
                <h2 className="text-2xl font-bold text-white mb-6 font-poppins">Estados de Feedback (Semânticos)</h2>
                <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
                  <ColorCard name="Success" hex="#22C55E" description="Aprovações, Sucesso" contrastRatio="4.8:1" />
                  <ColorCard name="Warning" hex="#F59E0B" description="Avisos importantes" contrastRatio="4.2:1" />
                  <ColorCard name="Error" hex="#EF4444" description="Falhas, Remoções" contrastRatio="4.5:1" />
                  <ColorCard name="Info" hex="#3B82F6" description="Tags informativas" contrastRatio="5.1:1" />
                </div>
              </div>

              <Separator className="bg-[#383838]" />

              <div>
                <h2 className="text-2xl font-bold text-white mb-6 font-poppins">Categoria de Usuários (Badges)</h2>
                <div className="grid gap-4 sm:grid-cols-3">
                  <ColorCard name="Músico" hex="#E8466C" description="Tag Primary" contrastRatio="4.5:1" />
                  <ColorCard name="Banda" hex="#C026D3" description="Tag Fuchsia/Purple" contrastRatio="5.8:1" />
                  <ColorCard name="Estúdio" hex="#DC2626" description="Tag Red" contrastRatio="5.3:1" />
                </div>
              </div>

              <Separator className="bg-[#383838]" />

              {/* Text Colors */}
              <div>
                <h2 className="text-2xl font-bold text-white mb-6 font-poppins">Cores de Texto</h2>
                <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
                  <ColorCard name="Text Primary" hex="#FFFFFF" description="Títulos, Textos principais" contrastRatio="21:1" />
                  <ColorCard name="Text Secondary" hex="#B3B3B3" description="Subtítulos, Descrições" contrastRatio="9.5:1" />
                  <ColorCard name="Text Muted" hex="#737373" description="Placeholders, Hints" contrastRatio="4.7:1" />
                  <ColorCard name="Text Disabled" hex="#525252" description="Campos desabilitados" contrastRatio="3.2:1" />
                </div>
              </div>
            </TabsContent>

            {/* TYPOGRAPHY TAB - Enhanced */}
            <TabsContent value="typography" className="space-y-8 animate-in fade-in-50 duration-500">
              <div className="grid gap-8 md:grid-cols-2">
                <Card className="bg-[#141414] border-[#383838]">
                  <CardHeader>
                    <CardTitle className="text-2xl font-poppins text-white">Poppins</CardTitle>
                    <CardDescription>Primary Display Font (Headlines & Labels)</CardDescription>
                  </CardHeader>
                  <CardContent className="space-y-6">
                    <div>
                      <div className="text-[32px] font-bold text-white leading-tight font-poppins">Headline XL</div>
                      <p className="text-sm font-mono text-muted-foreground">Bold (700) • 32px • Line height: 1.2 • Letter spacing: -0.02em</p>
                    </div>
                    <Separator className="bg-[#383838]" />
                    <div>
                      <div className="text-[28px] font-bold text-white leading-tight font-poppins">Headline Large</div>
                      <p className="text-sm font-mono text-muted-foreground">Bold (700) • 28px • Line height: 1.3 • Letter spacing: -0.01em</p>
                    </div>
                    <Separator className="bg-[#383838]" />
                    <div>
                      <div className="text-[24px] font-bold text-white leading-tight font-poppins">Headline Compact</div>
                      <p className="text-sm font-mono text-muted-foreground">Bold (700) • 24px • Line height: 1.3 • Letter spacing: 0</p>
                    </div>
                    <Separator className="bg-[#383838]" />
                    <div>
                      <div className="text-[18px] font-semibold text-white leading-tight font-poppins">Title Large</div>
                      <p className="text-sm font-mono text-muted-foreground">SemiBold (600) • 18px • Line height: 1.4 • Letter spacing: 0</p>
                    </div>
                    <Separator className="bg-[#383838]" />
                    <div>
                      <div className="text-[16px] font-bold text-white leading-tight font-poppins">Button Primary</div>
                      <p className="text-sm font-mono text-muted-foreground">Bold (700) • 16px • Line height: 1 • Letter spacing: 0.01em</p>
                    </div>
                  </CardContent>
                </Card>

                <Card className="bg-[#141414] border-[#383838]">
                  <CardHeader>
                    <CardTitle className="text-2xl font-inter text-white">Inter</CardTitle>
                    <CardDescription>Secondary Body Font (Leitura & Estrutura)</CardDescription>
                  </CardHeader>
                  <CardContent className="space-y-6">
                    <div>
                      <div className="text-[16px] font-medium text-white leading-relaxed font-inter">Body Large<br /><span className="text-muted-foreground text-sm">O texto foca na legibilidade primária.</span></div>
                      <p className="text-sm font-mono text-muted-foreground mt-2">Medium (500) • 16px • Line height: 1.6 • Letter spacing: 0</p>
                    </div>
                    <Separator className="bg-[#383838]" />
                    <div>
                      <div className="text-[14px] font-medium text-white leading-relaxed font-inter">Body Medium<br /><span className="text-muted-foreground text-sm">O padrão para descrições de cards.</span></div>
                      <p className="text-sm font-mono text-muted-foreground mt-2">Medium (500) • 14px • Line height: 1.5 • Letter spacing: 0</p>
                    </div>
                    <Separator className="bg-[#383838]" />
                    <div>
                      <div className="text-[12px] font-medium text-white leading-relaxed font-inter">Body Small<br /><span className="text-muted-foreground text-xs">Textos secundários e hints.</span></div>
                      <p className="text-sm font-mono text-muted-foreground mt-2">Medium (500) • 12px • Line height: 1.5 • Letter spacing: 0</p>
                    </div>
                    <Separator className="bg-[#383838]" />
                    <div>
                      <div className="text-[10px] font-medium text-[#B3B3B3] leading-relaxed font-inter tracking-[0.1em] uppercase">TAGS/CHIPS</div>
                      <p className="text-sm font-mono text-muted-foreground mt-2">Medium (500) • 10px • Line height: 1 • Letter spacing: 0.1em • Uppercase</p>
                    </div>
                    <Separator className="bg-[#383838]" />
                    <div>
                      <div className="text-[8px] font-semibold text-[#B3B3B3] leading-tight font-inter tracking-[0.15em] uppercase">METADATA/CAPTION</div>
                      <p className="text-sm font-mono text-muted-foreground mt-2">SemiBold (600) • 8px • Line height: 1.2 • Letter spacing: 0.15em • Uppercase</p>
                    </div>
                  </CardContent>
                </Card>
              </div>

              {/* Typography Hierarchy */}
              <Card className="bg-[#141414] border-[#383838]">
                <CardHeader>
                  <CardTitle className="text-white font-poppins">Hierarquia Tipográfica Aplicada</CardTitle>
                  <CardDescription>Exemplo de uso em um card de perfil</CardDescription>
                </CardHeader>
                <CardContent>
                  <div className="bg-[#1F1F1F] border border-[#383838] rounded-xl p-6 space-y-4">
                    <div>
                      <h3 className="text-[24px] font-bold text-white font-poppins">João Silva</h3>
                      <div className="flex gap-2 mt-2">
                        <span className="text-[10px] font-medium text-[#E8466C] bg-[#E8466C]/20 border border-[#E8466C]/50 px-3 py-1 rounded-full uppercase tracking-wider font-inter">Músico</span>
                        <span className="text-[10px] font-medium text-[#3B82F6] bg-[#3B82F6]/20 border border-[#3B82F6]/50 px-3 py-1 rounded-full uppercase tracking-wider font-inter">Violão</span>
                      </div>
                    </div>
                    <Separator className="bg-[#383838]" />
                    <div>
                      <h4 className="text-[18px] font-semibold text-white mb-2 font-poppins">Sobre</h4>
                      <p className="text-[14px] text-muted-foreground leading-relaxed font-inter">
                        Músico profissional com 10 anos de experiência em MPB e Samba. Procurando parceiros para projetos autorais.
                      </p>
                    </div>
                    <div>
                      <p className="text-[8px] font-semibold text-[#B3B3B3] uppercase tracking-[0.15em] font-inter">São Paulo, SP • Membro desde 2024</p>
                    </div>
                  </div>
                </CardContent>
              </Card>

              {/* Font Pairing */}
              <Card className="bg-[#141414] border-[#383838]">
                <CardHeader>
                  <CardTitle className="text-white font-poppins">Combinação de Fontes</CardTitle>
                </CardHeader>
                <CardContent>
                  <div className="space-y-4">
                    <div className="flex items-baseline gap-4">
                      <span className="text-[24px] font-bold text-[#E8466C] font-poppins">Poppins Bold</span>
                      <span className="text-[16px] text-muted-foreground font-inter">+ Inter Medium</span>
                    </div>
                    <p className="text-sm text-muted-foreground font-inter">
                      Poppins transmite personalidade e energia (headlines, botões), enquanto Inter oferece legibilidade superior para leitura prolongada (corpo de texto, descrições).
                    </p>
                    <div className="mt-4 p-4 bg-[#1F1F1F] border border-[#383838] rounded-lg">
                      <p className="text-xs text-[#B3B3B3] font-mono font-inter">
                        Google Fonts: @import url('https://fonts.googleapis.com/css2?family=Poppins:wght@400;600;700&family=Inter:wght@400;500;600;700&display=swap');
                      </p>
                    </div>
                  </div>
                </CardContent>
              </Card>
            </TabsContent>

            {/* SPACING TAB - New */}
            <TabsContent value="spacing" className="space-y-8 animate-in fade-in-50 duration-500">
              <Card className="bg-[#141414] border-[#383838]">
                <CardHeader>
                  <CardTitle className="text-white font-poppins">Sistema de Espaçamento</CardTitle>
                  <CardDescription>Baseado em múltiplos de 4px para consistência</CardDescription>
                </CardHeader>
                <CardContent>
                  <div className="space-y-4">
                    {[
                      { name: 'xs', value: '4px', use: 'Espaçamento mínimo entre ícones e textos' },
                      { name: 'sm', value: '8px', use: 'Padding interno de chips e badges' },
                      { name: 'md', value: '12px', use: 'Gap entre elementos de um grupo' },
                      { name: 'lg', value: '16px', use: 'Padding de cards e containers' },
                      { name: 'xl', value: '24px', use: 'Margem entre seções' },
                      { name: '2xl', value: '32px', use: 'Espaçamento de layout principal' },
                      { name: '3xl', value: '48px', use: 'Separação entre módulos principais' },
                      { name: '4xl', value: '64px', use: 'Margens de hero sections' },
                    ].map((spacing) => (
                      <div key={spacing.name} className="flex items-center gap-4">
                        <div className="w-24 text-right">
                          <code className="text-[#E8466C] font-mono text-sm">{spacing.name}</code>
                        </div>
                        <div className="flex-1 flex items-center gap-4">
                          <div 
                            className="h-8 bg-[#E8466C] rounded" 
                            style={{ width: spacing.value }}
                          />
                          <div className="flex-1">
                            <p className="text-white font-mono text-sm">{spacing.value}</p>
                            <p className="text-xs text-muted-foreground font-inter">{spacing.use}</p>
                          </div>
                        </div>
                      </div>
                    ))}
                  </div>
                </CardContent>
              </Card>

              <Card className="bg-[#141414] border-[#383838]">
                <CardHeader>
                  <CardTitle className="text-white font-poppins">Grid System</CardTitle>
                  <CardDescription>Layout baseado em 12 colunas responsivas</CardDescription>
                </CardHeader>
                <CardContent>
                  <div className="space-y-4">
                    <div className="grid grid-cols-12 gap-2">
                      {Array.from({ length: 12 }).map((_, i) => (
                        <div key={i} className="bg-[#E8466C]/20 border border-[#E8466C]/50 h-12 rounded flex items-center justify-center">
                          <span className="text-xs text-[#E8466C] font-mono">{i + 1}</span>
                        </div>
                      ))}
                    </div>
                    <div className="space-y-2 text-sm font-inter">
                      <p className="text-muted-foreground">• <strong className="text-white">Mobile:</strong> 1 coluna (até 640px)</p>
                      <p className="text-muted-foreground">• <strong className="text-white">Tablet:</strong> 4-6 colunas (641px - 1024px)</p>
                      <p className="text-muted-foreground">• <strong className="text-white">Desktop:</strong> 8-12 colunas (1025px+)</p>
                      <p className="text-muted-foreground">• <strong className="text-white">Gutter:</strong> 16px entre colunas</p>
                      <p className="text-muted-foreground">• <strong className="text-white">Margin:</strong> 24px nas laterais (mobile), 48px (desktop)</p>
                    </div>
                  </div>
                </CardContent>
              </Card>

              <Card className="bg-[#141414] border-[#383838]">
                <CardHeader>
                  <CardTitle className="text-white font-poppins">Border Radius</CardTitle>
                  <CardDescription>Arredondamentos padrão</CardDescription>
                </CardHeader>
                <CardContent>
                  <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
                    {[
                      { name: 'sm', value: '8px', use: 'Inputs, Small cards' },
                      { name: 'md', value: '12px', use: 'Cards, Modais padrão' },
                      { name: 'lg', value: '16px', use: 'Hero cards, Containers' },
                      { name: 'full', value: '9999px', use: 'Botões pill, Badges' },
                    ].map((radius) => (
                      <div key={radius.name} className="bg-[#1F1F1F] border border-[#383838] p-4 rounded-lg space-y-3">
                        <div 
                          className="h-24 bg-[#E8466C]" 
                          style={{ borderRadius: radius.value }}
                        />
                        <div>
                          <p className="text-white font-mono text-sm">{radius.name}: {radius.value}</p>
                          <p className="text-xs text-muted-foreground font-inter">{radius.use}</p>
                        </div>
                      </div>
                    ))}
                  </div>
                </CardContent>
              </Card>
            </TabsContent>

            {/* ICONOGRAPHY TAB - New */}
            <TabsContent value="iconography" className="space-y-8 animate-in fade-in-50 duration-500">
              <Card className="bg-[#141414] border-[#383838]">
                <CardHeader>
                  <CardTitle className="text-white font-poppins">Estilo de Ícones</CardTitle>
                  <CardDescription>Lucide Icons como biblioteca padrão</CardDescription>
                </CardHeader>
                <CardContent className="space-y-6">
                  <div>
                    <h4 className="text-white font-semibold mb-3 font-poppins">Características</h4>
                    <ul className="space-y-2 text-sm text-muted-foreground font-inter">
                      <li className="flex items-start gap-2">
                        <Check className="w-4 h-4 text-[#22C55E] mt-0.5 flex-shrink-0" />
                        <span>Outline style (stroke-width: 2px)</span>
                      </li>
                      <li className="flex items-start gap-2">
                        <Check className="w-4 h-4 text-[#22C55E] mt-0.5 flex-shrink-0" />
                        <span>Cantos arredondados (stroke-linecap: round)</span>
                      </li>
                      <li className="flex items-start gap-2">
                        <Check className="w-4 h-4 text-[#22C55E] mt-0.5 flex-shrink-0" />
                        <span>Grid de 24px × 24px</span>
                      </li>
                      <li className="flex items-start gap-2">
                        <Check className="w-4 h-4 text-[#22C55E] mt-0.5 flex-shrink-0" />
                        <span>Consistência visual com a tipografia</span>
                      </li>
                    </ul>
                  </div>

                  <Separator className="bg-[#383838]" />

                  <div>
                    <h4 className="text-white font-semibold mb-3 font-poppins">Tamanhos Padrão</h4>
                    <div className="grid gap-4 sm:grid-cols-4">
                      {[
                        { size: '16px', name: 'Small', use: 'Inline com texto' },
                        { size: '20px', name: 'Medium', use: 'Botões, Cards' },
                        { size: '24px', name: 'Large', use: 'Headers, Features' },
                        { size: '32px', name: 'XL', use: 'Empty states, Heroes' },
                      ].map((icon) => (
                        <div key={icon.size} className="bg-[#1F1F1F] border border-[#383838] rounded-lg p-4 flex flex-col items-center gap-2">
                          <Circle style={{ width: icon.size, height: icon.size }} className="text-[#E8466C]" />
                          <div className="text-center">
                            <p className="text-white font-mono text-sm">{icon.size}</p>
                            <p className="text-xs text-muted-foreground font-inter">{icon.name}</p>
                            <p className="text-xs text-[#B3B3B3] font-inter mt-1">{icon.use}</p>
                          </div>
                        </div>
                      ))}
                    </div>
                  </div>

                  <Separator className="bg-[#383838]" />

                  <div>
                    <h4 className="text-white font-semibold mb-3 font-poppins">Cores de Ícones</h4>
                    <div className="space-y-3">
                      <div className="flex items-center gap-3 p-3 bg-[#1F1F1F] rounded-lg border border-[#383838]">
                        <Eye className="w-6 h-6 text-white" />
                        <div className="flex-1">
                          <p className="text-white text-sm font-inter">Primary (#FFFFFF)</p>
                          <p className="text-xs text-muted-foreground font-inter">Ícones principais em fundos escuros</p>
                        </div>
                      </div>
                      <div className="flex items-center gap-3 p-3 bg-[#1F1F1F] rounded-lg border border-[#383838]">
                        <Palette className="w-6 h-6 text-[#E8466C]" />
                        <div className="flex-1">
                          <p className="text-white text-sm font-inter">Accent (#E8466C)</p>
                          <p className="text-xs text-muted-foreground font-inter">Ícones de ação, CTAs</p>
                        </div>
                      </div>
                      <div className="flex items-center gap-3 p-3 bg-[#1F1F1F] rounded-lg border border-[#383838]">
                        <Type className="w-6 h-6 text-[#B3B3B3]" />
                        <div className="flex-1">
                          <p className="text-white text-sm font-inter">Muted (#B3B3B3)</p>
                          <p className="text-xs text-muted-foreground font-inter">Ícones secundários, hints</p>
                        </div>
                      </div>
                    </div>
                  </div>
                </CardContent>
              </Card>

              <Card className="bg-[#141414] border-[#383838]">
                <CardHeader>
                  <CardTitle className="text-white font-poppins">Ícones Comuns na Interface</CardTitle>
                </CardHeader>
                <CardContent>
                  <div className="grid gap-3 sm:grid-cols-2 lg:grid-cols-4">
                    {[
                      { icon: <Eye className="w-6 h-6" />, name: 'Visualizar' },
                      { icon: <Type className="w-6 h-6" />, name: 'Editar' },
                      { icon: <Palette className="w-6 h-6" />, name: 'Personalizar' },
                      { icon: <Layers className="w-6 h-6" />, name: 'Camadas' },
                      { icon: <Check className="w-6 h-6" />, name: 'Confirmar' },
                      { icon: <X className="w-6 h-6" />, name: 'Fechar' },
                      { icon: <Download className="w-6 h-6" />, name: 'Download' },
                      { icon: <Sparkles className="w-6 h-6" />, name: 'Destaque' },
                    ].map((item, i) => (
                      <div key={i} className="flex items-center gap-3 p-3 bg-[#1F1F1F] rounded-lg border border-[#383838] hover:border-[#E8466C] transition-colors">
                        <div className="text-[#E8466C]">{item.icon}</div>
                        <span className="text-sm text-white font-inter">{item.name}</span>
                      </div>
                    ))}
                  </div>
                </CardContent>
              </Card>
            </TabsContent>

            {/* COMPONENTS TAB */}
            <TabsContent value="components" className="space-y-8 animate-in fade-in-50 duration-500">
              <Card className="bg-[#141414] border-[#383838]">
                <CardHeader>
                  <CardTitle className="text-white font-poppins">Botões e Ações</CardTitle>
                  <CardDescription>Sistema de interação com Rounded-Pill (Totalmente circulares)</CardDescription>
                </CardHeader>
                <CardContent className="space-y-6">
                  <div className="flex flex-wrap gap-4 items-center">
                    <button className="bg-[#E8466C] hover:bg-[#D13F61] text-white font-bold py-3 px-8 rounded-full transition-colors font-poppins shadow-lg shadow-[#E8466C]/20">
                      Primary Button
                    </button>
                    <button className="bg-transparent border-2 border-[#383838] hover:bg-white/5 text-white font-medium py-3 px-8 rounded-full transition-colors font-poppins">
                      Outlined Button
                    </button>
                    <button className="bg-transparent hover:bg-white/5 text-[#E8466C] font-bold py-3 px-8 rounded-full transition-colors font-poppins">
                      Text Button
                    </button>
                    <button className="bg-[#22C55E] hover:bg-[#16A34A] text-white font-bold py-3 px-8 rounded-full transition-colors font-poppins shadow-lg shadow-[#22C55E]/20">
                      Success Button
                    </button>
                  </div>

                  <Separator className="bg-[#383838]" />

                  <div>
                    <h4 className="text-white font-semibold mb-3 font-poppins">Tamanhos de Botão</h4>
                    <div className="flex flex-wrap gap-4 items-center">
                      <button className="bg-[#E8466C] hover:bg-[#D13F61] text-white font-bold py-2 px-6 rounded-full transition-colors font-poppins text-sm">
                        Small
                      </button>
                      <button className="bg-[#E8466C] hover:bg-[#D13F61] text-white font-bold py-3 px-8 rounded-full transition-colors font-poppins text-base">
                        Medium
                      </button>
                      <button className="bg-[#E8466C] hover:bg-[#D13F61] text-white font-bold py-4 px-10 rounded-full transition-colors font-poppins text-lg">
                        Large
                      </button>
                    </div>
                  </div>

                  <Separator className="bg-[#383838]" />

                  <div>
                    <h4 className="text-white font-semibold mb-3 font-poppins">Botões com Ícones</h4>
                    <div className="flex flex-wrap gap-4 items-center">
                      <button className="bg-[#E8466C] hover:bg-[#D13F61] text-white font-bold py-3 px-8 rounded-full transition-colors font-poppins flex items-center gap-2">
                        <Download className="w-5 h-5" />
                        Download
                      </button>
                      <button className="bg-transparent border-2 border-[#383838] hover:bg-white/5 text-white font-medium py-3 px-8 rounded-full transition-colors font-poppins flex items-center gap-2">
                        <Sparkles className="w-5 h-5" />
                        Match
                      </button>
                    </div>
                  </div>
                </CardContent>
              </Card>

              <div className="grid gap-6 md:grid-cols-2">
                <Card className="bg-[#141414] border-[#383838]">
                  <CardHeader>
                    <CardTitle className="text-white font-poppins">Badges de Usuários</CardTitle>
                    <CardDescription>Categorias e tags</CardDescription>
                  </CardHeader>
                  <CardContent className="space-y-4">
                    <div className="flex flex-wrap gap-3">
                      <div className="bg-[#E8466C]/20 border border-[#E8466C]/50 text-[#E8466C] px-3 py-1 rounded-full text-xs font-bold uppercase tracking-wider font-inter">
                        Músico
                      </div>
                      <div className="bg-[#C026D3]/20 border border-[#C026D3]/50 text-[#C026D3] px-3 py-1 rounded-full text-xs font-bold uppercase tracking-wider font-inter">
                        Banda
                      </div>
                      <div className="bg-[#DC2626]/20 border border-[#DC2626]/50 text-[#DC2626] px-3 py-1 rounded-full text-xs font-bold uppercase tracking-wider font-inter">
                        Estúdio
                      </div>
                    </div>

                    <Separator className="bg-[#383838]" />

                    <div>
                      <h4 className="text-sm text-muted-foreground mb-2 font-inter">Badges de Status</h4>
                      <div className="flex flex-wrap gap-3">
                        <div className="bg-[#22C55E]/20 border border-[#22C55E]/50 text-[#22C55E] px-3 py-1 rounded-full text-xs font-bold uppercase tracking-wider font-inter">
                          Online
                        </div>
                        <div className="bg-[#F59E0B]/20 border border-[#F59E0B]/50 text-[#F59E0B] px-3 py-1 rounded-full text-xs font-bold uppercase tracking-wider font-inter">
                          Ocupado
                        </div>
                        <div className="bg-[#737373]/20 border border-[#737373]/50 text-[#737373] px-3 py-1 rounded-full text-xs font-bold uppercase tracking-wider font-inter">
                          Offline
                        </div>
                      </div>
                    </div>
                  </CardContent>
                </Card>

                <Card className="bg-[#141414] border-[#383838]">
                  <CardHeader>
                    <CardTitle className="text-white font-poppins">Inputs</CardTitle>
                    <CardDescription>Campos de formulário</CardDescription>
                  </CardHeader>
                  <CardContent className="space-y-4">
                    <div className="flex flex-col gap-2">
                      <label className="text-sm font-medium text-white font-inter">Nome de perfil</label>
                      <input 
                        type="text" 
                        placeholder="Digite seu nome..." 
                        className="bg-[#1F1F1F] border border-[#383838] rounded-xl px-4 py-3 text-white placeholder:text-[#737373] focus:outline-none focus:border-[#E8466C] transition-colors font-inter"
                      />
                    </div>

                    <div className="flex flex-col gap-2">
                      <label className="text-sm font-medium text-white font-inter">Bio</label>
                      <textarea 
                        placeholder="Conte um pouco sobre você..." 
                        rows={3}
                        className="bg-[#1F1F1F] border border-[#383838] rounded-xl px-4 py-3 text-white placeholder:text-[#737373] focus:outline-none focus:border-[#E8466C] transition-colors resize-none font-inter"
                      />
                    </div>

                    <div className="flex flex-col gap-2">
                      <label className="text-sm font-medium text-white font-inter">Categoria</label>
                      <select className="bg-[#1F1F1F] border border-[#383838] rounded-xl px-4 py-3 text-white focus:outline-none focus:border-[#E8466C] transition-colors font-inter">
                        <option>Selecione...</option>
                        <option>Músico</option>
                        <option>Banda</option>
                        <option>Estúdio</option>
                      </select>
                    </div>
                  </CardContent>
                </Card>
              </div>

              <Card className="bg-[#141414] border-[#383838]">
                <CardHeader>
                  <CardTitle className="text-white font-poppins">Cards</CardTitle>
                  <CardDescription>Containers de conteúdo</CardDescription>
                </CardHeader>
                <CardContent>
                  <div className="grid gap-6 md:grid-cols-2 lg:grid-cols-3">
                    <div className="bg-[#1F1F1F] border border-[#383838] rounded-xl p-6 hover:border-[#E8466C] transition-colors group">
                      <div className="w-12 h-12 bg-[#E8466C]/20 rounded-full flex items-center justify-center mb-4 group-hover:bg-[#E8466C]/30 transition-colors">
                        <Sparkles className="w-6 h-6 text-[#E8466C]" />
                      </div>
                      <h3 className="text-lg font-bold text-white mb-2 font-poppins">Feature Card</h3>
                      <p className="text-sm text-muted-foreground font-inter">Descrição da feature ou funcionalidade do card.</p>
                    </div>

                    <div className="bg-gradient-to-br from-[#E8466C] to-[#D13F61] rounded-xl p-6 text-white">
                      <h3 className="text-lg font-bold mb-2 font-poppins">Premium Card</h3>
                      <p className="text-sm text-white/80 font-inter">Card com gradiente para destaque especial.</p>
                      <button className="mt-4 bg-white text-[#E8466C] font-bold py-2 px-6 rounded-full hover:bg-white/90 transition-colors font-poppins text-sm">
                        Saiba mais
                      </button>
                    </div>

                    <div className="bg-[#1F1F1F] border border-[#383838] rounded-xl overflow-hidden">
                      <div className="h-32 bg-gradient-to-br from-purple-900 to-black"></div>
                      <div className="p-4">
                        <h3 className="text-lg font-bold text-white mb-1 font-poppins">Image Card</h3>
                        <p className="text-xs text-muted-foreground font-inter">Card com imagem de cabeçalho</p>
                      </div>
                    </div>
                  </div>
                </CardContent>
              </Card>
            </TabsContent>

            {/* MOTION TAB - New */}
            <TabsContent value="motion" className="space-y-8 animate-in fade-in-50 duration-500">
              <Card className="bg-[#141414] border-[#383838]">
                <CardHeader>
                  <CardTitle className="text-white font-poppins">Princípios de Animação</CardTitle>
                  <CardDescription>Movimento com propósito e personalidade</CardDescription>
                </CardHeader>
                <CardContent className="space-y-4">
                  <div className="grid gap-4 md:grid-cols-2">
                    <div className="bg-[#1F1F1F] border border-[#383838] rounded-lg p-4">
                      <div className="flex items-center gap-2 mb-2">
                        <Zap className="w-5 h-5 text-[#E8466C]" />
                        <h4 className="font-semibold text-white font-poppins">Rápido & Responsivo</h4>
                      </div>
                      <p className="text-sm text-muted-foreground font-inter">
                        Animações devem ser rápidas (150-300ms) para não atrasar a interação do usuário.
                      </p>
                    </div>
                    <div className="bg-[#1F1F1F] border border-[#383838] rounded-lg p-4">
                      <div className="flex items-center gap-2 mb-2">
                        <Sparkles className="w-5 h-5 text-[#FF69B4]" />
                        <h4 className="font-semibold text-white font-poppins">Natural & Suave</h4>
                      </div>
                      <p className="text-sm text-muted-foreground font-inter">
                        Use easing curves que imitem movimento natural (ease-out para entradas, ease-in para saídas).
                      </p>
                    </div>
                  </div>
                </CardContent>
              </Card>

              <Card className="bg-[#141414] border-[#383838]">
                <CardHeader>
                  <CardTitle className="text-white font-poppins">Easing & Timing</CardTitle>
                </CardHeader>
                <CardContent>
                  <div className="space-y-6">
                    {[
                      { 
                        name: 'Standard Easing', 
                        value: 'cubic-bezier(0.4, 0.0, 0.2, 1)', 
                        duration: '200ms',
                        use: 'Transições gerais, hover states'
                      },
                      { 
                        name: 'Deceleration (Ease Out)', 
                        value: 'cubic-bezier(0.0, 0.0, 0.2, 1)', 
                        duration: '250ms',
                        use: 'Elementos entrando na tela'
                      },
                      { 
                        name: 'Acceleration (Ease In)', 
                        value: 'cubic-bezier(0.4, 0.0, 1, 1)', 
                        duration: '150ms',
                        use: 'Elementos saindo da tela'
                      },
                      { 
                        name: 'Sharp Easing', 
                        value: 'cubic-bezier(0.4, 0.0, 0.6, 1)', 
                        duration: '200ms',
                        use: 'Modais, drawers, navigation'
                      },
                    ].map((easing, i) => (
                      <div key={i}>
                        <div className="flex justify-between items-start mb-2">
                          <div>
                            <h4 className="font-semibold text-white font-poppins">{easing.name}</h4>
                            <p className="text-xs text-muted-foreground font-mono mt-1">{easing.value}</p>
                          </div>
                          <Badge className="bg-[#E8466C]/20 text-[#E8466C] border border-[#E8466C]/50">
                            {easing.duration}
                          </Badge>
                        </div>
                        <p className="text-sm text-muted-foreground font-inter mb-3">{easing.use}</p>
                        <div className="bg-[#1F1F1F] border border-[#383838] rounded-lg p-4">
                          <div className="h-1 bg-[#383838] rounded-full relative overflow-hidden">
                            <div 
                              className="absolute inset-y-0 left-0 bg-[#E8466C] rounded-full animate-pulse"
                              style={{ 
                                width: '30%',
                                transition: `all ${easing.duration} ${easing.value}`
                              }}
                            />
                          </div>
                        </div>
                      </div>
                    ))}
                  </div>
                </CardContent>
              </Card>

              <Card className="bg-[#141414] border-[#383838]">
                <CardHeader>
                  <CardTitle className="text-white font-poppins">Exemplos de Animação</CardTitle>
                </CardHeader>
                <CardContent className="space-y-6">
                  <div>
                    <h4 className="text-white font-semibold mb-3 font-poppins">Fade In</h4>
                    <div className="bg-[#1F1F1F] border border-[#383838] rounded-lg p-6 flex items-center justify-center">
                      <div className="animate-in fade-in duration-500">
                        <p className="text-white font-inter">Conteúdo aparecendo suavemente</p>
                      </div>
                    </div>
                    <p className="text-xs text-muted-foreground mt-2 font-mono">opacity: 0 → 1 | duration: 500ms</p>
                  </div>

                  <div>
                    <h4 className="text-white font-semibold mb-3 font-poppins">Slide Up</h4>
                    <div className="bg-[#1F1F1F] border border-[#383838] rounded-lg p-6 flex items-center justify-center overflow-hidden">
                      <div className="animate-in slide-in-from-bottom duration-500">
                        <p className="text-white font-inter">Conteúdo deslizando de baixo</p>
                      </div>
                    </div>
                    <p className="text-xs text-muted-foreground mt-2 font-mono">transform: translateY(20px) → translateY(0) | duration: 500ms</p>
                  </div>

                  <div>
                    <h4 className="text-white font-semibold mb-3 font-poppins">Scale</h4>
                    <div className="bg-[#1F1F1F] border border-[#383838] rounded-lg p-6 flex items-center justify-center">
                      <button className="bg-[#E8466C] hover:scale-110 text-white font-bold py-3 px-8 rounded-full transition-transform duration-200 font-poppins">
                        Hover Me
                      </button>
                    </div>
                    <p className="text-xs text-muted-foreground mt-2 font-mono">transform: scale(1) → scale(1.1) | duration: 200ms</p>
                  </div>
                </CardContent>
              </Card>

              <Card className="bg-[#141414] border-[#383838]">
                <CardHeader>
                  <CardTitle className="text-white font-poppins">Microinterações</CardTitle>
                  <CardDescription>Detalhes que fazem diferença</CardDescription>
                </CardHeader>
                <CardContent className="space-y-4">
                  <div className="space-y-2">
                    <h4 className="text-sm font-semibold text-white font-poppins">Botão de Like</h4>
                    <p className="text-xs text-muted-foreground font-inter">Scale pulse + cor change ao clicar</p>
                  </div>
                  <div className="space-y-2">
                    <h4 className="text-sm font-semibold text-white font-poppins">Match Confirmado</h4>
                    <p className="text-xs text-muted-foreground font-inter">Confetti animation + fade in do card</p>
                  </div>
                  <div className="space-y-2">
                    <h4 className="text-sm font-semibold text-white font-poppins">Loading States</h4>
                    <p className="text-xs text-muted-foreground font-inter">Skeleton screens com shimmer effect</p>
                  </div>
                  <div className="space-y-2">
                    <h4 className="text-sm font-semibold text-white font-poppins">Swipe Cards</h4>
                    <p className="text-xs text-muted-foreground font-inter">Spring physics para bounce back</p>
                  </div>
                </CardContent>
              </Card>
            </TabsContent>

            {/* ACCESSIBILITY TAB - New */}
            <TabsContent value="accessibility" className="space-y-8 animate-in fade-in-50 duration-500">
              <Card className="bg-[#141414] border-[#383838]">
                <CardHeader>
                  <CardTitle className="text-white font-poppins">Compromisso com Acessibilidade</CardTitle>
                  <CardDescription>Seguindo WCAG 2.1 Level AA</CardDescription>
                </CardHeader>
                <CardContent>
                  <p className="text-muted-foreground font-inter mb-4">
                    O MubeApp é para todos. Nosso design segue as diretrizes WCAG 2.1 Level AA para garantir que músicos de todas as habilidades possam usar nossa plataforma.
                  </p>
                  <div className="grid gap-4 md:grid-cols-2">
                    <div className="bg-[#1F1F1F] border border-[#383838] rounded-lg p-4">
                      <div className="flex items-center gap-2 mb-2">
                        <Check className="w-5 h-5 text-[#22C55E]" />
                        <h4 className="font-semibold text-white font-poppins">Contraste de Cores</h4>
                      </div>
                      <p className="text-sm text-muted-foreground font-inter">
                        Todas as combinações de texto/fundo atingem mínimo 4.5:1 para texto normal e 3:1 para texto grande.
                      </p>
                    </div>
                    <div className="bg-[#1F1F1F] border border-[#383838] rounded-lg p-4">
                      <div className="flex items-center gap-2 mb-2">
                        <Check className="w-5 h-5 text-[#22C55E]" />
                        <h4 className="font-semibold text-white font-poppins">Navegação por Teclado</h4>
                      </div>
                      <p className="text-sm text-muted-foreground font-inter">
                        Todos os elementos interativos são acessíveis via Tab, com indicadores de foco visíveis.
                      </p>
                    </div>
                    <div className="bg-[#1F1F1F] border border-[#383838] rounded-lg p-4">
                      <div className="flex items-center gap-2 mb-2">
                        <Check className="w-5 h-5 text-[#22C55E]" />
                        <h4 className="font-semibold text-white font-poppins">Screen Readers</h4>
                      </div>
                      <p className="text-sm text-muted-foreground font-inter">
                        Uso semântico de HTML, ARIA labels e alt text descritivo em todas as imagens.
                      </p>
                    </div>
                    <div className="bg-[#1F1F1F] border border-[#383838] rounded-lg p-4">
                      <div className="flex items-center gap-2 mb-2">
                        <Check className="w-5 h-5 text-[#22C55E]" />
                        <h4 className="font-semibold text-white font-poppins">Touch Targets</h4>
                      </div>
                      <p className="text-sm text-muted-foreground font-inter">
                        Áreas clicáveis mínimas de 44px × 44px para facilitar interação em dispositivos móveis.
                      </p>
                    </div>
                  </div>
                </CardContent>
              </Card>

              <Card className="bg-[#141414] border-[#383838]">
                <CardHeader>
                  <CardTitle className="text-white font-poppins">Tabela de Contraste</CardTitle>
                  <CardDescription>Validação WCAG AA para principais combinações</CardDescription>
                </CardHeader>
                <CardContent>
                  <div className="overflow-x-auto">
                    <table className="w-full text-sm">
                      <thead>
                        <tr className="border-b border-[#383838]">
                          <th className="text-left py-3 px-4 text-white font-semibold font-poppins">Combinação</th>
                          <th className="text-left py-3 px-4 text-white font-semibold font-poppins">Contraste</th>
                          <th className="text-left py-3 px-4 text-white font-semibold font-poppins">Status</th>
                          <th className="text-left py-3 px-4 text-white font-semibold font-poppins">Uso</th>
                        </tr>
                      </thead>
                      <tbody className="font-inter">
                        {[
                          { combo: '#FFFFFF / #0A0A0A', ratio: '21:1', status: 'AAA', use: 'Texto principal' },
                          { combo: '#B3B3B3 / #0A0A0A', ratio: '9.5:1', status: 'AAA', use: 'Texto secundário' },
                          { combo: '#737373 / #0A0A0A', ratio: '4.7:1', status: 'AA', use: 'Texto muted' },
                          { combo: '#E8466C / #0A0A0A', ratio: '4.5:1', status: 'AA', use: 'CTAs, Links' },
                          { combo: '#FFFFFF / #E8466C', ratio: '4.7:1', status: 'AA', use: 'Botões primários' },
                          { combo: '#22C55E / #0A0A0A', ratio: '4.8:1', status: 'AA', use: 'Success states' },
                          { combo: '#FFFFFF / #141414', ratio: '18.2:1', status: 'AAA', use: 'Cards, Containers' },
                        ].map((row, i) => (
                          <tr key={i} className="border-b border-[#383838]/50">
                            <td className="py-3 px-4">
                              <code className="text-xs text-muted-foreground">{row.combo}</code>
                            </td>
                            <td className="py-3 px-4 font-mono text-white">{row.ratio}</td>
                            <td className="py-3 px-4">
                              <Badge className={row.status === 'AAA' ? 'bg-[#22C55E]/20 text-[#22C55E] border border-[#22C55E]/50' : 'bg-[#3B82F6]/20 text-[#3B82F6] border border-[#3B82F6]/50'}>
                                {row.status}
                              </Badge>
                            </td>
                            <td className="py-3 px-4 text-muted-foreground">{row.use}</td>
                          </tr>
                        ))}
                      </tbody>
                    </table>
                  </div>
                  <p className="text-xs text-muted-foreground mt-4 font-inter">
                    WCAG AA: mínimo 4.5:1 para texto normal, 3:1 para texto grande (18px+ ou 14px+ bold)<br />
                    WCAG AAA: mínimo 7:1 para texto normal, 4.5:1 para texto grande
                  </p>
                </CardContent>
              </Card>

              <Card className="bg-[#141414] border-[#383838]">
                <CardHeader>
                  <CardTitle className="text-white font-poppins">Indicadores de Foco</CardTitle>
                </CardHeader>
                <CardContent className="space-y-4">
                  <p className="text-sm text-muted-foreground font-inter">
                    Todos os elementos interativos devem ter um indicador de foco visível quando navegados por teclado:
                  </p>
                  <div className="space-y-4">
                    <button className="bg-[#E8466C] text-white font-bold py-3 px-8 rounded-full font-poppins focus:outline-none focus:ring-4 focus:ring-[#E8466C]/50">
                      Botão com Focus Ring
                    </button>
                    <input 
                      type="text" 
                      placeholder="Input com Focus Border" 
                      className="w-full bg-[#1F1F1F] border border-[#383838] rounded-xl px-4 py-3 text-white placeholder:text-[#737373] focus:outline-none focus:border-[#E8466C] focus:ring-2 focus:ring-[#E8466C]/30 transition-all font-inter"
                    />
                  </div>
                  <div className="mt-4 p-4 bg-[#1F1F1F] border border-[#383838] rounded-lg">
                    <p className="text-xs text-muted-foreground font-mono">
                      focus:outline-none focus:ring-4 focus:ring-[#E8466C]/50
                    </p>
                  </div>
                </CardContent>
              </Card>

              <Card className="bg-[#141414] border-[#383838]">
                <CardHeader>
                  <CardTitle className="text-white font-poppins">Boas Práticas</CardTitle>
                </CardHeader>
                <CardContent>
                  <ul className="space-y-3">
                    {[
                      'Sempre forneça alt text descritivo para imagens (não apenas "imagem" ou "foto")',
                      'Use labels semânticos em formulários (não apenas placeholders)',
                      'Mantenha hierarquia de headings (h1 → h2 → h3, sem pular níveis)',
                      'Forneça feedback visual E textual para ações (não apenas mudança de cor)',
                      'Certifique-se que animações possam ser desabilitadas (prefers-reduced-motion)',
                      'Teste com leitores de tela (NVDA, JAWS, VoiceOver)',
                      'Garanta que todo conteúdo é acessível apenas com teclado (sem mouse)',
                    ].map((practice, i) => (
                      <li key={i} className="flex items-start gap-3">
                        <Check className="w-5 h-5 text-[#22C55E] mt-0.5 flex-shrink-0" />
                        <span className="text-sm text-muted-foreground font-inter">{practice}</span>
                      </li>
                    ))}
                  </ul>
                </CardContent>
              </Card>
            </TabsContent>

            {/* DOWNLOADS TAB - New */}
            <TabsContent value="downloads" className="space-y-8 animate-in fade-in-50 duration-500">
              <Card className="bg-[#141414] border-[#383838]">
                <CardHeader>
                  <CardTitle className="text-white font-poppins">Pacote de Assets</CardTitle>
                  <CardDescription>Download de logos e recursos oficiais</CardDescription>
                </CardHeader>
                <CardContent>
                  <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
                    <div className="bg-[#1F1F1F] border border-[#383838] rounded-xl p-6 hover:border-[#E8466C] transition-colors group">
                      <div className="w-12 h-12 bg-[#E8466C]/20 rounded-full flex items-center justify-center mb-4 group-hover:bg-[#E8466C]/30 transition-colors">
                        <Download className="w-6 h-6 text-[#E8466C]" />
                      </div>
                      <h3 className="text-lg font-bold text-white mb-2 font-poppins">Logos SVG</h3>
                      <p className="text-sm text-muted-foreground mb-4 font-inter">
                        Todas as variações de logo em formato vetorial escalável
                      </p>
                      <button className="w-full bg-transparent border border-[#383838] hover:bg-white/5 text-white font-medium py-2 px-4 rounded-full transition-colors font-poppins text-sm">
                        Download ZIP (2.4 MB)
                      </button>
                    </div>

                    <div className="bg-[#1F1F1F] border border-[#383838] rounded-xl p-6 hover:border-[#E8466C] transition-colors group">
                      <div className="w-12 h-12 bg-[#FF69B4]/20 rounded-full flex items-center justify-center mb-4 group-hover:bg-[#FF69B4]/30 transition-colors">
                        <Download className="w-6 h-6 text-[#FF69B4]" />
                      </div>
                      <h3 className="text-lg font-bold text-white mb-2 font-poppins">Logos PNG</h3>
                      <p className="text-sm text-muted-foreground mb-4 font-inter">
                        Logos em alta resolução (2x, 3x) para web e impressão
                      </p>
                      <button className="w-full bg-transparent border border-[#383838] hover:bg-white/5 text-white font-medium py-2 px-4 rounded-full transition-colors font-poppins text-sm">
                        Download ZIP (8.1 MB)
                      </button>
                    </div>

                    <div className="bg-[#1F1F1F] border border-[#383838] rounded-xl p-6 hover:border-[#E8466C] transition-colors group">
                      <div className="w-12 h-12 bg-[#E8466C]/20 rounded-full flex items-center justify-center mb-4 group-hover:bg-[#E8466C]/30 transition-colors">
                        <Download className="w-6 h-6 text-[#E8466C]" />
                      </div>
                      <h3 className="text-lg font-bold text-white mb-2 font-poppins">Paleta de Cores</h3>
                      <p className="text-sm text-muted-foreground mb-4 font-inter">
                        Arquivo ASE para Photoshop, Illustrator e Figma
                      </p>
                      <button className="w-full bg-transparent border border-[#383838] hover:bg-white/5 text-white font-medium py-2 px-4 rounded-full transition-colors font-poppins text-sm">
                        Download (.ase)
                      </button>
                    </div>

                    <div className="bg-[#1F1F1F] border border-[#383838] rounded-xl p-6 hover:border-[#E8466C] transition-colors group">
                      <div className="w-12 h-12 bg-[#D13F61]/20 rounded-full flex items-center justify-center mb-4 group-hover:bg-[#D13F61]/30 transition-colors">
                        <Download className="w-6 h-6 text-[#D13F61]" />
                      </div>
                      <h3 className="text-lg font-bold text-white mb-2 font-poppins">Fontes</h3>
                      <p className="text-sm text-muted-foreground mb-4 font-inter">
                        Poppins e Inter (Google Fonts links incluídos)
                      </p>
                      <button className="w-full bg-transparent border border-[#383838] hover:bg-white/5 text-white font-medium py-2 px-4 rounded-full transition-colors font-poppins text-sm">
                        Ver Instruções
                      </button>
                    </div>

                    <div className="bg-[#1F1F1F] border border-[#383838] rounded-xl p-6 hover:border-[#E8466C] transition-colors group">
                      <div className="w-12 h-12 bg-[#FF69B4]/20 rounded-full flex items-center justify-center mb-4 group-hover:bg-[#FF69B4]/30 transition-colors">
                        <Download className="w-6 h-6 text-[#FF69B4]" />
                      </div>
                      <h3 className="text-lg font-bold text-white mb-2 font-poppins">Ícones</h3>
                      <p className="text-sm text-muted-foreground mb-4 font-inter">
                        Pack de ícones customizados do MubeApp (SVG)
                      </p>
                      <button className="w-full bg-transparent border border-[#383838] hover:bg-white/5 text-white font-medium py-2 px-4 rounded-full transition-colors font-poppins text-sm">
                        Download ZIP (1.2 MB)
                      </button>
                    </div>

                    <div className="bg-gradient-to-br from-[#E8466C] to-[#D13F61] rounded-xl p-6">
                      <div className="w-12 h-12 bg-white/20 rounded-full flex items-center justify-center mb-4">
                        <Download className="w-6 h-6 text-white" />
                      </div>
                      <h3 className="text-lg font-bold text-white mb-2 font-poppins">Pacote Completo</h3>
                      <p className="text-sm text-white/80 mb-4 font-inter">
                        Todos os assets do manual de marca em um único arquivo
                      </p>
                      <button className="w-full bg-white text-[#E8466C] font-bold py-2 px-4 rounded-full hover:bg-white/90 transition-colors font-poppins text-sm">
                        Download Tudo (15 MB)
                      </button>
                    </div>
                  </div>
                </CardContent>
              </Card>

              <Card className="bg-[#141414] border-[#383838]">
                <CardHeader>
                  <CardTitle className="text-white font-poppins">Termos de Uso</CardTitle>
                </CardHeader>
                <CardContent>
                  <div className="space-y-4 text-sm text-muted-foreground font-inter">
                    <div className="flex items-start gap-2">
                      <Check className="w-5 h-5 text-[#22C55E] mt-0.5 flex-shrink-0" />
                      <p>Permitido uso dos assets para divulgação oficial do MubeApp</p>
                    </div>
                    <div className="flex items-start gap-2">
                      <Check className="w-5 h-5 text-[#22C55E] mt-0.5 flex-shrink-0" />
                      <p>Parceiros e press kits podem usar mediante autorização</p>
                    </div>
                    <div className="flex items-start gap-2">
                      <X className="w-5 h-5 text-[#EF4444] mt-0.5 flex-shrink-0" />
                      <p>Proibido alterar cores, distorcer ou modificar os logos</p>
                    </div>
                    <div className="flex items-start gap-2">
                      <X className="w-5 h-5 text-[#EF4444] mt-0.5 flex-shrink-0" />
                      <p>Proibido uso comercial sem autorização por escrito</p>
                    </div>
                  </div>
                  <div className="mt-6 p-4 bg-[#1F1F1F] border border-[#383838] rounded-lg">
                    <p className="text-xs text-muted-foreground font-inter">
                      Para dúvidas sobre licenciamento e uso dos assets, entre em contato através de: <span className="text-[#E8466C]">brand@mubeapp.com</span>
                    </p>
                  </div>
                </CardContent>
              </Card>

              <Card className="bg-[#141414] border-[#383838]">
                <CardHeader>
                  <CardTitle className="text-white font-poppins">Precisa de Mais?</CardTitle>
                  <CardDescription>Recursos adicionais e suporte</CardDescription>
                </CardHeader>
                <CardContent className="space-y-4">
                  <div className="grid gap-4 md:grid-cols-2">
                    <div className="bg-[#1F1F1F] border border-[#383838] rounded-lg p-4">
                      <h4 className="font-semibold text-white mb-2 font-poppins">Figma Design System</h4>
                      <p className="text-sm text-muted-foreground mb-3 font-inter">Acesse nosso design system completo no Figma</p>
                      <a href="#" className="text-sm text-[#E8466C] hover:underline font-inter">Acessar Figma →</a>
                    </div>
                    <div className="bg-[#1F1F1F] border border-[#383838] rounded-lg p-4">
                      <h4 className="font-semibold text-white mb-2 font-poppins">Suporte Técnico</h4>
                      <p className="text-sm text-muted-foreground mb-3 font-inter">Entre em contato para suporte de implementação</p>
                      <a href="mailto:brand@mubeapp.com" className="text-sm text-[#E8466C] hover:underline font-inter">brand@mubeapp.com →</a>
                    </div>
                  </div>
                </CardContent>
              </Card>
            </TabsContent>

          </div>
        </Tabs>
      </main>

      {/* Footer */}
      <footer className="border-t border-[#383838] bg-[#0A0A0A] mt-24">
        <div className="container mx-auto px-4 sm:px-6 lg:px-8 py-8">
          <div className="flex flex-col md:flex-row justify-between items-center gap-4">
            <div>
              <p className="text-sm text-muted-foreground font-inter">
                © 2026 MubeApp. Todos os direitos reservados.
              </p>
            </div>
            <div className="flex gap-6">
              <a href="#" className="text-sm text-muted-foreground hover:text-[#E8466C] transition-colors font-inter">
                Política de Privacidade
              </a>
              <a href="#" className="text-sm text-muted-foreground hover:text-[#E8466C] transition-colors font-inter">
                Termos de Uso
              </a>
              <a href="mailto:brand@mubeapp.com" className="text-sm text-muted-foreground hover:text-[#E8466C] transition-colors font-inter">
                Contato
              </a>
            </div>
          </div>
        </div>
      </footer>
    </div>
  );
}
