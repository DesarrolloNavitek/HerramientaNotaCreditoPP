SET DATEFIRST 7
SET ANSI_NULLS OFF
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
SET LOCK_TIMEOUT -1
SET QUOTED_IDENTIFIER OFF
GO
CREATE OR ALTER PROCEDURE spNaviExploraProntoPagoActualizar
	@Empresa varchar(5)
AS BEGIN

	DECLARE 
	@IDAct			int,
			@EmpresaAct		varchar(5),
			@MovAct			varchar(20),
			@MovIDAct		varchar(20),
			@FechaPagoAct	datetime,
			@AplicaAct		varchar(20),
			@AplicaIDAct	varchar(20),
			@IDAplicaAct	varchar(20),
			@SaldoAct		float,
			@SaldoAnt		float,
			@FechaOrig		date,
			@Estatus		varchar(10),
			@Modificar		bit

	IF EXISTS(SELECT TOP(1) 0 FROM NaviExploraProntoPago)
	BEGIN

		DECLARE crActualizaSaldo CURSOR FAST_FORWARD FOR
		SELECT ID,Empresa,Mov,MovID,FechaPago,Aplica,AplicaID,IDAplica,Total, Modificar
		FROM NaviExploraProntoPago
		WHERE Empresa = @Empresa
		AND ISNULL(Procesado,0) = 0
		AND ISNULL(ImporteDesc,0) > 0
		AND ISNULL(Total,0) != 0

		OPEN crActualizaSaldo

		FETCH NEXT FROM crActualizaSaldo INTO @IDAct,@EmpresaAct,@MovAct,@MovIDAct,@FechaPagoAct,@AplicaAct,@AplicaIDAct,@IDAplicaAct,@SaldoAnt, @Modificar

		WHILE @@FETCH_STATUS = 0
		BEGIN

			-- Actualiza Fecha Original
			SELECT @FechaOrig = ISNULL(c1.FechaOriginal,ISNULL(c2.FechaOriginal,n.FechaPago/*n.FechaEmision*/))
			FROM NaviExploraProntoPago n 
			LEFT JOIN Cxc c1 ON n.IDAplica = c1.ID 
			LEFT JOIN Cxc c2 ON c1.MovAplica = c2.Mov AND c1.MovAplicaID = c2.MovID 
			WHERE 
			n.IDAplica = @IDAplicaAct

			IF NULLIF(@FechaOrig,NULL) IS NOT NULL
				UPDATE NaviExploraProntoPago SET FechaPago = @FechaOrig WHERE ID = @IDAct AND Empresa = @EmpresaAct AND Mov = @MovAct AND MovID = @MovIDAct AND Aplica = @AplicaAct AND AplicaID = @AplicaIDAct AND IDAplica = @IDAplicaAct
			
			SELECT @Estatus = Estatus FROM Cxc WHERE ID = @IDAplicaAct
			IF ISNULL(@Estatus,'') = 'CANCELADO'
			BEGIN
				DELETE FROM NaviExploraProntoPago WHERE ID = @IDAct AND Empresa = @EmpresaAct AND Mov = @MovAct AND MovID = @MovIDAct AND Aplica = @AplicaAct AND AplicaID = @AplicaIDAct AND IDAplica = @IDAplicaAct
				FETCH NEXT FROM crActualizaSaldo INTO @IDAct,@EmpresaAct,@MovAct,@MovIDAct,@FechaPagoAct,@AplicaAct,@AplicaIDAct,@IDAplicaAct,@SaldoAnt, @Modificar
			END
			ELSE
			BEGIN
				-- Actualiza el cálculo
				IF (SELECT COUNT(*) FROM NaviExploraProntoPago WHERE ID = @IDAct AND Empresa = @EmpresaAct AND ISNULL(Anticipo,0) != 0 AND Aplica = 'Aplicacion') > 0
				BEGIN
					-- Posee notas de crédito
					SELECT @SaldoAnt = SUM(Anticipo) FROM NaviExploraProntoPago WHERE ID = @IDAct AND Empresa = @EmpresaAct AND ISNULL(Anticipo,0) != 0 AND Aplica = 'Aplicacion'
					IF ISNULL(@SaldoAnt,0) > 0
					BEGIN

						IF ISNULL(@Modificar,0) = 0
						BEGIN
							UPDATE NaviExploraProntoPago SET ImporteDesc = CASE WHEN ISNULL( Parcial,0) = 0  
																			THEN  ((Importe+ISNULL(IVA,0))-(ISNULL(@SaldoAnt,0)))*(ISNULL(Descuento,0)/100)  -- Importe de la factura
																			ELSE  Anticipo*(ISNULL(Descuento,0)/100)    
																			END  
							WHERE ID = @IDAct AND Empresa = @EmpresaAct AND Mov = @MovAct AND MovID = @MovIDAct AND Aplica = @AplicaAct AND AplicaID = @AplicaIDAct AND IDAplica = @IDAplicaAct
						END
					END
				END

				SELECT @SaldoAct = ImporteDesc FROM NaviExploraProntoPago WHERE ID = @IDAct AND Empresa = @EmpresaAct AND Mov = @MovAct AND MovID = @MovIDAct AND Aplica = @AplicaAct AND AplicaID = @AplicaIDAct AND IDAplica = @IDAplicaAct


		
				FETCH NEXT FROM crActualizaSaldo INTO @IDAct,@EmpresaAct,@MovAct,@MovIDAct,@FechaPagoAct,@AplicaAct,@AplicaIDAct,@IDAplicaAct,@SaldoAnt, @Modificar
			END
		END

		CLOSE crActualizaSaldo
		DEALLOCATE crActualizaSaldo

		-- Actualiza los días
		UPDATE NaviExploraProntoPago SET Dias = ISNULL(DATEDIFF(DD, FechaEmision, FechaPago),0) WHERE Empresa = @Empresa

		---- Actualiza el importe del descuento
		--UPDATE N SET	Descuento = ISNULL(C.Descuento,0),    
		--				ImporteDesc =	CASE WHEN ISNULL( N.Parcial,0)=0  
		--									--THEN	(Importe+ISNULL(IVA,0))*(ISNULL(C.Descuento,0)/100)  -- Importe de la factura
		--									THEN	(ISNULL(Total,0))*(ISNULL(C.Descuento,0)/100) -- Saldo de la factura
		--								ELSE  Anticipo*(ISNULL(C.Descuento,0)/100)    
		--								END      
		--FROM NaviExploraProntoPago N        
		--JOIN NaviCfgDescuento C on n.dias	BETWEEN	CASE WHEN CHARINDEX('A', rangodia,  1)=0   
		--								    			THEN SUBSTRING(RANGODIA, 1, CHARINDEX('O', rangodia,  1)-1)   
		--											ELSE SUBSTRING(RANGODIA, 1, CHARINDEX('A', rangodia,  1)-1)   
		--											END    
		--									AND	CASE	WHEN charindex('A', rangodia,  1)=0   
		--												THEN 10000   
		--										ELSE SUBSTRING(RANGODIA, CHARINDEX('A', rangodia,  2)+2, 2)   
		--										END     
		--									AND N.Empresa = C.Empresa    
		--WHERE N.Empresa = @Empresa

	END
	RETURN
