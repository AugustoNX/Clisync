<?php
$config = include("/home/u839614019/domains/clisync.com.br/firebase_config/config.php");

$idUsuario = $_GET['id'] ?? null;
if (!$idUsuario || strlen(trim($idUsuario)) < 1) {
    die("ID do usuário inválido.");
}

// Campos obrigatórios
$nomeRaw = trim($_POST['nome'] ?? '');
$telefoneRaw = trim($_POST['telefone'] ?? '');
$tipoServico = trim($_POST['tipo_servico'] ?? '');
$dataServicoRaw = $_POST['data_servico'] ?? '';
$horarioServico = $_POST['horario_servico'] ?? '';

if (!$nomeRaw || !$telefoneRaw || !$tipoServico || !$dataServicoRaw || !$horarioServico) {
    die("Preencha todos os campos obrigatórios.");
}

// Campos opcionais padrão
$bairro = trim($_POST['bairro'] ?? '');
$cidade = trim($_POST['cidade'] ?? '');
$rua = trim($_POST['rua'] ?? '');
$numero = trim($_POST['numero'] ?? '');
$frequencia = trim($_POST['frequencia'] ?? '');
$prioridade = trim($_POST['prioridade'] ?? '');
$dataVencimento = trim($_POST['dataVencimento'] ?? '');

// Campos personalizados
$camposPersonalizados = [];
if (isset($_POST['camposPersonalizados']) && is_array($_POST['camposPersonalizados'])) {
    foreach ($_POST['camposPersonalizados'] as $chave => $valor) {
        $chaveLimpa = trim($chave);
        $valorLimpo = trim($valor);
        if ($chaveLimpa && $valorLimpo) {
            $camposPersonalizados[$chaveLimpa] = $valorLimpo;
        }
    }
}

$dataServicoFormatada = date("d-m-Y", strtotime($dataServicoRaw));
$dataDisplay = date("d/m/y", strtotime($dataServicoRaw));
$timestamp = round(microtime(true) * 1000);

function normalize_name($s) {
    $s = trim(mb_strtolower($s, 'UTF-8'));
    $s = iconv('UTF-8', 'ASCII//TRANSLIT//IGNORE', $s);
    $s = preg_replace('/\s+/', ' ', $s);
    return $s;
}

function normalize_phone_remove55($p) {
    $digits = preg_replace('/\D+/', '', $p);
    if (strpos($digits, '55') === 0) {
        $digits = substr($digits, 2);
    }
    $digits = ltrim($digits, '0');
    return $digits;
}

$nome = normalize_name($nomeRaw);
$telefone = normalize_phone_remove55($telefoneRaw);

// Busca o valor do serviço selecionado
$urlServicos = $config["database_url"] . "/usuarios/$idUsuario/servicosUnicos.json?auth=" . $config["secret"];
$servicosJson = @file_get_contents($urlServicos);
$servicos = json_decode($servicosJson, true);
$valorServico = isset($servicos[$tipoServico]) ? (float)$servicos[$tipoServico] : 0;

$urlClientes = $config["database_url"] . "/usuarios/$idUsuario/clientes_unicos.json?auth=" . $config["secret"];

$clientesJson = @file_get_contents($urlClientes);
$clientes = json_decode($clientesJson, true);

$idClienteExistente = null;

if ($clientes && is_array($clientes)) {
    foreach ($clientes as $idCli => $dadosCli) {
        $telBancoRaw = $dadosCli['telefone'] ?? '';
        $telBanco = normalize_phone_remove55($telBancoRaw);

        if ($telBanco === $telefone) {
            $idClienteExistente = $idCli;
            break;
        }
    }
}

$novoServico = [
    $dataServicoFormatada => [
        "horario" => $horarioServico,
        "statusPagamento" => "agendado",
        "tipoServico" => $tipoServico,
        "valor" => $valorServico
    ]
];

