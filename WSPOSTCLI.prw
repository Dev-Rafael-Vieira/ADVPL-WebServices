#include 'protheus.ch'
#include 'parmtype.ch'
#include 'totvs.ch'
#include 'restful.ch'

//-------------------------------------------------------------------
/*/{Protheus.doc} POST
@description Metodo para POST.
@type wsmethod
@author Rafael Jose Vieira
@since 25/10/2024
/*/
//-------------------------------------------------------------------

WSRESTFUL WSPOSTCLI DESCRIPTION "WebService para cadastro de clientes."

    WSMETHOD POST; 
    DESCRIPTION "Inseri cliente."; 
    WSSYNTAX "/WSPOSTCLI"

END WSRESTFUL


WSMETHOD POST WSSERVICE WSPOSTCLI

    // Variáveis.
    local   cConteudo   := self:getContent()
    local   oCliente    := JsonObject():New()
    local   cCodMun     := ""

    // Parse do conteudo da requisicao.
    cError := oCliente:fromJson(cConteudo)

    // Valida erros no parse.
    if !Empty(cError)
        SetRestFault(400, cError)
        return .F.
    endif

    // Abre alias SA1.
    DBSelectArea('SA1')
    SA1->(DbSetOrder(3)) // FILIAL + CNPJ
    SA1->(DbGoTop())

    // Valida CNPJ.
    if len(oCliente['cnpj']) != 14
        SetRestFault(400, EncodeUTF8('O CNPJ informado tem o comprimento inválido.'))
        return .F.
    endif

    // Verifica se CNPJ existe no cadastro.
    if SA1->( DbSeek( xFilial('SA1') + oCliente['cnpj'] ) )
        SetRestFault(400, EncodeUTF8('O CNPJ informado já está registrado.'))
        return .F.
    endif

    // Busca municipio.
    DBSelectArea('CC2')
    DbSetOrder(2)
    DbGoTop()

    if CC2->( DbSeek( xFilial("CC2") + Upper(oCliente['municipio']) ) )
        cCodMun := CC2->CC2_CODMUN
    endif
    
    // Grava cliente.
    RecLock("SA1", .T.)
    SA1->A1_COD     := GetSx8Num("SA1","A1_COD")
    SA1->A1_LOJA    := "01"
    SA1->A1_NOME    := Upper(oCliente['razao'])
    SA1->A1_NREDUZ  := Upper(oCliente['nome'])
    SA1->A1_TIPO    := Upper(oCliente['tipo'])
    SA1->A1_CGC     := Upper(oCliente['cnpj'])
    SA1->A1_INSCR   := Upper(oCliente['ie'])
    SA1->A1_PESSOA  := Upper(oCliente['pessoa'])
    SA1->A1_EMAIL   := Upper(oCliente['email'])
    SA1->A1_CEP     := Upper(oCliente['cep'])
    SA1->A1_END     := Upper(oCliente['endereco'])
    SA1->A1_BAIRRO  := Upper(oCliente['bairro'])
    SA1->A1_EST     := Upper(oCliente['uf'])
    SA1->A1_MUN     := Upper(oCliente['municipio'])
    SA1->A1_COD_MUN := cCodMun
    SA1->A1_DDD     := Upper(oCliente['ddd'])
    SA1->A1_TEL     := Upper(oCliente['telefone'])
    SA1->A1_MSBLQL  := "2"
    SA1->A1_DTCAD   := Date()
    SA1->A1_HRCAD   := Time()
    MsUnlock()

    // Define o tipo de retorno do método.
	self:SetContentType( 'application/json' )

    // Define a resposta.
    self:SetResponse(EncodeUTF8(oCliente:toJson()))

Return .T.
