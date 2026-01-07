# Clisync 📱

Aplicativo completo de gestão e controle financeiro para prestadores de serviços, desenvolvido em Flutter. O Clisync oferece uma solução integrada para gerenciar clientes, controlar pagamentos, gerar relatórios e agendar serviços de forma eficiente e profissional.

## 📋 Sobre o App

O **Clisync** é uma plataforma multiplataforma desenvolvida para **todos os prestadores de serviços** que precisam de um sistema robusto para gerenciar seu negócio. Ideal para:

- 💇 **Cabeleleiros e salões de beleza**
- 💅 **Manicures e pedicures**
- 🎨 **Pintores e decoradores**
- 🔧 **Técnicos e prestadores de serviços gerais**
- 🏢 **Empresas de vigilância e segurança**
- 🧹 **Prestadores de serviços domésticos**
- E **qualquer profissional** que precisa gerenciar clientes e serviços

### O que o Clisync oferece:

- **Gerenciar clientes** de forma organizada e eficiente
- **Controlar pagamentos mensais** e identificar inadimplências
- **Agendar serviços** e acompanhar próximos atendimentos
- **Gerar relatórios financeiros** em PDF para análise e documentação
- **Análises visuais** com gráficos e métricas de desempenho
- **Personalizar campos** de acordo com as necessidades do seu negócio
- **Integrar com formulários web** para coleta de dados de clientes

O aplicativo foi projetado para atender dois tipos principais de modelos de negócio: **clientes recorrentes** (mensalidades fixas) e **clientes únicos** (serviços pontuais com agendamento).

## 🚀 Funcionalidades Principais

### 🔐 Autenticação e Perfil
- **Sistema de login seguro** com Firebase Authentication
- **Registro de novos usuários** com validação de email
- **Recuperação de senha** automática
- **Perfil personalizável** com informações da empresa
- **Onboarding** para primeiro acesso com configuração inicial
- **Edição de perfil** com dados da empresa, endereço e chave PIX
- **Configuração de horários de atendimento** e tempo médio de serviço
- **Cadastro de tipos de serviço** com valores personalizados

### 👥 Gestão de Clientes

#### Modo Recorrentes
- **Cadastro completo** de clientes com informações detalhadas
- **Controle de pagamentos mensais** por período (mês/ano)
- **Marcação de pagamentos futuros** em lote (múltiplos meses)
- **Status de adimplência** em tempo real
- **Busca inteligente** por nome ou endereço (sem acentos)
- **Ativação/desativação** de clientes
- **Validação de duplicatas** por nome
- **Visualização detalhada** de histórico de pagamentos
- **Edição completa** de dados do cliente

#### Modo Únicos
- **Cadastro de clientes únicos** para serviços pontuais
- **Agendamento de serviços** com data e horário específicos
- **Sistema de horários disponíveis** baseado em configurações do perfil
- **Validação de conflitos** de horário entre clientes
- **Histórico completo** de serviços prestados por cliente
- **Status de serviços**: Agendado, Aguardando Pagamento, Pago
- **Edição de serviços** com atualização automática de valores
- **Visualização de próximos serviços** agendados
- **Geração de link de formulário** para coleta de dados via web
- **Integração com formulário web** para recebimento de agendamentos externos
- **Exclusão de serviços** com confirmação

### 📊 Relatórios e Análises

#### Relatórios Mensais (Recorrentes)
- **Relatório completo** de fechamento mensal
- **Estatísticas financeiras**: valor total, recebido e pendente
- **Métricas de clientes**: ativos, novos, pausados
- **Análise de adimplência**: adimplentes vs inadimplentes
- **Geração de PDF** profissional e personalizado
- **Exportação** para impressão ou compartilhamento
- **Processamento automático** de virada de mês