END


/*Respaldo Prod*/
--CREATE PROCEDURE spNaviExploraProntoPagoActualizar
--	@Empresa varchar(5)
--AS BEGIN

--	DECLARE 
--	@IDAct			int,
--			@EmpresaAct		varchar(5),
--			@MovAct			varchar(20),
--			@MovIDAct		varchar(20),
--			@FechaPagoAct	datetime,
--			@AplicaAct		varchar(20),
--			@AplicaIDAct	varchar(20),
--			@IDAplicaAct	varchar(20),
--			@SaldoAct		float,
--			@SaldoAnt		float,
--			@FechaOrig		date,
--			@Estatus		varchar(10),
--			@Modificar		bit

--	IF EXISTS(SELECT TOP(1) 0 FROM NaviExploraProntoPago)
--	BEGIN

--		DECLARE crActualizaSaldo CURSOR FAST_FORWARD FOR
--		SELECT ID,Empresa,Mov,MovID,FechaPago,Aplica,AplicaID,IDAplica,Total, Modificar
--		FROM NaviExploraProntoPago
--		WHERE Empresa = @Empresa
--		AND ISNULL(Procesado,0) = 0
--		AND ISNULL(ImporteDesc,0) > 0
--		AND ISNULL(Total,0) != 0

--		OPEN crActualizaSaldo

--		FETCH NEXT FROM crActualizaSaldo INTO @IDAct,@EmpresaAct,@MovAct,@MovIDAct,@FechaPagoAct,@AplicaAct,@AplicaIDAct,@IDAplicaAct,@SaldoAnt, @Modificar

--		WHILE @@FETCH_STATUS = 0
--		BEGIN

--			-- Actualiza Fecha Original
--			SELECT @FechaOrig = ISNULL(c1.FechaOriginal,ISNULL(c2.FechaOriginal,n.FechaEmision))
--			FROM NaviExploraProntoPago n 
--			LEFT JOIN Cxc c1 ON n.IDAplica = c1.ID 
--			LEFT JOIN Cxc c2 ON c1.MovAplica = c2.Mov AND c1.MovAplicaID = c2.MovID 
--			WHERE 
--			n.IDAplica = @IDAplicaAct

--			IF NULLIF(@FechaOrig,NULL) IS NOT NULL
--				UPDATE NaviExploraProntoPago SET FechaPago = @FechaOrig WHERE ID = @IDAct AND Empresa = @EmpresaAct AND Mov = @MovAct AND MovID = @MovIDAct AND Aplica = @AplicaAct AND AplicaID = @AplicaIDAct AND IDAplica = @IDAplicaAct
			
