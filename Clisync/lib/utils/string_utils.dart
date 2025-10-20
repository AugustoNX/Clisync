/// Remove acentos de uma string para facilitar buscas
String removerAcentos(String str) {
  const comAcento = 'ÀÁÂÃÄÅàáâãäåÒÓÔÕÕÖØòóôõöøÈÉÊËèéêëðÇçÐÌÍÎÏìíîïÙÚÛÜùúûüÑñŠšŸÿýŽž';
  const semAcento = 'AAAAAAaaaaaaOOOOOOOooooooEEEEeeeeeCcDIIIIiiiiUUUUuuuuNnSsYyyZz';
  
  String resultado = str;
  for (int i = 0; i < comAcento.length; i++) {
    resultado = resultado.replaceAll(comAcento[i], semAcento[i]);
  }
  
  return resultado;
}

/// Normaliza string para busca (remove acentos e converte para minúsculas)
String normalizarParaBusca(String str) {
  return removerAcentos(str).toLowerCase();
}

