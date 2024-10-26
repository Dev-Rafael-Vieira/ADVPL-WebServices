#include 'protheus.ch'
#include 'parmtype.ch'
#include 'totvs.ch'
#include 'restful.ch'

/*
{Protheus.doc} WSCLIENTES
@description WebService para consulta de clientes
@type wsrestfull
@autor Rafael Jose Vieira
@since 25/10/2024
*/

// Declarando o corpo do serviço do tipo GET com sua descrição e rota
WSRESTFUL WSCLIENTES DESCRIPTION "WebService para consulta de clientes"

    WSMETHOD GET;
    DESCRIPTION "Retorna informaçãoes do cliente na tabela SA1";
    WSSYNTAX "/WSCLIENTES/{codigo}/{loja}"

END WSRESTFUL


//Implementação do metodo
WSMETHOD GET WSSERVICE WSCLIENTES

    //recebe os parametros da URL, cria o objeto cliente e define a response atribuindo esses valores a variaveis
    Local cCodigo := self:aURLParms[1]
    Local cLoja := self:aURLParms[2]
    Local oCliente := JSonObject():New()
    Local cResponse := ""

    //Abre o alias SA1
    DBSelectArea('SA1')
    DBSetOrder(1)
    DbGoTop()

    //verifica se a string informada no parâmetro da URL atende os requisitos de tamanho
    if len(cCodigo) != 6 .OR. len(cLoja) != 2
        SetRestFault(400, EncodeUTF8("Codigo ou Loja inválido."))
        return .f.
    endif
    //Verifica se o cliente informado pode ser achado dentro do banco
    if !SA1->(DbSeek( xFilial("SA1") + cCodigo + cLoja))
        SetRestFault(404, EncodeUTF8("Cliente não localizado."))
        return .f.
    endif

    //passa os valores encontrados no banco para os atributos do objeto oCliente
    oCliente['codigo'] := AllTrim(SA1->A1_COD)
    oCliente['loja'] := AllTrim(SA1->A1_LOJA)
    oCliente['uf'] := AllTrim(SA1->A1_EST)
    oCliente['municipio'] := AllTrim(SA1->A1_MUN)
    oCliente['bairro'] := AllTrim(SA1->A1_BAIRRO)
    oCliente['end'] := AllTrim(SA1->A1_END)
    oCliente['cnpj'] := AllTrim(SA1->A1_CGC)

    //Realiza a conversão do objeto oCliente para uma representação em JSON expressa em texto
    cResponse := oCliente:toJson()

    //Define o cabeçalho que será enviado para o navegador no formato JSON
    self:SetContentType('application/json')

    //Seta a resposta com o conteudo da variavel cResponse
    self:SetResponse( EncodeUTF8(cResponse))

return .t.
