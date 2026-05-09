<?php
header('Content-Type: application/json');

$config = include("/home/u839614019/domains/clisync.com.br/firebase_config/config.php");

$idUsuario = $_GET['id'] ?? null;
$dataFormatada = $_GET['data'] ?? null;

if (!$idUsuario || !$dataFormatada) {
    echo json_encode(['success' => false, 'horarios' => []]);
    exit;
}

try {
    // Busca todos os clientes únicos do usuário
    $urlClientes = $config["database_url"] . "/usuarios/$idUsuario/clientes_unicos.json?auth=" . $config["secret"];
    $clientesJson = @file_get_contents($urlClientes);
    $clientes = json_decode($clientesJson, true);
    
    $horariosOcupados = [];
    
    if ($clientes && is_array($clientes)) {
        foreach ($clientes as $clienteId => $cliente) {
            // Verifica se o cliente tem histórico de serviços
            if (isset($cliente['historicoServicos']) && is_array($cliente['historicoServicos'])) {
                // Verifica se há serviço na data selecionada
                if (isset($cliente['historicoServicos'][$dataFormatada])) {
                    $servico = $cliente['historicoServicos'][$dataFormatada];
                    
                    // Se o serviço é um objeto/array, busca o horário
                    if (is_array($servico) && isset($servico['horario'])) {
                        $horario = $servico['horario'];
                        if (!empty($horario)) {
                            $horariosOcupados[] = $horario;
                        }
                    }
                }
            }
        }
    }
    
    echo json_encode([
        'success' => true,
        'horarios' => array_unique($horariosOcupados)
    ]);
} catch (Exception $e) {
    echo json_encode([
        'success' => false,
        'horarios' => [],
        'error' => $e->getMessage()
    ]);
}
?>

