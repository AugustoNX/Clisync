<?php
/**
 * Arquivo responsável por buscar todos os dados do usuário do banco de dados
 * 
 * PROTEÇÃO: Este arquivo não deve ser acessado diretamente via URL
 */
if (!defined('CLISYNC_INCLUDED')) {
    http_response_code(403);
    die('Acesso negado.');
}

function buscarDadosUsuario($idUsuario, $config) {
    $dados = [
        'nomeEmpresa' => '',
        'servicos' => [],
        'horarioInicio' => null,
        'horarioFim' => null,
        'tempoServico' => 30, // Padrão 30 minutos se não configurado
        'camposAtivos' => [],
        'camposPersonalizados' => [],
    ];
    
    if (!$idUsuario) {
        return $dados;
    }
    
    // Busca nome da empresa
    $urlNomeEmpresa = $config["database_url"] . "/usuarios/$idUsuario/nomeEmpresa.json?auth=" . $config["secret"];
    $nomeEmpresaJson = @file_get_contents($urlNomeEmpresa);
    $nomeEmpresa = json_decode($nomeEmpresaJson, true);
    $dados['nomeEmpresa'] = $nomeEmpresa ? htmlspecialchars($nomeEmpresa) : '';
    
    // Busca os serviços únicos do usuário
    $urlServicos = $config["database_url"] . "/usuarios/$idUsuario/servicosUnicos.json?auth=" . $config["secret"];
    $servicosJson = @file_get_contents($urlServicos);
    $servicos = json_decode($servicosJson, true);
    $dados['servicos'] = $servicos && is_array($servicos) ? $servicos : [];
    
    // Busca horários de atendimento e tempoServico do usuário
    $urlUsuario = $config["database_url"] . "/usuarios/$idUsuario.json?auth=" . $config["secret"];
    $usuarioJson = @file_get_contents($urlUsuario);
    $usuario = json_decode($usuarioJson, true);
    
    if ($usuario && is_array($usuario)) {
        $dados['horarioInicio'] = $usuario['horarioInicio'] ?? null;
        $dados['horarioFim'] = $usuario['horarioFim'] ?? null;
        $dados['tempoServico'] = isset($usuario['tempoServico']) ? (int)$usuario['tempoServico'] : 30;
    }
    
    // Busca a configuração de campos dos clientes únicos
    $urlConfig = $config["database_url"] . "/usuarios/$idUsuario/configuracao_unicos.json?auth=" . $config["secret"];
    $configJson = @file_get_contents($urlConfig);
    $configuracao = json_decode($configJson, true);
    $configuracao = $configuracao && is_array($configuracao) ? $configuracao : [];
    
    // Extrai campos ativos e campos personalizados
    foreach ($configuracao as $chave => $valor) {
        if ($chave === 'camposPersonalizados' && is_array($valor)) {
            foreach ($valor as $campoPersonalizado => $ativo) {
                if ($ativo === true) {
                    $dados['camposPersonalizados'][$campoPersonalizado] = true;
                }
            }
        } elseif (is_bool($valor) && $valor === true) {
            $dados['camposAtivos'][$chave] = true;
        }
    }
    
    return $dados;
}
?>
