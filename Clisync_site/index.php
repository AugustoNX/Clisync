<?php
// Define constante para proteção dos arquivos includes
define('CLISYNC_INCLUDED', true);

// Carrega configuração
$config = include("/home/u839614019/domains/clisync.com.br/firebase_config/config.php");

// Carrega funções auxiliares
require_once __DIR__ . '/includes/funcoes.php';
require_once __DIR__ . '/includes/dados_usuario.php';

// Valida ID do usuário
$idUsuario = $_GET['id'] ?? null;

if (!validarIdUsuario($idUsuario)) {
    die("Usuário inválido.");
}

// Busca todos os dados do usuário
$dadosUsuario = buscarDadosUsuario($idUsuario, $config);

// Extrai variáveis para facilitar uso no template
$nomeEmpresa = $dadosUsuario['nomeEmpresa'];
$servicos = $dadosUsuario['servicos'];
$horarioInicio = $dadosUsuario['horarioInicio'];
$horarioFim = $dadosUsuario['horarioFim'];
$tempoServico = $dadosUsuario['tempoServico'];
$camposAtivos = $dadosUsuario['camposAtivos'];
$camposPersonalizados = $dadosUsuario['camposPersonalizados'];

// Obtém mapeamento de campos
$mapeamentoCampos = obterMapeamentoCampos();
?>

<!DOCTYPE html>
<html lang="pt-BR">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Clisync | Cadastro de serviço</title>
    <link rel="stylesheet" href="style.css">
    <meta name="robots" content="noindex, nofollow">
    <link rel="icon" href="https://clisync.com.br/images/logo-clisync.png" sizes="48x48">
    <script async src="https://pagead2.googlesyndication.com/pagead/js/adsbygoogle.js?client=ca-pub-9090801296043819"
     crossorigin="anonymous"></script>
</head>
<body>
    <div class="page-wrapper">
        <header class="header">
            <img src="logo-completa-clisync.png" alt="Logo Clisync">
        </header>

        <main class="content">
            <?php
            $id = $_GET['id'] ?? null;
            if (!$id):
            ?>
                <section class="card alert-card">
                    <h1>Formulario inválido</h1>
                    <p>Não encontramos o link de agendamento. Solicite à empresa o envio correto para continuar.</p>
                </section>
            <?php else: ?>
                <section class="card">
                    <div class="card-header">
                        <h1>Solicitar serviço para a empresa: <?= $nomeEmpresa ?></h1>
                        <p>Informe os dados abaixo para agendar o atendimento.</p>
                    </div>
                    <form action="salvar.php?id=<?= htmlspecialchars($id) ?>" method="POST" class="form">
                        <?php
                        // Renderiza campos padrão que estão ativos na configuração
                        foreach ($mapeamentoCampos as $labelConfig => $configCampo) {
                            if (isset($camposAtivos[$labelConfig])) {
                                renderizarCampo($configCampo, $labelConfig);
                            }
                        }
                        
                        // Renderiza campos personalizados
                        foreach ($camposPersonalizados as $campoPersonalizado => $ativo) {
                            if ($ativo) {
                                echo "<div class=\"field-group\">";
                                echo "<label for=\"campo_personalizado_" . htmlspecialchars($campoPersonalizado) . "\">" . htmlspecialchars($campoPersonalizado) . "</label>";
                                echo "<input type=\"text\" id=\"campo_personalizado_" . htmlspecialchars($campoPersonalizado) . "\" name=\"camposPersonalizados[" . htmlspecialchars($campoPersonalizado) . "]\" placeholder=\"Digite " . htmlspecialchars(strtolower($campoPersonalizado)) . "\">";
                                echo "</div>";
                            }
                        }
                        ?>

                        <div class="field-group">
                            <label for="tipo_servico">Tipo de serviço</label>
                            <select id="tipo_servico" name="tipo_servico" required>
                                <option value="">Selecione um serviço</option>
                                <?php foreach ($servicos as $nomeServico => $valor): ?>
                                    <option value="<?= htmlspecialchars($nomeServico) ?>">
                                        <?= htmlspecialchars($nomeServico) ?> - R$ <?= number_format($valor, 2, ',', '.') ?>
                                    </option>
                                <?php endforeach; ?>
                            </select>
                        </div>

                        <!-- Data e Horário do serviço são sempre obrigatórios para o agendamento -->
                        <div class="field-group">
                            <label for="data_servico">Data do serviço</label>
                            <input type="date" id="data_servico" name="data_servico" required min="<?= date('Y-m-d') ?>">
                        </div>

                        <div class="field-group">
                            <label for="horario_servico">Horário do serviço</label>
                            <select id="horario_servico" name="horario_servico" required disabled>
                                <option value="">Selecione primeiro a data do serviço</option>
                            </select>
                        </div>

                        <div class="g-recaptcha" data-sitekey="6LfAHA4sAAAAALxOHfxI43xZfvIDGpJAzelXMtdh" data-callback="onRecaptchaSuccess" data-expired-callback="onRecaptchaExpired"></div>
                        <button type="submit" class="btn-primary" id="btn-submit" disabled>Enviar</button>
                    </form>
                </section>
            <?php endif; ?>
        </main>

        <footer class="footer">
            <small>&copy; <?= date('Y'); ?> Clisync. Todos os direitos reservados.</small>
        </footer>
    </div>
