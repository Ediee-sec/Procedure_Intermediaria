CREATE PROCEDURE [dbo].[sp_atualiza_ender_z02]
        @CodTransp   VARCHAR(6) -- Parâmetro da Procedure, deve ser informado o código campo Z02_CODIGO que é uma PRIMARY KEY e IDENTITY
AS
     
BEGIN
	-- Declaração de váriaveis, observe que algumas váriáveis é com base em retorno se Querys
	DECLARE
		@cEnderZ02   VARCHAR(6)   =      (SELECT TOP 1 Z02_LOCALI FROM Z02010 (NOLOCK) WHERE Z02_CODIGO = @CodTransp AND Z02_STATUS = 'E' AND D_E_L_E_T_ = '')
	,   @cFilial     VARCHAR(4)   =      (SELECT TOP 1 Z02_FILIAL FROM Z02010 (NOLOCK) WHERE Z02_CODIGO = @CodTransp AND Z02_STATUS = 'E' AND D_E_L_E_T_ = '')
	,   @cPedido     VARCHAR(6)   =      (SELECT TOP 1 Z02_NUMPV FROM Z02010 (NOLOCK) WHERE Z02_CODIGO = @CodTransp AND Z02_STATUS = 'E' AND D_E_L_E_T_ = '')
	,   @cProduto    VARCHAR(MAX)       
	,   @cEnderBF    VARCHAR(6)

	-- Está váriavel é capaz de retornar exatamente o produto da tabela Z02, o pâmatro @CodTransp garante está exatidão
	SET
		@cProduto	=      (    
								SELECT TOP 1 Z02_PRODUT
								FROM   Z02010 (NOLOCK)
								WHERE  Z02_CODIGO = @CodTransp
								AND          D_E_L_E_T_ = ''       
							);

    /*	Está váriavel retorna o endereço do produto no estoque, as váriaveis @cProduto e @cFilial, garante que estamos procurando o produto correto...
		Além do mais é também garantido que iremos pegar o endereço para este produto com maior saldo no estoque o ORDER BY nos auxilia neste caso...
		Outra condição importante é que a quantidade do produto sempre deve ser maior do que a quantidade empenhada
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
		PRINT('O Endereço Entre Z02 e SBF esta correto')
	ELSE IF @cPedido <> ''
		PRINT('Não é possivel atualizar endereço de transposição com Pedido de Vendas')

	-- Se as condições acima retornar FALSE, prossegumos com o UPDATE
	ELSE
		BEGIN TRAN
			BEGIN
				/*
					Iremos atualizar o campo Z02_LOCALI com base na váriavel @cEnderBF preenchida na linha 28 do código...
					A condição principal será o Z02_CODIGO que é PRIMARY KEY e IDENTITY, esta condição será preenchida com o parâmetro @CodTransp, linha 2
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