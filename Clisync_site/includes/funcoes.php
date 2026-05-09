<?php
/**
 * Arquivo com funções auxiliares e mapeamentos
 * 
 * PROTEÇÃO: Este arquivo não deve ser acessado diretamente via URL
 */
if (!defined('CLISYNC_INCLUDED')) {
    http_response_code(403);
    die('Acesso negado.');
}

// Mapeamento de nomes de campos da configuração para nomes de campos do formulário/banco
function obterMapeamentoCampos() {
    return [
        'Nome' => ['name' => 'nome', 'type' => 'text', 'placeholder' => 'Digite seu nome completo', 'required' => true],
        'Telefone' => ['name' => 'telefone', 'type' => 'text', 'placeholder' => '00000000000', 'required' => true, 'maxlength' => 11],
        'Bairro' => ['name' => 'bairro', 'type' => 'text', 'placeholder' => 'Digite o bairro', 'required' => false],
        'Cidade' => ['name' => 'cidade', 'type' => 'text', 'placeholder' => 'Digite a cidade', 'required' => false],
        'Rua' => ['name' => 'rua', 'type' => 'text', 'placeholder' => 'Digite a rua', 'required' => false],
        'Número' => ['name' => 'numero', 'type' => 'text', 'placeholder' => 'Digite o número', 'required' => false],
        'Data de vencimento do pagamento' => ['name' => 'dataVencimento', 'type' => 'date', 'placeholder' => '', 'required' => false],
        'Frequência' => ['name' => 'frequencia', 'type' => 'text', 'placeholder' => 'Digite a frequência', 'required' => false],
        'Prioridade' => ['name' => 'prioridade', 'type' => 'text', 'placeholder' => 'Digite a prioridade', 'required' => false],
    ];
}

// Função para renderizar um campo
function renderizarCampo($config, $label) {
    $name = $config['name'];
    $type = $config['type'];
    $placeholder = $config['placeholder'] ?? '';
    $required = $config['required'] ?? false;
    $maxlength = $config['maxlength'] ?? '';
    
    $requiredAttr = $required ? 'required' : '';
    $maxlengthAttr = $maxlength ? "maxlength=\"$maxlength\"" : '';
    
    echo "<div class=\"field-group\">";
    echo "<label for=\"$name\">$label</label>";
    echo "<input type=\"$type\" id=\"$name\" name=\"$name\" placeholder=\"$placeholder\" $requiredAttr $maxlengthAttr>";
    echo "</div>";
}

// Função para validar ID do usuário
function validarIdUsuario($idUsuario) {
    if (!$idUsuario || strlen(trim($idUsuario)) < 1) {
        return false;
    }
    return true;
}
?>