</body>
</html>
<script src="https://www.google.com/recaptcha/api.js" async defer></script>
<script>
    // Validação do campo de telefone - só aceita números e não aceita espaços
    const telefoneInput = document.getElementById('telefone');
    if (telefoneInput) {
        telefoneInput.addEventListener('input', function(e) {
            // Remove tudo que não é número
            this.value = this.value.replace(/\D/g, '');
        });
        
        telefoneInput.addEventListener('keypress', function(e) {
            // Permite apenas números
            const char = String.fromCharCode(e.which);
            if (!/[0-9]/.test(char)) {
                e.preventDefault();
            }
        });
        
        telefoneInput.addEventListener('paste', function(e) {
            e.preventDefault();
            const paste = (e.clipboardData || window.clipboardData).getData('text');
            // Remove tudo que não é número
            this.value = paste.replace(/\D/g, '');
        });
    }
    
    // Validação do campo de data - não pode ser menor que o dia atual
    const dataServicoInput = document.getElementById('data_servico');
    const horarioServicoSelect = document.getElementById('horario_servico');
    
    // Dados do usuário para gerar horários
    const horarioInicio = <?= $horarioInicio ? "'" . htmlspecialchars($horarioInicio) . "'" : 'null' ?>;
    const horarioFim = <?= $horarioFim ? "'" . htmlspecialchars($horarioFim) . "'" : 'null' ?>;
    const tempoServico = <?= $tempoServico ?>;
    const idUsuario = '<?= htmlspecialchars($idUsuario) ?>';
    
    if (dataServicoInput) {
        // Define a data mínima como hoje
        const hoje = new Date().toISOString().split('T')[0];
        dataServicoInput.setAttribute('min', hoje);
        
        dataServicoInput.addEventListener('change', function(e) {
            const dataSelecionada = new Date(this.value);
            const dataAtual = new Date();
            dataAtual.setHours(0, 0, 0, 0);
            
            if (dataSelecionada < dataAtual) {
                alert('A data do serviço não pode ser anterior à data atual.');
                this.value = hoje;
                return;
            }
            
            // Atualiza horários disponíveis quando a data muda
            atualizarHorariosDisponiveis(this.value);
        });
    }
    
    // Função para gerar horários disponíveis
    async function atualizarHorariosDisponiveis(dataSelecionada) {
        if (!horarioServicoSelect) {
            return;
        }
        
        if (!horarioInicio || !horarioFim) {
            horarioServicoSelect.innerHTML = '<option value="">Configure os horários de atendimento no perfil</option>';
            horarioServicoSelect.disabled = true;
            return;
        }
        
        // Limpa o select
        horarioServicoSelect.innerHTML = '<option value="">Carregando horários...</option>';
        horarioServicoSelect.disabled = true;
        
        try {
            // Busca horários ocupados na data selecionada
            const horariosOcupados = await buscarHorariosOcupados(dataSelecionada);
            
            // Gera todos os horários possíveis
            const todosHorarios = gerarHorarios(horarioInicio, horarioFim, tempoServico);
            
            // Filtra horários ocupados
            const horariosDisponiveis = todosHorarios.filter(horario => {
                return !horariosOcupados.includes(horario);
            });
            
            // Atualiza o select
            horarioServicoSelect.innerHTML = '';
            if (horariosDisponiveis.length === 0) {
                horarioServicoSelect.innerHTML = '<option value="">Nenhum horário disponível para esta data</option>';
            } else {
                horarioServicoSelect.innerHTML = '<option value="">Selecione um horário</option>';
                horariosDisponiveis.forEach(horario => {
                    const option = document.createElement('option');
                    option.value = horario;
                    option.textContent = horario;
                    horarioServicoSelect.appendChild(option);
                });
            }
            horarioServicoSelect.disabled = false;
        } catch (error) {
            console.error('Erro ao carregar horários:', error);
            horarioServicoSelect.innerHTML = '<option value="">Erro ao carregar horários</option>';
            horarioServicoSelect.disabled = false;
        }
    }
    
    // Função para gerar horários baseados no tempoServico
    function gerarHorarios(inicio, fim, intervaloMinutos) {
        const horarios = [];
        
        // Converte horários para minutos
        const [inicioHora, inicioMinuto] = inicio.split(':').map(Number);
        const [fimHora, fimMinuto] = fim.split(':').map(Number);
        const inicioTotalMinutos = inicioHora * 60 + inicioMinuto;
        const fimTotalMinutos = fimHora * 60 + fimMinuto;
        
        // Gera horários com intervalo
        let minutosAtuais = inicioTotalMinutos;
        while (minutosAtuais <= fimTotalMinutos) {
            const hora = Math.floor(minutosAtuais / 60);
            const minuto = minutosAtuais % 60;
            const horarioFormatado = String(hora).padStart(2, '0') + ':' + String(minuto).padStart(2, '0');
            horarios.push(horarioFormatado);
            minutosAtuais += intervaloMinutos;
        }
        
        return horarios;
    }
    
    // Função para buscar horários ocupados
    async function buscarHorariosOcupados(dataSelecionada) {
        // Formata a data no formato usado no banco: "dd-MM-yyyy"
        const dataFormatada = formatarDataParaBanco(dataSelecionada);
        
        try {
            // Busca todos os clientes únicos
            const response = await fetch(`buscar_horarios_ocupados.php?id=${idUsuario}&data=${dataFormatada}`);
            const data = await response.json();
            
            if (data.success && Array.isArray(data.horarios)) {
                return data.horarios;
            }
            return [];
        } catch (error) {
            console.error('Erro ao buscar horários ocupados:', error);
            return [];
        }
    }
    
    // Função para formatar data para o formato do banco (dd-MM-yyyy)
    function formatarDataParaBanco(dataISO) {
        // dataISO vem no formato "YYYY-MM-DD"
        const partes = dataISO.split('-');
        if (partes.length === 3) {
            const ano = partes[0];
            const mes = partes[1];
            const dia = partes[2];
            return `${dia}-${mes}-${ano}`;
        }
        // Fallback: tenta parsear como Date
        const data = new Date(dataISO + 'T00:00:00');
        const dia = String(data.getDate()).padStart(2, '0');
        const mes = String(data.getMonth() + 1).padStart(2, '0');
        const ano = data.getFullYear();
        return `${dia}-${mes}-${ano}`;
    }
    
    // Validação do reCAPTCHA
    const form = document.querySelector('form');
    const btnSubmit = document.getElementById('btn-submit');
    let recaptchaCompleted = false;
    
    // Callback quando o reCAPTCHA é completado (chamado pelo atributo data-callback)
    window.onRecaptchaSuccess = function(response) {
        recaptchaCompleted = true;
        if (btnSubmit) {
            btnSubmit.disabled = false;
        }
    };
    
    // Callback quando o reCAPTCHA expira ou é resetado (chamado pelo atributo data-expired-callback)
    window.onRecaptchaExpired = function() {
        recaptchaCompleted = false;
        if (btnSubmit) {
            btnSubmit.disabled = true;
        }
    };
    
    // Validação no submit do formulário
    if (form) {
        form.addEventListener('submit', function(e) {
            // Primeira verificação: se a flag indica que foi completado
            if (!recaptchaCompleted) {
                e.preventDefault();
                alert('Por favor, complete o reCAPTCHA antes de enviar o formulário.');
                return false;
            }
            
            // Segunda verificação: valida se há resposta do reCAPTCHA através da API
            if (typeof grecaptcha !== 'undefined') {
                try {
                    // Obtém a resposta do reCAPTCHA (sem parâmetro retorna o primeiro widget)
                    const response = grecaptcha.getResponse();
                    
                    if (!response || response.length === 0) {
                        e.preventDefault();
                        alert('Por favor, complete o reCAPTCHA antes de enviar o formulário.');
                        recaptchaCompleted = false;
                        if (btnSubmit) {
                            btnSubmit.disabled = true;
                        }
                        return false;
                    }
                } catch (error) {
                    console.error('Erro ao verificar reCAPTCHA:', error);
                    e.preventDefault();
                    alert('Erro ao validar o reCAPTCHA. Por favor, tente novamente.');
                    return false;
                }
            } else {
                e.preventDefault();
                alert('O reCAPTCHA não foi carregado corretamente. Por favor, recarregue a página.');
                return false;
            }
        });
    }
</script>


