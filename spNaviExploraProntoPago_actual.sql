SET DATEFIRST 7
SET ANSI_NULLS OFF
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
SET LOCK_TIMEOUT -1
SET QUOTED_IDENTIFIER OFF
GO
--exec spNaviExploraProntoPago 'NVK',N'JQUEZADA',N'01/01/2026',N'31/07/2026',N'0'
--EXEC spNaviExploraProntoPagoActualizar  'NVK'
IF EXISTS (SELECT 1 FROM sys.objects WHERE name = 'spNaviExploraProntoPago' AND TYPE  ='P')
DROP PROC spNaviExploraProntoPago
GO
CREATE PROCEDURE spNaviExploraProntoPago
    @Empresa  varchar(5),        
    @Agente  varchar(20),        
    @FechaD  datetime,        
    @FechaA  datetime,  
    @DIAS    varchar(20)  
--//WITH ENCRYPTION        
AS   
BEGIN        
      
 CREATE TABLE #NaviExploraProntoPago  
 (  
  ID				int				NOT NULL,  
  Empresa			varchar(20)		NOT NULL,  
  Mov				varchar(20)		NOT NULL,  
  MovID				varchar(20)		NOT NULL,  
  Cliente			varchar(20)		NULL,  
  NombreCte			varchar(100)	NULL,  
  Agente			varchar(20)		NULL,  
  FechaEmision		datetime		NULL,  
  Importe			float			NULL,  
  IVA				float			NULL,
  ImporteNC			float			NULL,--JARC agrega notas de crédito
  IVANC				float			NULL,--JARC agrega notas de crédito
  Retencion			float			NULL,  
  Anticipo			float			NULL,  
  Total				float			NULL,  
  Dias				int				NULL,  
  FechaPago			datetime		NOT NULL,  
  Descuento			float			NULL,  
  ImporteDesc		float			NULL,  
  LiberaEjec		bit				NULL,  
  Ejecutivo			varchar(20)		NULL,  
  LiberaGerente		bit				NULL,  
  Gerente			varchar(20)		NULL,  
  Moneda			varchar(20)		NULL,  
  TipoCambio		float			NULL,  
  Procesado			bit				NULL,  
  Aplica			varchar(20)		NOT NULL,  
  AplicaID			varchar(20)		NOT NULL,  
  Parcial			bit				NULL,  
  IDAplica			int				NOT NULL,  
  Seleccionar		bit				NULL,  
  NoDPP				bit				NULL  
 )  
  
 DECLARE @IDInsertar		int,  
   @EmpresaInsertar			varchar(5),  
   @MovInsertar				varchar(20),  
   @MovIDInsertar			varchar(20),  
   @FechaPagoInsertar		datetime,  
   @AplicaInsertar			varchar(20),  
   @AplicaIDInsertar		varchar(20),  
   @IDAplicaInsertar		int,
   @Seleccionar				bit,
   @LiberarEjecutivoS		bit,
   @LiberaGerenteS			bit,
   @ProcesadoM				bit,
   @Eliminar				bit,
   @ImporteTotalX			float,
   @DescuentoX				float,
   @Modificar				bit
  
    DECLARE @Tipo varchar(50)    
    --DELETE FROM NaviExploraProntoPago WHERE Empresa='NVK'@Empresa         --Esta parte elmina toda la tabla    
    SELECT @Tipo = TIPO FROM AGENTE WHERE AGENTE = @Agente      
  
    IF @tipo='DIRECTOR'   --172590  
 BEGIN  
  INSERT INTO #NaviExploraProntoPago   (  
                                          ID,                                
                                          Empresa,        
                                          Mov,                  
                                          MovID,                  
                                          Cliente,                      
                                          NombreCte,              
                                          Agente,           
                                          FechaEmision,            
                                          Importe,               
                                          IVA,
										  ImporteNC,--JARC agrega notas de crédito
										  IVANC,--JARC agrega notas de crédito
                                          Retencion,            
                                          Anticipo,                    
                                          Total,                
                                          Dias,        
                                          FechaPago,               
                                          Moneda,         
                                          TipoCambio,                
                                          LiberaEjec,            
                                          Ejecutivo,   
                                          LiberaGerente,   
                                          Gerente,   
                                          Aplica,   
                                          AplicaID,   
                                          ImporteDesc,      
                                          Parcial,                        
                                          IDAplica,         
                                          Seleccionar,    
                                          NoDPP  
                                      )        
  
  SELECT DISTINCT                         c.ID,                       
                                      c.Empresa,     
                                          c.Mov,                                                        
                                          c.MovID,                                                                     
                                          c.Cliente,                     
                                        Cte.Nombre,           
                                          c.Agente,                  
                                          c.FechaEmision,        
                                          c.Importe,            
                                          c.Impuestos,
										  ISNULL(NCA.Importe,0)  + ISNULL(NCNR.Importe,0),--JARC agrega notas de crédito
										  ISNULL(NCA.Impuestos,0),--JARC agrega notas de crédito
                                          c.Retencion,         
                                          ISNULL(P.IMPORTE, ISNULL(antc.anticipo, ant.Importe)) as Anticipo,    
                                          ISNULL(C.Saldo,0),    -- Total: Se reemplaza el saldo de la factura por el importe de la factura menos el valor de la nota de crédito aplicada   
                                          --ISNULL(ISNULL((C.Importe+ISNULL(C.Impuestos,0))-ISNULL(C.Retencion,0),0) - ISNULL((ISNULL(P.IMPORTE, ISNULL(antc.anticipo, ant.Importe))),0),0),
										  ISNULL(DATEDIFF(DD, C.FechaEmision, P.FechaOriginal),0), --*Dias    
                                          --ISNULL(P.FechaEmision,C.FechaEmision),
										  --ISNULL(P.FechaEmision,ISNULL(antc.FechaEmision,ISNULL(ant.FechaEmision,ISNULL(NC.FechaEmision,C.FechaEmision)))),
										  ISNULL(P.FechaOriginal,ISNULL(antc.FechaOriginal,ISNULL(ant.FechaOriginal,ISNULL(NC.FechaOriginal,ISNULL(C.FechaOriginal,ISNULL(P.FechaEmision,C.FechaEmision)))))),
                                          c.Moneda,           
                                          c.TipoCambio,   
                                          0,   
                                          @Agente,   
                                          0,   
                                          @Agente,      
                                          ISNULL(ant.Mov,''),   
                                          isnull(ant.MovID,''),  
                                          0,   
                                          ISNULL(P.Parcial,0),   
                                          ISNULL(p.id,C.ID),   
                                          0,   
                                          0  
  FROM CXC C        
  JOIN Cte ON C.Cliente = Cte.Cliente        
  JOIN MovTipo M ON C.Mov = M.Mov AND M.Modulo = 'CXC' AND M.CLAVE='CXC.F' --AND C.MOV='FACTURA'        
/***************************************** JARC se modifica la tabla para que devuelva un solo registro******************************************/
/***************************************** cobros y aplicaciones que en el detalle aplican a factura   ******************************************/
LEFT JOIN (
    SELECT  Aplica, AplicaID, ID, Importe, Parcial, Origen, OrigenID,
            Mov, MovID, FechaEmision, FechaOriginal
    FROM (
        SELECT  CD.Aplica, CD.AplicaID, C.ID, C.Parcial,
                Origen, OrigenID, C.Mov, C.MovID, C.FechaEmision, C.FechaOriginal,
                SUM(CD.Importe) OVER (PARTITION BY CD.Aplica, CD.AplicaID) AS Importe,   -- acumula el importe en 1 línea
                ROW_NUMBER()    OVER (PARTITION BY CD.Aplica, CD.AplicaID
                                      ORDER BY C.ID DESC) AS rn                          -- fila representativa (último cobro)
        FROM CXC C
        JOIN MovTipo M  ON C.Mov = M.Mov  AND M.Modulo='CXC' AND M.Clave IN ('CXC.C','CXC.ANC')
        JOIN CXCD CD    ON C.ID = CD.ID
        JOIN MovTipo M2 ON CD.Aplica = M2.Mov AND M2.Modulo='CXC' AND M2.Clave='CXC.F'
        WHERE C.Estatus IN ('PENDIENTE','CONCLUIDO') AND C.Empresa = @Empresa
    ) z
    WHERE z.rn = 1
) P ON C.Mov = P.Aplica AND C.MovID = P.AplicaID
/***************************************** Cobros y aplicaciones de anticipos   ******************************************/
  LEFT JOIN   (
                  SELECT  CD.Aplica, CD.AplicaID, c. ID, c.mov, c.movid, ABS(cd.importe) AS ANTICIPO, c.FechaEmision, C.FechaOriginal  --max(id)  
                  FROM CXC C         
                  JOIN MovTipo M ON C.Mov=M.Mov AND M.Modulo ='CXC' AND M.Clave IN ('CXC.C', 'CXC.ANC')      
                  JOIN CXCD CD ON C.ID = CD.ID        
                  JOIN MovTipo M2 ON CD.Aplica=M2.Mov AND M2.Modulo ='CXC' AND M2.Clave='CXC.A'        
                  WHERE C.ESTATUS in ('PENDIENTE','CONCLUIDO') and C.Empresa = @Empresa   
              )   antc on P.ID=ANTC.ID         