--			SELECT @Estatus = Estatus FROM Cxc WHERE ID = @IDAplicaAct
--			IF ISNULL(@Estatus,'') = 'CANCELADO'
--			BEGIN
--				DELETE FROM NaviExploraProntoPago WHERE ID = @IDAct AND Empresa = @EmpresaAct AND Mov = @MovAct AND MovID = @MovIDAct AND Aplica = @AplicaAct AND AplicaID = @AplicaIDAct AND IDAplica = @IDAplicaAct
--				FETCH NEXT FROM crActualizaSaldo INTO @IDAct,@EmpresaAct,@MovAct,@MovIDAct,@FechaPagoAct,@AplicaAct,@AplicaIDAct,@IDAplicaAct,@SaldoAnt, @Modificar
--			END
--			ELSE
--			BEGIN
--				-- Actualiza el cálculo
--				IF (SELECT COUNT(*) FROM NaviExploraProntoPago WHERE ID = @IDAct AND Empresa = @EmpresaAct AND ISNULL(Anticipo,0) != 0 AND Aplica = 'Aplicacion') > 0
--				BEGIN
--					-- Posee notas de crédito
--					SELECT @SaldoAnt = SUM(Anticipo) FROM NaviExploraProntoPago WHERE ID = @IDAct AND Empresa = @EmpresaAct AND ISNULL(Anticipo,0) != 0 AND Aplica = 'Aplicacion'
--					IF ISNULL(@SaldoAnt,0) > 0
--					BEGIN

--						IF ISNULL(@Modificar,0) = 0
--						BEGIN
--							UPDATE NaviExploraProntoPago SET ImporteDesc = CASE WHEN ISNULL( Parcial,0) = 0  
--																			THEN  ((Importe+ISNULL(IVA,0))-(ISNULL(@SaldoAnt,0)))*(ISNULL(Descuento,0)/100)  -- Importe de la factura
--																			ELSE  Anticipo*(ISNULL(Descuento,0)/100)    
--																			END  
--							WHERE ID = @IDAct AND Empresa = @EmpresaAct AND Mov = @MovAct AND MovID = @MovIDAct AND Aplica = @AplicaAct AND AplicaID = @AplicaIDAct AND IDAplica = @IDAplicaAct
--						END
--					END
--				END

--				SELECT @SaldoAct = ImporteDesc FROM NaviExploraProntoPago WHERE ID = @IDAct AND Empresa = @EmpresaAct AND Mov = @MovAct AND MovID = @MovIDAct AND Aplica = @AplicaAct AND AplicaID = @AplicaIDAct AND IDAplica = @IDAplicaAct


		
--				FETCH NEXT FROM crActualizaSaldo INTO @IDAct,@EmpresaAct,@MovAct,@MovIDAct,@FechaPagoAct,@AplicaAct,@AplicaIDAct,@IDAplicaAct,@SaldoAnt, @Modificar
--			END
--		END

--		CLOSE crActualizaSaldo
--		DEALLOCATE crActualizaSaldo

--		-- Actualiza los días
--		UPDATE NaviExploraProntoPago SET Dias = ISNULL(DATEDIFF(DD, FechaEmision, FechaPago),0) WHERE Empresa = @Empresa

--		---- Actualiza el importe del descuento
--		--UPDATE N SET	Descuento = ISNULL(C.Descuento,0),    
--		--				ImporteDesc =	CASE WHEN ISNULL( N.Parcial,0)=0  
--		--									--THEN	(Importe+ISNULL(IVA,0))*(ISNULL(C.Descuento,0)/100)  -- Importe de la factura
--		--									THEN	(ISNULL(Total,0))*(ISNULL(C.Descuento,0)/100) -- Saldo de la factura
--		--								ELSE  Anticipo*(ISNULL(C.Descuento,0)/100)    
--		--								END      
--		--FROM NaviExploraProntoPago N        
--		--JOIN NaviCfgDescuento C on n.dias	BETWEEN	CASE WHEN CHARINDEX('A', rangodia,  1)=0   
--		--								    			THEN SUBSTRING(RANGODIA, 1, CHARINDEX('O', rangodia,  1)-1)   
--		--											ELSE SUBSTRING(RANGODIA, 1, CHARINDEX('A', rangodia,  1)-1)   
--		--											END    
--		--									AND	CASE	WHEN charindex('A', rangodia,  1)=0   
--		--												THEN 10000   
--		--										ELSE SUBSTRING(RANGODIA, CHARINDEX('A', rangodia,  2)+2, 2)   
--		--										END     
--		--									AND N.Empresa = C.Empresa    
--		--WHERE N.Empresa = @Empresa

--	END
--	RETURN
--END