#### Relatórios Mensais (Clientes Únicos)
- **Relatório mensal** de serviços prestados
- **Total de serviços** realizados no período
- **Valor total faturado** no mês
- **Valor recebido** e **valor pendente**
- **Novos clientes** cadastrados
- **Clientes não pagos** identificados automaticamente
- **Análises visuais** com gráficos interativos:
  - **Gráfico de serviços por tipo**: visualização em barras da quantidade de cada tipo de serviço
  - **Gráfico de picos de movimento**: análise de dias da semana e horários mais movimentados
- **Filtro inteligente**: apenas serviços pagos ou com pagamento pendente (exclui agendamentos futuros)
- **Navegação para pendências** do mês específico

#### Relatórios de Pendências
- **Lista de clientes inadimplentes** por mês
- **Agrupamento por mês** para melhor organização
- **Filtros e busca** avançada por nome ou endereço
- **Marcação rápida** de pagamentos recebidos com confirmação
- **Visualização detalhada** de cada pendência
- **Ordenação cronológica** dos serviços (mais antigo para mais recente)
- **Modo dinâmico**: visualização de todas as pendências ou filtrado por mês específico
- **Separação individual** de serviços (mesmo cliente com múltiplos serviços aparece separadamente)

#### Relatórios de Pendências (Clientes Únicos)
- **Lista de serviços pendentes** agrupados por mês
- **Informações detalhadas**: cliente, data, horário, tipo de serviço e valor
- **Cada serviço em card separado** mesmo para o mesmo cliente
- **Ordenação por data e horário** (mais antigo primeiro)
- **Marcação individual** de pagamento por serviço
- **Confirmação antes de marcar** como pago
- **Filtro por mês** ou visualização completa
- **Busca inteligente** por nome do cliente

### ⚙️ Configurações e Personalização

- **Campos personalizáveis**: habilite ou desabilite campos conforme necessidade
- **Campos customizados**: adicione campos específicos do seu negócio
- **Tipos de serviço**: configure tipos de serviço personalizados com valores
- **Valores por tipo**: cada tipo de serviço pode ter um valor específico
- **Modo dual**: alternância entre modo Recorrentes e Únicos
- **Configuração de horários**: defina horário de início e fim de atendimento
- **Tempo médio de serviço**: configure intervalo entre agendamentos
- **Tema escuro** moderno e profissional
- **Interface responsiva** adaptada para diferentes tamanhos de tela

### 📅 Agendamento e Próximos Serviços

- **Dashboard de próximos serviços** na tela inicial
- **Visualização de agendamentos** ordenados por data e horário
- **Informações completas**: cliente, data, horário e contato
- **Sistema de horários disponíveis**: geração automática baseada em configurações
- **Prevenção de conflitos**: não permite agendamentos em horários já ocupados
- **Link de formulário** para clientes agendarem serviços
- **Integração web** para recebimento de agendamentos externos
- **Atualização em tempo real** de novos agendamentos

### 🔍 Busca e Filtros

- **Busca inteligente** com normalização de texto (sem acentos)
- **Busca por nome** ou endereço em tempo real
- **Filtros por status** de pagamento
- **Filtros por mês** nos relatórios
- **Validação de duplicatas** automática
- **Resultados instantâneos** conforme digitação

## 🔗 Integrações

### Firebase
- **Firebase Authentication**: Autenticação segura de usuários
- **Firebase Realtime Database**: Armazenamento em tempo real de dados
- **Sincronização automática** entre dispositivos
- **Backup automático** na nuvem
- **Dados isolados por usuário** para máxima segurança

### Formulário Web
- **Integração com sistema web**: Sistema web para coleta de dados de clientes
- **Link personalizado** por usuário para formulário de agendamento
- **Recebimento automático** de dados de clientes via web
- **Sincronização** entre app e formulário web
- **Validação de dados** recebidos externamente

### Geração de PDF
- **Biblioteca de impressão**: Geração profissional de relatórios
- **Layout personalizado** com logo e informações da empresa
- **Formatação automática** de valores monetários
- **Exportação** para impressão ou compartilhamento
- **Design responsivo** para diferentes tamanhos de papel