/***************************************** aplicaciones de notas de credito y anticipos   ******************************************/
  LEFT JOIN   (
				--SELECT Aplica,AplicaID,Importe,Origen,OrigenID,MOV,MovID,FechaEmision,FechaOriginal
				--FROM (
				--	SELECT cd.Aplica,cd.AplicaID,Origen,OrigenID,c.MOV,c.MovID,c.FechaEmision,c.FechaOriginal,
				--		SUM(cd.Importe) OVER (PARTITION BY cd.Aplica, cd.AplicaID) AS Importe,                                    -- acumula importe sin GROUP BY
				--		ROW_NUMBER() OVER (PARTITION BY cd.Aplica, cd.AplicaID ORDER BY c.ID DESC) AS rn                                          -- fila representativa por par Aplica/AplicaID
				--	FROM CXC c
				--	JOIN CXCD cd   ON c.ID  = cd.ID
				--	JOIN MovTipo m ON c.MOV = m.MOV 
				--				  AND m.MODULO = 'CXC' 
				--				  AND m.Clave  = 'CXC.ANC'              -- filtro original, solo anticipos
				--	WHERE c.Empresa = @Empresa
				--	  AND c.Estatus IN ('PENDIENTE', 'CONCLUIDO')
				--) z
				--WHERE z.rn = 1
				SELECT Aplica,AplicaID,Importe,Origen,OrigenID,MOV,MovID,FechaEmision,FechaOriginal
				FROM (
					SELECT cd.Aplica,cd.AplicaID,c.Origen,c.OrigenID,c.MOV,c.MovID,c.FechaEmision,c.FechaOriginal
					,SUM(cd.Importe) OVER (PARTITION BY cd.Aplica, cd.AplicaID) AS Importe,                                    -- acumula importe sin GROUP BY
					 ROW_NUMBER() OVER (PARTITION BY cd.Aplica, cd.AplicaID ORDER BY c.ID DESC) AS rn                                          -- fila representativa por par Aplica/AplicaID
					FROM CXC c
					JOIN CXCD cd   ON c.ID  = cd.ID
					JOIN MovTipo m ON c.MOV = m.MOV 
								  AND m.MODULO = 'CXC' 
								  AND m.Clave  = 'CXC.ANC'              -- filtro original, solo anticipos
					LEFT JOIN MovFlujo mf	ON mf.OMov = c.Origen AND mf.OMovID = c.OrigenID
					LEFT JOIN MovFlujo mf2	ON mf.OID = mf2.DID 
					WHERE c.Empresa = 'NVK'
					  AND c.Estatus IN ('PENDIENTE', 'CONCLUIDO')
					  AND cd.Aplica <> 'Redondeo'
					  and c.ID = mf.DID
					  AND mf2.OModulo <> 'VTAS'
				) z
				WHERE z.rn = 1
/*****************************************JARC se comentan las lineas de origen y origenid ya que se eliminan en la linea anterior******************************************/				  
              )   ant on c.Mov=ant.Aplica AND c.MovID=ant.AplicaID  AND P.Origen = ant.Origen AND P.OrigenID = ant.OrigenID       
/***************************************** notas de crédito pronto pago ******************************************/
  LEFT JOIN   (SELECT CD.Aplica, CD.AplicaID, C.ID, Referencia, c.FechaEmision, c.FechaOriginal      
                  FROM CXC  C      
                  JOIN MovTipo M ON C.Mov=M.MOV AND M.MODULO='CXC' AND SubClave='CXC.NCPP'      
                  JOIN CXCD CD ON C.ID=CD.ID      
                  WHERE C.ESTATUS='CONCLUIDO' AND C.Empresa = @Empresa  
              )   NC ON C.MOV=NC.Aplica AND C.MovID=NC.AplicaID and nc.Referencia=ant.mov+' '+ant.movid  
/***************************************** notas de crédito ******************************************/
  LEFT JOIN  (		
				SELECT CD.Aplica, CD.AplicaID, C.ID, C.Importe,C.Impuestos,Referencia, c.FechaEmision, c.FechaOriginal      
                  FROM CXC  C      
                  JOIN MovTipo M ON C.Mov=M.MOV AND M.MODULO='CXC' AND Clave='CXC.NC'   
                  JOIN CXCD CD ON C.ID=CD.ID      
                  WHERE C.ESTATUS='CONCLUIDO' AND C.Empresa = @Empresa --AND M.SubClave <> 'CXC.NCPP'
				    AND M.Mov IN ('Cancel Sat Ingresos',
								'Nota Cliente',	
								'Nota Cliente Vta',
								'Nota Cred Comercial',
								'Nota Cred Finanzas',
								'Nota Cred Refactura',
								'Nota Credito',
								'Nota Credito PP',
								'Nota Credito SI',
								'Nota Credito Temp')
			) NCA ON C.Mov = NCA.Aplica AND C.MovID = NCA.AplicaID	
/***************************************** JARC Aplicacinones NC no referenciadas ******************************************/
  LEFT JOIN (
  --SELECT C.Origen,C.OrigenID,d.Aplica,d.AplicaID,d.Importe
  --  FROM Cxc		c
  --  LEFT JOIN		MovTipo		mt ON mt.Mov=c.Mov AND mt.Modulo='CXC' AND mt.Clave = 'CXC.ANC'
  --  LEFT JOIN		MovFlujo	mf ON c.Mov = mf.dmov AND c.MovID = mf.DMovID
  --  JOIN			CxcD		d  ON d.ID  = c.ID
  -- WHERE  C.Empresa = @Empresa
  --   AND mf.DModulo = 'CXC'
  --   AND d.Aplica   NOT IN ('Redondeo')
  --   AND mf.OMov    IN ('Cancel Sat Ingresos',
		--				'Nota Cliente',	
		--				'Nota Cliente Vta',
		--				'Nota Cred Comercial',
		--				'Nota Cred Finanzas',
		--				'Nota Cred Refactura',
		--				'Nota Credito',
		--				'Nota Credito PP',
		--				'Nota Credito SI',
		--				'Nota Credito Temp')

SELECT mf2.OModulo,mf2.OMov,mf2.OMovID,C.Origen,C.OrigenID,d.Aplica,d.AplicaID,d.Importe
    FROM Cxc		c
    LEFT JOIN		MovTipo		mt ON mt.Mov=c.Mov AND mt.Modulo='CXC' --AND mt.Clave = 'CXC.ANC'
    LEFT JOIN		MovFlujo	mf ON c.Mov = mf.dmov AND c.MovID = mf.DMovID
	LEFT JOIN		MovFlujo	mf2 ON mf.OID = mf2.DID
    JOIN			CxcD		d  ON d.ID  = c.ID
   WHERE  C.Empresa = 'NVK'
     AND mf.DModulo = 'CXC'
     AND d.Aplica   NOT IN ('Redondeo')
	 AND mf2.OModulo = 'VTAS'
	 AND mf2.OMov IN ('Bonificacion Venta','Devolucion Venta')
	 AND c.Estatus = 'CONCLUIDO'
	 AND mt.Clave = 'CXC.ANC'
			)NCNR ON NCNR.Aplica = c.mov AND NCNR.AplicaID = c.Movid			
  WHERE c.Empresa = @Empresa AND c.Estatus IN ('PENDIENTE','CONCLUIDO')        
  AND C.FechaEmision BETWEEN @FechaD AND @FechaA        
  AND NC.Referencia IS NULL  
 END  
    ELSE     --- *!Caso contrario de tipo ejecutivo  
    BEGIN  
  INSERT INTO #NaviExploraProntoPago   (    
                                          ID,          
                                          Empresa,                  
                                          Mov,                  
                                          MovID,                  
                                          Cliente,                      
                                          NombreCte,                
                                          Agente,                   
                                          FechaEmision,     
                                          Importe,               
                                          IVA,
										  ImporteNC,--JARC agrega notas de crédito
										  IVANC,--JARC agrega notas de crédito										  
                                          Retencion,            
                                          Anticipo,          
                                          Total,                    
                                          Dias,                                                      
                                          FechaPago,                
                                          Moneda,                   
                                          TipoCambio,                
                                          LiberaEjec,          
                                          Ejecutivo,   
                                          Aplica,   
                                          AplicaID,     
                                          ImporteDesc,   
                                          Parcial,   
                                          IDAplica,   
                                          Seleccionar,   
                                          NoDPP  
                                      )        
  SELECT DISTINCT                         c.ID,                  
                                          c.Empresa,               
                                          c.Mov,                 
                                          c.MovID,                                                                     
                            c.Cliente,          
                                          Cte.Nombre,            
                                          c.Agente,                
                                          c.FechaEmision,     
                                          c.Importe,
                                          c.Impuestos,
										  ISNULL(NCA.Importe,0) + ISNULL(NCNR.Importe,0),--JARC agrega notas de crédito
										  ISNULL(NCA.Impuestos,0),--JARC agrega notas de crédito										  
                                          c.Retencion,         
                                          ISNULL(P.IMPORTE, ISNULL(antc.anticipo, ant.Importe)) as Anticipo,    
                                          ISNULL(C.Saldo,0), /*.Importe+ISNULL(c.Impuestos,0)-ISNULL(c.Retencion,0)- ISNULL(antc.anticipo, ant.Importe) as Total*/        
                                          --ISNULL(ISNULL((C.Importe+ISNULL(C.Impuestos,0))-ISNULL(C.Retencion,0),0) - ISNULL((ISNULL(P.IMPORTE, ISNULL(antc.anticipo, ant.Importe))),0),0),
										  ISNULL(DATEDIFF(DD, C.FechaEmision, P.FechaOriginal),0),    -- *Dias  
                                          --ISNULL(P.FechaEmision, C.FechaEmision),    
										  --ISNULL(P.FechaEmision,ISNULL(antc.FechaEmision,ISNULL(ant.FechaEmision,ISNULL(NC.FechaEmision,C.FechaEmision)))),
										  ISNULL(P.FechaOriginal,ISNULL(antc.FechaOriginal,ISNULL(ant.FechaOriginal,ISNULL(NC.FechaOriginal,C.FechaOriginal)))),
                                          c.Moneda,           
                                          c.TipoCambio,   
                                          0,   
                                          @Agente,        
                                          ISNULL(ant.Mov,''),   
                                          ISNULL(ant.MovID,''),  
                                          0,   
                                          Isnull(P.Parcial, 0),   
                                          ISNULL(p.id, C.ID),   
                                          0,   
                                          0   
  FROM CXC C    
  JOIN Cte ON C.Cliente = Cte.Cliente        
  JOIN MovTipo M ON C.Mov = M.Mov AND M.Modulo = 'CXC' AND M.CLAVE='CXC.F' --AND C.MOV='FACTURA'        
