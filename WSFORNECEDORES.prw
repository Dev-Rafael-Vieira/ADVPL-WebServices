#include 'protheus.ch'
#include 'parmtype.ch'
#include 'totvs.ch'
#include 'restful.ch'

//-------------------------------------------------------------------
// Documenta��o do WebService WSFORNECEDORES
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

    // Define os par�metros que o WebService aceitar�
    WSDATA codigo AS STRING  // C�digo do fornecedor
    WSDATA loja AS STRING    // Loja do fornecedor

    // Define que este WebService utiliza o m�todo GET
    WSMETHOD GET; 
    DESCRIPTION "Retorna informa��es do fornecedor."; 
    WSSYNTAX "/WSFORNECEDORES"  // Define a sintaxe do endpoint

END WSRESTFUL


// Implementa o m�todo GET para o WebService WSFORNECEDORES
WSMETHOD GET WSRECEIVE codigo, loja WSSERVICE WSFORNECEDORES

    // Declara��o de vari�veis
    local cCodigo := iif(valtype(self:codigo)=="U", "", self:codigo)  // Verifica se o c�digo � indefinido; se sim, usa string vazia
    local cLoja := iif(valtype(self:loja)=="U", "", self:loja)         // Verifica se a loja � indefinida; se sim, usa string vazia
    local ofornecedor := JSonObject():New()  // Cria um novo objeto JSON para armazenar informa��es do fornecedor
    local cResponse := ""  // Inicializa a vari�vel de resposta como string vazia

    // Abre o alias da tabela SA2 que cont�m informa��es dos fornecedores
    DBSelectArea('SA2')
    DbSetOrder(1) // Define a ordem de pesquisa como FILIAL + CODIGO + LOJA
    DbGoTop()  // Move o ponteiro do banco de dados para o in�cio da tabela

    // VALIDA��O: Verifica se o c�digo e a loja possuem o tamanho correto
    if len(cCodigo) != 6 .OR. len(cLoja) != 2
        SetRestFault(400, EncodeUTF8("C�digo ou Loja � inv�lido."))  // Retorna erro 400 se a valida��o falhar
        return .F.  // Retorna falso, indicando falha na execu��o
    endif

    // POSICIONA NO FORNECEDOR: Busca o registro do fornecedor na tabela SA2
    if !SA2->(DbSeek(xFilial("SA2") + cCodigo + cLoja))
        SetRestFault(404, EncodeUTF8("Fornecedor n�o localizado."))  // Retorna erro 404 se o fornecedor n�o for encontrado
        return .F.  // Retorna falso, indicando falha na execu��o
    endif

    // Cria o objeto JSON com os dados do fornecedor encontrados
    oFornecedor['codigo'] := AllTrim(SA2->A2_COD)         // C�digo do fornecedor
    oFornecedor['loja'] := AllTrim(SA2->A2_LOJA)           // Loja do fornecedor
    oFornecedor['uf'] := AllTrim(SA2->A2_EST)             // UF do fornecedor
    oFornecedor['municipio'] := AllTrim(SA2->A2_MUN)      // Munic�pio do fornecedor
    oFornecedor['bairro'] := AllTrim(SA2->A2_BAIRRO)      // Bairro do fornecedor
    oFornecedor['end'] := AllTrim(SA2->A2_END)            // Endere�o do fornecedor
    oFornecedor['cnpj'] := AllTrim(SA2->A2_CGC)           // CNPJ do fornecedor

    // Converte o objeto JSON para uma string
    cResponse := oFornecedor:toJson()

    // Define o tipo de conte�do da resposta como JSON
    self:SetContentType('application/json')

    // Define a resposta do WebService com o conte�do JSON
    self:SetResponse(EncodeUTF8(cResponse))  // Retorna a resposta codificada em UTF-8

return .T.  // Retorna verdadeiro, indicando sucesso na execu��o
