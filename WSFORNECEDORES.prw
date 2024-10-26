#include 'protheus.ch'
#include 'parmtype.ch'
#include 'totvs.ch'
#include 'restful.ch'

//-------------------------------------------------------------------
// Documentação do WebService WSFORNECEDORES
/*/{Protheus.doc} WSFORNECEDORES
@description WebService para consulta de fornecedores.
@type wsrestful
@author Rafael Jose Vieira
@since 25/10/2024
Exemplo de chamada da rota: /REST/wsfornecedores?codigo=000001&loja=01
/*/
//-------------------------------------------------------------------

// Define o WebService WSFORNECEDORES
WSRESTFUL WSFORNECEDORES DESCRIPTION "WebService para consulta de fornecedores."

    // Define os parâmetros que o WebService aceitará
    WSDATA codigo AS STRING  // Código do fornecedor
    WSDATA loja AS STRING    // Loja do fornecedor

    // Define que este WebService utiliza o método GET
    WSMETHOD GET; 
    DESCRIPTION "Retorna informações do fornecedor."; 
    WSSYNTAX "/WSFORNECEDORES"  // Define a sintaxe do endpoint

END WSRESTFUL


// Implementa o método GET para o WebService WSFORNECEDORES
WSMETHOD GET WSRECEIVE codigo, loja WSSERVICE WSFORNECEDORES

    // Declaração de variáveis
    local cCodigo := iif(valtype(self:codigo)=="U", "", self:codigo)  // Verifica se o código é indefinido; se sim, usa string vazia
    local cLoja := iif(valtype(self:loja)=="U", "", self:loja)         // Verifica se a loja é indefinida; se sim, usa string vazia
    local ofornecedor := JSonObject():New()  // Cria um novo objeto JSON para armazenar informações do fornecedor
    local cResponse := ""  // Inicializa a variável de resposta como string vazia

    // Abre o alias da tabela SA2 que contém informações dos fornecedores
    DBSelectArea('SA2')
    DbSetOrder(1) // Define a ordem de pesquisa como FILIAL + CODIGO + LOJA
    DbGoTop()  // Move o ponteiro do banco de dados para o início da tabela

    // VALIDAÇÃO: Verifica se o código e a loja possuem o tamanho correto
    if len(cCodigo) != 6 .OR. len(cLoja) != 2
        SetRestFault(400, EncodeUTF8("Código ou Loja é inválido."))  // Retorna erro 400 se a validação falhar
        return .F.  // Retorna falso, indicando falha na execução
    endif

    // POSICIONA NO FORNECEDOR: Busca o registro do fornecedor na tabela SA2
    if !SA2->(DbSeek(xFilial("SA2") + cCodigo + cLoja))
        SetRestFault(404, EncodeUTF8("Fornecedor não localizado."))  // Retorna erro 404 se o fornecedor não for encontrado
        return .F.  // Retorna falso, indicando falha na execução
    endif

    // Cria o objeto JSON com os dados do fornecedor encontrados
    oFornecedor['codigo'] := AllTrim(SA2->A2_COD)         // Código do fornecedor
    oFornecedor['loja'] := AllTrim(SA2->A2_LOJA)           // Loja do fornecedor
    oFornecedor['uf'] := AllTrim(SA2->A2_EST)             // UF do fornecedor
    oFornecedor['municipio'] := AllTrim(SA2->A2_MUN)      // Município do fornecedor
    oFornecedor['bairro'] := AllTrim(SA2->A2_BAIRRO)      // Bairro do fornecedor
    oFornecedor['end'] := AllTrim(SA2->A2_END)            // Endereço do fornecedor
    oFornecedor['cnpj'] := AllTrim(SA2->A2_CGC)           // CNPJ do fornecedor

    // Converte o objeto JSON para uma string
    cResponse := oFornecedor:toJson()

    // Define o tipo de conteúdo da resposta como JSON
    self:SetContentType('application/json')

    // Define a resposta do WebService com o conteúdo JSON
    self:SetResponse(EncodeUTF8(cResponse))  // Retorna a resposta codificada em UTF-8

return .T.  // Retorna verdadeiro, indicando sucesso na execução