/***************************************** JARC se modifica la tabla para que devuelva un solo registro******************************************/
/***************************************** cobros y aplicaciones que en el detalle aplican a factura   ******************************************/
LEFT JOIN (
    SELECT  Aplica, AplicaID, ID, Importe, Parcial, Origen, OrigenID,
            Mov, MovID, FechaEmision, FechaOriginal
    FROM (
        SELECT  CD.Aplica, CD.AplicaID, C.ID, C.Parcial,
                Origen, OrigenID, C.Mov, C.MovID, C.FechaEmision, C.FechaOriginal,
                SUM(CD.Importe) OVER (PARTITION BY CD.Aplica, CD.AplicaID) AS Importe,   -- acumula el importe en 1 línea
                ROW_NUMBER()    OVER (PARTITION BY CD.Aplica, CD.AplicaID
                                      ORDER BY C.ID DESC) AS rn                          -- fila representativa (último cobro)
        FROM CXC C
        JOIN MovTipo M  ON C.Mov = M.Mov  AND M.Modulo='CXC' AND M.Clave IN ('CXC.C','CXC.ANC')
        JOIN CXCD CD    ON C.ID = CD.ID
        JOIN MovTipo M2 ON CD.Aplica = M2.Mov AND M2.Modulo='CXC' AND M2.Clave='CXC.F'
        WHERE C.Estatus IN ('PENDIENTE','CONCLUIDO') AND C.Empresa = @Empresa
    ) z
    WHERE z.rn = 1
) P ON C.Mov = P.Aplica AND C.MovID = P.AplicaID
/***************************************** Cobros y aplicaciones de anticipos   ******************************************/
  LEFT JOIN   (   
                  SELECT  CD.Aplica, CD.AplicaID, c. ID, c.mov, c.movid, ABS(cd.importe) AS ANTICIPO, c.FechaEmision, C.FechaOriginal  --max(id)  
                  FROM CXC C         
                  JOIN MovTipo M ON C.Mov=M.Mov AND M.Modulo ='CXC' AND M.Clave IN ('CXC.C', 'CXC.ANC')      
                  JOIN CXCD CD ON C.ID = CD.ID        
                  JOIN MovTipo M2 ON CD.Aplica=M2.Mov AND M2.Modulo ='CXC' AND M2.Clave='CXC.A'        
                  WHERE C.ESTATUS in ('PENDIENTE','CONCLUIDO') AND C.Empresa = @Empresa   
              )   antc on P.ID=ANTC.ID
/***************************************** aplicaciones de notas de credito y anticipos   ******************************************/			  
  LEFT JOIN   (
					--SELECT Aplica,AplicaID,Importe,Origen,OrigenID,MOV,MovID,FechaEmision,FechaOriginal
					--FROM (
					--	SELECT cd.Aplica,cd.AplicaID,Origen,OrigenID,c.MOV,c.MovID,c.FechaEmision,c.FechaOriginal,
					--		SUM(cd.Importe) OVER (PARTITION BY cd.Aplica, cd.AplicaID) AS Importe,                                    -- acumula importe sin GROUP BY
					--		ROW_NUMBER() OVER (PARTITION BY cd.Aplica, cd.AplicaID ORDER BY c.ID DESC) AS rn                                          -- fila representativa por par Aplica/AplicaID
					--	FROM CXC c
					--	JOIN CXCD cd   ON c.ID  = cd.ID
					--	JOIN MovTipo m ON c.MOV = m.MOV 
					--				  AND m.MODULO = 'CXC' 
					--				  AND m.Clave  = 'CXC.ANC'              -- filtro original, solo anticipos
					--	WHERE c.Empresa = @Empresa
					--	  AND c.Estatus IN ('PENDIENTE', 'CONCLUIDO')
					--) z
					--WHERE z.rn = 1

				SELECT Aplica,AplicaID,Importe,Origen,OrigenID,MOV,MovID,FechaEmision,FechaOriginal
				FROM (
					SELECT cd.Aplica,cd.AplicaID,c.Origen,c.OrigenID,c.MOV,c.MovID,c.FechaEmision,c.FechaOriginal
					,SUM(cd.Importe) OVER (PARTITION BY cd.Aplica, cd.AplicaID) AS Importe,                                    -- acumula importe sin GROUP BY
					 ROW_NUMBER() OVER (PARTITION BY cd.Aplica, cd.AplicaID ORDER BY c.ID DESC) AS rn                                          -- fila representativa por par Aplica/AplicaID
					FROM CXC c
					JOIN CXCD cd   ON c.ID  = cd.ID
					JOIN MovTipo m ON c.MOV = m.MOV 
								  AND m.MODULO = 'CXC' 
								  AND m.Clave  = 'CXC.ANC'              -- filtro original, solo anticipos
					LEFT JOIN MovFlujo mf	ON mf.OMov = c.Origen AND mf.OMovID = c.OrigenID
					LEFT JOIN MovFlujo mf2	ON mf.OID = mf2.DID 
					WHERE c.Empresa = 'NVK'
					  AND c.Estatus IN ('PENDIENTE', 'CONCLUIDO')
					  AND cd.Aplica <> 'Redondeo'
					  and c.ID = mf.DID
					  AND mf2.OModulo <> 'VTAS'
				) z
				WHERE z.rn = 1
/*****************************************JARC se comentan las lineas de origen y origenid ya que se eliminan en la linea anterior******************************************/				  
              )   ant on c.Mov=ant.Aplica AND c.MovID=ant.AplicaID  AND P.Origen = ant.Origen AND P.OrigenID = ant.OrigenID
/***************************************** notas de crédito pronto pago ******************************************/				  
  LEFT JOIN   (  
                  SELECT CD.Aplica, CD.AplicaID, C.ID, c.Referencia, c.FechaEmision, c.FechaOriginal      
                  FROM CXC  C      
                  JOIN MovTipo M ON C.Mov=M.MOV AND M.MODULO='CXC' AND SubClave='CXC.NCPP'      
                  JOIN CXCD CD ON C.ID=CD.ID      
                  WHERE C.ESTATUS='CONCLUIDO' AND C.Empresa = @Empresa  
              )   NC ON C.MOV=NC.Aplica AND C.MovID=NC.AplicaID and nc.Referencia=ant.mov+' '+ant.movid
/***************************************** notas de crédito ******************************************/
  LEFT JOIN  (		
				SELECT CD.Aplica, CD.AplicaID, C.ID, C.Importe,C.Impuestos,Referencia, c.FechaEmision, c.FechaOriginal      
                  FROM CXC  C      
                  JOIN MovTipo M ON C.Mov=M.MOV AND M.MODULO='CXC' AND Clave='CXC.NC'   
                  JOIN CXCD CD ON C.ID=CD.ID      
                  WHERE C.ESTATUS='CONCLUIDO' AND C.Empresa = @Empresa --AND M.SubClave <> 'CXC.NCPP'
				    AND M.Mov IN ('Cancel Sat Ingresos',
								'Nota Cliente',	
								'Nota Cliente Vta',
								'Nota Cred Comercial',
								'Nota Cred Finanzas',
								'Nota Cred Refactura',
								'Nota Credito',
								'Nota Credito PP',
								'Nota Credito SI',
								'Nota Credito Temp')
			) NCA ON C.Mov = NCA.Aplica AND C.MovID = NCA.AplicaID
