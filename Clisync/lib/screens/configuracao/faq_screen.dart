import 'package:flutter/material.dart';
import 'package:clisync/theme/app_theme.dart';

class FAQScreen extends StatelessWidget {
  const FAQScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Perguntas Frequentes'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildSection(
              context,
              '📱 Sobre o Clisync',
              [
                _buildQuestionAnswer(
                  context,
                  'O que é o Clisync?',
                  'O Clisync é um aplicativo completo de gestão e controle financeiro para prestadores de serviços. Ele permite gerenciar clientes, controlar pagamentos, gerar relatórios e agendar serviços de forma organizada e profissional.',
                ),
                _buildQuestionAnswer(
                  context,
                  'Quem pode usar o Clisync?',
                  'O Clisync foi desenvolvido para todos os prestadores de serviços, incluindo cabeleleiros, manicures, pintores, técnicos, empresas de vigilância, prestadores de serviços domésticos e qualquer profissional que precisa gerenciar clientes e serviços.',
                ),
                _buildQuestionAnswer(
                  context,
                  'Quais são os modos disponíveis?',
                  'O Clisync oferece dois modos de operação:\n\n'
                  '• Modo Recorrentes: Ideal para clientes que pagam mensalidades fixas (como empresas de vigilância, assinaturas de serviços). Permite controlar pagamentos mensais por período.\n\n'
                  '• Modo Únicos: Perfeito para serviços pontuais com agendamento (como salões de beleza, serviços técnicos). Permite agendar serviços específicos com data e horário.',
                ),
              ],
            ),
            _buildSection(
              context,
              '🏠 Tela Inicial (Home)',
              [
                _buildQuestionAnswer(
                  context,
                  'O que encontro na tela inicial?',
                  'Na tela inicial você encontra:\n\n'
                  '• Seleção de Modo: Botões para alternar entre modo Recorrentes e Únicos.\n\n'
                  '• Próximos Serviços (Modo Únicos): Lista dos próximos serviços agendados, mostrando cliente, data e horário.\n\n'
                  '• Link do Formulário (Modo Únicos): Botão para gerar e copiar o link do formulário web que permite seus clientes agendarem serviços diretamente.\n\n'
                  '• Ações Rápidas (Modo Recorrentes): Acesso rápido para cadastrar novos clientes e visualizar pendências.',
                ),
                _buildQuestionAnswer(
                  context,
                  'Como alterno entre os modos?',
                  'Na tela inicial, você verá dois botões lado a lado: "Únicos" e "Recorrentes". Toque no modo desejado. O aplicativo automaticamente ajusta as telas e funcionalidades disponíveis conforme o modo selecionado.',
                ),
                _buildQuestionAnswer(
                  context,
                  'Como acesso o menu lateral?',
                  'No canto superior esquerdo da tela inicial há um ícone de menu (☰). Toque nele para abrir o sidebar, onde você pode acessar:\n\n'
                  '• Configurações da sua conta\n'
                  '• Configuração de serviços\n'
                  '• Configuração de campos\n'
                  '• Sair da conta',
                ),
              ],
            ),
            _buildSection(
              context,
              '👥 Lista de Clientes',
              [
                _buildQuestionAnswer(
                  context,
                  'Como visualizar meus clientes?',
                  'Acesse a aba "Clientes" na barra de navegação inferior. Você verá uma lista completa de todos os seus clientes cadastrados, com informações como nome, status de pagamento e outras informações relevantes.',
                ),
                _buildQuestionAnswer(
                  context,
                  'Como buscar um cliente?',
                  'Na tela de lista de clientes, há um campo de busca no topo. Digite o nome ou endereço do cliente. A busca funciona mesmo sem acentos e mostra os resultados em tempo real conforme você digita.',
                ),
                _buildQuestionAnswer(
                  context,
                  'Como cadastrar um novo cliente?',
                  '1. Acesse a aba "Clientes"\n'
                  '2. Toque no botão "+" (flutuante) no canto inferior direito\n'
                  '3. Preencha os dados do cliente\n'
                  '4. Para modo Recorrentes: defina o valor mensal ou selecione um plano existente\n'
                  '5. Para modo Únicos: você pode agendar serviços após o cadastro\n'
                  '6. Toque em "Salvar"',
                ),
                _buildQuestionAnswer(
                  context,
                  'Como editar dados de um cliente?',
                  '1. Na lista de clientes, toque no cliente desejado\n'
                  '2. Na tela de detalhes, toque no ícone de lápis (editar)\n'
                  '3. Faça as alterações necessárias\n'
                  '4. Para modo Recorrentes: você pode alterar o plano vinculado ao cliente\n'
                  '5. Toque em "Salvar" para confirmar',
                ),
                _buildQuestionAnswer(
                  context,
                  'Como marcar pagamento de um cliente?',
                  '**Modo Recorrentes:**\n'
                  '1. Toque no cliente na lista\n'
                  '2. Na tela de detalhes, selecione o período desejado\n'
                  '   • Se o cliente tiver um plano, o sistema calcula automaticamente os períodos baseado na frequência do plano\n'
                  '   • Se não tiver plano, os períodos são mensais (mês/ano)\n'
                  '3. Toque em "Marcar como Pago"\n'
                  '4. Você também pode marcar múltiplos períodos de uma vez\n\n'
                  '**Modo Únicos:**\n'
                  '1. Toque no serviço específico na lista de serviços do cliente\n'
                  '2. Toque em "Marcar como Pago"\n'
                  '3. Confirme a ação',
                ),
              ],
            ),
            _buildSection(
              context,
              '⚙️ Configuração de Serviços',
              [
                _buildQuestionAnswer(
                  context,
                  'O que é a configuração de serviços?',
                  'A configuração de serviços permite que você defina os tipos de serviços que você oferece e os valores de cada um. Por exemplo: "Corte de Cabelo - R\$ 50,00", "Manicure - R\$ 30,00", etc.\n\n'
                  '**Importante**: Esta configuração é essencial para o modo Únicos, onde os serviços são agendados individualmente.',
                ),
                _buildQuestionAnswer(
                  context,
                  'Como configurar meus serviços?',
                  '1. Abra o menu lateral (☰) na tela inicial\n'
                  '2. Toque em "Serviços"\n'
                  '3. Toque no botão "+" para adicionar um novo tipo de serviço\n'
                  '4. Digite o nome do serviço (ex: "Corte de Cabelo")\n'
                  '5. Digite o valor (ex: 50.00)\n'
                  '6. Toque em "Salvar"\n'
                  '7. Repita o processo para cada tipo de serviço',
                ),
                _buildQuestionAnswer(
                  context,
                  'Posso editar ou excluir um serviço?',
                  'Sim! Na tela de configuração de serviços, você pode:\n\n'
                  '• **Editar**: Toque no serviço desejado e modifique o nome ou valor\n'
                  '• **Excluir**: Toque no serviço e depois no ícone de lixeira\n\n'
                  '**Atenção**: Ao excluir um serviço, ele será removido da lista, mas serviços já cadastrados que usam esse tipo não serão afetados.',
                ),
                _buildQuestionAnswer(
                  context,
                  'Por que preciso configurar serviços?',
                  'Configurar os tipos de serviços é essencial porque:\n\n'
                  '• Permite selecionar rapidamente o tipo ao agendar um serviço\n'
                  '• O valor é preenchido automaticamente\n'
                  '• Facilita a geração de relatórios por tipo de serviço\n'
                  '• Para modo Únicos: os serviços aparecem como opções no formulário web\n'
                  '• Permite análise de quais serviços são mais solicitados',
                ),
              ],
            ),
            _buildSection(
              context,
              '💳 Planos (Modo Recorrentes)',
              [
                _buildQuestionAnswer(
                  context,
                  'O que são planos?',
                  'Planos são configurações de valores e frequências de pagamento que você pode criar e associar aos seus clientes recorrentes. Eles permitem gerenciar clientes com diferentes periodicidades de pagamento (mensal, quinzenal, semanal, etc.) de forma organizada.',
                ),
                _buildQuestionAnswer(
                  context,
                  'Como criar um plano?',
                  '1. Abra o menu lateral (☰) na tela inicial\n'
                  '2. Toque em "Planos"\n'
                  '3. Toque no botão "+" (flutuante) no canto inferior direito\n'
                  '4. Preencha os dados:\n'
                  '   • Nome do plano (ex: "Plano Básico")\n'
                  '   • Valor do plano\n'
                  '   • Frequência (mensal, quinzenal, semanal, etc.)\n'
                  '   • Descrição (opcional)\n'
                  '5. Toque em "Salvar"',
                ),
                _buildQuestionAnswer(
                  context,
                  'Como associar um plano a um cliente?',
                  '1. Ao cadastrar ou editar um cliente recorrente\n'
                  '2. Selecione um plano na lista de planos disponíveis\n'
                  '3. O valor será preenchido automaticamente com o valor do plano\n'
                  '4. O sistema calculará automaticamente os períodos de pagamento baseado na frequência do plano',
                ),
                _buildQuestionAnswer(
                  context,
                  'Como funciona a frequência dos planos?',
                  'A frequência do plano define com que periodicidade o cliente deve pagar:\n\n'
                  '• **Mensal**: Pagamento uma vez por mês\n'
                  '• **Quinzenal**: Pagamento a cada 15 dias\n'
                  '• **Semanal**: Pagamento uma vez por semana\n'
                  '• **Outras frequências**: O sistema calcula automaticamente os períodos\n\n'
                  'O sistema calcula automaticamente os períodos de pagamento baseado na data de cadastro do cliente e na frequência do plano.',
                ),
                _buildQuestionAnswer(
                  context,
                  'Posso editar ou excluir um plano?',
                  'Sim! Na tela de planos:\n\n'
                  '• **Editar**: Toque no ícone de lápis no plano desejado\n'
                  '• **Desativar**: Toque no ícone de pausa para desativar temporariamente (planos desativados ficam em uma seção separada)\n'
                  '• **Ativar**: Planos desativados podem ser reativados\n'
                  '• **Excluir**: Apenas planos desativados podem ser excluídos permanentemente\n\n'
                  '**Atenção**: Ao editar um plano, os clientes que já estão vinculados a ele não terão seus valores alterados automaticamente. Você precisará atualizar manualmente cada cliente se desejar.',
                ),
                _buildQuestionAnswer(
                  context,
                  'O que acontece se eu excluir um plano?',
                  'Ao excluir um plano:\n\n'
                  '• O plano é removido permanentemente\n'
                  '• Clientes que estavam vinculados ao plano continuam com o valor que tinham, mas perdem a vinculação com o plano\n'
                  '• O histórico de pagamentos dos clientes é mantido\n\n'
                  '**Dica**: Considere desativar o plano ao invés de excluí-lo, para manter o histórico organizado.',
                ),
              ],
            ),
            _buildSection(
              context,
              '🔧 Configuração de Campos',
              [
                _buildQuestionAnswer(
                  context,
                  'O que é a configuração de campos?',
                  'A configuração de campos permite personalizar quais informações você coleta ao cadastrar clientes. Você pode habilitar ou desabilitar campos padrão (como endereço, telefone, etc.) e também adicionar campos personalizados específicos do seu negócio.',
                ),
                _buildQuestionAnswer(
                  context,
                  'Como configurar os campos?',
                  '1. Abra o menu lateral (☰)\n'
                  '2. Toque em "Campos"\n'
                  '3. Você verá uma lista de campos padrão com interruptores\n'
                  '4. Ative ou desative os campos conforme sua necessidade\n'
                  '5. Para adicionar campos personalizados, role até o final e toque em "Adicionar Campo Personalizado"\n'
                  '6. Digite o nome do campo e escolha o tipo (texto, número, data, etc.)\n'
                  '7. Toque em "Salvar"',
                ),
                _buildQuestionAnswer(
                  context,
                  'O que são campos personalizados?',
                  'Campos personalizados são campos adicionais que você cria para coletar informações específicas do seu negócio. Por exemplo:\n\n'
                  '• "Cor preferida" (para salões)\n'
                  '• "Tipo de propriedade" (para empresas de vigilância)\n'
                  '• "Observações especiais"\n'
                  '• Qualquer outra informação relevante para você',
                ),
                _buildQuestionAnswer(
                  context,
                  'Os campos configurados afetam o formulário web?',
                  'Sim! Os campos que você habilitar na configuração aparecerão no formulário web que seus clientes usam para agendar serviços. Isso garante que você receba todas as informações necessárias diretamente do cliente.',
                ),
              ],
            ),
            _buildSection(
              context,
              '📋 Formulário Web',
              [
                _buildQuestionAnswer(
                  context,
                  'O que é o formulário web?',
                  'O formulário web é um link que você pode compartilhar com seus clientes. Eles acessam esse link, preenchem suas informações e agendam um serviço. O agendamento aparece automaticamente no seu aplicativo.',
                ),
                _buildQuestionAnswer(
                  context,
                  'Como gerar o link do formulário?',
                  '1. Certifique-se de estar no modo Únicos\n'
                  '2. Na tela inicial, role até a seção "Próximos Serviços"\n'
                  '3. Toque no botão "Gerar e copiar link do formulário"\n'
                  '4. O link será copiado automaticamente para sua área de transferência\n'
                  '5. Compartilhe esse link por WhatsApp, email, ou qualquer outro meio',
                ),
                _buildQuestionAnswer(
                  context,
                  'Por que não consigo gerar o link?',
                  'Para gerar o link, você precisa ter configurado:\n\n'
                  '• Nome da empresa (em "Conta" > "Editar Perfil")\n'
                  '• Pelo menos um tipo de serviço (em "Serviços")\n'
                  '• Configuração de campos (em "Campos")\n\n'
                  'Se algum desses itens estiver faltando, você verá um aviso com as ações pendentes.',
                ),
                _buildQuestionAnswer(
                  context,
                  'Como os clientes usam o formulário?',
                  '1. Cliente acessa o link que você compartilhou\n'
                  '2. Preenche seus dados pessoais\n'
                  '3. Seleciona o tipo de serviço desejado\n'
                  '4. Escolhe uma data e horário disponível\n'
                  '5. Envia o formulário\n'
                  '6. Você recebe o agendamento automaticamente no app',
                ),
                _buildQuestionAnswer(
                  context,
                  'Como vejo os agendamentos feitos pelo formulário?',
                  'Os agendamentos feitos pelo formulário web aparecem automaticamente:\n\n'
                  '• Na tela inicial, na seção "Próximos Serviços"\n'
                  '• Na aba "Agendamento" da barra de navegação\n'
                  '• Na lista de serviços do cliente específico',
                ),
              ],
            ),
            _buildSection(
              context,
              '📊 Relatórios',
              [
                _buildQuestionAnswer(
                  context,
                  'Quais relatórios estão disponíveis?',
                  'O Clisync oferece vários tipos de relatórios:\n\n'
                  '**Para ambos os modos:**\n'
                  '• **Fechamento do Mês**: Visão completa do mês com estatísticas financeiras e métricas\n'
                  '• **Pendências**: Lista de clientes ou serviços não pagos\n'
                  '• **Evolução Patrimonial**: Gráfico mostrando a evolução financeira ao longo do tempo\n\n'
                  '**Apenas para Modo Recorrentes:**\n'
                  '• **Relatório dos Planos**: Análise detalhada de todos os planos cadastrados\n\n'
                  '**Apenas para Modo Únicos:**\n'
                  '• **Serviços Mensais**: Gráficos de crescimento mensal e análise por tipo de serviço\n'
                  '• **Ranking de Clientes**: Lista dos clientes que mais utilizam seus serviços',
                ),
                _buildQuestionAnswer(
                  context,
                  'Como gerar um relatório mensal?',
                  '1. Acesse a aba "Relatórios"\n'
                  '2. Selecione "Fechamento do Mês"\n'
                  '3. Escolha o mês e ano desejado\n'
                  '4. Visualize todas as estatísticas do período\n'
                  '5. Para modo Únicos: visualize gráficos interativos de serviços por tipo e picos de movimento',
                ),
                _buildQuestionAnswer(
                  context,
                  'O que encontro no relatório mensal?',
                  'O relatório mensal mostra:\n\n'
                  '**Modo Recorrentes:**\n'
                  '• Valor total esperado\n'
                  '• Valor recebido\n'
                  '• Valor pendente\n'
                  '• Número de clientes ativos\n'
                  '• Novos clientes do mês\n'
                  '• Análise de adimplência\n\n'
                  '**Modo Únicos:**\n'
                  '• Total de serviços realizados\n'
                  '• Valor total faturado\n'
                  '• Valor recebido e pendente\n'
                  '• Novos clientes\n'
                  '• Gráficos interativos de serviços por tipo\n'
                  '• Gráficos de picos de movimento (dias da semana e horários)',
                ),
                _buildQuestionAnswer(
                  context,
                  'Como visualizar pendências?',
                  '1. Acesse a aba "Relatórios"\n'
                  '2. Toque em "Pendências"\n'
                  '3. Visualize todos os serviços não pagos\n'
                  '4. Use o filtro para ver um mês específico\n'
                  '5. Toque em um item para marcar como pago\n'
                  '6. Use a busca para encontrar um cliente específico\n\n'
                  '**Modo Recorrentes:** Pendências são agrupadas por mês/ano\n'
                  '**Modo Únicos:** Cada serviço pendente aparece individualmente, mesmo para o mesmo cliente',
                ),
                _buildQuestionAnswer(
                  context,
                  'O que é a evolução patrimonial?',
                  'A evolução patrimonial é um gráfico que mostra como seu faturamento evoluiu ao longo dos meses. É uma forma visual de acompanhar o crescimento do seu negócio e identificar tendências. Disponível para ambos os modos (Recorrentes e Únicos).',
                ),
                _buildQuestionAnswer(
                  context,
                  'O que é o relatório de serviços mensais? (Modo Únicos)',
                  'O relatório de serviços mensais mostra:\n\n'
                  '• Gráfico de crescimento mensal dos últimos 6 meses\n'
                  '• Análise de serviços por tipo de serviço\n'
                  '• Comparação entre meses\n'
                  '• Identificação de tendências de crescimento\n\n'
                  'Acesse: Relatórios > Serviços Mensais',
                ),
                _buildQuestionAnswer(
                  context,
                  'O que é o ranking de clientes? (Modo Únicos)',
                  'O ranking de clientes mostra quais clientes mais utilizam seus serviços:\n\n'
                  '• Pódio com os 3 primeiros colocados (ouro, prata, bronze)\n'
                  '• Lista completa ordenada por quantidade de serviços\n'
                  '• Possibilidade de tocar no cliente para ver seus detalhes\n'
                  '• Contagem apenas de serviços válidos (exclui cancelados)\n\n'
                  'Acesse: Relatórios > Ranking de Clientes',
                ),
                _buildQuestionAnswer(
                  context,
                  'O que é o relatório dos planos? (Modo Recorrentes)',
                  'O relatório dos planos oferece uma análise completa de todos os planos cadastrados:\n\n'
                  '• Estatísticas por plano (quantidade de clientes, valores)\n'
                  '• Análise de adimplência por plano\n'
                  '• Comparação entre diferentes planos\n'
                  '• Identificação de planos mais populares\n\n'
                  'Acesse: Relatórios > Relatório dos Planos',
                ),
              ],
            ),
            _buildSection(
              context,
              '⚙️ Configurações da Conta',
              [
                _buildQuestionAnswer(
                  context,
                  'Como editar meus dados?',
                  '1. Abra o menu lateral (☰)\n'
                  '2. Toque em "Conta"\n'
                  '3. Edite os campos desejados:\n'
                  '   • Nome\n'
                  '   • Email\n'
                  '   • Telefone (obrigatório)\n'
                  '   • Nome da empresa\n'
                  '   • Endereço\n'
                  '   • Chave PIX\n'
                  '   • Horário de atendimento\n'
                  '   • Tempo médio de serviço\n'
                  '4. Toque em "Salvar"',
                ),
                _buildQuestionAnswer(
                  context,
                  'Para que serve o horário de atendimento?',
                  'O horário de atendimento define em quais períodos você está disponível para receber agendamentos. No modo Únicos, esse horário é usado para gerar os horários disponíveis no formulário web e ao agendar serviços manualmente.',
                ),
                _buildQuestionAnswer(
                  context,
                  'O que é o tempo médio de serviço?',
                  'O tempo médio de serviço é o intervalo entre um agendamento e outro. Por exemplo, se você definir 1 hora, o sistema calculará os horários disponíveis respeitando esse intervalo, evitando sobreposições.',
                ),
                _buildQuestionAnswer(
                  context,
                  'Como alterar minha senha?',
                  '1. Na tela de login, toque em "Esqueci minha senha"\n'
                  '2. Digite seu email\n'
                  '3. Você receberá um email com instruções para redefinir a senha\n'
                  '4. Siga as instruções do email',
                ),
              ],
            ),
            _buildSection(
              context,
              '❓ Outras Dúvidas',
              [
                _buildQuestionAnswer(
                  context,
                  'Meus dados estão seguros?',
                  'Sim! O Clisync utiliza Firebase (Google) para armazenar seus dados com segurança. Todas as informações são criptografadas e apenas você tem acesso aos seus dados através do seu login.',
                ),
                _buildQuestionAnswer(
                  context,
                  'Preciso de internet para usar o app?',
                  'Sim, o Clisync precisa de conexão com a internet para funcionar, pois seus dados são armazenados na nuvem. Isso garante que você possa acessar suas informações de qualquer dispositivo.',
                ),
                _buildQuestionAnswer(
                  context,
                  'Posso usar em mais de um dispositivo?',
                  'Sim! Como seus dados estão na nuvem, você pode fazer login em qualquer dispositivo e terá acesso a todas as suas informações sincronizadas.',
                ),
                _buildQuestionAnswer(
                  context,
                  'O que acontece se eu excluir um cliente?',
                  'Ao excluir um cliente, todas as informações relacionadas a ele serão removidas permanentemente, incluindo histórico de pagamentos e serviços. Esta ação não pode ser desfeita.',
                ),
                _buildQuestionAnswer(
                  context,
                  'Como desativar um cliente sem excluí-lo?',
                  '**Modo Recorrentes:**\n'
                  'Na tela de detalhes do cliente, há uma opção para ativar/desativar. Um cliente desativado não aparece nos relatórios ativos, mas seus dados são mantidos. Você pode reativá-lo a qualquer momento.\n\n'
                  '**Modo Únicos:**\n'
                  'Você pode excluir serviços específicos sem excluir o cliente. O cliente permanece no sistema com seu histórico. Serviços cancelados não aparecem no ranking de clientes.',
                ),
              ],
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title, List<Widget> children) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          ...children,
        ],
      ),
    );
  }

  Widget _buildQuestionAnswer(BuildContext context, String question, String answer) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent,
        ),
        child: ExpansionTile(
          title: Text(
            question,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color.fromARGB(255, 216, 216, 216),
            ),
          ),
          iconColor: AppTheme.accentColor,
          collapsedIconColor: Colors.white70,
          backgroundColor: Colors.transparent,
          collapsedBackgroundColor: Colors.transparent,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
          collapsedShape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          childrenPadding: EdgeInsets.zero,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16.0, 0.0, 16.0, 16.0),
              child: Text(
                answer,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.6,
                  color: Colors.white.withOpacity(0.9),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

