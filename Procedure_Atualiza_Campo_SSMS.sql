CREATE PROCEDURE [dbo].[sp_atualiza_ender_z02]
        @CodTransp   VARCHAR(6) -- Par�metro da Procedure, deve ser informado o c�digo campo Z02_CODIGO que � uma PRIMARY KEY e IDENTITY
AS
     
BEGIN
	-- Declara��o de v�riaveis, observe que algumas v�ri�veis � com base em retorno se Querys
	DECLARE
		@cEnderZ02   VARCHAR(6)   =      (SELECT TOP 1 Z02_LOCALI FROM Z02010 (NOLOCK) WHERE Z02_CODIGO = @CodTransp AND Z02_STATUS = 'E' AND D_E_L_E_T_ = '')
	,   @cFilial     VARCHAR(4)   =      (SELECT TOP 1 Z02_FILIAL FROM Z02010 (NOLOCK) WHERE Z02_CODIGO = @CodTransp AND Z02_STATUS = 'E' AND D_E_L_E_T_ = '')
	,   @cPedido     VARCHAR(6)   =      (SELECT TOP 1 Z02_NUMPV FROM Z02010 (NOLOCK) WHERE Z02_CODIGO = @CodTransp AND Z02_STATUS = 'E' AND D_E_L_E_T_ = '')
	,   @cProduto    VARCHAR(MAX)       
	,   @cEnderBF    VARCHAR(6)

	-- Est� v�riavel � capaz de retornar exatamente o produto da tabela Z02, o p�matro @CodTransp garante est� exatid�o
	SET
		@cProduto	=      (    
								SELECT TOP 1 Z02_PRODUT
								FROM   Z02010 (NOLOCK)
								WHERE  Z02_CODIGO = @CodTransp
								AND          D_E_L_E_T_ = ''       
							);

    /*	Est� v�riavel retorna o endere�o do produto no estoque, as v�riaveis @cProduto e @cFilial, garante que estamos procurando o produto correto...
		Al�m do mais � tamb�m garantido que iremos pegar o endere�o para este produto com maior saldo no estoque o ORDER BY nos auxilia neste caso...
		Outra condi��o importante � que a quantidade do produto sempre deve ser maior do que a quantidade empenhada
	*/
	SET
		@cEnderBF    =      (      
								SELECT TOP 1 BF_LOCALIZ
								FROM   SBF010 (NOLOCK)
								WHERE  BF_LOCALIZ <> 'MC'
								AND    BF_PRODUTO = @cProduto
								AND    BF_FILIAL  = @cFilial
								AND	   BF_LOCAL	  = '01'
								AND    BF_QUANT > BF_EMPENHO
								ORDER BY BF_QUANT DESC
							);

 
	-- Condicionais antes de realizar o UPDATE
	IF @cEnderZ02 = @cEnderBF
		PRINT('O Endere�o Entre Z02 e SBF esta correto')
	ELSE IF @cPedido <> ''
		PRINT('N�o � possivel atualizar endere�o de transposi��o com Pedido de Vendas')

	-- Se as condi��es acima retornar FALSE, prossegumos com o UPDATE
	ELSE
		BEGIN TRAN
			BEGIN
				/*
					Iremos atualizar o campo Z02_LOCALI com base na v�riavel @cEnderBF preenchida na linha 28 do c�digo...
					A condi��o principal ser� o Z02_CODIGO que � PRIMARY KEY e IDENTITY, esta condi��o ser� preenchida com o par�metro @CodTransp, linha 2
				*/
				UPDATE Z02010
				SET Z02_LOCALI = @cEnderBF
				WHERE Z02_CODIGO = @CodTransp AND D_E_L_E_T_ = ''

				-- Para este UPDATE apena 1 linha por vez deve ser atualizada, com o @@ROWCOUNT, podemos garantir o commit apenas neste caso
				IF @@ROWCOUNT = 1
					COMMIT
				ELSE
					ROLLBACK
			END
      
END