/***************************************** JARC Aplicacinones NC no referenciadas ******************************************/
  LEFT JOIN (
  --SELECT C.Origen,C.OrigenID,d.Aplica,d.AplicaID,d.Importe
  --  FROM Cxc		c
  --  LEFT JOIN		MovTipo		mt ON mt.Mov=c.Mov AND mt.Modulo='CXC' AND mt.Clave = 'CXC.ANC'
  --  LEFT JOIN		MovFlujo	mf ON c.Mov = mf.dmov AND c.MovID = mf.DMovID
  --  JOIN			CxcD		d  ON d.ID  = c.ID
  -- WHERE  C.Empresa = @Empresa
  --   AND mf.DModulo = 'CXC'
  --   AND d.Aplica   NOT IN ('Redondeo')
  --   AND mf.OMov    IN ('Cancel Sat Ingresos',
		--				'Nota Cliente',	
		--				'Nota Cliente Vta',
		--				'Nota Cred Comercial',
		--				'Nota Cred Finanzas',
		--				'Nota Cred Refactura',
		--				'Nota Credito',
		--				'Nota Credito PP',
		--				'Nota Credito SI',
		--				'Nota Credito Temp')
SELECT mf2.OModulo,mf2.OMov,mf2.OMovID,C.Origen,C.OrigenID,d.Aplica,d.AplicaID,d.Importe
    FROM Cxc		c
    LEFT JOIN		MovTipo		mt ON mt.Mov=c.Mov AND mt.Modulo='CXC' --AND mt.Clave = 'CXC.ANC'
    LEFT JOIN		MovFlujo	mf ON c.Mov = mf.dmov AND c.MovID = mf.DMovID
	LEFT JOIN		MovFlujo	mf2 ON mf.OID = mf2.DID
    JOIN			CxcD		d  ON d.ID  = c.ID
   WHERE  C.Empresa = 'NVK'
     AND mf.DModulo = 'CXC'
     AND d.Aplica   NOT IN ('Redondeo')
	 AND mf2.OModulo = 'VTAS'
	 AND mf2.OMov IN ('Bonificacion Venta','Devolucion Venta')
	 AND c.Estatus = 'CONCLUIDO'
	 AND mt.Clave = 'CXC.ANC'
			)NCNR ON NCNR.Aplica = c.mov AND NCNR.AplicaID = c.Movid
			
  WHERE c.Empresa = @Empresa AND c.Estatus IN ('PENDIENTE','CONCLUIDO')        
  AND C.FechaEmision BETWEEN @FechaD AND @FechaA        
  AND C.agente in (SELECT  agente from agente where ReportaA=@Agente)       
  AND NC.Referencia IS NULL        
 END  
 
    DELETE FROM #NaviExploraProntoPago WHERE LEN(Anticipo)=0 AND Empresa = @Empresa --*!Elimina el registro insertado cuyo anticipo sea 0  
  
    UPDATE N SET    Descuento=ISNULL(C.Descuento,0),    
                    ImporteDesc =   
					CASE WHEN ISNULL( N.Parcial,0)=0  
                                        THEN ( (Importe+ISNULL(IVA,0)) - (ISNULL(ImporteNC,0)+ISNULL(IVANC,0))  )*(ISNULL(C.Descuento,0)/100)  -- Importe de la factura, JARC se restán notas de crédito
										--THEN	(ISNULL(Total,0))*(ISNULL(C.Descuento,0)/100) -- Saldo de la factura
                                    ELSE  Anticipo*(ISNULL(C.Descuento,0)/100)    
                                    END      
    FROM #NaviExploraProntoPago N        
    JOIN NaviCfgDescuento C on n.dias BETWEEN   CASE WHEN CHARINDEX('A', rangodia,  1)=0   
                                                    THEN SUBSTRING(RANGODIA, 1, CHARINDEX('O', rangodia,  1)-1)   
                                                ELSE SUBSTRING(RANGODIA, 1, CHARINDEX('A', rangodia,  1)-1)   
                                                END    
    AND CASE WHEN charindex('A', rangodia,  1)=0   
            THEN 10000   
        ELSE SUBSTRING(RANGODIA, CHARINDEX('A', rangodia,  2)+2, 2)   
        END     
    AND N.Empresa = C.Empresa    
    WHERE N.Empresa = @Empresa   
  
  
    UPDATE #NaviExploraProntoPago SET Aplica=Mov, AplicaID=MovID WHERE LEN(Aplica) = 0 AND LEN(AplicaID)=0 AND Empresa = @Empresa 
    --DELETE FROM #NaviExploraProntoPago WHERE IDAplica IN (SELECT ID FROM Cxc WHERE ISNULL(NoDPP,0) = 1 AND Empresa = @Empresa) AND Empresa = @Empresa  
    DELETE FROM #NaviExploraProntoPago WHERE ISNULL(ImporteDesc,0)<1  
  
    DELETE FROM #NaviExploraProntoPago   
    FROM #NaviExploraProntoPago n      LEFT JOIN   (  
                    SELECT  c.ID, cd.Aplica+' '+cd.AplicaID AS Aplica, c.Empresa, c.mov, c.movid  
                    FROM Cxc c   
                    JOIN CxcD cd ON c.ID = cd.ID   
                    JOIN Movtipo m on m.Modulo ='CXC' AND c.Mov=m.Mov AND m.SubClave='CXC.NCPP'   
                    JOIN CxcAplica cx ON cd.Aplica=cx.Mov AND cd.AplicaID=cx.MovID AND c.Empresa = cx.Empresa AND ISNULL(cx.Saldo,0)=0  
                    WHERE c.Estatus='CONCLUIDO' AND cd.Aplica NOT IN ('REDONDEO')   
                )   nc ON n.Mov+' '+n.MovID = nc.Aplica   
    AND n.Empresa=nc.Empresa  
    WHERE n.Empresa=@Empresa    
    AND nc.ID IS not NULL   
  
 IF @DIAS <>0  
  DELETE FROM #NaviExploraProntoPago WHERE Dias > @DIAS  
 ELSE  
  DELETE FROM #NaviExploraProntoPago WHERE Total = 0  

  
 DECLARE crInsertaNaviExploraProntoPago CURSOR FAST_FORWARD FOR  
 SELECT ID,  
   Empresa,  
   Mov,  
   MovID,  
   FechaPago,  
   Aplica,  
   AplicaID,  
   IDAplica  
 FROM #NaviExploraProntoPago
  
 OPEN crInsertaNaviExploraProntoPago  
 FETCH NEXT FROM crInsertaNaviExploraProntoPago INTO @IDInsertar,@EmpresaInsertar,@MovInsertar,@MovIDInsertar,@FechaPagoInsertar,@AplicaInsertar,@AplicaIDInsertar,@IDAplicaInsertar  
  
 WHILE @@FETCH_STATUS = 0  
 BEGIN  
  IF EXISTS (  
      SELECT TOP (1)   
       0   
      FROM NaviExploraProntoPago   
      WHERE ID = @IDInsertar   
      AND  Empresa = @EmpresaInsertar   
      AND  Mov = @MovInsertar   
      AND  MovID = @MovIDInsertar   
      --AND  FechaPago = @FechaPagoInsertar   
      AND  Aplica = @AplicaInsertar   
      AND  AplicaID = @AplicaIDInsertar  
      AND  IDAplica = @IDAplicaInsertar  
      --AND     Seleccionar = 1  
     )  
  BEGIN  

   SELECT TOP(1) @Seleccionar = Seleccionar, @LiberarEjecutivoS = LiberaEjec, @LiberaGerenteS = LiberaGerente, @ProcesadoM = Procesado, @Eliminar = NoDPP, @ImporteTotalX = Total, @DescuentoX = ImporteDesc, @Modificar = Modificar  FROM NaviExploraProntoPago WHERE ID = @IDInsertar AND  Empresa = @EmpresaInsertar AND  Mov = @MovInsertar AND  MovID = @MovIDInsertar /*AND  FechaPago = @FechaPagoInsertar*/ AND  Aplica = @AplicaInsertar AND  AplicaID = @AplicaIDInsertar AND IDAplica = @IDAplicaInsertar  
   DELETE FROM NaviExploraProntoPago 
    WHERE ID = @IDInsertar 
 	  AND Empresa = @EmpresaInsertar 
	  AND Mov = @MovInsertar 
	  AND MovID = @MovIDInsertar 
	  /*AND FechaPago = @FechaPagoInsertar*/ 
	  AND Aplica = @AplicaInsertar 
	  AND AplicaID = @AplicaIDInsertar 
	  AND IDAplica = @IDAplicaInsertar 
	  AND ISNULL(Seleccionar,0) = ISNULL(@Seleccionar,0) 
	  AND ISNULL(LiberaEjec,0) = ISNULL(@LiberarEjecutivoS,0) 
	  AND ISNULL(LiberaGerente,0) = ISNULL(@LiberaGerenteS,0) 
	  AND ISNULL(Procesado,0) = ISNULL(@ProcesadoM,0) 
	  AND ISNULL(@Eliminar,0) = ISNULL(NoDPP,0)   
   INSERT INTO NaviExploraProntoPago  
   SELECT  
   ID    ,  
   Empresa   ,  
   Mov    ,  
   MovID   ,  
   Cliente   ,  
   NombreCte  ,  
   Agente   ,  
   FechaEmision  ,  
   Importe   ,  
   IVA    ,  
   Retencion  ,  
   Anticipo  ,  
   Total  ,
   Dias   ,  
   FechaPago  ,  
   Descuento  ,  
   IIF(ISNULL(@Modificar,0) = 0, ImporteDesc, @DescuentoX)  , --20250707 Se cambia el Importe que calcula nativamente la herramienta por el que modifica el usuario ImporteDesc se cambia por @DescuentoX  
   @LiberarEjecutivoS  ,  
   Ejecutivo  ,  
   @LiberaGerenteS  ,  
   Gerente   ,  
   Moneda   ,  
   TipoCambio  ,  
   @ProcesadoM  ,  
   Aplica   ,  
   AplicaID  ,  
   Parcial   ,  
   IDAplica  ,  
   @Seleccionar     ,  
   @Eliminar     ,
   @Modificar
   FROM #NaviExploraProntoPago  
   WHERE ID = @IDInsertar   
   AND  Empresa = @EmpresaInsertar   
   AND  Mov = @MovInsertar   
   AND  MovID = @MovIDInsertar   
   AND  FechaPago = @FechaPagoInsertar   
   AND  Aplica = @AplicaInsertar   
   AND  AplicaID = @AplicaIDInsertar  
   AND  IDAplica = @IDAplicaInsertar

   IF ISNULL(@Eliminar,0) = 1
   BEGIN
	  IF NOT EXISTS (  
      SELECT TOP (1)   
       0   
      FROM NaviExploraProntoPagoEliminadas   
      WHERE ID = @IDInsertar   
      AND  Empresa = @EmpresaInsertar   
      AND  Mov = @MovInsertar   
      AND  MovID = @MovIDInsertar   
      --AND  FechaPago = @FechaPagoInsertar   
      AND  Aplica = @AplicaInsertar   
      AND  AplicaID = @AplicaIDInsertar  
      AND  IDAplica = @IDAplicaInsertar  
      --AND     Seleccionar = 1
     ) 
	 BEGIN
		INSERT INTO NaviExploraProntoPagoEliminadas  
		SELECT  
		ID    ,  
		Empresa   ,  
		Mov    ,  
		MovID   ,  
		Cliente   ,  
		NombreCte  ,  
		Agente   ,  
		FechaEmision  ,  
		Importe   ,  
		IVA    ,  
		Retencion  ,  
		Anticipo  ,  
		Total   ,  
		Dias   ,  
		FechaPago  ,  
		Descuento  ,  
		ImporteDesc  ,  
		@LiberarEjecutivoS  ,  
		Ejecutivo  ,  
		@LiberaGerenteS  ,  
		Gerente   ,  
		Moneda   ,  
		TipoCambio  ,  
		@ProcesadoM  ,  
		Aplica   ,  
		AplicaID  ,  
		Parcial   ,  
		IDAplica  ,  
		@Seleccionar     ,  
		@Eliminar,
		0
		FROM #NaviExploraProntoPago  
		WHERE ID = @IDInsertar   
		AND  Empresa = @EmpresaInsertar   
		AND  Mov = @MovInsertar   
		AND  MovID = @MovIDInsertar   
		AND  FechaPago = @FechaPagoInsertar   
		AND  Aplica = @AplicaInsertar   
		AND  AplicaID = @AplicaIDInsertar  
		AND  IDAplica = @IDAplicaInsertar
	 END

   END

   FETCH NEXT FROM crInsertaNaviExploraProntoPago INTO @IDInsertar,@EmpresaInsertar,@MovInsertar,@MovIDInsertar,@FechaPagoInsertar,@AplicaInsertar,@AplicaIDInsertar,@IDAplicaInsertar  
  END  
  ELSE  
  BEGIN  
   INSERT INTO NaviExploraProntoPago 
   SELECT --JARC se omiten campos de nota cred
   --*
  ID,
  Empresa,
  Mov,
  MovID,
  Cliente,
  NombreCte,
  Agente,
  FechaEmision,
  Importe,
  IVA,
  Retencion,
  Anticipo,
  Total,
  Dias,
  FechaPago,
  Descuento,
  ImporteDesc,
  LiberaEjec,
  Ejecutivo,
  LiberaGerente,
  Gerente,
  Moneda,
  TipoCambio,
  Procesado,
  Aplica,
  AplicaID,
  Parcial,
  IDAplica,
  Seleccionar,
  NoDPP,
   0  
   FROM #NaviExploraProntoPago  
   WHERE ID = @IDInsertar   
   AND  Empresa = @EmpresaInsertar   
   AND  Mov = @MovInsertar   
   AND  MovID = @MovIDInsertar   
 AND  FechaPago = @FechaPagoInsertar   
   AND  Aplica = @AplicaInsertar   
   AND  AplicaID = @AplicaIDInsertar  
   AND  IDAplica = @IDAplicaInsertar  
   FETCH NEXT FROM crInsertaNaviExploraProntoPago INTO @IDInsertar,@EmpresaInsertar,@MovInsertar,@MovIDInsertar,@FechaPagoInsertar,@AplicaInsertar,@AplicaIDInsertar,@IDAplicaInsertar  
  END  
  
 END  
  
 CLOSE crInsertaNaviExploraProntoPago  
 DEALLOCATE crInsertaNaviExploraProntoPago  

 INSERT INTO NaviExploraProntoPagoEliminadas
 SELECT n.*
 FROM NaviExploraProntoPago n
 LEFT JOIN NaviExploraProntoPagoEliminadas n2 ON n.ID = n2.ID AND n.Empresa = n2.Empresa AND n.Mov = n2.Mov AND n.MovID = n2.MovID /*AND n.FechaPago = n2.FechaPago*/ AND n.Aplica = n2.Aplica AND n.AplicaID = n2.AplicaID AND n.IDAplica = n2.IDAplica
 WHERE n2.ID IS NULL AND n2.Empresa IS NULL AND n2.Mov IS NULL AND n2.MovID IS NULL AND n2.FechaPago IS NULL AND n2.Aplica  IS NULL AND n2.AplicaID IS NULL AND n2.IDAplica IS NULL AND ISNULL(n.NoDPP,0) = 1
	
	DELETE n FROM NaviExploraProntoPago n JOIN NaviExploraProntoPagoEliminadas n2 ON n.ID = n2.ID AND n.Empresa = n2.Empresa AND n.Mov = n2.Mov AND n.MovID = n2.MovID /*AND n.FechaPago = n2.FechaPago*/ AND n.Aplica = n2.Aplica AND n.AplicaID = n2.AplicaID AND n.IDAplica = n2.IDAplica
  
    SELECT n.ID, n.Empresa, n.Mov, n.MovID, Cliente, NombreCte, Agente, FechaEmision, Importe, IVA, Retencion, Anticipo, Total,   
    Dias, FechaPago, Descuento, ImporteDesc, LiberaEjec, Ejecutivo, LiberaGerente, Gerente, Moneda, TipoCambio,  
    Procesado, n.Aplica, AplicaID, Parcial, IDAplica, Seleccionar, ISNULL(NoDPP,0) NoDPP--, nc.mov, nc.MovID  
    FROM NaviExploraProntoPago n  
    WHERE n.Empresa=@Empresa  AND ISNULL(ImporteDesc,0)>1
    ORDER BY FechaEmision  
  
