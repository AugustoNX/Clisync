<?php
// Carrega configuração
$config = include("/home/u839614019/domains/clisync.com.br/firebase_config/config.php");

// Obtém o ID do usuário
$idUsuario = $_GET['id'] ?? null;

// Busca o telefone do usuário (empresa) do banco de dados
$telefoneEmpresa = '';
if ($idUsuario) {
    $urlTelefone = $config["database_url"] . "/usuarios/$idUsuario/telefone.json?auth=" . $config["secret"];
    $telefoneJson = @file_get_contents($urlTelefone);
    $telefoneEmpresa = $telefoneJson ? htmlspecialchars(trim($telefoneJson, '"')) : '';
}

$mensagem = "olá me chamo $nome. Tenho um agendamento marcado para o dia $data às $hora, gostaria de mais informações!";
$mensagem = urlencode($mensagem);

$url = "https://wa.me/$telefoneEmpresa?text=$mensagem";

?>
<!DOCTYPE html>
<html lang="pt-BR">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Clisync | Agendamento realizado</title>
    <link rel="stylesheet" href="style.css">
    <meta name="robots" content="noindex nofollow">
    <link rel="icon" href="https://clisync.com.br/images/logo-clisync.png" sizes="48x48">
</head>
<body>
    <div class="page-wrapper">
        <header class="header">
            <img src="logo-completa-clisync.png" alt="Logo Clisync">
        </header>

        <main class="content">
            <?php
            $nome = $_GET['nome'] ?? '';
            $data = $_GET['data'] ?? '';
            $hora = $_GET['hora'] ?? '';
            ?>
            <section class="card alert-card">
                <h1>Agendamento realizado com sucesso</h1>
                <?php if ($nome && $data && $hora): ?>
                    <p>Olá <strong><?= htmlspecialchars($nome) ?></strong>, seu agendamento no dia <strong><?= htmlspecialchars($data) ?></strong> às <strong><?= htmlspecialchars($hora) ?></strong> foi realizado com sucesso.</p>
                <?php else: ?>
                    <p>Recebemos suas informações. Em breve a equipe entrará em contato para confirmar os detalhes.</p>
                <?php endif; ?>
                <?php if ($telefoneEmpresa): ?>
                    <p style="margin-top: 16px;">Para mais detalhes sobre seu serviço entre em contato com: <a href="https://wa.me/$telefoneEmpresa?text=ol%C3%A1%20me%20chamo%20$nome.%20Tenho%20um%20agendamento%20marcado%20para%20o%20dia%20$data%20%C3%A0s%20$hora,%20gostaria%20de%20mais%20informa%C3%A7%C3%B5es!"><strong><?= $telefoneEmpresa ?></strong></a></p>
                <?php endif; ?>
            </section>
        </main>

        <footer class="footer">
            <small>&copy; <?= date('Y'); ?> Clisync. Todos os direitos reservados.</small>
        </footer>
    </div>
</body>
</html>