if ($idClienteExistente) {
    // Adiciona o novo serviço ao histórico
    $urlAddServico = $config["database_url"]
        . "/usuarios/$idUsuario/clientes_unicos/$idClienteExistente/historicoServicos.json?auth=" . $config["secret"];

    $ch = curl_init($urlAddServico);
    curl_setopt($ch, CURLOPT_CUSTOMREQUEST, "PATCH");
    curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($novoServico));
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
    $result = curl_exec($ch);
    curl_close($ch);

    // Atualiza os dados do cliente existente se houver novos campos
    $dadosAtualizacao = [];
    
    if ($bairro) $dadosAtualizacao["bairro"] = $bairro;
    if ($cidade) $dadosAtualizacao["cidade"] = $cidade;
    if ($rua) $dadosAtualizacao["rua"] = $rua;
    if ($numero) $dadosAtualizacao["numero"] = $numero;
    if ($frequencia) $dadosAtualizacao["frequencia"] = $frequencia;
    if ($prioridade) $dadosAtualizacao["prioridade"] = $prioridade;
    if ($dataVencimento) $dadosAtualizacao["dataVencimento"] = $dataVencimento;
    
    // Atualiza campos personalizados
    if (!empty($camposPersonalizados)) {
        // Busca campos personalizados existentes
        $urlCliente = $config["database_url"]
            . "/usuarios/$idUsuario/clientes_unicos/$idClienteExistente.json?auth=" . $config["secret"];
        $clienteJson = @file_get_contents($urlCliente);
        $clienteExistente = json_decode($clienteJson, true);
        
        $camposPersonalizadosExistentes = [];
        if (isset($clienteExistente['camposPersonalizados']) && is_array($clienteExistente['camposPersonalizados'])) {
            $camposPersonalizadosExistentes = $clienteExistente['camposPersonalizados'];
        }
        
        // Mescla campos personalizados novos com existentes
        $camposPersonalizadosExistentes = array_merge($camposPersonalizadosExistentes, $camposPersonalizados);
        $dadosAtualizacao["camposPersonalizados"] = $camposPersonalizadosExistentes;
    }
    
    // Atualiza o cliente se houver dados para atualizar
    if (!empty($dadosAtualizacao)) {
        $urlAtualizarCliente = $config["database_url"]
            . "/usuarios/$idUsuario/clientes_unicos/$idClienteExistente.json?auth=" . $config["secret"];
        
        $ch = curl_init($urlAtualizarCliente);
        curl_setopt($ch, CURLOPT_CUSTOMREQUEST, "PATCH");
        curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($dadosAtualizacao));
        curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
        $result = curl_exec($ch);
        curl_close($ch);
    }

    $q = http_build_query([
        'nome' => $nomeRaw,
        'data' => $dataDisplay,
        'hora' => $horarioServico,
        'id' => $idUsuario
    ]);
    header("Location: sucesso.php?$q");
    exit();
}

$idUnico = str_replace('.', '_', uniqid("cli_", true));

// Monta os dados do novo cliente seguindo a estrutura do banco
$dadosNovoCliente = [
    "bairro" => $bairro,
    "cidade" => $cidade,
    "dataCadastro" => $timestamp,
    "nome" => $nomeRaw,
    "numero" => $numero,
    "rua" => $rua,
    "status" => "ativo",
    "telefone" => $telefoneRaw,
    "valor" => 0,
    "historicoServicos" => [
        $dataServicoFormatada => [
            "horario" => $horarioServico,
            "statusPagamento" => "agendado",
            "tipoServico" => $tipoServico,
            "valor" => $valorServico
        ]
    ]
];

// Adiciona campos opcionais apenas se preenchidos
if ($frequencia) {
    $dadosNovoCliente["frequencia"] = $frequencia;
}
if ($prioridade) {
    $dadosNovoCliente["prioridade"] = $prioridade;
}
if ($dataVencimento) {
    $dadosNovoCliente["dataVencimento"] = $dataVencimento;
}

// Adiciona campos personalizados se houver
if (!empty($camposPersonalizados)) {
    $dadosNovoCliente["camposPersonalizados"] = $camposPersonalizados;
}

$urlNovoCliente = $config["database_url"]
    . "/usuarios/$idUsuario/clientes_unicos/$idUnico.json?auth=" . $config["secret"];

$ch = curl_init($urlNovoCliente);
curl_setopt($ch, CURLOPT_CUSTOMREQUEST, "PUT");
curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($dadosNovoCliente));
curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
$result = curl_exec($ch);
curl_close($ch);

// Redireciona para a página de sucesso com os dados informados
$q = http_build_query([
    'nome' => $nomeRaw,
    'data' => $dataDisplay,
    'hora' => $horarioServico,
    'id' => $idUsuario
]);
header("Location: sucesso.php?$q");
exit();