END
GO
/************     respaldo Producción
SET DATEFIRST 7
SET ANSI_NULLS OFF
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
SET LOCK_TIMEOUT -1
SET QUOTED_IDENTIFIER OFF
GO
IF EXISTS (SELECT 1 FROM SYSOBJECTS WHERE NAME = 'spNaviExploraProntoPago' AND TYPE = 'P')
DROP PROC dbo.spNaviExploraProntoPago
GO
CREATE PROCEDURE spNaviExploraProntoPago
    @Empresa  varchar(5),        
    @Agente  varchar(20),        
    @FechaD  datetime,        
    @FechaA  datetime,  
    @DIAS    varchar(20)  
--//WITH ENCRYPTION        
AS   
BEGIN        
      
 CREATE TABLE #NaviExploraProntoPago  
 (  
  ID    int    NOT NULL,  
  Empresa   varchar(20)  NOT NULL,  
  Mov    varchar(20)  NOT NULL,  
  MovID   varchar(20)  NOT NULL,  
  Cliente   varchar(20)   NULL,  
  NombreCte  varchar(100)   NULL,  
  Agente   varchar(20)   NULL,  
  FechaEmision  datetime    NULL,  
  Importe   float     NULL,  
  IVA    float     NULL,  
  Retencion  float     NULL,  
  Anticipo  float     NULL,  
  Total   float     NULL,  
  Dias   int     NULL,  
  FechaPago  datetime   NOT NULL,  
  Descuento  float     NULL,  
  ImporteDesc  float     NULL,  
  LiberaEjec  bit     NULL,  
  Ejecutivo  varchar(20)   NULL,  
  LiberaGerente  bit     NULL,  
  Gerente   varchar(20)   NULL,  
  Moneda   varchar(20)   NULL,  
  TipoCambio  float     NULL,  
  Procesado  bit     NULL,  
  Aplica   varchar(20)  NOT NULL,  
  AplicaID  varchar(20)  NOT NULL,  
  Parcial   bit     NULL,  
  IDAplica  int    NOT NULL,  
  Seleccionar  bit     NULL,  
  NoDPP   bit     NULL  
 )  
  
 DECLARE @IDInsertar   int,  
   @EmpresaInsertar varchar(5),  
   @MovInsertar  varchar(20),  
   @MovIDInsertar  varchar(20),  
   @FechaPagoInsertar datetime,  
   @AplicaInsertar  varchar(20),  
   @AplicaIDInsertar varchar(20),  
   @IDAplicaInsertar int,
   @Seleccionar	bit,
   @LiberarEjecutivoS bit,
   @LiberaGerenteS bit,
   @ProcesadoM bit,
   @Eliminar bit,
   @ImporteTotalX float,
   @DescuentoX float,
   @Modificar bit
  
    DECLARE @Tipo varchar(50)    
    --DELETE FROM NaviExploraProntoPago WHERE Empresa=@Empresa         --Esta parte elmina toda la tabla    
    SELECT @Tipo = TIPO FROM AGENTE WHERE AGENTE = @Agente      
  
    IF @tipo='DIRECTOR'   --172590  
 BEGIN  
  INSERT INTO #NaviExploraProntoPago   (  
                                          ID,                                
                                          Empresa,        
                                          Mov,                  
                                          MovID,                  
                                          Cliente,                      
                                          NombreCte,              
                                          Agente,           
                                          FechaEmision,            
                                          Importe,               
                                          IVA,                        
                                          Retencion,            
                                          Anticipo,                    
                                          Total,                
                                          Dias,        
                                          FechaPago,               
                                          Moneda,         
                                          TipoCambio,                
                                          LiberaEjec,            
                                          Ejecutivo,   
                                          LiberaGerente,   
                                          Gerente,   
                                          Aplica,   
                                          AplicaID,   
                                          ImporteDesc,      
                                          Parcial,                        
                                          IDAplica,         
                                          Seleccionar,    
                                          NoDPP  
                                      )        
  
  SELECT DISTINCT                         c.ID,                       
                                      c.Empresa,     
                                          c.Mov,                                                        
                                          c.MovID,                                                                     
                                          c.Cliente,                     
                                        Cte.Nombre,           
                                          c.Agente,                  
                                          c.FechaEmision,        
                                          c.Importe,            
                                          c.Impuestos,     
                                          c.Retencion,         
                                          ISNULL(P.IMPORTE, ISNULL(antc.anticipo, ant.Importe)) as Anticipo,    
                                          ISNULL(C.Saldo,0),    -- Total: Se reemplaza el saldo de la factura por el importe de la factura menos el valor de la nota de crédito aplicada   
                                          --ISNULL(ISNULL((C.Importe+ISNULL(C.Impuestos,0))-ISNULL(C.Retencion,0),0) - ISNULL((ISNULL(P.IMPORTE, ISNULL(antc.anticipo, ant.Importe))),0),0),
										  ISNULL(DATEDIFF(DD, C.FechaEmision, P.FechaOriginal),0), --*Dias    
                                          --ISNULL(P.FechaEmision,C.FechaEmision),
										  --ISNULL(P.FechaEmision,ISNULL(antc.FechaEmision,ISNULL(ant.FechaEmision,ISNULL(NC.FechaEmision,C.FechaEmision)))),
										  ISNULL(P.FechaOriginal,ISNULL(antc.FechaOriginal,ISNULL(ant.FechaOriginal,ISNULL(NC.FechaOriginal,ISNULL(C.FechaOriginal,ISNULL(P.FechaEmision,C.FechaEmision)))))),
                                          c.Moneda,           
                                          c.TipoCambio,   
                                          0,   
                                          @Agente,   
                                          0,   
                                          @Agente,      
                                          ISNULL(ant.Mov,''),   
                                          isnull(ant.MovID,''),  
                                          0,   
                                          ISNULL(P.Parcial,0),   
                                          ISNULL(p.id,C.ID),   
                                          0,   
                                          0  
  FROM CXC C        
  JOIN Cte ON C.Cliente = Cte.Cliente        
  JOIN MovTipo M ON C.Mov = M.Mov AND M.Modulo = 'CXC' AND M.CLAVE='CXC.F' --AND C.MOV='FACTURA'        
  LEFT JOIN   (   SELECT  CD.Aplica, CD.AplicaID, c. ID, cd.importe, c.Parcial, Origen, OrigenID,  C.Mov, C.MOVID, C.FechaEmision, C.FechaOriginal  --max(id)  
                  FROM CXC C         
                  JOIN MovTipo M ON C.Mov=M.Mov AND M.Modulo ='CXC' AND M.Clave IN ('CXC.C', 'CXC.ANC')      
                  JOIN CXCD CD ON C.ID = CD.ID        
                  JOIN MovTipo M2 ON CD.Aplica=M2.Mov AND M2.Modulo ='CXC' AND M2.Clave='CXC.F'        
                  WHERE C.ESTATUS in ('PENDIENTE','CONCLUIDO') AND C.Empresa = @Empresa   
              )   P ON C.MOV=P.APLICA AND C.MovID=P.AplicaID        
  LEFT JOIN   (   
                  SELECT  CD.Aplica, CD.AplicaID, c. ID, c.mov, c.movid, ABS(cd.importe) AS ANTICIPO, c.FechaEmision, C.FechaOriginal  --max(id)  
                  FROM CXC C         
                  JOIN MovTipo M ON C.Mov=M.Mov AND M.Modulo ='CXC' AND M.Clave IN ('CXC.C', 'CXC.ANC')      
                  JOIN CXCD CD ON C.ID = CD.ID        
                  JOIN MovTipo M2 ON CD.Aplica=M2.Mov AND M2.Modulo ='CXC' AND M2.Clave='CXC.A'        
                  WHERE C.ESTATUS in ('PENDIENTE','CONCLUIDO') and C.Empresa = @Empresa   
              )   antc on P.ID=ANTC.ID         
  LEFT JOIN   (     
                  SELECT  cd.Aplica, cd.AplicaID, SUM(cd.Importe) Importe, Origen, OrigenID, C.MOV, C.MovID, c.FechaEmision, C.FechaOriginal        
                  FROM CXC C        
                  JOIN CXCD CD ON C.ID = CD.ID        
                  JOIN MovTipo M ON C.MOV=M.MOV AND m.MODULO='CXC' and m.Clave='CXC.ANC'        
                  WHERE C.Empresa = @Empresa AND  
                  C.Estatus IN ('PENDIENTE', 'CONCLUIDO')       
                  GROUP BY CD.APLICA, CD.AplicaID, C.MOV, C.MovID,  Origen, OrigenID, c.FechaEmision, c.FechaOriginal       
              )   ant on c.Mov=ant.Aplica AND c.MovID=ant.AplicaID  AND P.Origen = ant.Origen AND P.OrigenID = ant.OrigenID       
  LEFT JOIN   (   SELECT CD.Aplica, CD.AplicaID, C.ID, Referencia, c.FechaEmision, c.FechaOriginal      
                  FROM CXC  C      
                  --JOIN MovTipo M ON C.Mov=M.MOV AND M.MODULO='CXC' AND SubClave='CXC.NCPP'      
                  --JOIN CXCD CD ON C.ID=CD.ID      
                  --WHERE C.ESTATUS='CONCLUIDO' AND C.Empresa = @Empresa
				  JOIN MovTipo M ON C.Mov=M.MOV AND M.MODULO='CXC' AND Clave='CXC.NC' 
				  AND c.Mov IN ('Cancel Sat Ingresos',
								'Nota Cliente',	
								'Nota Cliente Vta',
								'Nota Cred Comercial',
								'Nota Cred Finanzas',
								'Nota Cred Refactura',
								'Nota Credito',
								'Nota Credito PP',
								'Nota Credito SI',
								'Nota Credito Temp')
                  JOIN CXCD CD ON C.ID=CD.ID      
                  WHERE C.ESTATUS='CONCLUIDO' AND C.Empresa = @Empresa  
              )   NC ON C.MOV=NC.Aplica AND C.MovID=NC.AplicaID and nc.Referencia=ant.mov+' '+ant.movid    
  WHERE c.Empresa = @Empresa AND c.Estatus IN ('PENDIENTE','CONCLUIDO')        
  AND C.FechaEmision BETWEEN @FechaD AND @FechaA        
  AND NC.Referencia IS NULL  
 END  
    ELSE     --- *!Caso contrario de tipo ejecutivo  
    BEGIN  
  INSERT INTO #NaviExploraProntoPago   (    
                                          ID,          
                                          Empresa,                  
                                          Mov,                  
                                          MovID,                  
                                          Cliente,                      
                                          NombreCte,                
                                          Agente,                   
                                          FechaEmision,     
                                          Importe,               
                                          IVA,                        
                                          Retencion,            
                                          Anticipo,          
                                          Total,                    
                                          Dias,                                                      
                                          FechaPago,                
                                          Moneda,                   
                                          TipoCambio,                
                                          LiberaEjec,          
                                          Ejecutivo,   
                                          Aplica,   
                                          AplicaID,     
                                          ImporteDesc,   
                                          Parcial,   
                                          IDAplica,   
                                          Seleccionar,   
                                          NoDPP  
                                      )        
  SELECT DISTINCT                         c.ID,                  
                                          c.Empresa,               
                                          c.Mov,                 
                                          c.MovID,                                                                     
                            c.Cliente,          
                                          Cte.Nombre,            
                                          c.Agente,                
                                          c.FechaEmision,     
                                          c.Importe,            
                                          c.Impuestos,       
                                          c.Retencion,         
                                          ISNULL(P.IMPORTE, ISNULL(antc.anticipo, ant.Importe)) as Anticipo,    
                                          ISNULL(C.Saldo,0), /*.Importe+ISNULL(c.Impuestos,0)-ISNULL(c.Retencion,0)- ISNULL(antc.anticipo, ant.Importe) as Total*/        
                                          --ISNULL(ISNULL((C.Importe+ISNULL(C.Impuestos,0))-ISNULL(C.Retencion,0),0) - ISNULL((ISNULL(P.IMPORTE, ISNULL(antc.anticipo, ant.Importe))),0),0),
										  ISNULL(DATEDIFF(DD, C.FechaEmision, P.FechaOriginal),0),    -- *Dias  
                                          --ISNULL(P.FechaEmision, C.FechaEmision),    
										  --ISNULL(P.FechaEmision,ISNULL(antc.FechaEmision,ISNULL(ant.FechaEmision,ISNULL(NC.FechaEmision,C.FechaEmision)))),
										  ISNULL(P.FechaOriginal,ISNULL(antc.FechaOriginal,ISNULL(ant.FechaOriginal,ISNULL(NC.FechaOriginal,C.FechaOriginal)))),
                                          c.Moneda,           
                                          c.TipoCambio,   
                                          0,   
                                          @Agente,        
                                          ISNULL(ant.Mov,''),   
                                          ISNULL(ant.MovID,''),  
                                          0,   
                                          Isnull(P.Parcial, 0),   
                                          ISNULL(p.id, C.ID),   
                                          0,   
                                          0   
  FROM CXC C    
  JOIN Cte ON C.Cliente = Cte.Cliente        
  JOIN MovTipo M ON C.Mov = M.Mov AND M.Modulo = 'CXC' AND M.CLAVE='CXC.F' --AND C.MOV='FACTURA'        
  LEFT JOIN   (   
                  SELECT  CD.Aplica, CD.AplicaID,  c. ID, cd.importe, c.Parcial, Origen, OrigenID,  C.Mov, C.MOVID, C.FechaEmision, C.FechaOriginal      
                  FROM CXC C         
                  JOIN MovTipo M ON C.Mov=M.Mov AND M.Modulo ='CXC' AND M.Clave IN ('CXC.C', 'CXC.ANC')      
                  JOIN CXCD CD ON C.ID = CD.ID        
                  JOIN MovTipo M2 ON CD.Aplica=M2.Mov AND M2.Modulo ='CXC' AND M2.Clave='CXC.F'        
                  WHERE C.ESTATUS in ('PENDIENTE','CONCLUIDO') AND C.Empresa = @Empresa  
              )   P ON C.MOV=P.APLICA AND C.MovID=P.AplicaID        
  LEFT JOIN   (   
                  SELECT  CD.Aplica, CD.AplicaID, c. ID, c.mov, c.movid, ABS(cd.importe) AS ANTICIPO, c.FechaEmision, C.FechaOriginal  --max(id)  
                  FROM CXC C         
                  JOIN MovTipo M ON C.Mov=M.Mov AND M.Modulo ='CXC' AND M.Clave IN ('CXC.C', 'CXC.ANC')      
                  JOIN CXCD CD ON C.ID = CD.ID        
                  JOIN MovTipo M2 ON CD.Aplica=M2.Mov AND M2.Modulo ='CXC' AND M2.Clave='CXC.A'        
                  WHERE C.ESTATUS in ('PENDIENTE','CONCLUIDO') AND C.Empresa = @Empresa   
              )   antc on P.ID=ANTC.ID         
  LEFT JOIN   (  
                  SELECT  cd.Aplica, cd.AplicaID, SUM(cd.Importe) Importe, C.MOV, C.MovID, Origen, OrigenID, c.FechaEmision, c.FechaOriginal         
                  FROM CXC C        
                  JOIN CXCD CD ON C.ID = CD.ID        
                  JOIN MovTipo M ON C.MOV=M.MOV AND m.MODULO='CXC' and m.Clave='CXC.ANC'        
                  WHERE C.Empresa = @Empresa AND C.Estatus IN ('PENDIENTE', 'CONCLUIDO')       
                  GROUP BY CD.APLICA, CD.AplicaID, C.MOV, C.MovID, Origen, OrigenID, c.FechaEmision, c.FechaOriginal        
              )   ant on c.Mov=ant.Aplica AND c.MovID=ant.AplicaID  AND P.Origen = ant.Origen AND P.OrigenID = ant.OrigenID       
  LEFT JOIN   (  
                  SELECT CD.Aplica, CD.AplicaID, C.ID, c.Referencia, c.FechaEmision, c.FechaOriginal      
                  FROM CXC  C      
                  --JOIN MovTipo M ON C.Mov=M.MOV AND M.MODULO='CXC' AND SubClave='CXC.NCPP'      
                  --JOIN CXCD CD ON C.ID=CD.ID      
                  --WHERE C.ESTATUS='CONCLUIDO' AND C.Empresa = @Empresa  
				  JOIN MovTipo M ON C.Mov=M.MOV AND M.MODULO='CXC' AND Clave='CXC.NC' 
				  AND c.Mov IN ('Cancel Sat Ingresos',
								'Nota Cliente',	
								'Nota Cliente Vta',
								'Nota Cred Comercial',
								'Nota Cred Finanzas',
								'Nota Cred Refactura',
								'Nota Credito',
								'Nota Credito PP',
								'Nota Credito SI',
								'Nota Credito Temp')
                  JOIN CXCD CD ON C.ID=CD.ID      
                  WHERE C.ESTATUS='CONCLUIDO' AND C.Empresa = @Empresa 
              )   NC ON C.MOV=NC.Aplica AND C.MovID=NC.AplicaID and nc.Referencia=ant.mov+' '+ant.movid      
  WHERE c.Empresa = @Empresa AND c.Estatus IN ('PENDIENTE','CONCLUIDO')        
  AND C.FechaEmision BETWEEN @FechaD AND @FechaA        
  AND C.agente in (SELECT  agente from agente where ReportaA=@Agente)       
  AND NC.Referencia IS NULL        
 END  

    DELETE FROM #NaviExploraProntoPago WHERE LEN(Anticipo)=0 AND Empresa = @Empresa --*!Elimina el registro insertado cuyo anticipo sea 0  
  
    UPDATE N SET    Descuento=ISNULL(C.Descuento,0),    
                    ImporteDesc =   CASE WHEN ISNULL( N.Parcial,0)=0  
                                        THEN  (Importe+ISNULL(IVA,0))*(ISNULL(C.Descuento,0)/100)  -- Importe de la factura
										--THEN	(ISNULL(Total,0))*(ISNULL(C.Descuento,0)/100) -- Saldo de la factura
                                    ELSE  Anticipo*(ISNULL(C.Descuento,0)/100)    
                                    END      
    FROM #NaviExploraProntoPago N        
    JOIN NaviCfgDescuento C on n.dias BETWEEN   CASE WHEN CHARINDEX('A', rangodia,  1)=0   
                                                    THEN SUBSTRING(RANGODIA, 1, CHARINDEX('O', rangodia,  1)-1)   
                                                ELSE SUBSTRING(RANGODIA, 1, CHARINDEX('A', rangodia,  1)-1)   
                                                END    
    AND CASE WHEN charindex('A', rangodia,  1)=0   
            THEN 10000   
        ELSE SUBSTRING(RANGODIA, CHARINDEX('A', rangodia,  2)+2, 2)   
        END     
    AND N.Empresa = C.Empresa    
    WHERE N.Empresa = @Empresa   
  
  
    UPDATE #NaviExploraProntoPago SET Aplica=Mov, AplicaID=MovID WHERE LEN(Aplica) = 0 AND LEN(AplicaID)=0 AND Empresa = @Empresa 
    --DELETE FROM #NaviExploraProntoPago WHERE IDAplica IN (SELECT ID FROM Cxc WHERE ISNULL(NoDPP,0) = 1 AND Empresa = @Empresa) AND Empresa = @Empresa  
    DELETE FROM #NaviExploraProntoPago WHERE ISNULL(ImporteDesc,0)<1  
  
    DELETE FROM #NaviExploraProntoPago   
    FROM #NaviExploraProntoPago n      LEFT JOIN   (  
                    SELECT  c.ID, cd.Aplica+' '+cd.AplicaID AS Aplica, c.Empresa, c.mov, c.movid  
                    FROM Cxc c   
                    JOIN CxcD cd ON c.ID = cd.ID   
                    JOIN Movtipo m on m.Modulo ='CXC' AND c.Mov=m.Mov AND m.SubClave='CXC.NCPP'   
                    JOIN CxcAplica cx ON cd.Aplica=cx.Mov AND cd.AplicaID=cx.MovID AND c.Empresa = cx.Empresa AND ISNULL(cx.Saldo,0)=0  
                    WHERE c.Estatus='CONCLUIDO' AND cd.Aplica NOT IN ('REDONDEO')   
                )   nc ON n.Mov+' '+n.MovID = nc.Aplica   
    AND n.Empresa=nc.Empresa  
    WHERE n.Empresa=@Empresa    
    AND nc.ID IS not NULL   
  
 IF @DIAS <>0  
  DELETE FROM #NaviExploraProntoPago WHERE Dias > @DIAS  
 ELSE  
  DELETE FROM #NaviExploraProntoPago WHERE Total = 0  


 DECLARE crInsertaNaviExploraProntoPago CURSOR FAST_FORWARD FOR  
 SELECT ID,  
   Empresa,  
   Mov,  
   MovID,  
   FechaPago,  
   Aplica,  
   AplicaID,  
   IDAplica  
 FROM #NaviExploraProntoPago
  
 OPEN crInsertaNaviExploraProntoPago  
 FETCH NEXT FROM crInsertaNaviExploraProntoPago INTO @IDInsertar,@EmpresaInsertar,@MovInsertar,@MovIDInsertar,@FechaPagoInsertar,@AplicaInsertar,@AplicaIDInsertar,@IDAplicaInsertar  
  
 WHILE @@FETCH_STATUS = 0  
 BEGIN  
  IF EXISTS (  
      SELECT TOP (1)   
       0   
      FROM NaviExploraProntoPago   
      WHERE ID = @IDInsertar   
      AND  Empresa = @EmpresaInsertar   
      AND  Mov = @MovInsertar   
      AND  MovID = @MovIDInsertar   
      --AND  FechaPago = @FechaPagoInsertar   
      AND  Aplica = @AplicaInsertar   
      AND  AplicaID = @AplicaIDInsertar  
      AND  IDAplica = @IDAplicaInsertar  
      --AND     Seleccionar = 1  
     )  
  BEGIN  

   SELECT TOP(1) @Seleccionar = Seleccionar, @LiberarEjecutivoS = LiberaEjec, @LiberaGerenteS = LiberaGerente, @ProcesadoM = Procesado, @Eliminar = NoDPP, @ImporteTotalX = Total, @DescuentoX = ImporteDesc, @Modificar = Modificar  FROM NaviExploraProntoPago WHERE ID = @IDInsertar AND  Empresa = @EmpresaInsertar AND  Mov = @MovInsertar AND  MovID = @MovIDInsertar /*AND  FechaPago = @FechaPagoInsertar*/ AND  Aplica = @AplicaInsertar AND  AplicaID = @AplicaIDInsertar AND IDAplica = @IDAplicaInsertar  
   DELETE FROM NaviExploraProntoPago WHERE ID = @IDInsertar AND Empresa = @EmpresaInsertar AND Mov = @MovInsertar AND MovID = @MovIDInsertar /*AND FechaPago = @FechaPagoInsertar*/ AND Aplica = @AplicaInsertar AND AplicaID = @AplicaIDInsertar AND IDAplica = @IDAplicaInsertar AND ISNULL(Seleccionar,0) = ISNULL(@Seleccionar,0) AND ISNULL(LiberaEjec,0) = ISNULL(@LiberarEjecutivoS,0) AND ISNULL(LiberaGerente,0) = ISNULL(@LiberaGerenteS,0) AND ISNULL(Procesado,0) = ISNULL(@ProcesadoM,0) AND ISNULL(@Eliminar,0) = ISNULL(NoDPP,0)   
   INSERT INTO NaviExploraProntoPago  
   SELECT  
   ID    ,  
   Empresa   ,  
   Mov    ,  
   MovID   ,  
   Cliente   ,  
   NombreCte  ,  
   Agente   ,  
   FechaEmision  ,  
   Importe   ,  
   IVA    ,  
   Retencion  ,  
   Anticipo  ,  
   Total  ,
   Dias   ,  
   FechaPago  ,  
   Descuento  ,  
   IIF(ISNULL(@Modificar,0) = 0, ImporteDesc, @DescuentoX)  , --20250707 Se cambia el Importe que calcula nativamente la herramienta por el que modifica el usuario ImporteDesc se cambia por @DescuentoX  
   @LiberarEjecutivoS  ,  
   Ejecutivo  ,  
   @LiberaGerenteS  ,  
   Gerente   ,  
   Moneda   ,  
   TipoCambio  ,  
   @ProcesadoM  ,  
   Aplica   ,  
   AplicaID  ,  
   Parcial   ,  
   IDAplica  ,  
   @Seleccionar     ,  
   @Eliminar     ,
   @Modificar
   FROM #NaviExploraProntoPago  
   WHERE ID = @IDInsertar   
   AND  Empresa = @EmpresaInsertar   
   AND  Mov = @MovInsertar   
   AND  MovID = @MovIDInsertar   
   AND  FechaPago = @FechaPagoInsertar   
   AND  Aplica = @AplicaInsertar   
   AND  AplicaID = @AplicaIDInsertar  
   AND  IDAplica = @IDAplicaInsertar

   IF ISNULL(@Eliminar,0) = 1
   BEGIN
	  IF NOT EXISTS (  
      SELECT TOP (1)   
       0   
      FROM NaviExploraProntoPagoEliminadas   
      WHERE ID = @IDInsertar   
      AND  Empresa = @EmpresaInsertar   
      AND  Mov = @MovInsertar   
      AND  MovID = @MovIDInsertar   
      --AND  FechaPago = @FechaPagoInsertar   
      AND  Aplica = @AplicaInsertar   
      AND  AplicaID = @AplicaIDInsertar  
      AND  IDAplica = @IDAplicaInsertar  
      --AND     Seleccionar = 1
     ) 
	 BEGIN
		INSERT INTO NaviExploraProntoPagoEliminadas  
		SELECT  
		ID    ,  
		Empresa   ,  
		Mov    ,  
		MovID   ,  
		Cliente   ,  
		NombreCte  ,  
		Agente   ,  
		FechaEmision  ,  
		Importe   ,  
		IVA    ,  
		Retencion  ,  
		Anticipo  ,  
		Total   ,  
		Dias   ,  
		FechaPago  ,  
		Descuento  ,  
		ImporteDesc  ,  
		@LiberarEjecutivoS  ,  
		Ejecutivo  ,  
		@LiberaGerenteS  ,  
		Gerente   ,  
		Moneda   ,  
		TipoCambio  ,  
		@ProcesadoM  ,  
		Aplica   ,  
		AplicaID  ,  
		Parcial   ,  
		IDAplica  ,  
		@Seleccionar     ,  
		@Eliminar,
		0
		FROM #NaviExploraProntoPago  
		WHERE ID = @IDInsertar   
		AND  Empresa = @EmpresaInsertar   
		AND  Mov = @MovInsertar   
		AND  MovID = @MovIDInsertar   
		AND  FechaPago = @FechaPagoInsertar   
		AND  Aplica = @AplicaInsertar   
		AND  AplicaID = @AplicaIDInsertar  
		AND  IDAplica = @IDAplicaInsertar
	 END

   END

   FETCH NEXT FROM crInsertaNaviExploraProntoPago INTO @IDInsertar,@EmpresaInsertar,@MovInsertar,@MovIDInsertar,@FechaPagoInsertar,@AplicaInsertar,@AplicaIDInsertar,@IDAplicaInsertar  
  END  
  ELSE  
  BEGIN  
   INSERT INTO NaviExploraProntoPago  
   SELECT *,0  
   FROM #NaviExploraProntoPago  
   WHERE ID = @IDInsertar   
   AND  Empresa = @EmpresaInsertar   
   AND  Mov = @MovInsertar   
   AND  MovID = @MovIDInsertar   
 AND  FechaPago = @FechaPagoInsertar   
   AND  Aplica = @AplicaInsertar   
   AND  AplicaID = @AplicaIDInsertar  
   AND  IDAplica = @IDAplicaInsertar  
   FETCH NEXT FROM crInsertaNaviExploraProntoPago INTO @IDInsertar,@EmpresaInsertar,@MovInsertar,@MovIDInsertar,@FechaPagoInsertar,@AplicaInsertar,@AplicaIDInsertar,@IDAplicaInsertar  
  END  
  
 END  
  
 CLOSE crInsertaNaviExploraProntoPago  
 DEALLOCATE crInsertaNaviExploraProntoPago  

 INSERT INTO NaviExploraProntoPagoEliminadas
 SELECT n.*
 FROM NaviExploraProntoPago n
 LEFT JOIN NaviExploraProntoPagoEliminadas n2 ON n.ID = n2.ID AND n.Empresa = n2.Empresa AND n.Mov = n2.Mov AND n.MovID = n2.MovID /*AND n.FechaPago = n2.FechaPago*/ AND n.Aplica = n2.Aplica AND n.AplicaID = n2.AplicaID AND n.IDAplica = n2.IDAplica
 WHERE n2.ID IS NULL AND n2.Empresa IS NULL AND n2.Mov IS NULL AND n2.MovID IS NULL AND n2.FechaPago IS NULL AND n2.Aplica  IS NULL AND n2.AplicaID IS NULL AND n2.IDAplica IS NULL AND ISNULL(n.NoDPP,0) = 1
	
	DELETE n FROM NaviExploraProntoPago n JOIN NaviExploraProntoPagoEliminadas n2 ON n.ID = n2.ID AND n.Empresa = n2.Empresa AND n.Mov = n2.Mov AND n.MovID = n2.MovID /*AND n.FechaPago = n2.FechaPago*/ AND n.Aplica = n2.Aplica AND n.AplicaID = n2.AplicaID AND n.IDAplica = n2.IDAplica
  
    SELECT n.ID, n.Empresa, n.Mov, n.MovID, Cliente, NombreCte, Agente, FechaEmision, Importe, IVA, Retencion, Anticipo, Total,   
    Dias, FechaPago, Descuento, ImporteDesc, LiberaEjec, Ejecutivo, LiberaGerente, Gerente, Moneda, TipoCambio,  
    Procesado, n.Aplica, AplicaID, Parcial, IDAplica, Seleccionar, ISNULL(NoDPP,0) NoDPP--, nc.mov, nc.MovID  
    FROM NaviExploraProntoPago n  
    WHERE n.Empresa=@Empresa  AND ISNULL(ImporteDesc,0)>1
    ORDER BY FechaEmision  
  
END

********************/