## ✨ Diferenciais

### 🎯 Dois Modos de Operação
O Clisync é único por oferecer **dois modos distintos** de gestão, adaptáveis a diferentes tipos de negócios:
- **Modo Recorrentes**: Ideal para clientes com mensalidades fixas (ex: salões com planos mensais, serviços de limpeza recorrentes, assinaturas)
- **Modo Únicos**: Perfeito para serviços pontuais com agendamento (ex: cortes de cabelo, manicures, pinturas, reparos)

### 🔄 Alternância Dinâmica
- **Troca instantânea** entre modos sem perder dados
- **Interface adaptativa** que muda conforme o modo selecionado
- **Funcionalidades específicas** para cada tipo de negócio
- **Flexibilidade total** para atender diferentes modelos de prestação de serviços

### 📊 Análises Visuais Avançadas
- **Gráficos interativos** de serviços por tipo
- **Análise de picos de movimento** por dia da semana e horário
- **Métricas em tempo real** de desempenho do negócio
- **Visualizações intuitivas** para tomada de decisão

### 📱 Multiplataforma Nativa
- **Android**: App nativo com performance otimizada
- **iOS**: Aplicativo completo para iPhone e iPad
- **Web**: Versão PWA acessível pelo navegador
- **Windows**: Aplicativo desktop para Windows
- **macOS**: App nativo para Mac
- **Linux**: Suporte completo para distribuições Linux

### 🎨 Interface Moderna
- **Design dark theme** profissional e elegante
- **Navegação intuitiva** com bottom navigation
- **Sidebar** com acesso rápido a configurações
- **Animações suaves** e transições fluidas
- **Feedback visual** em todas as ações
- **Cards informativos** com destaque visual

### 🔍 Busca Inteligente
- **Normalização de texto** para busca sem acentos
- **Busca por nome** ou endereço
- **Filtros em tempo real** para listas de clientes
- **Validação de duplicatas** automática
- **Resultados instantâneos**

### 📊 Relatórios Completos
- **Análise financeira detalhada** por mês
- **Métricas de crescimento** (novos clientes, saídas)
- **Identificação de inadimplência** automática
- **PDFs profissionais** prontos para apresentação
- **Gráficos e visualizações** para análise de tendências
- **Filtros inteligentes** para relatórios precisos

### 🔐 Segurança e Privacidade
- **Autenticação segura** com Firebase Auth
- **Dados isolados por usuário** no banco de dados
- **Validação de entrada** em todos os formulários
- **Proteção contra duplicatas** e dados inválidos
- **Confirmações** para ações críticas

### ⚡ Performance
- **Sincronização em tempo real** com Firebase
- **Carregamento otimizado** de dados
- **Cache local** para melhor experiência
- **Atualizações incrementais** sem recarregar tudo
- **Validação de horários** otimizada

## 🛠️ Tecnologias Utilizadas

- **Flutter**: Framework multiplataforma para desenvolvimento
- **Dart**: Linguagem de programação moderna e eficiente
- **Firebase Core**: Infraestrutura base do Firebase
- **Firebase Auth**: Autenticação de usuários
- **Firebase Realtime Database**: Banco de dados em tempo real
- **Google Fonts**: Tipografia personalizada
- **PDF**: Geração de documentos PDF
- **Printing**: Impressão e visualização de PDFs
- **Intl**: Internacionalização e formatação
- **Shared Preferences**: Armazenamento local de preferências
- **URL Launcher**: Abertura de links externos
- **Mask Text Input Formatter**: Formatação de campos de entrada

## 👨‍💻 Desenvolvedor

**Augusto NX**
- GitHub: [@AugustoNX](https://github.com/AugustoNX)

## 📞 Suporte

Se você encontrar algum problema ou tiver dúvidas, por favor abra uma issue no GitHub.

---

**Clisync** - Gestão completa para prestadores de serviços 💼
